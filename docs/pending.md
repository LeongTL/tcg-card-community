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
| 4 | TODO: hosted projects need the same API schema list (`supabase config push`, then check Settings > API on `TCG-stg`); the deploy workflow only runs `db push` | You or a later pass |
| 5 | SETUP (before beta): pick an SMS provider for Malaysia, enable it under `[auth.sms.*]` in `config.toml` and on `TCG-stg`/`TCG-prd`, and record its cost per message in the design doc. Until then only the local test OTP (`60123456789` = `123456`) works | You |
| 5 | NOTE: `deals.deals` has a verified-buyer insert policy but users have no insert grant; Task 14's function must call `identity.is_verified(buyer_id)` itself if it runs as security definer | Task 14 |
