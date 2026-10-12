begin;
select plan(4);

select is(
  (select bool_and(has_schema_privilege('authenticated', s, 'usage'))
     from unnest(array['identity','catalog','listings','deals','reviews']) s),
  true, 'authenticated_has_usage_on_all_five_module_schemas');

select is(
  (select bool_or(has_schema_privilege('anon', s, 'usage'))
     from unnest(array['identity','catalog','listings','deals','reviews']) s),
  false, 'anon_has_no_usage_on_any_module_schema');

select is(
  (select bool_and(has_schema_privilege('service_role', s, 'usage'))
     from unnest(array['identity','catalog','listings','deals','reviews']) s),
  true, 'service_role_has_usage_on_all_five_module_schemas');

select is(
  (select count(*) from pg_publication_tables
    where pubname = 'supabase_realtime'
      and ((schemaname = 'deals' and tablename = 'messages')
        or (schemaname = 'identity' and tablename = 'notifications'))),
  2::bigint, 'deals_messages_and_identity_notifications_are_in_the_realtime_publication');

select * from finish();
rollback;
