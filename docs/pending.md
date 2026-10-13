# Pending / TODO

Things skipped or waiting on someone. Updated after every task. Remove a line when it is done.

| Task | Pending item | Blocked on |
|---|---|---|
| 1 | SETUP (stg/prod rollout): fill `SUPABASE_ANON_KEY` in `app/env/staging.json` and `app/env/prod.json` (public anon or publishable key from dashboard > Project Settings > API Keys; never the service-role key). `dev.json` is done | Staging / prod rollout |
| 1b | SETUP (prod): turn on daily backups for `TCG-prd` (`ijwbaqavqmgurlekdcgc`); projects are created in Singapore and refs are in `docs/ops/supabase-setup.md` | You, in the dashboard (paid plan) |
| 1b | SETUP (prod): Step 3 prod secrets (`PROD_PROJECT_REF`, `PROD_DB_PASSWORD`) and `supabase secrets set` on `TCG-prd` | Prod rollout |
| 1b | SETUP (prod): the prod deploy workflow has never run; Step 5 verify a waiting prod run; create the `production` GitHub environment with reviewers | Prod rollout |
| 2 | LATER (before any public launch): card image rights are unresolved (MIT covers the data, not the art). For now images are hotlinked from TCGdex for study use only; ask TCGdex maintainers before launch or before copying images to our storage | You |
| 3 | LATER: no frame times were measured (owner's call). When Task 8's `RarityCard` runs on a real low-end phone, check 45 fps single / 30 fps grid; if it misses, switch to layered gradients (see `app/lib/shared/rarity_card/SPIKE.md`) | Real devices |
| setup | TODO: decide inline (executing-plans) vs subagent mode for Tasks 4+, and the model tiers | You |
| 1 | TODO: build the `staging` and `prod` Android flavors once to confirm (only `dev` was built; iOS `dev`, `staging` and `prod` all build for the simulator) | Next Flutter run |
| open | Open questions from CLAUDE.md: TCGdex licence, Pokémon Price Tracker licence, SMS provider for OTP, FX source (default Frankfurter), dispute handling, Malaysia-only launch | You |
| 4 | TODO: hosted projects need the same API schema list (`supabase config push`, then check Settings > API on `TCG-stg`); the deploy workflow only runs `db push` | You or a later pass |
| 5 | NOTE: the seed inserts profiles directly; the sign-up trigger in Task 5 must use `on conflict do nothing` so `supabase db reset` still works | Task 5 |
