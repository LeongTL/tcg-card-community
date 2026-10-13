# Pending / TODO

Things skipped or waiting on someone. Updated after every task. Remove a line when it is done.

| Task | Pending item | Blocked on |
|---|---|---|
| 1 | SETUP (stg/prod rollout): fill `SUPABASE_ANON_KEY` in `app/env/staging.json` and `app/env/prod.json` (public anon or publishable key from dashboard > Project Settings > API Keys; never the service-role key). `dev.json` is done | Staging / prod rollout |
| 1b | SETUP (prod): turn on daily backups for `TCG-prd` (`ijwbaqavqmgurlekdcgc`); projects are created in Singapore and refs are in `docs/ops/supabase-setup.md` | You, in the dashboard (paid plan) |
| 1b | SETUP (prod): Step 3 prod secrets (`PROD_PROJECT_REF`, `PROD_DB_PASSWORD`) and `supabase secrets set` on `TCG-prd` | Prod rollout |
| 1b | SETUP (prod): the prod deploy workflow has never run; Step 5 verify a waiting prod run; create the `production` GitHub environment with reviewers | Prod rollout |
| 3 | LATER: no frame times were measured (owner's call). When Task 8's `RarityCard` runs on a real low-end phone, check 45 fps single / 30 fps grid; if it misses, switch to layered gradients (see `app/lib/shared/rarity_card/SPIKE.md`) | Real devices |
| setup | TODO: decide inline (executing-plans) vs subagent mode for Tasks 4+, and the model tiers | You |
| 1 | TODO: build the `staging` and `prod` Android flavors once to confirm (only `dev` was built; iOS `dev`, `staging` and `prod` all build for the simulator) | Next Flutter run |
| open | Open questions from CLAUDE.md: TCGdex licence, Pokémon Price Tracker licence, SMS provider for OTP, FX source (default Frankfurter), dispute handling, Malaysia-only launch | You |
| 4 | TODO: hosted projects need the same API schema list (`supabase config push`, then check Settings > API on `TCG-stg`); the same push also carries Task 5's phone settings in `config.toml` (`[auth.sms]` confirmations), so check Authentication > Providers > Phone on both hosted projects; the deploy workflow only runs `db push` | You or a later pass |
| 5 | SETUP (before beta): pick an SMS provider for Malaysia, enable it under `[auth.sms.*]` in `config.toml` and on `TCG-stg`/`TCG-prd`, and record its cost per message in the design doc. Until then only the local test OTP (`60123456789` = `123456`) works | You |
| 5 | NOTE: `deals.deals` has a verified-buyer insert policy but users have no insert grant; Task 14's function must call `identity.is_verified(buyer_id)` itself if it runs as security definer | Task 14 |
| 6 | TODO: deploy `sync-catalog` to `TCG-stg` (`supabase functions deploy sync-catalog --project-ref xcaomcsbtfeqhkjavywz`), run it in chunks of 10 sets (`?sets=a,b,...`; one call for all ~220 sets would time out), then confirm `catalog.cards` is within 1% of TCGdex's count (plan Step 5) | You (deploy was denied to Claude) |
| 6 | SETUP: add GitHub secrets `STAGING_SERVICE_ROLE_KEY` (and `PROD_SERVICE_ROLE_KEY` at prod rollout) so `.github/workflows/sync-catalog.yml` can run weekly; the key stays in GitHub secrets only | You |
| 6 | NOTE: `foilStyleFor` maps by rarity only, so a plain `Rare` is `plain` even when the real card is holo (and `Common`/`Uncommon` are `reverse`); the `cosmos` style is only given to Amazing, Radiant and Futuristic Rare. Revisit with variant data in Task 8 | Task 8 |
| 7 | TODO: deploy `sync-prices` to `TCG-stg` after the catalog is complete, run it in chunks (`?sets=a,b,...`, same time-limit reason as `sync-catalog`), then check `catalog.card_price_view` on staging; schedule it (hourly to daily) with a workflow like `sync-catalog.yml` | You or a later pass |
| 7 | OPEN: FX source is Frankfurter (plan default), never confirmed by the owner; and `sync-prices` re-fetches every card from TCGdex (about the same cost as the catalog sync), so a combined catalog + price job may be cheaper later | You |
| 7 | NOTE: reference price uses Cardmarket (`trend`) when present, else TCGplayer's first variant `marketPrice`; day-one change uses TCGdex `avg1/avg7/avg30` (TCGdex's `avg1` can be very noisy, e.g. -50% on a stable card), so Task 10 may want to hide the 1-day change | Task 10 |
