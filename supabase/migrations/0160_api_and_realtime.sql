-- Schema access: signed-in users and service_role only, never anon.
grant usage on schema identity, catalog, listings, deals, reviews to authenticated, service_role;

-- service_role (Edge Functions) gets everything, now and for later migrations.
grant all on all tables in schema identity, catalog, listings, deals, reviews to service_role;
grant all on all sequences in schema identity, catalog, listings, deals, reviews to service_role;
grant all on all functions in schema identity, catalog, listings, deals, reviews to service_role;
alter default privileges in schema identity, catalog, listings, deals, reviews
  grant all on tables to service_role;
alter default privileges in schema identity, catalog, listings, deals, reviews
  grant all on sequences to service_role;
alter default privileges in schema identity, catalog, listings, deals, reviews
  grant all on functions to service_role;

-- identity: phone and location are never readable by other users; the verification level
-- and phone fields are written only by functions, so they are not in the update grant.
grant select (id, display_name, avatar_url, bio, city, verification_level) on identity.profiles to authenticated;
grant update (display_name, avatar_url, bio, city, location) on identity.profiles to authenticated;
grant select on identity.user_flags to authenticated;
grant select on identity.notifications to authenticated;
grant update (read_at) on identity.notifications to authenticated;

-- catalog: read-only for users.
grant select on catalog.cards, catalog.card_prices, catalog.price_history, catalog.fx_rates,
  catalog.card_summary to authenticated;

-- listings
grant select, insert, update, delete on listings.collection_items, listings.listings,
  listings.wanted_posts, listings.watchlist to authenticated;
grant select on listings.listing_feed to authenticated;

-- deals: users read deals and write chat messages; deal changes go through functions.
grant select on deals.deals to authenticated;
grant select, insert on deals.messages to authenticated;
revoke all on function deals.completed_counterparty(uuid, uuid) from public;
grant execute on function deals.completed_counterparty(uuid, uuid) to authenticated, service_role;

-- reviews
grant select, insert on reviews.reviews to authenticated;
grant select on reviews.profile_rating to authenticated;

-- Realtime
alter publication supabase_realtime add table deals.messages, identity.notifications;
