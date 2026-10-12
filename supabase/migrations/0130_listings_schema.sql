create schema listings;

create table listings.collection_items (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users on delete cascade,
  card_id text not null,
  condition text,
  status text not null default 'showcase' check (status in ('showcase', 'open_to_sell'))
);
create index collection_items_owner_idx on listings.collection_items (owner_id);

create table listings.listings (
  id uuid primary key default gen_random_uuid(),
  item_id uuid references listings.collection_items on delete set null,
  seller_id uuid not null references auth.users on delete cascade,
  card_id text not null,
  price numeric not null check (price >= 0),
  type text not null check (type in ('sell', 'exchange')),
  status text not null default 'active' check (status in ('active', 'in_progress', 'sold', 'removed')),
  previous_price numeric,
  price_dropped_at timestamptz,
  created_at timestamptz not null default now()
);
create index listings_feed_idx on listings.listings (status, created_at desc);
create index listings_seller_idx on listings.listings (seller_id);
create index listings_card_idx on listings.listings (card_id);

create table listings.wanted_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  card_id text not null,
  max_price numeric,
  note text,
  location extensions.geography(point, 4326),
  status text not null default 'open'
);

create table listings.watchlist (
  user_id uuid not null references auth.users on delete cascade,
  card_id text not null,
  primary key (user_id, card_id)
);

alter table listings.collection_items enable row level security;
alter table listings.listings enable row level security;
alter table listings.wanted_posts enable row level security;
alter table listings.watchlist enable row level security;

create policy collection_items_select on listings.collection_items for select to authenticated using (true);
create policy collection_items_insert_own on listings.collection_items for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy collection_items_update_own on listings.collection_items for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy collection_items_delete_own on listings.collection_items for delete to authenticated
  using (owner_id = (select auth.uid()));

create policy listings_select on listings.listings for select to authenticated using (true);
create policy listings_insert_own on listings.listings for insert to authenticated
  with check (seller_id = (select auth.uid()));
create policy listings_update_own on listings.listings for update to authenticated
  using (seller_id = (select auth.uid())) with check (seller_id = (select auth.uid()));
create policy listings_delete_own on listings.listings for delete to authenticated
  using (seller_id = (select auth.uid()));

create policy wanted_posts_select on listings.wanted_posts for select to authenticated using (true);
create policy wanted_posts_insert_own on listings.wanted_posts for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy wanted_posts_update_own on listings.wanted_posts for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy wanted_posts_delete_own on listings.wanted_posts for delete to authenticated
  using (user_id = (select auth.uid()));

create policy watchlist_own on listings.watchlist for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- Home and search read listings joined to card details through catalog.card_summary only.
create view listings.listing_feed with (security_invoker = true) as
select l.id as listing_id, l.item_id, l.seller_id, l.card_id, l.price, l.type,
       l.previous_price, l.price_dropped_at, l.created_at,
       c.name, c.set_name, c.number, c.rarity, c.image_url, c.foil_style
from listings.listings l
join catalog.card_summary c on c.card_id = l.card_id
where l.status = 'active';
