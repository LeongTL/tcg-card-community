begin;
select plan(5);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'a1@test.dev'),
  ('00000000-0000-0000-0000-0000000000a2', 'a2@test.dev');
insert into identity.notifications (id, user_id, type) values
  ('00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-0000000000a1', 'x'),
  ('00000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0000-0000000000a2', 'x');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);

select throws_ok(
  $$update identity.user_flags set enable_foil_effect = true where user_id = '00000000-0000-0000-0000-0000000000a1'$$,
  '42501', null, 'user_cannot_update_own_user_flags');

select throws_ok(
  $$update identity.profiles set verification_level = 1 where id = '00000000-0000-0000-0000-0000000000a1'$$,
  '42501', null, 'user_cannot_set_own_verification_level');

select is((select count(*) from identity.notifications), 1::bigint,
  'user_cannot_read_another_users_notifications');

select lives_ok(
  $$update identity.profiles set display_name = 'Uno' where id = '00000000-0000-0000-0000-0000000000a1'$$,
  'user_can_update_own_display_name');

select throws_ok($$select phone from identity.profiles$$, '42501', null, 'phone_is_not_readable_by_users');

select * from finish();
rollback;
