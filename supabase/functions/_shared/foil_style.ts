export type FoilStyle = 'sir' | 'alt' | 'ultra' | 'holo' | 'gold' | 'reverse' | 'shiny' | 'cosmos' | 'plain';

// Keys are lower-case TCGdex rarity names. Rarity alone cannot tell a holo "Rare" from a plain one,
// so a bare "Rare" stays plain. shortcut: rarity-only mapping, upgrade when per-variant data is synced.
const BY_RARITY: Record<string, FoilStyle> = {
  'special illustration rare': 'sir',
  'illustration rare': 'alt',
  'double rare': 'ultra',
  'ultra rare': 'ultra',
  'holo rare v': 'ultra',
  'holo rare vmax': 'ultra',
  'holo rare vstar': 'ultra',
  'full art trainer': 'ultra',
  'ace spec rare': 'ultra',
  'black white rare': 'ultra',
  'rare holo': 'holo',
  'holo rare': 'holo',
  'rare holo lv.x': 'holo',
  'rare prime': 'holo',
  'legend': 'holo',
  'promo': 'holo',
  'classic collection': 'holo',
  'hyper rare': 'gold',
  'mega hyper rare': 'gold',
  'secret rare': 'gold',
  'crown': 'gold',
  'shiny rare': 'shiny',
  'shiny rare v': 'shiny',
  'shiny rare vmax': 'shiny',
  'shiny ultra rare': 'shiny',
  'one shiny': 'shiny',
  'two shiny': 'shiny',
  'amazing rare': 'cosmos',
  'radiant rare': 'cosmos',
  'futuristic rare': 'cosmos',
  'common': 'reverse',
  'uncommon': 'reverse',
};

export function foilStyleFor(rarity?: string | null): FoilStyle {
  return BY_RARITY[(rarity ?? '').trim().toLowerCase()] ?? 'plain';
}
