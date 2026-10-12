begin;
select plan(4);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'buyer@test.dev'),
  ('00000000-0000-0000-0000-0000000000a2', 'seller@test.dev'),
  ('00000000-0000-0000-0000-0000000000a3', 'stranger@test.dev');
insert into deals.deals (id, buyer_id, seller_id, status) values
  ('00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a2', 'contacting'),
  ('00000000-0000-0000-0000-0000000000e2', '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a2', 'completed');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);

select throws_ok(
  $$insert into reviews.reviews (id, deal_id, reviewer_id, reviewee_id, stars)
    values (gen_random_uuid(), '00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a2', 5)$$,
  '42501', null, 'review_requires_completed_deal');

select lives_ok(
  $$insert into reviews.reviews (id, deal_id, reviewer_id, reviewee_id, stars)
    values (gen_random_uuid(), '00000000-0000-0000-0000-0000000000e2', '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a2', 5)$$,
  'completed_deal_participant_can_review');

select is((select average::float8 from reviews.profile_rating where user_id = '00000000-0000-0000-0000-0000000000a2'),
  5::float8, 'profile_rating_averages_stars');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a3","role":"authenticated"}', true);
select throws_ok(
  $$insert into reviews.reviews (id, deal_id, reviewer_id, reviewee_id, stars)
    values (gen_random_uuid(), '00000000-0000-0000-0000-0000000000e2', '00000000-0000-0000-0000-0000000000a3', '00000000-0000-0000-0000-0000000000a1', 1)$$,
  '42501', null, 'reviewer_must_be_a_deal_participant');

select * from finish();
rollback;
