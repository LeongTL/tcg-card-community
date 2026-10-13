import { assertEquals, assert } from 'jsr:@std/assert@1';
import { foilStyleFor } from '../_shared/foil_style.ts';
import type { TcgdexClient, TcgdexCard } from '../_shared/tcgdex_client.ts';
import { syncCatalog, type CardRow, type Db } from './sync.ts';

function card(id: string, rarity = 'Common'): TcgdexCard {
  const [setId, localId] = id.split('-');
  return { id, localId, name: `Card ${id}`, rarity, hp: 50, image: `https://img/${setId}/${localId}`, set: { id: setId, name: `Set ${setId}` } };
}

class FakeClient implements TcgdexClient {
  failCards = new Set<string>();
  failSets = new Set<string>();
  constructor(public sets: Record<string, TcgdexCard[]>) {}
  listSets() { return Promise.resolve(Object.keys(this.sets).map((id) => ({ id, name: `Set ${id}` }))); }
  getSet(id: string) {
    if (this.failSets.has(id)) return Promise.reject(new Error(`set ${id} down`));
    return Promise.resolve({ id, name: `Set ${id}`, cards: this.sets[id].map((c) => ({ id: c.id })) });
  }
  getCard(id: string) {
    if (this.failCards.has(id)) return Promise.reject(new Error(`card ${id} down`));
    return Promise.resolve(Object.values(this.sets).flat().find((c) => c.id === id) ?? null);
  }
}

// The Db interface has no delete method, so a missing card can only stay.
class FakeDb implements Db {
  rows = new Map<string, CardRow>();
  upsertCards(cards: CardRow[]) {
    for (const c of cards) this.rows.set(c.id, c);
    return Promise.resolve();
  }
}

Deno.test('foil_style_maps_special_illustration_rare_to_sir', () => {
  assertEquals(foilStyleFor('Special illustration rare'), 'sir');
  assertEquals(foilStyleFor('special illustration rare'), 'sir');
});

Deno.test('foil_style_maps_unknown_rarity_to_plain', () => {
  assertEquals(foilStyleFor('Some Future Rarity'), 'plain');
  assertEquals(foilStyleFor(''), 'plain');
  assertEquals(foilStyleFor(undefined), 'plain');
});

Deno.test('sync_is_idempotent_when_run_twice', async () => {
  const client = new FakeClient({ a: [card('a-1'), card('a-2', 'Hyper rare')], b: [card('b-1')] });
  const db = new FakeDb();
  const first = await syncCatalog(client, db);
  const sizeAfterFirst = db.rows.size;
  const second = await syncCatalog(client, db);
  assertEquals(first, { upserted: 3, failed: 0 });
  assertEquals(second, first);
  assertEquals(db.rows.size, sizeAfterFirst);
  assertEquals(db.rows.get('a-2')?.foil_style, 'gold');
  assertEquals(db.rows.get('a-1')?.image_url, 'https://img/a/1/high.webp');
});

Deno.test('sync_never_deletes_cards', async () => {
  const db = new FakeDb();
  await db.upsertCards([{ id: 'gone-1', name: 'Old', set_id: 'gone', set_name: 'Gone', number: '1', rarity: 'Rare', hp: 1, image_url: null, foil_style: 'plain' }]);
  await syncCatalog(new FakeClient({ a: [card('a-1')] }), db);
  assert(db.rows.has('gone-1'));
  assert(db.rows.has('a-1'));
});

Deno.test('sync_keeps_existing_cards_when_provider_fails_midway', async () => {
  const db = new FakeDb();
  await syncCatalog(new FakeClient({ a: [card('a-1')], b: [card('b-1')] }), db);
  const before = new Map(db.rows);
  const client = new FakeClient({ a: [card('a-1', 'Rare Holo')], b: [card('b-1'), card('b-2')], c: [card('c-1')] });
  client.failSets.add('a');
  client.failCards.add('b-2');
  const result = await syncCatalog(client, db);
  assert(result.failed > 0);
  for (const [id, row] of before) assertEquals(db.rows.get(id), row); // earlier rows untouched
  assert(db.rows.has('c-1')); // a healthy set after the failure still syncs
});

Deno.test('sync_counts_a_failed_batch_and_keeps_going', async () => {
  const db = new FakeDb();
  let calls = 0;
  const flaky: Db = { upsertCards: (c) => (++calls === 1 ? Promise.reject(new Error('db down')) : db.upsertCards(c)) };
  const result = await syncCatalog(new FakeClient({ a: [card('a-1')], b: [card('b-1')] }), flaky);
  assertEquals(result, { upserted: 1, failed: 1 });
});
