begin;
select plan(4);

insert into auth.users (id, email) values ('00000000-0000-0000-0000-0000000000a1', 'a1@test.dev');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);

select throws_ok(
  $$insert into catalog.cards (id, name) values ('t-1', 'Test')$$,
  '42501', null, 'cards_writable_only_by_service_role');

reset role;
set local role service_role;
select lives_ok(
  $$insert into catalog.cards (id, name, set_id, set_name, number, rarity, image_url, foil_style)
    values ('t-1', 'Test', 's', 'Set', '1', 'Common', 'http://img', 'none')$$,
  'service_role_can_write_cards');

reset role;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
select is((select count(*) from catalog.card_summary where card_id = 't-1'), 1::bigint, 'authenticated_can_read_card_summary');

reset role;
set local role anon;
select throws_ok($$select * from catalog.cards$$, '42501', null, 'anon_cannot_read_cards');

select * from finish();
rollback;
