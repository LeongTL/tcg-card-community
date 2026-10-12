create schema identity;

create table identity.profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text,
  avatar_url text,
  bio text,
  city text,
  location extensions.geography(point, 4326), -- coarse only, rounded to about 1 km
  phone text,
  phone_verified_at timestamptz,
  verification_level smallint not null default 0 check (verification_level in (0, 1, 2))
);

create table identity.user_flags (
  user_id uuid primary key references auth.users on delete cascade,
  enable_foil_effect boolean not null default false
);

create table identity.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  type text not null,
  ref_kind text,
  ref_id uuid,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on identity.notifications (user_id, created_at desc);

alter table identity.profiles enable row level security;
alter table identity.user_flags enable row level security;
alter table identity.notifications enable row level security;

-- Profiles are public; the phone and location columns are hidden by column grants in 0160.
create policy profiles_select on identity.profiles for select to authenticated using (true);
create policy profiles_update_own on identity.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy user_flags_select_own on identity.user_flags for select to authenticated
  using (user_id = (select auth.uid()));

create policy notifications_select_own on identity.notifications for select to authenticated
  using (user_id = (select auth.uid()));
create policy notifications_update_own on identity.notifications for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
