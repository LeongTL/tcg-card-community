import type { TcgdexCard, TcgdexClient } from './tcgdex_client.ts';

export interface PriceRow {
  card_id: string;
  source: 'tcgplayer' | 'cardmarket';
  currency: string;
  low: number | null;
  mid: number | null;
  high: number | null;
  market: number | null;
  trend: number | null;
  avg1: number | null;
  avg7: number | null;
  avg30: number | null;
}

/** A replacement provider is a new class implementing this, not an app change. */
export interface PriceProvider {
  /** Cards the provider has no price for are left out of the result. */
  fetchPrices(cardIds: string[]): Promise<PriceRow[]>;
}

type Num = number | null | undefined;
const n = (v: Num): number | null => (typeof v === 'number' ? v : null);
const VARIANTS = ['normal', 'holofoil', 'reverse-holofoil', '1st-edition', '1st-edition-holofoil', 'unlimited', 'unlimited-holofoil'];

export function toPriceRows(card: TcgdexCard & { pricing?: Record<string, any> | null }): PriceRow[] {
  const rows: PriceRow[] = [];
  const cm = card.pricing?.cardmarket;
  if (cm && n(cm.trend) !== null) {
    rows.push({
      card_id: card.id, source: 'cardmarket', currency: cm.unit ?? 'EUR',
      low: n(cm.low), mid: n(cm.avg), high: null, market: n(cm.trend), trend: n(cm.trend),
      avg1: n(cm.avg1), avg7: n(cm.avg7), avg30: n(cm.avg30),
    });
  }
  const tp = card.pricing?.tcgplayer;
  const variant = tp && VARIANTS.find((v) => n(tp[v]?.marketPrice) !== null);
  if (tp && variant) {
    const p = tp[variant];
    rows.push({
      card_id: card.id, source: 'tcgplayer', currency: tp.unit ?? 'USD',
      low: n(p.lowPrice), mid: n(p.midPrice), high: n(p.highPrice), market: n(p.marketPrice), trend: null,
      avg1: null, avg7: null, avg30: null,
    });
  }
  return rows;
}

export class TcgdexPriceProvider implements PriceProvider {
  constructor(private client: TcgdexClient) {}
  async fetchPrices(cardIds: string[]): Promise<PriceRow[]> {
    const rows: PriceRow[] = [];
    for (let i = 0; i < cardIds.length; i += 10) {
      const cards = await Promise.all(cardIds.slice(i, i + 10).map((id) => this.client.getCard(id)));
      for (const card of cards) if (card) rows.push(...toPriceRows(card as never));
    }
    return rows;
  }
}
