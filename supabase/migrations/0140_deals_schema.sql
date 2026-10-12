create schema deals;

create table deals.deals (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid,
  wanted_id uuid,
  buyer_id uuid not null references auth.users on delete cascade,
  seller_id uuid not null references auth.users on delete cascade,
  status text not null default 'contacting'
    check (status in ('contacting', 'arranged', 'handed_over', 'completed', 'cancelled')),
  meetup_area text,
  meetup_at timestamptz,
  buyer_confirmed_at timestamptz,
  seller_confirmed_at timestamptz,
  created_at timestamptz not null default now()
);
create index deals_buyer_idx on deals.deals (buyer_id);
create index deals_seller_idx on deals.deals (seller_id);

create table deals.messages (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references deals.deals on delete cascade,
  sender_id uuid not null references auth.users on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);
create index messages_deal_idx on deals.messages (deal_id, created_at);

alter table deals.deals enable row level security;
alter table deals.messages enable row level security;

-- Deals are created and moved along by functions (Task 14), so users only read them here.
create policy deals_select_participants on deals.deals for select to authenticated
  using ((select auth.uid()) in (buyer_id, seller_id));

create policy messages_select_participants on deals.messages for select to authenticated
  using (exists (select 1 from deals.deals d
                 where d.id = deal_id and (select auth.uid()) in (d.buyer_id, d.seller_id)));
create policy messages_insert_participants on deals.messages for insert to authenticated
  with check (sender_id = (select auth.uid())
              and exists (select 1 from deals.deals d
                          where d.id = deal_id and sender_id in (d.buyer_id, d.seller_id)));

-- How the reviews module checks a deal without reading deals tables: returns the other
-- participant of a completed deal, or null if the deal is not completed or p_user is not in it.
create function deals.completed_counterparty(p_deal uuid, p_user uuid)
returns uuid
language sql stable security definer set search_path = ''
as $$
  select case when p_user = d.buyer_id then d.seller_id
              when p_user = d.seller_id then d.buyer_id end
  from deals.deals d
  where d.id = p_deal and d.status = 'completed';
$$;
