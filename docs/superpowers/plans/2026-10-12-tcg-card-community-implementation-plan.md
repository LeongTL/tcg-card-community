# TCG Card Community – Sub-project 1 Implementation Plan

Oct 9, 2026 · @Leong

> **For agentic workers:** use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task by task. Steps use checkbox syntax for tracking.

**Goal:** build and release the MVP of TCG Card Community: a Flutter app on Android and iOS, backed by Supabase, where Malaysian Pokémon collectors scan, list, price and trade cards through cash-on-delivery deals.

**Architecture:** a Flutter client talks only to one Supabase project. The backend is a modular monolith with five modules (`identity`, `catalog`, `listings`, `deals`, `reviews`), each owning its own Postgres schema, migrations and edge functions. TCGdex feeds the `cards`, `card_prices` and `price_history` tables through scheduled sync jobs; the app never calls TCGdex.

**Tech stack:** Flutter and Dart, Riverpod, go\_router, Supabase (Postgres with PostGIS, Auth, Storage, Realtime, Edge Functions in TypeScript), Google ML Kit text recognition for scan, fragment shaders for the foil effect, GitHub Actions for CI, k6 for load tests.

**Spec:** the approved design doc, [TCG Card Community – Sub-project 1 Design](https://claude.ai/code/artifact/befdb8aa-0203-4863-8611-74d32a5ef55c). Executors read it alongside this plan.

## Global constraints

Every task's requirements include these, copied from the spec.

- Platforms: Android and iOS launch together, from one Flutter codebase.
- Backend: Supabase only. One Postgres schema per module (`identity`, `catalog`, `listings`, `deals`, `reviews`). A module reads and writes only its own schema's tables and reaches other modules through a view or a function, never a direct join.
- Security: row-level security on every table. Users cannot write their own `user_flags`, `verification_level`, or deal status. Deal status changes go through a server function.
- Catalog and raw-card prices: TCGdex, copied into our tables by scheduled jobs. Graded prices: Pokémon Price Tracker (eBay sold data), fetched on demand by the graded-price function and cached. The app never calls either provider directly.
- Prices: shown in RM as a labelled reference price, with 1, 7 and 30-day change = (today − earlier) ÷ earlier × 100. Day-one change uses TCGdex's own 1, 7 and 30-day averages; the daily job also writes `price_history`.
- Trust: email or Google sign-in plus phone OTP. Listing a card or starting a deal needs `verification_level` 1. Level 2 is reserved for eKYC and not built.
- Payments: none. Every deal is cash on delivery.
- Privacy (PDPA): store a city and a location rounded to about 1 km, only with permission. Never store exact positions or exact meetup addresses. Phone numbers are never public. Account deletion removes personal data. Location falls back to city if permission is denied.
- Foil effect: one shared `RarityCard` widget draws every card. It is gated by the user's `enable_foil_effect` flag and falls back to a plain card on low-end devices, with reduce-motion on, or if the flag cannot be fetched.
- Scan: text is read on the phone and photos never leave the device.
- Notifications: in-app only, with an unread badge on the bell. No push notifications.
- Look: grayscale with one accent, `#ff6a1a`. Four tabs: Home, Collectibles, Scan, Settings.
- Environments: local, staging and production as separate Supabase projects, applying the same migration files in order.

## Review focus

The spec is silent on these inputs, and each would hurt a real user. The task that owns each one carries its test.

1. A card with no TCGdex price (the provider omits it): show "no reference price", never `NaN`, `0` or a crash. Owned by Task 7 and Task 10.
2. A missing or zero earlier price, or a first day with no history: the change shows a dash, never infinity or a divide-by-zero error. Owned by Task 7.
3. Two buyers contact one listing, or the listing sells while a chat is open: the second deal is refused, and completing a deal twice changes nothing the second time. Owned by Task 14.
4. Location permission denied, location turned off, or a user with no stored position: Near me and Wanted near you fall back to city, with no crash. Owned by Task 12 and Task 17.
5. A catalog or price sync that is interrupted or run twice: it is an upsert, never deletes cards, and existing listings keep pointing at valid cards. Owned by Task 6 and Task 7.

## File structure

One repository holds the app, the backend and the tools. Each folder has one job.

```
tcg-card-community/
├── app/                          Flutter app (iOS and Android)
│   ├── lib/core/                 theme, router, Supabase client, config, formatters
│   ├── lib/shared/               models, services, and rarity_card/ (the foil widget)
│   ├── lib/features/             auth, home, cards, scan, collectibles, marketplace,
│   │                             deals, reviews, wanted, watchlist, notifications,
│   │                             profile, settings (each: presentation, domain, data)
│   ├── assets/shaders/           one fragment shader per foil style
│   ├── test/                     unit and widget tests, mirroring lib/
│   └── integration_test/         end-to-end flows
├── supabase/
│   ├── migrations/               SQL, flat, prefixed by module (identity_, catalog_, ...)
│   ├── functions/                sync-catalog, sync-prices, deal-transition, notify, delete-account
│   ├── tests/                    pgTAP tests for row-level security and SQL functions
│   └── seed.sql                  dummy data for local and staging
├── tools/
│   ├── source-test/              the TCGdex coverage check (Task 2)
│   └── loadtest/                 k6 scripts (Task 20)
└── .github/workflows/            CI: test on push, deploy to staging, gated release
```

**One deliberate difference from the design doc.** The Supabase CLI only reads a flat `supabase/migrations/` folder, so each module's migrations are separated by a name prefix and by Postgres schema, not by separate folders. The module boundary rules are unchanged.

## Phase 0: setup and spikes

### Task 1: Project scaffold, flavors and CI

**Files:**

- Create: `app/` (Flutter project), `app/lib/core/config/app_config.dart`, `app/test/core/app_config_test.dart`, `.env.example`, `.gitignore`
- Create: `supabase/config.toml` (from `supabase init`), `.github/workflows/ci.yml`

**Interfaces:**

- Produces: `class AppConfig { final String flavor; final String supabaseUrl; final String supabaseAnonKey; factory AppConfig.fromEnvironment(); }` with flavors `staging` and `prod`, read from `--dart-define-from-file`.

* [ ] **Step 1: Write failing tests in `app_config_test.dart`:** `reads_flavor_and_keys_from_environment` (a map with `FLAVOR=staging`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` gives matching fields) and `throws_when_a_key_is_missing` (a missing `SUPABASE_URL` throws `StateError`).
* [ ] **Step 2: Run `flutter test app/test/core/app_config_test.dart`.** Expected: FAIL, `AppConfig` is not defined.
* [ ] **Step 3: Implement `AppConfig`** in `app_config.dart`, reading `String.fromEnvironment` values and failing fast on an empty one. Add Android flavors and iOS schemes named `staging` and `prod`, with a different app name and icon banner for staging.
* [ ] **Step 4: Run the tests again.** Expected: PASS.
* [ ] **Step 5: Create `ci.yml`** to run `flutter analyze` and `flutter test` on every push. Expected: a green run on the first push.
* [ ] **Step 6: Commit** with `feat: scaffold flutter app, flavors and ci`.

### Task 1b: Hosted Supabase projects, secrets and deploy pipeline

Task 6 Step 5, Task 20 and Task 21 all run against hosted projects, so they are created here, before any migration exists.

**Files:**

- Create: `docs/ops/supabase-setup.md`, `.github/workflows/deploy-staging.yml`, `.github/workflows/deploy-prod.yml`
- Modify: `.env.example` (document every variable, with no real values)

**Interfaces:**

- Produces: two hosted Supabase projects (`staging`, `prod`) in the region closest to Malaysia (Singapore); GitHub repository secrets `SUPABASE_ACCESS_TOKEN`, `STAGING_PROJECT_REF`, `STAGING_DB_PASSWORD`, `PROD_PROJECT_REF`, `PROD_DB_PASSWORD`; Edge Function secrets `PRICE_PROVIDER_KEY` (Pokémon Price Tracker), `FX_API_KEY` if the chosen rate source needs one, and the SMS provider credentials, set per project with `supabase secrets set`.
- Rule: the service-role key lives only in Edge Function secrets and is never in the app, `.env.example` or the repository. The app gets only the project URL and anon key.

* [ ] **Step 1: Create the `staging` and `prod` projects** in the Supabase dashboard, turn on daily backups for `prod`, and write both project refs and the region in `docs/ops/supabase-setup.md`.
* [ ] **Step 2: Link locally** with `supabase link --project-ref <staging>` and check that `supabase db push --dry-run` reports nothing to apply and no errors.
* [ ] **Step 3: Set the secrets.** Add the GitHub repository secrets and run `supabase secrets set` on each project for the Edge Function secrets. Provider keys not yet bought stay empty and are listed as open in `supabase-setup.md`; the functions that need them fail with a clear error and not a crash.
* [ ] **Step 4: Write `deploy-staging.yml`** to run on every push to `main` after the CI workflow passes: `supabase db push` then `supabase functions deploy`, both against staging. Write `deploy-prod.yml` as manual (`workflow_dispatch`) behind a GitHub environment that needs an approval, running the same two commands against `prod`.
* [ ] **Step 5: Verify.** Expected: a green staging deploy on the first push with no migrations yet, and a manual `prod` run waiting for approval and not deploying until it is given.
* [ ] **Step 6: Commit** with `chore: supabase environments and deploy pipeline`.

### Task 2: TCGdex source test

This task decides whether TCGdex is good enough. Nothing later is built on it until it passes.

**Files:**

- Create: `tools/source-test/check_coverage.ts`, `tools/source-test/check_coverage.test.ts`, `tools/source-test/cards.json`, `tools/source-test/report.md`

**Interfaces:**

- Produces: `checkCards(ids: string[], client: TcgdexClient): Promise<CardReport[]>` where `CardReport = { id: string; found: boolean; hasRarity: boolean; hasImage: boolean; hasPrice: boolean; priceSources: string[] }`. Also produces a pass or fail decision in `report.md`.

* [ ] **Step 1: Write failing tests** in `check_coverage.test.ts` with a stubbed client: `reports_missing_price_as_false` (a card with no pricing gives `hasPrice: false` and `priceSources: []`) and `reports_unknown_card_as_not_found` (a 404 gives `found: false`).
* [ ] **Step 2: Run `npx vitest tools/source-test`.** Expected: FAIL.
* [ ] **Step 3: Implement `checkCards`** against the TCGdex REST API in English, using the three newest sets from `/sets` plus the 20 tricky cards in `cards.json` (reprints, promos, holo and reverse holo variants).
* [ ] **Step 4: Run the unit tests.** Expected: PASS.
* [ ] **Step 5: Run it against live TCGdex and write `report.md`.** Pass means at least 98% of the newest sets' cards are found with rarity and image, at least 90% have a TCGplayer or Cardmarket price, and all 20 tricky cards are found with the right variant. On a fail, record Scrydex as the replacement behind the provider interface in Task 7, and tell the owner before continuing.
* [ ] **Step 6: Read the licence** in the `tcgdex/cards-database` repository and the TCGdex terms, then record whether commercial use in a public app is allowed in the design doc's open questions.
* [ ] **Step 7: Commit** with `chore: tcgdex source test and report`.

### Task 3: Foil shader spike

This is throwaway code. Its output is a measurement and a decision, not a merged feature.

**Files:**

- Create: `app/assets/shaders/foil_sir.frag`, `app/lib/shared/rarity_card/spike/spike_page.dart`, `app/lib/shared/rarity_card/SPIKE.md`

**Interfaces:**

- Produces: a decision in `SPIKE.md` between fragment shaders and layered gradients for the foil styles, with measured frame times.

* [ ] **Step 1: Build `spike_page.dart`** showing one large card with tilt and the SIR rainbow foil shader, and a 3-column grid of 9 cards with a static foil where only the touched card tilts.
* [ ] **Step 2: Run it on the lowest-end Android phone you have and on an iPhone** in profile mode, and record the average frame time over 10 seconds of tilting.
* [ ] **Step 3: Apply the threshold:** average at least 45 frames per second for the single card, and at least 30 for the grid. If shaders miss it, repeat Step 2 with layered gradients and blend modes.
* [ ] **Step 4: Write the decision and the numbers in `SPIKE.md`.** Task 8 builds `RarityCard` on whichever approach passed.
* [ ] **Step 5: Commit** the note only, with `docs: foil shader spike result`. Delete `spike/`.

## Phase 1: backend foundations

### Task 4: Schemas, migrations and row-level security

**Files:**

- Create: `supabase/migrations/0100_extensions.sql` (PostGIS), and one migration per module: `0110_identity_schema.sql`, `0120_catalog_schema.sql`, `0130_listings_schema.sql`, `0140_deals_schema.sql`, `0150_reviews_schema.sql`, and `0160_api_and_realtime.sql` (schema grants and the Realtime publication)
- Create: `supabase/tests/rls_identity.test.sql`, `rls_catalog.test.sql`, `rls_listings.test.sql`, `rls_deals.test.sql`, `rls_reviews.test.sql`, `api_exposure.test.sql`, and `supabase/seed.sql`
- Modify: `supabase/config.toml` (`[api] schemas` lists `public` and the five module schemas)

**Interfaces:**

- Produces these tables, with every table under row-level security:
  - `identity.profiles(id uuid pk references auth.users, display_name text, avatar_url text, bio text, city text, location geography(point), phone text, phone_verified_at timestamptz, verification_level smallint default 0)`, `identity.user_flags(user_id uuid pk, enable_foil_effect boolean default false)`, `identity.notifications(id uuid pk, user_id uuid, type text, ref_kind text, ref_id uuid, read_at timestamptz, created_at timestamptz)`
  - `catalog.cards(id text pk, name text, set_id text, set_name text, number text, rarity text, hp int, image_url text, foil_style text)`, `catalog.card_prices(card_id text, source text, currency text, low numeric, mid numeric, high numeric, market numeric, trend numeric, avg1 numeric, avg7 numeric, avg30 numeric, updated_at timestamptz, pk(card_id, source))`, `catalog.price_history(card_id text, source text, day date, price numeric, pk(card_id, source, day))`, `catalog.fx_rates(currency text pk, rate_to_myr numeric, updated_at timestamptz)`
  - `listings.collection_items(id uuid pk, owner_id uuid, card_id text, condition text, status text check in ('showcase','open_to_sell'))`, `listings.listings(id uuid pk, item_id uuid, seller_id uuid, card_id text, price numeric, type text check in ('sell','exchange'), status text check in ('active','in_progress','sold','removed'), previous_price numeric, price_dropped_at timestamptz)`, `listings.wanted_posts(id uuid pk, user_id uuid, card_id text, max_price numeric, note text, location geography(point), status text)`, `listings.watchlist(user_id uuid, card_id text, pk(user_id, card_id))`
  - `deals.deals(id uuid pk, listing_id uuid null, wanted_id uuid null, buyer_id uuid, seller_id uuid, status text check in ('contacting','arranged','handed_over','completed','cancelled'), meetup_area text, meetup_at timestamptz, buyer_confirmed_at timestamptz, seller_confirmed_at timestamptz)`, `deals.messages(id uuid pk, deal_id uuid, sender_id uuid, body text, created_at timestamptz)`
  - `reviews.reviews(id uuid pk, deal_id uuid, reviewer_id uuid, reviewee_id uuid, stars smallint check between 1 and 5, comment text, unique(deal_id, reviewer_id))`
- Produces cross-module views: catalog.card\_summary (card\_id, name, set\_name, number, rarity, image\_url, foil\_style), `listings.listing_feed` (active listings joined to card details through the catalog.card\_summary view, for Home and search; no module joins another module's tables directly) and `reviews.profile_rating(user_id, average, count)`.

* [ ] **Step 1: Write failing pgTAP tests** with these exact names and assertions: `user_cannot_update_own_user_flags` (an update as the user changes 0 rows), `user_cannot_set_own_verification_level`, `non_participant_cannot_read_messages` (a third user sees 0 rows), `user_cannot_edit_another_users_listing`, `review_requires_completed_deal` (insert on a `contacting` deal fails), `reviewer_must_be_a_deal_participant`, `cards_writable_only_by_service_role`, `user_cannot_read_another_users_notifications`. In `api_exposure.test.sql`: `authenticated_has_usage_on_all_five_module_schemas`, `anon_has_no_usage_on_any_module_schema`, `deals_messages_and_identity_notifications_are_in_the_realtime_publication` (read `pg_publication_tables` for `supabase_realtime`).
* [ ] **Step 2: Run `supabase db reset && supabase test db`.** Expected: FAIL, tables do not exist.
* [ ] **Step 3: Write the migrations** so each module's tables live in its own schema, with the policies the tests need. Cross-module reads go through the two views only. In `0160_api_and_realtime.sql`: grant `usage` on each module schema to `authenticated` and `service_role` (never `anon`), grant table and function privileges only where a policy or function needs them, set default privileges so later migrations inherit them, and add `deals.messages` and `identity.notifications` to the `supabase_realtime` publication. List the five schemas in `[api] schemas` in `config.toml`; hosted projects take the same list through `supabase config push` (confirm under Settings, API in the dashboard). Without this the Flutter client cannot reach any table or function outside `public`.
* [ ] **Step 4: Run `supabase test db`.** Expected: all tests PASS.
* [ ] **Step 5: Add `seed.sql`** with 30 cards covering every foil style, 5 users and a few listings, and confirm `supabase db reset` loads it.
* [ ] **Step 6: Commit** with `feat(db): module schemas, policies and rls tests`.

### Task 5: Sign-up trigger, phone OTP and verification gating

**Files:**

- Create: `supabase/migrations/0200_identity_signup.sql`, `supabase/tests/identity_signup.test.sql`
- Modify: `supabase/config.toml` (enable phone sign-in)

**Interfaces:**

- Consumes: the tables from Task 4.
- Produces: trigger `identity.on_auth_user_created()` creating a `profiles` row and a `user_flags` row; trigger `identity.on_phone_confirmed()` setting `phone_verified_at` and `verification_level = 1`; policies requiring `verification_level >= 1` to insert into `listings.listings` and `deals.deals`.

* [ ] **Step 1: Write failing tests:** `signup_creates_profile_and_flags_rows` (`enable_foil_effect` is false), `phone_confirmation_sets_level_1`, `unverified_user_cannot_insert_listing`, `unverified_user_cannot_start_deal`, `verified_user_can_insert_listing`.
* [ ] **Step 2: Run `supabase test db`.** Expected: FAIL.
* [ ] **Step 3: Implement the two triggers and the two policies.** Phone OTP uses Supabase Auth's phone provider; record the chosen SMS provider and its cost per message in the design doc's open questions.
* [ ] **Step 4: Run `supabase test db`.** Expected: PASS.
* [ ] **Step 5: Commit** with `feat(identity): signup trigger, phone verification and gating`.

### Task 6: Catalog sync job

**Files:**

- Create: `supabase/functions/sync-catalog/index.ts`, `supabase/functions/_shared/tcgdex_client.ts`, `supabase/functions/_shared/foil_style.ts`, and `supabase/functions/sync-catalog/sync.test.ts`

**Interfaces:**

- Produces: `foilStyleFor(rarity: string): FoilStyle` where `FoilStyle = 'sir' | 'alt' | 'ultra' | 'holo' | 'gold' | 'reverse' | 'shiny' | 'cosmos' | 'plain'`; `syncCatalog(client: TcgdexClient, db: Db): Promise<{ upserted: number; failed: number }>`.

* [ ] **Step 1: Write failing tests:** `foil_style_maps_special_illustration_rare_to_sir`, `foil_style_maps_unknown_rarity_to_plain`, `sync_is_idempotent_when_run_twice` (second run upserts the same count and the table row count does not change), `sync_never_deletes_cards` (a card missing from the provider stays), `sync_keeps_existing_cards_when_provider_fails_midway` (rows from before are intact and `failed` is above 0).
* [ ] **Step 2: Run `deno test supabase/functions/sync-catalog`.** Expected: FAIL.
* [ ] **Step 3: Implement the mapping and `syncCatalog`** as an upsert keyed on the TCGdex id, in batches, never truncating. Schedule it weekly and allow a manual run.
* [ ] **Step 4: Run the tests.** Expected: PASS.
* [ ] **Step 5: Run it once against staging** and confirm the `catalog.cards` row count is within 1% of TCGdex's count.
* [ ] **Step 6: Commit** with `feat(catalog): tcgdex catalog sync`.

### Task 7: Price sync, history and change percent

**Files:**

- Create: `supabase/functions/sync-prices/index.ts`, `supabase/functions/_shared/price_provider.ts`, `supabase/migrations/0250_catalog_price_functions.sql`, `supabase/tests/catalog_prices.test.sql`, `supabase/functions/sync-prices/sync.test.ts`

**Interfaces:**

- Produces: `interface PriceProvider { fetchPrices(cardIds: string[]): Promise<PriceRow[]> }` with `TcgdexPriceProvider` as the only implementation (a replacement provider is a new class, not an app change); SQL `catalog.change_pct(card_id text, days int) returns numeric`; view `catalog.card_price_view(card_id, low_rm, market_rm, high_rm, change_1d, change_7d, change_30d, updated_at)`.
- Rule: `change_pct` returns null when the earlier price is missing or zero. It uses the `price_history` row from `today - days` when one exists, and otherwise `avg1`, `avg7` or `avg30` from `card_prices`.

* [ ] **Step 1: Write failing SQL tests:** `change_pct_is_minus_50_when_price_goes_from_2_to_1`, `change_pct_is_null_when_earlier_price_is_zero`, `change_pct_is_null_when_no_earlier_price`, `card_without_price_has_null_prices_not_zero`, `usd_price_converts_to_rm_using_stored_rate`.
* [ ] **Step 2: Write failing function tests:** `price_sync_twice_same_day_writes_one_history_row`, `price_sync_does_not_delete_cards_or_prices_when_provider_fails`, `price_sync_skips_cards_the_provider_omits`.
* [ ] **Step 3: Run `supabase test db` and `deno test supabase/functions/sync-prices`.** Expected: FAIL.
* [ ] **Step 4: Implement the SQL function and view, the provider and `sync-prices`.** It writes `card_prices` and one `price_history` row per card, source and day, and refreshes `catalog.fx_rates` for USD and EUR from an exchange-rate API (the owner confirms which one; an ECB-based free service such as Frankfurter is the default). Run it hourly to daily.
* [ ] **Step 5: Run both test suites.** Expected: PASS.
* [ ] **Step 6: Commit** with `feat(catalog): price sync, history and change percent`.

## Phase 2: core app

### Task 8: Theme, router, shell and the RarityCard widget

**Files:**

- Create: `app/lib/core/theme/app_theme.dart`, `app/lib/core/router/app_router.dart`, `app/lib/core/network/supabase_client.dart`
- Create: `app/lib/shared/rarity_card/foil_style.dart`, `rarity_card.dart`, `foil_gate.dart`; `app/lib/shared/services/user_flags_provider.dart`; `app/lib/shared/models/card_model.dart`
- Create: `app/lib/core/monitoring/crash_reporter.dart`
- Create tests: `app/test/shared/rarity_card_test.dart`, `app/test/core/app_shell_test.dart`, `app/test/core/crash_reporter_test.dart`
- Modify: `app/lib/core/config/app_config.dart` (adds an optional `sentryDsn`; empty is allowed, unlike the Supabase keys)

**Interfaces:**

- Produces: `abstract class CrashReporter { Future<void> init(AppConfig config); void recordError(Object error, StackTrace stack); void setUser(String? userId); }` with `SentryCrashReporter` and a `NoopCrashReporter` used when `sentryDsn` is empty and in tests. Sentry is chosen over Crashlytics so the app needs no Firebase project; the design allows either. `setUser` takes only the user id, never an email or phone number (PDPA).
- Produces: `enum FoilStyle { sir, alt, ultra, holo, gold, reverse, shiny, cosmos, plain }` with `static FoilStyle parse(String? value)` (unknown or null gives `plain`); `class RarityCard extends ConsumerWidget` taking `required CardModel card`, `double tilt = 1.2`, `bool big = false`, `VoidCallback? onTap`; `final foilEnabledProvider = Provider<bool>` combining the user's `enableFoilEffect` flag, device capability and the OS reduce-motion setting; `Future<UserFlags> fetchFlags()` returning `UserFlags(enableFoilEffect: false)` on any failure.
- Uses the approach chosen in Task 3's `SPIKE.md`.

* [ ] **Step 1: Write failing tests:** `parse_unknown_foil_style_is_plain`, `rarity_card_renders_plain_when_flag_off`, `rarity_card_renders_plain_when_reduce_motion_on`, `rarity_card_renders_plain_when_flags_fetch_fails`, `rarity_card_shows_placeholder_when_image_fails`, and in `app_shell_test.dart` `shell_shows_four_tabs_home_collectibles_scan_settings` (no Community tab); in `crash_reporter_test.dart` `uncaught_flutter_error_reaches_the_reporter`, `uncaught_async_error_reaches_the_reporter`, `app_starts_normally_when_the_dsn_is_empty`.
* [ ] **Step 2: Run `flutter test`.** Expected: FAIL.
* [ ] **Step 3: Implement** the theme (grayscale with accent `#ff6a1a`), the go\_router shell with four tabs, the Supabase client from `AppConfig`, `FoilStyle`, the flag provider and `RarityCard`, with one shader or gradient layer per style from `SPIKE.md`. Initialise the `CrashReporter` before `runApp`, route `FlutterError.onError` and `PlatformDispatcher.onError` to it, tag events with the flavor, and call `setUser` with the user id after sign-in.
* [ ] **Step 4: Run `flutter test`.** Expected: PASS.
* [ ] **Step 5: Commit** with `feat(app): theme, shell and rarity card`.

### Task 9: Sign-up, log-in, phone OTP and profile

**Files:**

- Create: `app/lib/features/auth/{data,domain,presentation}/` (auth repository, `Profile` model, screens), `app/lib/shared/widgets/verification_gate.dart`, `app/lib/features/auth/presentation/consent_screen.dart`, `app/test/features/auth/auth_flow_test.dart`
- Create: `supabase/migrations/0210_identity_consent.sql` (adds `consent_at timestamptz` and `consent_version text` to `identity.profiles`), `supabase/tests/identity_consent.test.sql`

**Interfaces:**

- Consumes: Task 5 triggers, Task 8 router.
- Produces: SQL `identity.record_consent(p_version text) returns void` (the only way to set the consent columns; users cannot write them directly); `ConsentScreen` shown before sign-up completes, with two separate unticked boxes (Terms of Service and Privacy Policy; consent to collect and use personal data under PDPA) and links to both documents from Task 21; `AuthRepository.recordConsent(String version)` below.
- Produces: `abstract class AuthRepository { Future<void> recordConsent(String version); Future<void> signUpEmail(String email, String password); Future<void> signInEmail(String email, String password); Future<void> signInGoogle(); Future<void> sendPhoneOtp(String phone); Future<void> verifyPhoneOtp(String phone, String code); Future<void> signOut(); Stream<Profile?> watchProfile(); Future<void> saveProfile({required String displayName, String? city, String? bio, Uint8List? avatar}); }`; `VerificationGate` widget that wraps an action and sends a level-0 user to the OTP screen.

* [ ] **Step 1: Write failing tests with a fake repository:** `signup_then_prompts_for_phone_otp`, `wrong_otp_shows_error_and_stays_on_screen`, `profile_form_requires_display_name`, `level_0_user_is_sent_to_otp_by_gate_when_listing`, `level_1_user_passes_the_gate`, `consent_screen_blocks_sign_up_until_both_boxes_are_ticked`, `consent_is_recorded_with_the_document_version_after_sign_up`. Also write failing pgTAP tests in `identity_consent.test.sql`: `record_consent_stores_version_and_time`, `user_cannot_update_consent_columns_directly`, `record_consent_requires_a_signed_in_user`.
* [ ] **Step 2: Run `flutter test app/test/features/auth` and `supabase test db`.** Expected: FAIL.
* [ ] **Step 3: Implement** the repository on Supabase Auth, the consent, sign-up, log-in, OTP and create-profile screens (the prototype's onboarding becomes the create-profile step), `VerificationGate`, and the consent migration. A user with no `consent_at` is sent to the consent screen on next launch, so accounts made before the policy existed cannot skip it.
* [ ] **Step 4: Run the tests.** Expected: PASS.
* [ ] **Step 5: Commit** with `feat(auth): sign-up, otp and profile`.

### Task 10: Catalog search and card detail

**Files:**

- Create: `app/lib/features/cards/{data,domain,presentation}/`, `app/lib/features/cards/presentation/price_block.dart`, `app/test/features/cards/price_block_test.dart`, `app/test/features/cards/card_search_test.dart`

**Interfaces:**

- Consumes: `catalog.card_price_view` and `listings.listing_feed` from Tasks 4 and 7.
- Produces: `class CardPrice { final double? marketRm; final double? lowRm; final double? highRm; final double? change1d; final double? change7d; final double? change30d; }` (every field nullable); `abstract class CardRepository { Future<List<CardModel>> search(String query, {ListingFilter filter}); Future<CardModel> getCard(String id); Future<CardPrice?> priceFor(String cardId); }`; `PriceBlock(CardPrice? price)` rendering for example `RM 42  ▼ 12% (7d)`.

* [ ] **Step 1: Write failing tests:** `price_block_shows_no_reference_price_when_price_is_null`, `price_block_shows_dash_when_change_is_null`, `price_block_formats_down_arrow_and_percent_for_minus_12`, `search_matches_name_set_and_number`, `search_filter_for_sale_hides_cards_with_no_active_listing`.
* [ ] **Step 2: Run `flutter test app/test/features/cards`.** Expected: FAIL.
* [ ] **Step 3: Implement** search (name, set, number, with All, For sale, Exchange chips), card detail (foil hero card, rarity and foil name, `PriceBlock` with low, market and high, owners list with a Contact seller button), and the repository.
* [ ] **Step 4: Run the tests.** Expected: PASS.
* [ ] **Step 5: Commit** with `feat(cards): search, detail and price block`.

### Task 11: Collectibles and the manage sheet

**Files:**

- Create: `supabase/migrations/0300_identity_prefs.sql` (adds `identity.profiles.prefs jsonb` with keys `collection_public`, `near_me` and per-type notification switches), `supabase/tests/listings_status.test.sql`
- Create: `app/lib/features/collectibles/{data,domain,presentation}/`, `app/test/features/collectibles/collectibles_test.dart`

**Interfaces:**

- Produces: SQL function `listings.set_item_status(item_id uuid, status text, price numeric default null, condition text default null, allow_swap boolean default false) returns uuid` creating, updating or removing the listing; `abstract class CollectionRepository { Future<List<CollectionItem>> items(String ownerId); Future<void> addItem(String cardId, String condition); Future<void> setStatus(String itemId, ItemStatus status, {double? price, String? condition, bool allowSwap}); }`.

* [ ] **Step 1: Write failing SQL tests:** `open_to_sell_creates_active_listing_with_the_price`, `showcase_removes_the_active_listing`, `price_must_be_positive`, `collection_hidden_from_others_when_not_public`.
* [ ] **Step 2: Write failing widget tests:** `estimated_value_ignores_cards_without_a_price`, `manage_sheet_requires_a_price_for_open_to_sell`.
* [ ] **Step 3: Run `supabase test db` and `flutter test app/test/features/collectibles`.** Expected: FAIL.
* [ ] **Step 4: Implement** the SQL function, the repository and the Collectibles screen (stats row, All, For sale and Showcase chips, the manage sheet with asking price, condition and a swap option), wrapped in `VerificationGate` for the sell action.
* [ ] **Step 5: Run both suites.** Expected: PASS.
* [ ] **Step 6: Commit** with `feat(collectibles): collection, manage sheet and status function`.

### Task 12: Listings, Home feed, Newly listed and Near me

**Files:**

- Create: `supabase/migrations/0320_listings_nearby.sql`, `supabase/tests/listings_nearby.test.sql`
- Create: `app/lib/features/home/`, `app/lib/features/marketplace/`, `app/lib/shared/services/location_service.dart`, `app/test/features/home/home_feed_test.dart`

**Interfaces:**

- Produces: SQL `identity.set_coarse_location(lat double precision, lng double precision) returns void` that rounds to 2 decimal places (about 1 km) before storing; SQL `listings.nearby_feed(radius_km int default 50) returns table(listing_id uuid, ..., distance_km numeric)` ordered by distance and falling back to the same city when the caller has no location; Dart `abstract class LocationService { Future<CoarsePosition?> coarsePosition(); }` returning null when permission is denied or location is off.

* [ ] **Step 1: Write failing SQL tests:** `set_coarse_location_rounds_to_two_decimals`, `nearby_feed_orders_by_distance`, `nearby_feed_falls_back_to_same_city_when_user_has_no_location`.
* [ ] **Step 2: Write failing widget tests:** `home_shows_city_ranked_feed_when_location_is_denied`, `home_filter_chips_all_for_sale_exchange_and_near_me`, `new_listing_appears_at_the_top_of_newly_listed`, `view_all_opens_the_full_newly_listed_list`.
* [ ] **Step 3: Run both suites.** Expected: FAIL.
* [ ] **Step 4: Implement** the SQL functions, `LocationService` with a clear permission explanation screen, the Home feed (search bar, filter chips, Newly listed with View all, a Near you section showing approximate distance) and the listing creation path from Task 11.
* [ ] **Step 5: Run both suites.** Expected: PASS.
* [ ] **Step 6: Commit** with `feat(home): feed, newly listed and near me`.

### Task 13: Card scan

**Files:**

- Create: `app/lib/features/scan/{data,domain,presentation}/` including `scan_text_parser.dart`, `card_matcher.dart`, `card_text_reader.dart`; `app/test/features/scan/scan_text_parser_test.dart`, `card_matcher_test.dart`, `scan_flow_test.dart`

**Interfaces:**

- Produces: pure `ScanQuery parseCardText(List<String> lines)` where `ScanQuery = { String? name, String? number, String? setCode }`; `abstract class CardTextReader { Future<List<String>> read(CameraImage frame); }` (ML Kit text recognition, on the phone); `abstract class CardMatcher { Future<List<CardMatch>> match(ScanQuery query); }` ordered best first. The flow never auto-selects: the user always confirms.

* [ ] **Step 1: Write failing tests:** `parse_extracts_name_and_number_from_charizard_ex_125_197`, `parse_returns_empty_query_for_unreadable_text`, `match_returns_every_reprint_and_never_auto_selects` (a number found in two sets gives 2 matches), `unreadable_scan_offers_manual_search`, `scan_flow_makes_no_network_call_with_image_bytes`.
* [ ] **Step 2: Run `flutter test app/test/features/scan`.** Expected: FAIL.
* [ ] **Step 3: Implement** the parser, the matcher against the local catalog, the camera screen, the confirm list (details, reference price, foil name, condition chips Near Mint, Lightly played, Played) and Save to my collectibles, using `RarityCard` for the result.
* [ ] **Step 4: Run the tests.** Expected: PASS.
* [ ] **Step 5: Test on 20 real cards** (foil, worn and non-English) on the low-end Android device and record the correct-match rate in `docs/scan-accuracy.md`. If under 80%, record the decision to add a server-side match later; do not block the release on it.
* [ ] **Step 6: Commit** with `feat(scan): on-device card scan`.

## Phase 3: Deals and trust

This phase builds the cash-on-delivery deal loop and everything that makes strangers willing to use it: chat, completion, reviews, wanted requests, watchlist, notifications, and safety tools.

### Task 14: Deal flow, chat and completion

**Files:**

- Create: `supabase/migrations/0390_listings_deal_hooks.sql`, `supabase/migrations/0400_deals_functions.sql`, `supabase/tests/listings_deal_hooks.test.sql`, `supabase/tests/deals_flow.test.sql`, `app/lib/features/deals/{deal_repository,deal_screen,chat_view,arrange_sheet}.dart`, `app/test/features/deals/deal_screen_test.dart`
- Modify: `app/lib/core/router/app_router.dart` (route `/deal/:id`), card detail Contact seller button

**Interfaces:**

- Consumes: `deals.deals`, `deals.messages` (Task 4), `VerificationGate` (Task 9). The deals module never touches listings tables: it calls the hooks below, which this task adds to the listings module.
- Produces, listings module (migration 0390): `listings.lock_for_deal(p_listing_id uuid, p_buyer uuid) returns void` (row-locks the listing, raises unless status is `active`, sets `in_progress`), `listings.reopen(p_listing_id uuid) returns void` (`in_progress` back to `active`), `listings.mark_sold(p_listing_id uuid) returns void`, `listings.receive_card(p_buyer uuid, p_card_id text, p_deal_id uuid) returns void` (adds the card to the buyer's collection once per deal, using a unique `source_deal_id` column on `listings.collection_items`).
- Produces, deals module (migration 0400): `deals.start_deal(p_listing_id uuid) returns uuid`, `deals.send_message(p_deal_id uuid, p_body text) returns uuid`, `deals.arrange_deal(p_deal_id uuid, p_meetup_area text, p_meetup_at timestamptz) returns void`, `deals.confirm_handover(p_deal_id uuid) returns void`, `deals.cancel_deal(p_deal_id uuid) returns void`; Dart `DealRepository` with `startDeal(String listingId) -> Future<String>`, `watchMessages(String dealId) -> Stream<List<Message>>`, `send(String dealId, String body)`, `arrange(String dealId, String area, DateTime at)`, `confirmHandover(String dealId)`, `cancel(String dealId)`.
- Rule: one buyer at a time. The first deal on a listing locks it (`in_progress`); later buyers are refused until that deal is cancelled, which reopens the listing.

* [ ] **Step 1: Write the failing pgTAP tests** in `listings_deal_hooks.test.sql`: `lock_for_deal sets in_progress`; `lock_for_deal on an in_progress or sold listing raises`; `reopen returns in_progress to active and leaves sold untouched`; `mark_sold sets sold`; `receive_card twice for the same deal leaves exactly one item in the buyer's collection`.
* [ ] **Step 2: Write the failing pgTAP tests** in `deals_flow.test.sql`: `start_deal creates one deal in contacting and the listing becomes in_progress`; `second start_deal on an in_progress listing is refused`; `start_deal on a sold listing is refused`; `seller cannot start a deal on their own listing`; `level 0 user cannot start a deal`; `arrange_deal sets arranged, meetup_area and meetup_at, only from contacting, only for the two parties`; `confirm_handover before arranged is refused`; `first confirm_handover sets only that side's confirmed_at and moves the deal to handed_over`; `the same side confirming twice changes nothing`; `second side confirming completes the deal, marks the listing sold and puts the card in the buyer's collection once`; `a completed deal cannot be confirmed again (idempotent)`; `cancel_deal in contacting or arranged cancels it and reopens the listing`; `cancel_deal after handed_over is refused`; `a non-party cannot read messages, arrange, confirm or cancel`.
* [ ] **Step 3: Run** `supabase test db` and expect FAIL (functions missing).
* [ ] **Step 4: Implement the four listings hooks** in `0390_listings_deal_hooks.sql` as `security definer` with `set search_path = ''`; `lock_for_deal` locks the row (`for update`) before checking status so two simultaneous buyers cannot both succeed. Then implement the five deals functions in `0400_deals_functions.sql`, which call only those hooks; `confirm_handover` finishes the deal in one transaction when both timestamps are set.
* [ ] **Step 5: Run** `supabase test db` and expect PASS.
* [ ] **Step 6: Write the failing widget test** `deal_screen_test.dart`: `shows chat, price and the current step`; `contacting: both sides see an Arrange meetup button and a Cancel deal button`; `arranged: both sides see Confirm handover and Cancel deal`; `after my confirmation I see Waiting for the other person and no Confirm button`; `handed_over: Cancel deal is hidden`; `completed: no action buttons`; `blocks a level 0 user with the VerificationGate`.
* [ ] **Step 7: Implement `DealRepository`, `DealScreen`, `ChatView` and `ArrangeSheet`** (messages via Realtime on `deals.messages` filtered by `deal_id`; send disabled while the body is empty or over 1,000 characters; ArrangeSheet takes a public meetup area name and a time, never an exact address), then wire Contact seller on card detail to `startDeal` and route to `/deal/:id`.
* [ ] **Step 8: Run** `flutter test app/test/features/deals` and expect PASS.
* [ ] **Step 9: Commit** `feat(deals): COD deal flow, chat, two-sided handover`.

- [ ] **Step 10: Home header card "Deals that need you".** Add SQL `deals.needs_my_action() returns setof deals.deals` (open deals where the last message is from the other party, or the caller is the seller and the deal is not completed) and a Home header card showing the count. Test first: `card hides at zero`; `shows 2 when two deals await my reply`; `tapping opens the oldest waiting deal`. Commit `feat(deals): deals that need you`.

### Task 15: Reviews, profile rating, deals history, public profile, share link

**Files:**

- Create: `supabase/migrations/0500_reviews_functions.sql`, `supabase/tests/reviews_test.sql`, `app/lib/features/reviews/{review_repository,review_sheet,rating_badge}.dart`, `app/lib/features/profile/{public_profile_screen,deals_history_screen}.dart`, `app/lib/core/share_links.dart`, matching tests under `app/test/`
- Modify: `app/lib/core/router/app_router.dart` (routes `/u/:id`, `/card/:id` as deep links)

**Interfaces:**

- Consumes: `reviews.reviews`, view `reviews.profile_rating` (Task 4), `DealRepository` (Task 14).
- Produces: SQL `reviews.submit_review(p_deal_id uuid, p_stars int, p_comment text) returns void`; Dart `ReviewRepository.submit(String dealId, int stars, String comment)`, `ReviewRepository.ratingFor(String userId) -> Future<Rating>` (`Rating{double average, int count}`), `ShareLinks.profile(String userId) -> Uri`, `ShareLinks.card(String cardId) -> Uri`.

* [ ] **Step 1: Write failing pgTAP tests**: `review allowed only after the deal is completed`; `only the buyer and seller of the deal can review, each once`; `stars outside 1 to 5 are refused`; `profile_rating returns average and count, and null average for a user with no reviews`. (The blocked-user review filter is tested in Task 19, where `identity.blocks` is created.)
* [ ] **Step 2: Run** `supabase test db`, expect FAIL.
* [ ] **Step 3: Implement `reviews.submit_review`** and finish `reviews.profile_rating`; run tests and expect PASS.
* [ ] **Step 4: Write failing Dart tests**: `ShareLinks.profile builds https://<host>/u/<id>` (host comes from `AppConfig`); `RatingBadge shows "No reviews yet" when count is 0`; `RatingBadge shows 4.5 (12) for average 4.5, count 12`; `review sheet submit is disabled until a star is chosen`.
* [ ] **Step 5: Implement** `RatingBadge`, `ReviewSheet` (shown once the deal reaches completed), `PublicProfileScreen` (rating, active listings, reviews list, Report/Block menu hook for Task 19, Share button using the OS share sheet), `DealsHistoryScreen` (all of the user's deals with status filter), and `ShareLinks`. Phone number and exact location never appear on the public profile.
* [ ] **Step 6: Run** `flutter test` for these files and expect PASS.
* [ ] **Step 7: Commit** `feat(reviews): ratings, public profile, share links`.

### Task 16: Price dropped

**Files:**

- Create: `supabase/migrations/0600_price_dropped.sql`, `supabase/tests/price_dropped_test.sql`, `app/lib/features/home/{price_dropped_section,price_dropped_screen}.dart`, `app/test/features/home/price_dropped_test.dart`
- Modify: `listings.listing_feed` view, `app/lib/features/cards/presentation/card_detail_screen.dart` (badge)

**Interfaces:**

- Consumes: `listings.listings.previous_price`, `price_dropped_at` (Task 4), `listings.set_item_status` (Task 11).
- Produces: trigger `listings.track_price_drop` (BEFORE UPDATE OF price), SQL function `listings.price_dropped_feed(p_limit int, p_offset int) returns setof listings.listing_feed`, Dart `ListingRepository.priceDropped({int limit, int offset}) -> Future<List<ListingSummary>>`, `ListingSummary.dropPct -> double?`.

* [ ] **Step 1: Write failing pgTAP tests**: `lowering the price stores previous_price and sets price_dropped_at`; `raising the price clears previous_price and price_dropped_at`; `a drop older than 7 days no longer appears in price_dropped_feed`; `price_dropped_feed is ordered by most recent drop first`; `an unchanged price leaves the columns untouched`.
* [ ] **Step 2: Run** `supabase test db`, expect FAIL; **implement** the trigger and function; rerun, expect PASS.
* [ ] **Step 3: Write failing widget tests**: `section hides itself when the feed is empty`; `shows the old price struck through, new price, and the drop percent (e.g. -20%)`; `View all opens PriceDroppedScreen`; `card detail shows a "Price dropped" badge when dropPct is not null`.
* [ ] **Step 4: Implement** the Home section, the full screen with pagination, and the card-detail badge; run `flutter test` and expect PASS.
* [ ] **Step 5: Commit** `feat(listings): price dropped section`.

### Task 17: Wanted requests and watchlist

**Files:**

- Create: `supabase/migrations/0700_wanted_watchlist.sql`, `supabase/tests/wanted_watchlist_test.sql`, `app/lib/features/wanted/{wanted_repository,wanted_screen,post_wanted_sheet,wanted_near_you_card}.dart`, `app/lib/features/watchlist/{watchlist_repository,watchlist_screen,watch_button}.dart`, matching tests
- Modify: `app/lib/features/cards/presentation/card_detail_screen.dart` (Watch button, "Looking for this card" list), `app/lib/features/home/home_screen.dart` (header card "Wanted near you")

**Interfaces:**

- Consumes: `listings.wanted_posts`, `listings.watchlist` (Task 4), `identity.set_coarse_location` and `LocationService` (Task 12), `DealRepository` (Task 14).
- Produces: SQL `listings.post_wanted(p_card_id text, p_max_price numeric, p_note text) returns uuid`, `listings.close_wanted(p_id uuid)`, `listings.wanted_nearby(p_limit int) returns setof listings.wanted_view`, `listings.toggle_watch(p_card_id text) returns boolean`, `deals.start_deal_from_wanted(p_wanted_id uuid, p_collection_item_id uuid) returns uuid`; Dart `WantedRepository.post/close/nearby/forCard(String cardId)`, `WatchlistRepository.toggle(String cardId) -> Future<bool>`, `isWatching(String cardId)`.

* [ ] **Step 1: Write failing pgTAP tests**: `a level 0 user cannot post a wanted request`; `post_wanted stores the poster's coarse location only`; `wanted_nearby orders by distance and excludes the caller's own posts`; `wanted_nearby falls back to the same city when the caller has no location`; `closing a wanted post removes it from wanted_nearby`; `toggle_watch twice returns true then false`; `start_deal_from_wanted requires the seller to own the card offered`; `start_deal_from_wanted opens a deal linked to the wanted post (listing_id null, wanted_id set)`; `completing a deal from a wanted post moves the card to the poster's collection and closes the post`.
* [ ] **Step 2: Run** `supabase test db`, expect FAIL; **implement** the functions (extend `deals.confirm_handover` from Task 14 to handle `wanted_id` so that when both sides have confirmed, a wanted deal calls listings.receive\_card for the poster and a new listings.close\_wanted(p\_wanted\_id), while keeping its idempotency test green); rerun, expect PASS.
* [ ] **Step 3: Write failing widget tests**: `WatchButton toggles between Watch and Watching`; `WantedNearYouCard hides when the list is empty`; `card detail lists wanted posts for this card with an "I have this" button for owners of the card`; `I have this opens a card picker then routes to the new deal chat`; `PostWantedSheet requires a card and rejects a negative max price`.
* [ ] **Step 4: Implement** the repositories, `PostWantedSheet`, `WantedScreen` (my wanted posts, with close), `WatchlistScreen`, `WatchButton`, and the Home header card; run `flutter test` and expect PASS.
* [ ] **Step 5: Commit** `feat(wanted): wanted requests and watchlist`.

### Task 18: Notifications bell

**Files:**

- Create: `supabase/migrations/0800_notification_events.sql`, `supabase/tests/notifications_test.sql`, `app/lib/features/notifications/{notification_repository,notifications_screen,bell_button}.dart`, matching tests
- Modify: `app/lib/core/router/app_router.dart` (bell in the app bar), `identity.profiles.prefs` (per-type switches)

**Interfaces:**

- Consumes: `identity.notifications` (Task 4), Realtime, `ListingRepository`/`DealRepository` events.
- Produces: SQL `identity.notify(p_user uuid, p_type text, p_ref uuid, p_title text) returns void` (skips types the user switched off), triggers calling it for: new message in a deal, deal started on my listing, deal completed, review received, price drop on a watched card, new wanted post matching a card I own; SQL `identity.mark_read(p_ids uuid[])`; Dart `NotificationRepository.watchUnreadCount() -> Stream<int>`, `list({int limit, int offset})`, `markRead(List<String> ids)`.

* [ ] **Step 1: Write failing pgTAP tests**: `a new message notifies the other party and not the sender`; `a price drop notifies users watching that card`; `a new wanted post notifies owners of that card nearby`; `notify is skipped when the user switched that type off`; `a user cannot read or mark another user's notifications`.
* [ ] **Step 2: Run** `supabase test db`, expect FAIL; **implement** `notify`, `mark_read` and the triggers; rerun, expect PASS.
* [ ] **Step 3: Write failing widget tests**: `BellButton shows a badge with the unread count and hides it at 0`; `badge shows 9+ above nine`; `opening the screen marks visible items read`; `tapping an item routes to the deal, listing, or profile it references`.
* [ ] **Step 4: Implement** the repository (Realtime subscription on `identity.notifications` for the signed-in user), screen, and bell; run `flutter test` and expect PASS.
* [ ] **Step 5: Commit** `feat(notifications): in-app bell`.

### Task 19: Settings, report and block, account deletion, help and safety

**Files:**

- Create: `supabase/migrations/0900_safety.sql`, `supabase/functions/delete-account/index.ts`, `supabase/tests/safety_test.sql`, `app/lib/features/settings/{settings_screen,notification_prefs_screen,help_safety_screen}.dart`, `app/lib/features/safety/{report_sheet,block_repository}.dart`, matching tests

**Interfaces:**

- Consumes: `identity.profiles.prefs`, all earlier repositories.
- Produces: tables `identity.blocks(blocker uuid, blocked uuid)` and `identity.reports(id, reporter, target_type, target_id, reason, created_at)`; SQL `identity.is_blocked(p_a uuid, p_b uuid) returns boolean` (true if either has blocked the other; the one hook other modules call, so none reads `identity.blocks` directly), `identity.block_user(p_user uuid)`, `identity.unblock_user(p_user uuid)`, `identity.report(p_target_type text, p_target_id uuid, p_reason text) returns void`; edge function `delete-account` (POST, authenticated, no body); Dart `BlockRepository.block/unblock/blockedIds()`, `ReportSheet.show(context, targetType, targetId)`.

* [ ] **Step 1: Write failing pgTAP tests**: `blocked users disappear from the blocker's feed, wanted list, and search of sellers`; `a blocked user cannot start a deal with the blocker`; `a user cannot block themselves`; `a blocked user's reviews are hidden from the blocker`; `report stores reporter, target and reason and is not readable by other users`; `reports with an empty reason are refused`.
* [ ] **Step 2: Run** `supabase test db`, expect FAIL; **implement**, apply the block filter (through `identity.is_blocked`) inside `listings.listing_feed`, `wanted_nearby`, `start_deal` and the select policy on `reviews.reviews`; rerun, expect PASS.
* [ ] **Step 3: Write a failing edge-function test** `delete-account_test.ts`: `deletes the auth user, profile, collection items, listings, wanted posts, watchlist and notifications`; `keeps completed deals but replaces the user's name with "Deleted user"`; `returns 401 without a session`. Implement, then run `deno test supabase/functions/delete-account` and expect PASS.
* [ ] **Step 4: Write failing widget tests**: `Settings lists My deals, Watchlist, My wanted posts, Notification preferences, Help and safety, Log out, Delete account`; `Delete account asks for a typed confirmation (the word DELETE) before calling the function`; `Report sheet requires a reason`; `Help and safety shows the meetup tips from the design doc`.
* [ ] **Step 5: Implement** the screens and sheets; Delete account calls the edge function then signs out and routes to onboarding. Run `flutter test` and expect PASS.
* [ ] **Step 6: Commit** `feat(safety): settings, report and block, account deletion`.

## Phase 4: Load test, beta and release

### Task 20: Load and performance test

**Files:**

- Create: `tools/loadtest/{seed_staging.sql,browse.js,deal_chat.js,README.md}`

**Interfaces:**

- Consumes: the staging Supabase project with all migrations applied.
- Produces: k6 scenarios `browse.js` (search, card detail, Home feed, near me) and `deal_chat.js` (start deal, send messages over Realtime); pass thresholds recorded in `README.md`.

* [ ] **Step 1: Write `seed_staging.sql`** to load the full synced catalog (about 20,000 cards with prices) plus 5,000 generated users, 20,000 listings spread across Malaysian cities, and 2,000 open deals with messages.
* [ ] **Step 2: Write `browse.js`** ramping to 1,000 concurrent virtual users over 5 minutes with thresholds `http_req_failed < 1%`, `http_req_duration p(95) < 800ms`, and no request over 10 seconds.
* [ ] **Step 3: Write `deal_chat.js`** with 300 concurrent users in active chats; thresholds: message delivery p(95) under 1 second, zero lost messages.
* [ ] **Step 4: Run both** against staging (`k6 run tools/loadtest/browse.js`) and expect all thresholds to pass. If one fails, find the slow query with `explain analyze`, add the index or lower the page size, commit the fix, and rerun until green.
* [ ] **Step 5: Record results** (date, instance size, p95 values) in `README.md` and commit `test: load test results`.

### Task 21: Closed beta and store release

**Files:**

- Create: `docs/release/{privacy-policy.md,terms-of-service.md,store-listing.md,beta-checklist.md}`
- Modify: `app/android/app/build.gradle`, `app/ios/Runner/Info.plist` (permission texts for camera and location)

**Interfaces:**

- Consumes: production Supabase project (same migrations as staging), `prod` Flutter flavor (Task 1).
- Produces: signed builds on TestFlight and Google Play internal testing, then public store listings.

* [ ] **Step 1: Apply migrations to production** by running the manual `deploy-prod.yml` workflow from Task 1b (which runs `supabase db push` and `supabase functions deploy` against `prod`), run the catalog and price syncs once, and confirm the cards count matches staging.
* [ ] **Step 2: Write the privacy policy** covering what is collected (email, phone, coarse location, listings, chat), that scan photos never leave the device, retention, and how to delete the account in-app. Also write `terms-of-service.md` (deals are between users and cash on delivery, the app holds no money, prohibited items such as counterfeit cards, report and ban rules, Malaysian governing law). Give both a version string, link both in Settings and from the consent screen (Task 9), and have Task 9 record that version. Have both documents read by a person qualified to review them before store submission.
* [ ] **Step 3: Fill permission texts** for camera (scan) and location (near me, coarse only), and complete the store forms (data safety on Google Play, App Privacy on App Store).
* [ ] **Step 4: Ship beta builds** (`flutter build appbundle --flavor prod`, `flutter build ipa --flavor prod`) to TestFlight and Play internal testing; upload the debug symbols to the crash reporter for each build so crashes are readable; invite 20 to 50 collectors.
* [ ] **Step 5: Run the beta checklist** in `beta-checklist.md`: every user completes sign-up, phone OTP, one scan, one listing, one wanted post, one deal to completion, one review; log every bug and fix the blockers.
* [ ] **Step 6: Beta exit gate.** Proceed only if no data-loss or wrong-owner bugs are open, crash-free sessions are at least 99% (read from the crash reporter's release-health page for the beta builds), and the foil effect falls back correctly on the lowest-end test phone.
* [ ] **Step 7: Submit to both stores**, then commit `docs: release materials`.

## Self-review

Spec coverage: every MVP item in the design maps to a task. Accounts, phone OTP and gating are Tasks 5 and 9; catalog and reference prices with 1, 7 and 30-day change are Tasks 6, 7 and 10; collectibles and manage sheet are Task 11; Home, Near you and filters are Task 12; scan is Task 13; deals, chat, completion and "Deals that need you" are Task 14; reviews, rating, public profile, deals history and share link are Task 15; Price dropped is Task 16; wanted requests, "Wanted near you", "Looking for this card" and Watch are Task 17; the notification bell is Task 18; Settings, report, block, account deletion and safety tips are Task 19; the foil effect and its one flag are Tasks 3 and 8. One gap was found and fixed: the "Deals that need you" header card had no owner, so it is now Step 9 of Task 14.

Type consistency: `FoilStyle`, `ListingSummary`, `DealRepository`, `VerificationGate` and `PriceProvider` are defined once and used with the same names later. Migration files are numbered by phase (0100 to 0900) in one flat folder with module prefixes, a deliberate deviation from one folder per module so the CLI applies them in order.

Proportion: tasks carry signatures, test names and pass criteria only; SQL and Dart bodies are left to the implementer.

## Execution handoff

Before building, four decisions from the design are still open and do not block Phase 0 to 1: the TCGdex commercial-use terms, the SMS provider for OTP, the FX rate source (default Frankfurter), and the Pokémon Price Tracker commercial-use licence for graded prices (needed before Task 24 ships). Task 2 (source test) is the checkpoint that can change the price provider.

**Review fixes (Oct 12).** Listing status now includes `in_progress`, and cancelling a deal reopens the listing. Task 14 builds the full two-sided flow (`arrange_deal`, `confirm_handover`, `cancel_deal`) and a deal completes only when both sides confirm. Cross-module writes go through small hook functions in the owning module (`listings.lock_for_deal`, `reopen`, `mark_sold`, `receive_card`), and Home and search join cards through the `catalog.card_summary` view. Graded cards are built after Task 14, and the global constraints name the graded-price provider. Migration names are numbered and file paths are standardised (`app_router.dart`, `features/cards`).

**Review fixes, second pass (Oct 12).** Task 1b creates the hosted staging and prod projects, the secrets and the deploy workflows. Task 4 now exposes the five module schemas to the API and adds the chat and notification tables to the Realtime publication. Task 8 adds crash reporting (Sentry), and Task 21's exit gate reads crash-free sessions from it. Task 9 adds a consent screen and recorded consent version, and Task 21 adds the terms of service. The blocked-user review test moved from Task 15 to Task 19, which owns `identity.blocks` and the `identity.is_blocked` hook. Still open, not P0: cancellation tracking for abuse, safe-meetup tips in the deal screen, sync scheduling, the avatar storage bucket, Google sign-in setup, and basic analytics.

## Addendum: Graded cards (Tasks 22 to 24)

Added after the first plan was written. Build Tasks 22 to 24 after Task 14 and before Task 15: Task 22 edits the deal chat header, which Task 14 creates, and Tasks 15 to 19 show the grade badge. Design reference: section "Graded cards (added to MVP)" in the design doc.

### Task 22: Grading fields on collectibles and listings

**Files:**

- Create: `supabase/migrations/0350_grading.sql`, `supabase/tests/grading_test.sql`, `app/lib/core/grading.dart`, `app/lib/widgets/grade_badge.dart`, `app/test/core/grading_test.dart`, `app/test/widgets/grade_badge_test.dart`
- Modify: `listings.collection_items` (new columns), views `listings.listing_feed` and `deals` chat header query, manage sheet (Task 11), Home cards (Task 12)

**Interfaces:**

- Produces: columns `grader text`, `grade numeric(3,1)`, `grade_label text`, `cert_number text` (all nullable; a graded item has grader and grade set, `condition` null); Dart `enum Grader { psa, bgs, cgc, sgc, ace, tag, other }`, `class Grading { Grader grader; String? otherName; double grade; String? label; String? certNumber; String get badge; }` where `badge` renders `PSA 10`, `BGS 9.5`, `BGS 10 Black Label`; `GradeBadge(grading)` widget.

* [ ] **Step 1: Write failing pgTAP tests**: `grader and grade must be set together`; `grade outside 1 to 10 is refused`; `a graded item cannot also have a raw condition`; `grade must be a multiple of 0.5`; `listing_feed exposes grader, grade and label`.
* [ ] **Step 2: Run** `supabase test db`, expect FAIL; **implement** the migration with check constraints; rerun, expect PASS.
* [ ] **Step 3: Write failing Dart tests**: `badge renders PSA 10`; `badge renders BGS 10 Black Label`; `badge renders the custom name for Other`; `GradeBadge hidden for ungraded items`.
* [ ] **Step 4: Implement** `Grading`, `GradeBadge`, and the manage-sheet toggle "Graded slab" which swaps the condition chips for company, grade, label and certificate number fields; show the badge on collectible details, listing, Home cards and the deal header. Run `flutter test`, expect PASS.
* [ ] **Step 5: Commit** `feat(grading): grading fields and badge`.

### Task 23: Slab label scan

**Files:**

- Create: `app/lib/features/scan/slab_parser.dart`, `app/test/features/scan/slab_parser_test.dart`, `app/test/fixtures/slabs/*.txt` (recognised label text from at least 3 real slabs per grader PSA, BGS, CGC, SGC)
- Modify: scan screen (Task 13) with a "Raw card / Graded slab" switch; confirm list shows the extra fields

**Interfaces:**

- Consumes: `CardTextReader`, `CardMatcher`, `Grading` (Task 22).
- Produces: `SlabReading parseSlabText(String text)` returning `SlabReading { Grader? grader; double? grade; String? label; String? certNumber; String? cardName; String? setHint; }`.

* [ ] **Step 1: Write failing tests** against the fixtures: `PSA label text gives grader psa, grade 10, an 8-digit certificate number`; `BGS label gives grade 9.5 and picks up Black Label`; `CGC label gives Pristine`; `unrecognised text returns all-null fields instead of throwing`; `card name from a slab is passed to CardMatcher and returns the right card for each fixture`.
* [ ] **Step 2: Run** `flutter test app/test/features/scan/slab_parser_test.dart`, expect FAIL.
* [ ] **Step 3: Implement `parseSlabText`** with one regex set per grader; whichever fields it cannot read stay null and are filled by the user on the confirm screen. Rerun, expect PASS.
* [ ] **Step 4: Wire the scan flow** so the saved collectible stores the confirmed grading; widget test `confirm screen shows grader, grade and cert number pre-filled and editable`.
* [ ] **Step 5: Commit** `feat(scan): read graded slab labels`.

### Task 24: Graded value panel

**Files:**

- Create: `supabase/migrations/0360_graded_prices.sql`, `supabase/functions/graded-price/index.ts`, `supabase/functions/graded-price/graded_price_test.ts`, `supabase/tests/graded_prices_test.sql`, `app/lib/features/cards/presentation/{graded_value_panel,grade_chips}.dart`, `app/test/features/cards/graded_value_panel_test.dart`
- Modify: `PriceBlock` (Task 10) to host the panel; `tools/source-test` (Task 2) to check graded coverage

**Interfaces:**

- Consumes: `PriceProvider` and FX rates (Task 7).
- Produces: table `catalog.graded_prices(card_id, grader, grade, median_usd, sales_count, fetched_at)`; edge function `graded-price` (POST `{card_id}`, authenticated) that returns all cached grades for the card and refreshes from the provider when `fetched_at` is older than 24 hours; Dart `GradedPriceRepository.forCard(String cardId) -> Future<List<GradedPrice>>`, `GradedPrice { Grader grader; double grade; double? rm; int salesCount; }`.

* [ ] **Step 1: Write failing Deno tests**: `returns cached rows without calling the provider when fresh`; `refreshes when older than 24 hours`; `returns an empty list instead of an error when the provider fails`; `rejects unauthenticated calls with 401`; `a card requested twice at the same time triggers one provider call`.
* [ ] **Step 2: Run** `deno test supabase/functions/graded-price`, expect FAIL; **implement** the function and table; rerun, expect PASS.
* [ ] **Step 3: Extend the source test (Task 2)** with 30 popular Malaysian-market cards and require a PSA 10 value for at least 70% of them; record the result in the plan notes and decide the provider tier.
* [ ] **Step 4: Write failing widget tests**: `panel opens on PSA 10 by default`; `opens on the item's own grade for an owned graded card`; `tapping BGS 9.5 shows its RM value and sale count`; `a grade with fewer than 3 sales shows Not enough sales`; `Raw chip shows the TCGdex price and the 1/7/30-day change`; `ACE and TAG show No graded price for this grader yet`.
* [ ] **Step 5: Implement** the panel and chips (PSA 10, PSA 9, BGS 9.5, BGS 9, CGC 10, Raw), the label "reference price, recent eBay sales", and a loading and failure state that falls back to Raw. Run `flutter test`, expect PASS.
* [ ] **Step 6: Commit** `feat(prices): graded value panel`.
