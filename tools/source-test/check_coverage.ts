export interface TcgdexCard {
  id: string;
  rarity?: string | null;
  image?: string | null;
  pricing?: Record<string, unknown> | null;
}

export interface TcgdexClient {
  /** Returns null when TCGdex answers 404. */
  getCard(id: string): Promise<TcgdexCard | null>;
}

export interface CardReport {
  id: string;
  found: boolean;
  hasRarity: boolean;
  hasImage: boolean;
  hasPrice: boolean;
  priceSources: string[];
}

const BASE = 'https://api.tcgdex.net/v2/en';

export const httpClient: TcgdexClient = {
  async getCard(id) {
    const res = await fetch(`${BASE}/cards/${encodeURIComponent(id)}`);
    if (res.status === 404) return null;
    if (!res.ok) throw new Error(`TCGdex ${res.status} for card ${id}`);
    return (await res.json()) as TcgdexCard;
  },
};

export async function checkCards(ids: string[], client: TcgdexClient): Promise<CardReport[]> {
  return Promise.all(
    ids.map(async (id): Promise<CardReport> => {
      const card = await client.getCard(id);
      if (!card) {
        return { id, found: false, hasRarity: false, hasImage: false, hasPrice: false, priceSources: [] };
      }
      const priceSources = Object.entries(card.pricing ?? {})
        .filter(([source, value]) => (source === 'tcgplayer' || source === 'cardmarket') && value)
        .map(([source]) => source);
      return {
        id,
        found: true,
        hasRarity: Boolean(card.rarity),
        hasImage: Boolean(card.image),
        hasPrice: priceSources.length > 0,
        priceSources,
      };
    }),
  );
}
