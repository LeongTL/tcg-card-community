# Pending / TODO

Things skipped or waiting on someone. Updated after every task. Remove a line when it is done.

| Task | Pending item | Blocked on |
|---|---|---|
| 1 | TODO: iOS `dev`, `staging`, `prod` schemes and build configurations (bundle IDs, app names) | A Mac with Xcode |
| 1 | TODO: see the CI workflow run green on GitHub (`.github/workflows/ci.yml`) | Pushing the branch |
| 1 | TODO: Step 6 commit (`feat: scaffold flutter app, flavors and ci`) | The user's go; no commits until asked |
| 1b | SETUP (prod): turn on daily backups for `TCG-prd` (`ijwbaqavqmgurlekdcgc`); projects are created in Singapore and refs are in `docs/ops/supabase-setup.md` | You, in the dashboard (paid plan) |
| 1b | SETUP (prod): Step 3 prod secrets (`PROD_PROJECT_REF`, `PROD_DB_PASSWORD`) and `supabase secrets set` on `TCG-prd` | Prod rollout |
| 1b | TODO (staging only for now): Step 5 verify a green staging deploy | Pushed branch, staging secrets |
| 1b | SETUP (prod): Step 5 verify a waiting prod run; create the `production` GitHub environment with reviewers | Prod rollout |
| 1b | TODO: Step 6 commit | The user's go |
| 2 | LATER (before any public launch): card image rights are unresolved (MIT covers the data, not the art). For now images are hotlinked from TCGdex for study use only; ask TCGdex maintainers before launch or before copying images to our storage | You |
| 2 | TODO: Step 7 commit | The user's go |
| 3 | TODO: foil shader spike, measure frame times on a low-end Android phone and an iPhone | Real devices |
| setup | TODO: delete the unused `linux/`, `web/`, `windows/`, `macos/` folders (still tracked; permission was blocked) | You: `git rm -r linux web windows macos` |
| setup | TODO: rename GitHub repo `LeongTL/1` (suggested `tcg-card-community`), add description and topics, decide public or private, then update the local remote | You, in GitHub settings |
| setup | TODO: decide inline (executing-plans) vs subagent mode for Tasks 4+, and the model tiers | You |
| 1 | TODO: build the `staging` and `prod` Android flavors once to confirm (only `dev` was built) | Next Flutter run |
| 1b | TODO: the deploy workflows (`deploy-staging.yml`, `deploy-prod.yml`) are written but never run | Secrets, pushed branch |
| open | Open questions from CLAUDE.md: TCGdex licence, Pokémon Price Tracker licence, SMS provider for OTP, FX source (default Frankfurter), dispute handling, Malaysia-only launch | You |
