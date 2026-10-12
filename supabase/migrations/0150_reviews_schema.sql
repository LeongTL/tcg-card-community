create schema reviews;

create table reviews.reviews (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null,
  reviewer_id uuid not null references auth.users on delete cascade,
  reviewee_id uuid not null references auth.users on delete cascade,
  stars smallint not null check (stars between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique (deal_id, reviewer_id)
);
create index reviews_reviewee_idx on reviews.reviews (reviewee_id);

alter table reviews.reviews enable row level security;

create policy reviews_select on reviews.reviews for select to authenticated using (true);
-- Reviewer must be in a completed deal and the reviewee must be the other participant.
create policy reviews_insert_after_completed_deal on reviews.reviews for insert to authenticated
  with check (reviewer_id = (select auth.uid())
              and reviewee_id = deals.completed_counterparty(deal_id, (select auth.uid())));

create view reviews.profile_rating with (security_invoker = true) as
select reviewee_id as user_id, round(avg(stars), 2) as average, count(*) as "count"
from reviews.reviews
group by reviewee_id;
