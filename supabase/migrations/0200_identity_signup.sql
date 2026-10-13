-- New auth user -> profile + flags rows. `on conflict do nothing` keeps seed.sql and re-runs safe.
create function identity.on_auth_user_created() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into identity.profiles (id, display_name)
    values (new.id, new.raw_user_meta_data ->> 'full_name')
    on conflict (id) do nothing;
  insert into identity.user_flags (user_id) values (new.id) on conflict do nothing;
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function identity.on_auth_user_created();

-- Phone confirmed in Auth -> level 1. Only moves up, never resets a level 2 user.
create function identity.on_phone_confirmed() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update identity.profiles
    set phone = new.phone,
        phone_verified_at = new.phone_confirmed_at,
        verification_level = greatest(verification_level, 1)
    where id = new.id;
  return new;
end $$;

create trigger on_phone_confirmed after update of phone_confirmed_at on auth.users
  for each row when (old.phone_confirmed_at is null and new.phone_confirmed_at is not null)
  execute function identity.on_phone_confirmed();

-- Other modules ask identity through this function, never by reading identity.profiles.
create function identity.is_verified(uid uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select verification_level >= 1 from identity.profiles where id = uid), false)
$$;
revoke all on function identity.is_verified(uuid) from public;
grant execute on function identity.is_verified(uuid) to authenticated, service_role;

-- Listing needs level 1.
drop policy listings_insert_own on listings.listings;
create policy listings_insert_verified on listings.listings for insert to authenticated
  with check (seller_id = (select auth.uid()) and identity.is_verified(seller_id));

-- Starting a deal needs level 1. Users get no insert grant yet (Task 14's function creates deals);
-- the policy guards any invoker-rights path.
create policy deals_insert_verified_buyer on deals.deals for insert to authenticated
  with check (buyer_id = (select auth.uid()) and identity.is_verified(buyer_id));
