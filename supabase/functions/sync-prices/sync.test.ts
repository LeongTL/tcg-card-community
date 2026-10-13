import { assert, assertEquals } from 'jsr:@std/assert@1';
import { refreshFx } from './fx.ts';
import { syncPrices, type PriceDb } from './sync.ts';
import type { PriceProvider, PriceRow } from '../_shared/price_provider.ts';

function price(card_id: string, market = 1): PriceRow {
  return { card_id, source: 'cardmarket', currency: 'EUR', low: 0.5, mid: null, high: null, market, trend: market, avg1: null, avg7: null, avg30: null };
}

// Mirrors the real table keys: card_prices by (card, source), price_history by (card, source, day).
class FakeDb implements PriceDb {
  prices = new Map<string, PriceRow>();
  history = new Map<string, number>();
  cards = new Set(['a', 'b', 'c']); // the db has no delete method, so cards and prices can only stay
  upsertPrices(rows: PriceRow[], day: string) {
    for (const r of rows) {
      this.prices.set(`${r.card_id}|${r.source}`, r);
      if (r.market != null) this.history.set(`${r.card_id}|${r.source}|${day}`, r.market);
    }
    return Promise.resolve();
  }
}

const provider = (rows: PriceRow[]): PriceProvider => ({
  fetchPrices: (ids) => Promise.resolve(rows.filter((r) => ids.includes(r.card_id))),
});

Deno.test('price_sync_twice_same_day_writes_one_history_row', async () => {
  const db = new FakeDb();
  const p = provider([price('a'), price('b')]);
  await syncPrices(p, db, ['a', 'b'], '2026-10-13');
  const result = await syncPrices(p, db, ['a', 'b'], '2026-10-13');
  assertEquals(db.history.size, 2);
  assertEquals(db.prices.size, 2);
  assertEquals(result, { upserted: 2, failed: 0 });
});

Deno.test('price_sync_does_not_delete_cards_or_prices_when_provider_fails', async () => {
  const db = new FakeDb();
  await syncPrices(provider([price('a', 5)]), db, ['a'], '2026-10-12');
  const failing: PriceProvider = { fetchPrices: () => Promise.reject(new Error('provider down')) };
  const result = await syncPrices(failing, db, ['a', 'b'], '2026-10-13');
  assert(result.failed > 0);
  assertEquals(db.prices.get('a|cardmarket')?.market, 5);
  assertEquals(db.cards.size, 3);
});

Deno.test('price_sync_skips_cards_the_provider_omits', async () => {
  const db = new FakeDb();
  const result = await syncPrices(provider([price('a')]), db, ['a', 'b'], '2026-10-13');
  assertEquals(result, { upserted: 1, failed: 0 });
  assert(!db.prices.has('b|cardmarket'));
});

Deno.test('fx_refresh_stores_rates_and_keeps_old_ones_on_failure', async () => {
  const saved = new Map<string, number>([['USD', 4]]);
  const save = (currency: string, rate: number) => { saved.set(currency, rate); return Promise.resolve(); };
  const ok = (url: string) => Promise.resolve(Response.json({ rates: { MYR: url.includes('USD') ? 4.2 : 4.9 } }));
  assertEquals(await refreshFx(ok, save), { updated: 2, failed: 0 });
  assertEquals(saved.get('EUR'), 4.9);
  const down = () => Promise.resolve(new Response('no', { status: 500 }));
  assertEquals(await refreshFx(down, save), { updated: 0, failed: 2 });
  assertEquals(saved.get('USD'), 4.2); // unchanged
});
