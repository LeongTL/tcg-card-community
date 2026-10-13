# TCG Card Community – Sub-project 1 Design

Oct 9, 2026 · @Leong

## Goal and scope

Sub-project 1 launches a trade loop for Pokémon card collectors in Malaysia: sign up, showcase cards, list one, agree a cash-on-delivery (COD) meetup, and review each other. It ships on Android and iOS together, built by one full-time developer.

**Decisions made**

- Goal: a real public launch, not a pilot or demo.
- Scope: trade loop, the tilt and foil card effect, card scan, reference prices with 1, 7 and 30-day change, nearby listings by distance, a Price dropped section, wanted requests, and a watchlist, and an in-app notification bell with an unread badge (no push alerts). Community feed, follows and collection value come in later sub-projects.
- Stack: Flutter and Supabase (Postgres, auth, storage, realtime, edge functions), built as a modular monolith: one Postgres schema and set of edge functions per module, with strict boundaries so a module can later be extracted into its own service.
- Card catalog: imported from TCGdex into our own `cards` table, re-synced when new sets release. The app never calls TCGdex live. Reference prices also come from TCGdex (TCGplayer and Cardmarket data), synced into our own tables and shown in RM as a reference price. One source means one set of card IDs and no matching between vendors. Scan reads the card's name and number on the phone and matches it to our catalog; photos never leave the device.
- Trust: email or Google sign-in plus phone OTP at launch. ID and face verification (eKYC) is dropped from the MVP and planned for the next phase (see the last section).
- Payments: none in this phase. All deals are COD.

**Assumptions to confirm**

- Launch market is Malaysia only, so PDPA applies.
- Android and iOS launch together, which needs Apple review time and the US$99/year developer account.

## Architecture

The Flutter app (iOS and Android) calls only Supabase over HTTPS, and row-level security in Postgres protects every table.

&#91;embedded content: architecture · app, Supabase and TCGdex\]

TCGdex never talks to the app. An edge function copies its card data into our `cards` table on a schedule, and users read the catalog from there. Auth, Postgres, Storage, Realtime and edge functions are all Supabase features, so one developer runs one backend. A second scheduled edge function refreshes reference prices from TCGdex into card\_prices, more often than the catalog (hourly to daily). Local, staging and production are three separate Supabase projects.

## Modules and scaling path

The backend is a modular monolith: five modules in one Supabase project, each owning its own data, so any one can be pulled out into a separate service when its load or team demands it.

| Module | Owns (Postgres schema) | Likely first to extract? |
| --- | --- | --- |
| `identity` | `profiles`, `user_flags`, verification level | No |
| `catalog` | `cards` and card\_prices with price\_history, plus the TCGdex and price sync jobs | Possibly, as a scheduled worker |
| `listings` | `collection_items`, `listings` | No |
| `deals` | `deals`, `messages` (realtime chat) | Yes, chat is the most likely load hotspot |
| `reviews` | `reviews` | No |

The `wanted_posts` and `watchlist` tables belong to the `listings` module.

The `notifications` table belongs to `identity`; other modules add events only by calling one function. Events: a new deal on your listing, a deal status change, a new chat message while you are away from the chat, a wanted request that matches a card you own, a price drop on a card you watch or a listing near you, and a review you received. The bell shows an unread count, updates live while the app is open through Realtime, and each item opens the related deal or card. Settings has one switch per event type.

**Boundary rules**

- A module reads and writes only its own schema's tables.
- Other modules reach its data only through a defined database view or edge function, never by joining its tables directly.
- Each module has its own edge functions and its own migration folder.
- Cross-module actions (for example completing a deal marks a listing sold and moves the card to the buyer) go through one small function the owning module provides, and a module never joins another module's tables, so joins across modules use a view such as the catalog card summary. Keeping every call a function means it can later become an API call or an event.
- Row-level security stays on every table inside each schema.

**Scaling path.** Launch as one Supabase project. When monitoring shows one module is the bottleneck, move its schema and functions to its own service and route the app to it, leaving the other modules untouched.

## Data model and security

Eight tables carry the trade loop, and row-level security (RLS) in Postgres decides who can read or write each row. A ninth table, card\_prices, holds reference prices per card (source, currency, market, low, trend, updated time) and is written only by the price sync job. A tenth table, price\_history, stores one row per card, source and day (price and date), written by the same job, so the app can show up or down percentages over 1, 7 and 30 days. Two more tables serve buyers: wanted\_posts (a user asks for a card, with a maximum price, a note and a coarse location) and watchlist (the cards a user is tracking). A notifications table feeds the bell: one row per event for a user, with a type, a link to the deal or card, and a read time.

| Table | Holds | Key fields |
| --- | --- | --- |
| `profiles` | One per user | display name, avatar, bio, city, approximate location (rounded), phone, `phone_verified_at`, `verification_level` |
| `cards` | Catalog, synced from TCGdex | TCGdex id, name, set, number, rarity, image URL, `foil_style` |
| `collection_items` | A user's copy of a card | owner, card, condition, status (`showcase` or `open_to_sell`) |
| `listings` | A card offered for sale or swap | price (RM), type (`sell` or `exchange`), active, in progress or sold, previous price and when it last dropped |
| `deals` | Buyer and seller on one listing, or on one wanted request | status: `contacting`, `arranged`, `handed_over`, `completed`, `cancelled` |
| `messages` | Deal chat | deal, sender, text, time |
| `reviews` | One per side of a completed deal | deal, reviewer, stars, comment. Profiles show the average stars and the review count, calculated from this table. |
| `user_flags` | Per-user switches | `enable_foil_effect` |

**Verification levels:** 0 = email or Google only, 1 = phone verified, 2 = ID and face verified through a provider (eKYC), reserved for the next phase. Browsing, following and showcasing work at level 0. Listing a card or starting a deal needs level 1.

**Access rules**

- Any signed-in user can read `cards` and active `listings`; only an admin can write `cards`.
- Users create, edit and delete only their own collection items, listings, wanted posts and watchlist entries.
- Only the two people in a deal can read its messages or move its status.
- A review is allowed only after the deal is `completed`, and only from someone who took part.
- Users can read their own `user_flags` but cannot change them.

**Privacy (PDPA):** only a city and a coarse location (rounded to about 1 km) are stored, and only with the user's permission; distances are calculated in Postgres (PostGIS), and the app shows them as approximate. Exact positions and exact meetup addresses are never stored. Phone numbers are never shown publicly and are deleted with the account.

## App structure, foil effect and deal flow

**App structure.** The Flutter app has a `core/` folder (theme, router, Supabase client), one `features/` folder per area (auth, home, cards, scan, collectibles, marketplace, deals, reviews, profile, settings) and a `shared/` folder (models and the foil widget). Each feature splits into `presentation` (screens), `domain` (models) and `data` (Supabase calls), so screens never query the database directly. State uses Riverpod and navigation uses go\_router. The bottom bar has four tabs: Home, Collectibles, Scan and Settings; the prototype's Community tab returns with the community feed in a later sub-project.

**Foil effect.** One shared widget, `RarityCard`, renders every card in the app. It reads the card's `foil_style` (for example `sir`, `ultra`, `vintage_holo`, `reverse`, `plain`), which is set once in the database from the card's rarity. Before animating it checks two gates: the user's `enable_foil_effect` flag, and the device (low-end phones and the OS reduce-motion setting fall back to a plain card). It draws tilt and glare from touch or motion input, with one fragment shader per style. A new style means one new shader and one new database value.

**Card scan.** The camera reads the card's name, number and set code on the phone using on-device text recognition, then looks the result up in our `cards` table. The app shows the best matches so the user confirms the right card, with manual search as a fallback. Photos never leave the device, which avoids upload cost and a PDPA concern. If accuracy is too low on foil, worn or non-English cards, a server-side image match or a paid recognition service can be added behind the same scan screen.

**Reference prices.** Card detail and scan results show a reference price from `card_prices`, converted to RM and labelled as a reference, because the data comes from US and European markets and not from Malaysian trades. The app never calls the price API live; a scheduled edge function refreshes the table, and the provider sits behind a small interface so it can be swapped. Next to the price the app shows an up or down arrow and the percentage change over 1, 7 and 30 days, calculated as (today − earlier) ÷ earlier × 100. On day one this uses TCGdex's own 1, 7 and 30-day averages; from launch the daily job also saves a snapshot to price\_history, which later powers charts and price-drop alerts.

**COD deal flow.** The four prototype steps map to a status on the `deals` row.

1. Contact: status `contacting`. Buyer and seller chat in realtime.
2. Arrange: status `arranged`. Both agree a public meetup area and time.
3. Handover: status `handed_over`. Cash and card change hands and both confirm in the app.
4. Done: status `completed`. The listing is marked sold and both sides can review.

A server function enforces the order, so a deal cannot reach `completed` unless both sides confirmed. Either side can cancel before handover, and each cancellation is recorded for abuse tracking. Cancelling reopens the listing. One buyer at a time: the first deal on a listing locks it as in progress, and other buyers are refused until that deal is cancelled; completing the deal marks the listing sold.

**Error handling.** A failed fetch shows a retry state. A failed image falls back to a placeholder. If the foil flag cannot be fetched, the effect defaults to off.

## Prototype screen map

Every screen of the prototype (`tcg-card-community-prototype_11.html`) is either kept, changed or removed for the MVP, so the Flutter build has no unexplained gaps. The Community tab is dropped, leaving four tabs.

| Prototype screen | MVP treatment |
| --- | --- |
| Onboarding | Kept as the create-profile step. The prototype has no login, so sign-up, log-in and phone OTP screens are added. The game chips become Pokémon only. |
| Home | Kept: search, filter chips (All, For sale, Exchange), Newly listed with View all. Changed: the swipeable header becomes two cards, Deals that need you and Wanted near you, and the collection value card is removed. Removed: Collectors to follow. Added back: a Price dropped section with View all (sort by biggest drop, newest or lowest price) and a Near you section ranked by distance. |
| Newly listed | Kept. |
| Search | Kept for card name, set and number, with All, For sale and Exchange filters. Searching for collectors is not in the MVP. |
| Card detail | Kept: foil hero card, rarity and foil name, reference price (low, market, high) with 7-day change, owners list with Contact seller and a price-drop badge (old price struck through, percent down). Changed: no price sparkline yet, since history is still building. Kept: Watch button, which adds the card to the watchlist. Added: a Looking for this card button that posts a wanted request. |
| COD deal (4 steps) | Kept. When the deal completes, the card moves into the buyer's collectibles and the listing is marked sold. |
| Scan | Kept as a real camera: best matches to confirm, card details, condition chips, then Save to my collectibles. |
| Collectibles (Cards, Deals, Reviews tabs) | Kept: cards, estimated value from reference prices, rating, deals count, Manage sheet (Open to sell or Showcase, asking price, condition, swap option), reviews with star breakdown, deals history. Removed: followers count, Message button and Preview as others. Kept: Share link for a public collection. |
| Review sheet | Kept. |
| Settings | Kept: profile card, My deals and reviews, Watchlist, My wanted posts, public collectibles and near-me preferences, COD note, Help and safety tips, Log out. Added: Delete account. Removed: Following row. The notifications toggle becomes one switch per event type for the in-app bell. |
| Edit profile | Kept: photo, name, city, bio. |
| My deals | Kept: active and completed. |
| All collectors and Following | Removed with follows. |
| Community | Removed. The tab returns with the community feed later. |
| Notification bell | Kept as an in-app notification centre with an unread badge. No push notifications, so users see new items when they open the app. |

**Screens the prototype lacks and the MVP adds:** sign-up and log-in, phone OTP, report and block, delete-account confirmation, post a wanted request, the Wanted near you list, the Watchlist, the Notifications list, and safe-meetup tips inside the deal flow.

**Open decisions on prototype features**

- [x] Decided: Near me and Near you use a coarse device location (rounded to about 1 km) with distance in km, falling back to city if permission is denied.
- [x] Decided: Price dropped (sellers who lowered their asking price) is in the MVP.
- [x] Decided: Wanted requests and the Watch button are in, with in-app indicators only (no push). An owner answers a request with I have this, which opens a deal chat linked to the request.
- [x] Decided: Share link only; direct messages and Preview as others are out.

## Testing, environments and launch

The release is gated by security tests on the database and a closed beta with real collectors.

**Testing**

| Layer | What it covers |
| --- | --- |
| Unit | Deal status rules, foil style mapping, price formatting |
| Database (RLS) | Two test users on local Supabase: user A cannot read B's chats, edit B's listings, or set their own flags |
| Widget | `RarityCard` with flag on, flag off, low-end device and image failure |
| Integration | Sign up, verify phone, add a card, list it, second user contacts the seller, both confirm handover, both review |
| Real devices | At least one low-end Android phone and one iPhone, where shader performance varies most, and scan accuracy on foil, worn and non-English cards |

**Environments.** Local, staging and production are separate Supabase projects that apply the same migration files in order. Flutter flavors give a clearly marked staging app. GitHub Actions runs the tests on every push and deploys to staging.

**Launch checklist**

- [ ] Privacy policy, terms, and in-app account deletion (required by both stores)
- [ ] PDPA consent at sign-up, a clear location-permission explanation, and a data deletion path
- [ ] Report and block for users and listings
- [ ] Safe-meetup guidance (public places) inside the deal flow
- [ ] Crash reporting (Crashlytics or Sentry) and basic analytics
- [x] Card image licensing and price-data terms checked (TCGdex)
- [ ] Catalog and price sync run against production, with daily history snapshots scheduled
- [ ] Closed beta of 20 to 50 collectors on TestFlight and Play internal testing

## Out of scope and open questions

Several features are deliberately left out of sub-project 1, and four questions stay open.

**Out of scope (later sub-projects):** community feed, push alerts for price drops, watchlist and wanted requests, follows, collection value widget, push notifications, price history charts, change percentages for graded values, and ID and face verification (eKYC). The schema and folders leave room for each.

**Open questions**

- [x] Card images: hotlink TCGdex image URLs, or copy them into our own storage? This depends on the licence. Checked 2026-10-13: the `tcgdex/cards-database` repo is MIT, but the MIT text does not say who owns the card art, and the repo states it is not affiliated with Nintendo or The Pokémon Company. Owner asked the TCGdex maintainers (2026-10-13) and was told the images can be used. Record the written reply in `docs/ops/` if there is one.
- [ ] Sync schedule: catalog per set release, prices hourly or daily? TCGdex licence (checked 2026-10-13): the database is MIT, which allows commercial use if the copyright and permission notice are kept. The site tcgdex.dev has no separate terms, rate limits or attribution rule. This is not legal advice; the Pokémon card names and art are still Nintendo / The Pokémon Company property.
- [ ] Phone OTP provider and its per-message cost in Malaysia. Status (Task 5): phone confirmation is wired in the database and `config.toml`, and local dev uses a fixed test OTP; no provider is chosen, so hosted projects cannot send real SMS yet.
- [ ] Dispute handling: what happens when a buyer and seller disagree about a completed deal?

* [ ] Source test, first task of the plan: check TCGdex against the three newest sets and about 20 tricky cards (reprints, promos, holo and reverse holo). Switch to Scrydex or Pokémon Price Tracker only if it is missing cards or has bad prices.

## Next phase: eKYC

ID and face verification is deferred from the MVP and should be built next, using a third-party provider and not our own system. The MVP relies on phone OTP, and level 2 in `verification_level` is reserved so no schema change is needed.

**Plan for the next phase**

- Require eKYC (ID document, liveness and face match) only to list a card or start a deal; browsing and showcasing stay open.
- Store only the pass or fail result, the date and the provider's reference. Never store ID or face images.
- Add a separate explicit PDPA consent screen for biometric data, plus a deletion path.
- Keep the provider behind a small interface in the code so it can be swapped.

**Published prices (May 2026, check with each vendor)**

| Provider | Price per verification | Minimum or free tier |
| --- | --- | --- |
| Didit | US$0.30 | No minimum; 500 free checks per month |
| Sumsub | US$1.35 to US$1.85 | US$149 to US$299 per month, annual commitment |
| KYCAID | €0.75 to €1.10 | €50 at registration |

The Didit page is vendor-published, so competitor figures are indicative. None of these pages confirmed MyKad support, so each shortlisted provider needs a MyKad test and a Malaysian quote, including local providers that do not publish prices.

**Questions for the next phase**

- [ ] Which provider supports MyKad and low-end Android phones at an acceptable cost per verified user?
- [ ] How many free or discounted checks can we get during the beta?
- [ ] What happens to users whose check fails: retry limit, manual review, or appeal?

## Graded cards (added to MVP)

**Grading companies supported:** PSA, BGS (Beckett), CGC, SGC, ACE, TAG, and Other (free-text name). Graded sales data from our price source covers PSA, CGC, BGS and SGC; for ACE, TAG and Other we store the grade and show it as a badge but show no graded value (the value panel says "No graded price for this grader yet").

**On each collectible:** optional grading company, grade (e.g. 10, 9.5), optional special label (e.g. BGS Black Label, CGC Pristine) and optional certificate number. A graded item shows a badge such as "PSA 10" on the manage sheet, collectible details, listing, Home cards and the deal chat header. Raw condition chips apply only to ungraded cards.

**Scanning a slab:** the scan screen reads the slab label on the phone (same on-device text reading as raw cards) and fills grading company, grade, certificate number and card name; the user confirms every field before saving. Photos still never leave the phone. Looking up the certificate number against the grader's own website is not in the MVP.

**Value panel on card detail:** one price panel with switch chips: PSA 10 (default), PSA 9, BGS 9.5, BGS 9, CGC 10, and Raw. When the user opens one of their own graded cards or a graded listing, the panel opens on that card's own grade instead. Each value is the median of recent eBay sold prices converted to RM, labelled "reference price, recent eBay sales", with the sale count; a grade with too few sales shows "Not enough sales" rather than a number. Raw keeps the TCGdex price and 1/7/30-day change from before. Change % for graded values is out of the MVP (no daily history yet).

**Data source change:** TCGdex has no graded prices. Graded values come from Pokémon Price Tracker (eBay sold data; graded call costs 2 credits per card; free tier 100 credits a day, API tier US$9.99 a month for 20,000 credits a day). Because we cannot refresh every card daily on the free tier, graded values are fetched on demand by a server function the first time a card is viewed, cached in our own table, and refreshed when older than 24 hours. The app still never calls the provider directly. Open questions: confirm the provider's commercial-use licence, and that its graded coverage for Malaysian-popular sets is good enough (added to the source test).
