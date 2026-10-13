export interface TcgdexCard {
  id: string;
  localId?: string;
  name: string;
  rarity?: string | null;
  hp?: number | null;
  image?: string | null;
  set?: { id: string; name: string };
}

export interface TcgdexSet {
  id: string;
  name: string;
  cards: { id: string }[];
}

export interface TcgdexClient {
  listSets(): Promise<{ id: string; name: string }[]>;
  getSet(id: string): Promise<TcgdexSet>;
  /** Returns null when TCGdex answers 404. */
  getCard(id: string): Promise<TcgdexCard | null>;
}

const BASE = 'https://api.tcgdex.net/v2/en';

async function getJson<T>(path: string): Promise<T | null> {
  const res = await fetch(`${BASE}${path}`);
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`TCGdex ${res.status} for ${path}`);
  return (await res.json()) as T;
}

export const httpClient: TcgdexClient = {
  async listSets() {
    return (await getJson<{ id: string; name: string }[]>('/sets')) ?? [];
  },
  async getSet(id) {
    const set = await getJson<TcgdexSet>(`/sets/${encodeURIComponent(id)}`);
    if (!set) throw new Error(`TCGdex set ${id} not found`);
    return set;
  },
  getCard: (id) => getJson<TcgdexCard>(`/cards/${encodeURIComponent(id)}`),
};
