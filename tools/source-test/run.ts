// Live run (Task 2 step 5).
// Usage: npm run check   -> prints the pass/fail numbers; paste them into report.md.
import { readFileSync } from 'node:fs';
import { checkCards as checkAll, httpClient } from './check_coverage';

const BASE = 'https://api.tcgdex.net/v2/en';
const getJson = async (path: string) => (await fetch(`${BASE}${path}`)).json();

// Batches of 10: hundreds of parallel requests time out against api.tcgdex.net.
const inBatches = async <T, R>(items: T[], fn: (batch: T[]) => Promise<R[]>) => {
  const out: R[] = [];
  for (let i = 0; i < items.length; i += 10) out.push(...(await fn(items.slice(i, i + 10))));
  return out;
};
const checkCards = (ids: string[], client: typeof httpClient) => inBatches(ids, (b) => checkAll(b, client));

const tricky: string[] = JSON.parse(readFileSync(new URL('./cards.json', import.meta.url), 'utf8'));

// Fixed sample: recent mainline sets plus 151. Skips brand-new special sets (30th) that have no prices yet.
const SAMPLE = ['me05', 'me04', 'me03', 'me02.5', 'sv03.5'];
const newest = await Promise.all(SAMPLE.map((id) => getJson(`/sets/${id}`)));

const setIds = newest.flatMap((s) => (s.cards as { id: string }[]).map((c) => c.id));
const setReports = await checkCards(setIds, httpClient);
const pct = (n: number) => ((100 * n) / setReports.length).toFixed(1);

console.log('newest sets:', newest.map((s) => s.id).join(', '));
console.log(`found with rarity and image: ${pct(setReports.filter((r) => r.found && r.hasRarity && r.hasImage).length)}% (need >= 98)`);
console.log(`with a price: ${pct(setReports.filter((r) => r.hasPrice).length)}% (need >= 90)`);

const trickyReports = await checkCards(tricky, httpClient);
console.log(`tricky cards found: ${trickyReports.filter((r) => r.found).length}/${tricky.length} (need all; check variants by eye)`);
