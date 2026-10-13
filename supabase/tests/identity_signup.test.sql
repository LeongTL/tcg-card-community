begin;
select plan(6);

insert into catalog.cards (id, name, set_id, set_name, number, rarity, image_url, foil_style)
  values ('t-1', 'Test', 's', 'Set', '1', 'Common', 'http://img', 'none');

-- a1 stays unverified, a2 confirms a phone; the trigger creates their profiles.
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'a1@test.dev'),
  ('00000000-0000-0000-0000-0000000000a2', 'a2@test.dev');

select is((select enable_foil_effect from identity.user_flags where user_id = '00000000-0000-0000-0000-0000000000a1'),
  false, 'signup_creates_profile_and_flags_rows');

update auth.users set phone = '60123456789', phone_confirmed_at = now()
  where id = '00000000-0000-0000-0000-0000000000a2';
select is((select verification_level from identity.profiles where id = '00000000-0000-0000-0000-0000000000a2'),
  1::smallint, 'phone_confirmation_sets_level_1');

insert into listings.collection_items (id, owner_id, card_id, condition, status) values
  ('00000000-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-0000000000a1', 't-1', 'NM', 'open_to_sell'),
  ('00000000-0000-0000-0000-0000000000c2', '00000000-0000-0000-0000-0000000000a2', 't-1', 'NM', 'open_to_sell');
-- deal creation is function-only until Task 14, so grant insert inside this rolled-back transaction to test the policy.
grant insert on deals.deals to authenticated;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
select throws_ok(
  $$insert into listings.listings (item_id, seller_id, card_id, price, type, status)
    values ('00000000-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-0000000000a1', 't-1', 10, 'sell', 'active')$$,
  '42501', null, 'unverified_user_cannot_insert_listing');
select throws_ok(
  $$insert into deals.deals (buyer_id, seller_id) values ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a2')$$,
  '42501', null, 'unverified_user_cannot_start_deal');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a2","role":"authenticated"}', true);
select lives_ok(
  $$insert into listings.listings (item_id, seller_id, card_id, price, type, status)
    values ('00000000-0000-0000-0000-0000000000c2', '00000000-0000-0000-0000-0000000000a2', 't-1', 10, 'sell', 'active')$$,
  'verified_user_can_insert_listing');
select lives_ok(
  $$insert into deals.deals (buyer_id, seller_id) values ('00000000-0000-0000-0000-0000000000a2', '00000000-0000-0000-0000-0000000000a1')$$,
  'verified_user_can_start_deal');

select * from finish();
rollback;
