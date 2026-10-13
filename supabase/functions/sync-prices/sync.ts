import type { PriceProvider, PriceRow } from '../_shared/price_provider.ts';

/** Upsert only, so a sync can never remove a card or a price. */
export interface PriceDb {
  /** Writes card_prices and one price_history row per (card, source, day). */
  upsertPrices(rows: PriceRow[], day: string): Promise<void>;
}

const BATCH = 100;

export async function syncPrices(
  provider: PriceProvider,
  db: PriceDb,
  cardIds: string[],
  day: string = new Date().toISOString().slice(0, 10),
): Promise<{ upserted: number; failed: number }> {
  let upserted = 0;
  let failed = 0;
  for (let i = 0; i < cardIds.length; i += BATCH) {
    const ids = cardIds.slice(i, i + BATCH);
    try {
      const rows = await provider.fetchPrices(ids);
      if (rows.length) await db.upsertPrices(rows, day);
      upserted += new Set(rows.map((r) => r.card_id)).size;
    } catch {
      failed += ids.length;
    }
  }
  return { upserted, failed };
}
