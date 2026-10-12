import { describe, expect, it } from 'vitest';
import { checkCards, type TcgdexCard, type TcgdexClient } from './check_coverage';

const clientWith = (cards: Record<string, TcgdexCard>): TcgdexClient => ({
  getCard: async (id) => cards[id] ?? null,
});

describe('checkCards', () => {
  it('reports_missing_price_as_false', async () => {
    const client = clientWith({
      'a-1': { id: 'a-1', rarity: 'Rare', image: 'https://img/a-1', pricing: {} },
    });

    const [report] = await checkCards(['a-1'], client);

    expect(report).toEqual({
      id: 'a-1',
      found: true,
      hasRarity: true,
      hasImage: true,
      hasPrice: false,
      priceSources: [],
    });
  });

  it('reports_unknown_card_as_not_found', async () => {
    const [report] = await checkCards(['nope-1'], clientWith({}));

    expect(report).toEqual({
      id: 'nope-1',
      found: false,
      hasRarity: false,
      hasImage: false,
      hasPrice: false,
      priceSources: [],
    });
  });

  it('lists_the_sources_that_have_a_price', async () => {
    const client = clientWith({
      'b-2': {
        id: 'b-2',
        rarity: 'Rare Holo',
        image: 'https://img/b-2',
        pricing: { tcgplayer: { normal: { marketPrice: 1.5 } }, cardmarket: null },
      },
    });

    const [report] = await checkCards(['b-2'], client);

    expect(report.hasPrice).toBe(true);
    expect(report.priceSources).toEqual(['tcgplayer']);
  });
});
