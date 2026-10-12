# Supabase environments

Three environments, same migrations in all of them.

| Environment | Where | Flutter flavor |
|---|---|---|
| local | `supabase start` on the developer machine | `dev` |
| staging | hosted project, region Singapore (`ap-southeast-1`) | `staging` |
| prod | hosted project, region Singapore, daily backups on | `prod` |

Project refs: staging (`TCG-stg`) = `xcaomcsbtfeqhkjavywz`, prod (`TCG-prd`) = `ijwbaqavqmgurlekdcgc`.

## GitHub repository secrets

`SUPABASE_ACCESS_TOKEN`, `STAGING_PROJECT_REF`, `STAGING_DB_PASSWORD`, `PROD_PROJECT_REF`, `PROD_DB_PASSWORD`.

Create a GitHub environment named `production` with required reviewers, so `deploy-prod.yml` waits for approval.

## Edge Function secrets (per project, `supabase secrets set`)

- `PRICE_PROVIDER_KEY` (Pokémon Price Tracker)
- `FX_API_KEY` (only if the chosen rate source needs one; default Frankfurter needs none)
- SMS provider credentials for phone OTP

The service-role key lives only in Edge Function secrets. It is never in the app, `.env.example` or the repository. The app gets only the project URL and the anon key.

## Open (keys not yet bought or chosen)

- Pokémon Price Tracker key and commercial-use licence
- SMS provider for Malaysian OTP
- FX rate source (default Frankfurter)

Functions that need a missing key must fail with a clear error, not crash.
