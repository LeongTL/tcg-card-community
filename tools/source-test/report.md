# TCGdex source test report

Run: 2026-10-13, `npm run check` in `tools/source-test`, TCGdex REST API v2, English.

## Result against the plan's rule (newest 3 sets by release date)

| Check | Needed | Got | |
|---|---|---|---|
| Cards found with rarity and image | >= 98% | 90.3% | FAIL |
| Cards with a TCGplayer or Cardmarket price | >= 90% | 39.0% | FAIL |
| 20 tricky cards found | all | 20/20 | PASS |

Newest 3 by date were `30th`, `30th-c` and `me05`.

## Why it fails: the sample, not the mainline sets

| Set | Released | Cards | Rarity + image | Price |
|---|---|---|---|---|
| 30th (30th Celebration) | 2026-09-16 | 158 | 100% | 0% |
| 30th-c (Classic Collection) | 2026-09-16 | 30 | 0% | 0% |
| me05 | 2026-07-17 | 120 | 100% | 100% |
| me04 | 2026-05-22 | 122 | 100% | 100% |
| me03 | 2026-03-27 | 124 | 100% | 100% |
| B2a | 2026-02-26 | 131 | 0% | 0% |
| me02.5 | 2026-01-30 | 295 | 100% | 100% |
| B2 | 2026-01-29 | 234 | 100% | 0% |

The three mainline sets (`me03` to `me05`) and `me02.5` pass at 100% on every check. The failures come from the 30th Celebration sets (two weeks old, no prices yet; `30th-c` has no rarity or image data) and from `B2`/`B2a`, which look like non-English-market sets with no price data.

## Tricky cards (20/20 found, images present)

Charizard reprints `base1-4`, `xy12-11`, `sv03-125`, `sv03.5-006`, `sv03.5-199`, `sv04.5-234`, `swsh9-018`; promos `basep-1`, `swshp-SWSH020`, `svp-001`; reverse holo `ex6-100`, `ecard1-1`, `dp1-1`, `me01-001`, `sv08-001`, `sv01-001`; holo and first edition `swsh1-1`, `neo1-9`, `base2-1`, `base1-58`.

Variant flags looked right for most (reverse holo true on the reverse-holo picks, `holo: true` on promos). Two to know about:
- `basep-1` (Pikachu promo) has no price from either source.
- `svp-001` (Sprigatito promo) has Cardmarket but no TCGplayer price.
- `xy12-11` (Charizard) lists `normal` only, though the real card is holo, so variant data is not fully reliable.

## Decision: PASS (owner-approved sample)

The owner chose a fixed sample instead of "newest 3 by date": `me05`, `me04`, `me03`, `me02.5` and `sv03.5` (151). Brand-new special sets (`30th`, `30th-c`) are left out because they have no prices yet.

| Check | Needed | Got | |
|---|---|---|---|
| Cards found with rarity and image | >= 98% | 100.0% | PASS |
| Cards with a TCGplayer or Cardmarket price | >= 90% | 100.0% | PASS |
| 20 tricky cards found | all | 20/20 | PASS |

TCGdex stays as the source. Scrydex is not needed. Watch point: a set released in the last few weeks may lack prices at first.
