-- One reference price per card: Cardmarket when it has a market price (it carries 1/7/30-day averages),
-- otherwise TCGplayer. Cards with no price are simply absent here.
create view catalog.reference_price with (security_invoker = true) as
select distinct on (card_id) card_id, source, currency, low, mid, high, market, trend,
       avg1, avg7, avg30, updated_at
from catalog.card_prices
where market is not null
order by card_id, (source = 'cardmarket') desc;

-- (today - earlier) / earlier * 100. Null when either price is missing or the earlier one is 0.
-- Earlier = the price_history row from p_days ago, else the provider's 1/7/30-day average.
create function catalog.change_pct(p_card_id text, p_days int) returns numeric
language sql stable as $$
  select case when x.earlier is null or x.earlier = 0 or x.cur is null then null
              else round((x.cur - x.earlier) / x.earlier * 100, 2) end
  from (
    select r.market as cur,
           coalesce(
             (select h.price from catalog.price_history h
              where h.card_id = r.card_id and h.source = r.source and h.day = current_date - p_days),
             case p_days when 1 then r.avg1 when 7 then r.avg7 when 30 then r.avg30 end) as earlier
    from catalog.reference_price r
    where r.card_id = p_card_id
  ) x
$$;

-- Every card has a row; prices are null (never 0) when there is no price or no stored rate.
-- shortcut: three change_pct calls per row, fine for card detail and lists of a page; precompute if a full-catalog scan appears.
create view catalog.card_price_view with (security_invoker = true) as
select c.id as card_id,
       round(r.low * fx.rate_to_myr, 2) as low_rm,
       round(r.market * fx.rate_to_myr, 2) as market_rm,
       round(r.high * fx.rate_to_myr, 2) as high_rm,
       catalog.change_pct(c.id, 1) as change_1d,
       catalog.change_pct(c.id, 7) as change_7d,
       catalog.change_pct(c.id, 30) as change_30d,
       r.updated_at
from catalog.cards c
left join catalog.reference_price r on r.card_id = c.id
left join catalog.fx_rates fx on fx.currency = r.currency;

grant select on catalog.reference_price, catalog.card_price_view to authenticated;
revoke all on function catalog.change_pct(text, int) from public;
grant execute on function catalog.change_pct(text, int) to authenticated, service_role;
