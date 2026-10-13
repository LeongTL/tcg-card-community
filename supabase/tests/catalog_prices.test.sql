begin;
select plan(7);

insert into catalog.cards (id, name, set_id, set_name, number, rarity, image_url, foil_style) values
  ('p-drop', 'Drop', 's', 'Set', '1', 'Rare', 'http://img', 'plain'),
  ('p-zero', 'Zero', 's', 'Set', '2', 'Rare', 'http://img', 'plain'),
  ('p-none', 'None', 's', 'Set', '3', 'Rare', 'http://img', 'plain'),
  ('p-avg', 'Avg', 's', 'Set', '4', 'Rare', 'http://img', 'plain'),
  ('p-usd', 'Usd', 's', 'Set', '5', 'Rare', 'http://img', 'plain'),
  ('p-noprice', 'NoPrice', 's', 'Set', '6', 'Rare', 'http://img', 'plain');
insert into catalog.fx_rates (currency, rate_to_myr) values ('EUR', 5), ('USD', 4.5);

insert into catalog.card_prices (card_id, source, currency, low, market, avg7) values
  ('p-drop', 'cardmarket', 'EUR', 0.5, 1, null),
  ('p-zero', 'cardmarket', 'EUR', 0.5, 1, null),
  ('p-none', 'cardmarket', 'EUR', 0.5, 1, null),
  ('p-avg', 'cardmarket', 'EUR', 0.5, 1, 2),
  ('p-usd', 'tcgplayer', 'USD', 8, 10, null);
insert into catalog.price_history (card_id, source, day, price) values
  ('p-drop', 'cardmarket', current_date - 7, 2),
  ('p-zero', 'cardmarket', current_date - 7, 0);

select is(catalog.change_pct('p-drop', 7), -50::numeric, 'change_pct_is_minus_50_when_price_goes_from_2_to_1');
select is(catalog.change_pct('p-zero', 7), null::numeric, 'change_pct_is_null_when_earlier_price_is_zero');
select is(catalog.change_pct('p-none', 7), null::numeric, 'change_pct_is_null_when_no_earlier_price');
select is(catalog.change_pct('p-avg', 7), -50::numeric, 'change_pct_falls_back_to_avg7_without_history');
select is(catalog.change_pct('p-avg', 3), null::numeric, 'change_pct_is_null_for_a_period_with_no_average');
select results_eq(
  $$select low_rm, market_rm, change_7d from catalog.card_price_view where card_id = 'p-noprice'$$,
  $$values (null::numeric, null::numeric, null::numeric)$$,
  'card_without_price_has_null_prices_not_zero');
select is((select market_rm from catalog.card_price_view where card_id = 'p-usd'), 45::numeric,
  'usd_price_converts_to_rm_using_stored_rate');

select * from finish();
rollback;
