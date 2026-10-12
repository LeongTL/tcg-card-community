begin;
select plan(4);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'buyer@test.dev'),
  ('00000000-0000-0000-0000-0000000000a2', 'seller@test.dev'),
  ('00000000-0000-0000-0000-0000000000a3', 'stranger@test.dev');
insert into deals.deals (id, buyer_id, seller_id, status)
  values ('00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000a1',
          '00000000-0000-0000-0000-0000000000a2', 'contacting');
insert into deals.messages (id, deal_id, sender_id, body)
  values (gen_random_uuid(), '00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000a1', 'hi');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a3","role":"authenticated"}', true);
select is((select count(*) from deals.messages), 0::bigint, 'non_participant_cannot_read_messages');
select is((select count(*) from deals.deals), 0::bigint, 'non_participant_cannot_see_deal');
select throws_ok(
  $$insert into deals.messages (id, deal_id, sender_id, body)
    values (gen_random_uuid(), '00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000a3', 'x')$$,
  '42501', null, 'non_participant_cannot_post_message');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
select is((select count(*) from deals.messages), 1::bigint, 'participant_can_read_messages');

select * from finish();
rollback;
