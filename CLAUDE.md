# TCG Card Community

Pokémon card marketplace and community app for collectors in Malaysia. Phase 1 (this repo's first sub-project): a cash-on-delivery (COD) trade loop with no in-app payment.

## Read first

- Design (what and why): `docs/superpowers/specs/2026-10-09-tcg-card-community-design.md`
- Implementation plan (how, 24 tasks): `docs/superpowers/plans/2026-10-12-tcg-card-community-implementation-plan.md`
- Low-fi prototype (screens to match): `prototype/tcg-card-community-prototype.html`

Work through the plan task by task. Tasks 22 to 24 (graded cards) are in the addendum at the end of the plan but are built after Task 14 and before Task 15. Each task starts with a failing test.

## Stack

- Flutter (iOS and Android, one codebase), Riverpod, go_router
- Supabase: Postgres + PostGIS, Auth (email/Google + phone OTP), Storage, Realtime, Edge Functions (TypeScript/Deno)
- pgTAP for database tests, k6 for load tests, GitHub Actions for CI
- On-device text recognition (Google ML Kit) for scanning cards and slab labels

## Architecture rules

- Modular monolith in one Supabase project, five modules: `identity`, `catalog`, `listings`, `deals`, `reviews`. Each owns its own Postgres schema and edge functions.
- A module touches only its own tables. Other modules reach its data through a view or a function, never by joining its tables. Example: completing a deal calls `listings.mark_sold` and `listings.receive_card`; Home and search read cards through the `catalog.card_summary` view.
- Deals: one buyer at a time per listing (first deal sets the listing `in_progress`; cancelling reopens it). A deal completes only when both sides confirm the handover.
- One flat `supabase/migrations/` folder, numbered by phase, with module prefixes. Same migrations run on local, staging and production (three separate Supabase projects). Flutter flavors: dev, staging, prod.
- The app never calls TCGdex or the price provider directly. Scheduled edge functions copy data into our own tables. Graded prices are fetched on demand by the `graded-price` edge function and cached 24 hours.
- Reference prices are shown in RM and always labelled "reference price".

## Product rules that must not drift

- Verification levels: 0 = email/Google, 1 = phone OTP verified, 2 = reserved for eKYC (next phase, not MVP). Listing or starting a deal needs level 1.
- Exactly one feature flag exists: `enable_foil_effect` (table `user_flags`, per user, read-only to the user, default off). The foil effect also falls back to a plain card on fetch failure, low-end device or reduce-motion.
- Privacy (PDPA): coarse location only (rounded to about 1 km), only with permission, city fallback. Never store exact positions or meetup addresses. Phone number never public. Scan photos never leave the device. In-app account deletion is required.
- Notifications are an in-app bell with an unread badge. No push notifications.
- Four tabs: Home, Collectibles, Scan, Settings. No Community tab in the MVP.
- Graded cards: grading company, grade, optional label and certificate number on a collectible. Graded value (PSA 10 by default, switchable) is a reference from eBay sales; no 1/7/30-day change for graded values.
- Out of MVP: community feed, follows, collection value widget, push notifications, price-history chart, eKYC, payments, direct messages, "Preview as others".

## Open questions (do not assume)

- TCGdex commercial-use terms and card-image licensing
- Pokémon Price Tracker commercial-use licence for graded prices
- SMS provider for OTP in Malaysia
- FX rate source (default: Frankfurter)
- Dispute handling between buyer and seller
- Whether Malaysia-only launch is final

## Working agreements

- Test first, small commits, one task per commit series.
- Match names and signatures in the plan's Interfaces blocks exactly; later tasks depend on them.
- Do not add feature flags, tabs or features beyond the plan without asking.
