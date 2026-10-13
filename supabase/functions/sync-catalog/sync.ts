import { foilStyleFor } from '../_shared/foil_style.ts';
import type { TcgdexCard, TcgdexClient } from '../_shared/tcgdex_client.ts';

export interface CardRow {
  id: string;
  name: string;
  set_id: string | null;
  set_name: string | null;
  number: string | null;
  rarity: string | null;
  hp: number | null;
  image_url: string | null;
  foil_style: string;
}

/** Upsert only: there is deliberately no delete, so a sync can never remove a card. */
export interface Db {
  upsertCards(cards: CardRow[]): Promise<void>;
}

const BATCH = 200;
const CONCURRENCY = 10;

export function toRow(c: TcgdexCard): CardRow {
  return {
    id: c.id,
    name: c.name,
    set_id: c.set?.id ?? null,
    set_name: c.set?.name ?? null,
    number: c.localId ?? null,
    rarity: c.rarity ?? null,
    hp: c.hp ?? null,
    image_url: c.image ? `${c.image}/high.webp` : null,
    foil_style: foilStyleFor(c.rarity),
  };
}

async function inChunks<T>(items: T[], size: number, fn: (chunk: T[]) => Promise<void>) {
  for (let i = 0; i < items.length; i += size) await fn(items.slice(i, i + size));
}

export async function syncCatalog(
  client: TcgdexClient,
  db: Db,
  opts: { setIds?: string[] } = {},
): Promise<{ upserted: number; failed: number }> {
  let upserted = 0;
  let failed = 0;
  let setIds = opts.setIds;
  if (!setIds) {
    try {
      setIds = (await client.listSets()).map((s) => s.id);
    } catch {
      return { upserted, failed: 1 };
    }
  }
  for (const setId of setIds) {
    const rows: CardRow[] = [];
    try {
      const set = await client.getSet(setId);
      await inChunks(set.cards, CONCURRENCY, async (chunk) => {
        await Promise.all(chunk.map(async ({ id }) => {
          try {
            const card = await client.getCard(id);
            if (card) rows.push(toRow(card)); else failed++;
          } catch {
            failed++;
          }
        }));
      });
    } catch {
      failed++;
    }
    await inChunks(rows, BATCH, async (batch) => {
      try {
        await db.upsertCards(batch);
        upserted += batch.length;
      } catch {
        failed += batch.length;
      }
    });
  }
  return { upserted, failed };
}
