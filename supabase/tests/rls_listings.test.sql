begin;
select plan(5);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'a1@test.dev'),
  ('00000000-0000-0000-0000-0000000000a2', 'a2@test.dev');
insert into catalog.cards (id, name, set_id, set_name, number, rarity, image_url, foil_style)
  values ('t-1', 'Test', 's', 'Set', '1', 'Common', 'http://img', 'none');
insert into listings.collection_items (id, owner_id, card_id, condition, status)
  values ('00000000-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-0000000000a1', 't-1', 'NM', 'open_to_sell');
insert into listings.listings (id, item_id, seller_id, card_id, price, type, status)
  values ('00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000c1',
          '00000000-0000-0000-0000-0000000000a1', 't-1', 100, 'sell', 'active');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a2","role":"authenticated"}', true);

select lives_ok(
  $$update listings.listings set price = 1 where id = '00000000-0000-0000-0000-0000000000d1'$$,
  'another_users_update_is_not_an_error');
select throws_ok(
  $$insert into listings.listings (id, item_id, seller_id, card_id, price, type, status)
    values (gen_random_uuid(), '00000000-0000-0000-0000-0000000000c1',
            '00000000-0000-0000-0000-0000000000a1', 't-1', 1, 'sell', 'active')$$,
  '42501', null, 'user_cannot_list_as_someone_else');
select is((select count(*) from listings.listing_feed where listing_id = '00000000-0000-0000-0000-0000000000d1'), 1::bigint, 'listing_feed_joins_card_details');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
select is((select price from listings.listings where id = '00000000-0000-0000-0000-0000000000d1'), 100::numeric,
  'user_cannot_edit_another_users_listing');
select lives_ok(
  $$update listings.listings set price = 90 where id = '00000000-0000-0000-0000-0000000000d1'$$,
  'owner_can_edit_own_listing');

select * from finish();
rollback;
