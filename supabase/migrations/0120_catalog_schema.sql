create schema catalog;

create table catalog.cards (
  id text primary key,
  name text not null,
  set_id text,
  set_name text,
  number text,
  rarity text,
  hp int,
  image_url text,
  foil_style text
);

create table catalog.card_prices (
  card_id text not null references catalog.cards on delete cascade,
  source text not null,
  currency text not null,
  low numeric, mid numeric, high numeric, market numeric, trend numeric,
  avg1 numeric, avg7 numeric, avg30 numeric,
  updated_at timestamptz not null default now(),
  primary key (card_id, source)
);

create table catalog.price_history (
  card_id text not null references catalog.cards on delete cascade,
  source text not null,
  day date not null,
  price numeric not null,
  primary key (card_id, source, day)
);

create table catalog.fx_rates (
  currency text primary key,
  rate_to_myr numeric not null,
  updated_at timestamptz not null default now()
);

alter table catalog.cards enable row level security;
alter table catalog.card_prices enable row level security;
alter table catalog.price_history enable row level security;
alter table catalog.fx_rates enable row level security;

-- Read-only for users; only service_role (which bypasses RLS) writes.
create policy cards_select on catalog.cards for select to authenticated using (true);
create policy card_prices_select on catalog.card_prices for select to authenticated using (true);
create policy price_history_select on catalog.price_history for select to authenticated using (true);
create policy fx_rates_select on catalog.fx_rates for select to authenticated using (true);

-- The one door other modules use to read card details.
create view catalog.card_summary with (security_invoker = true) as
select id as card_id, name, set_name, number, rarity, image_url, foil_style
from catalog.cards;
