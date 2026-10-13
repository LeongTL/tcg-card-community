import postgres from 'npm:postgres@3';
import { TcgdexPriceProvider, type PriceRow } from '../_shared/price_provider.ts';
import { httpClient } from '../_shared/tcgdex_client.ts';
import { refreshFx } from './fx.ts';
import { syncPrices } from './sync.ts';

// Called with the service-role key. ?sets=a,b limits the run to those sets (one call for the whole
// catalog would hit the Edge Function time limit); ?fx=1 only refreshes exchange rates.
Deno.serve(async (req) => {
  const url = Deno.env.get('SUPABASE_DB_URL');
  if (!url) return Response.json({ error: 'SUPABASE_DB_URL is not set' }, { status: 500 });
  const sql = postgres(url, { prepare: false, max: 1 });
  try {
    const params = new URL(req.url).searchParams;
    const fx = await refreshFx(fetch, async (currency, rate) => {
      await sql`insert into catalog.fx_rates (currency, rate_to_myr, updated_at) values (${currency}, ${rate}, now())
                on conflict (currency) do update set rate_to_myr = excluded.rate_to_myr, updated_at = excluded.updated_at`;
    });
    if (params.get('fx')) return Response.json({ fx });

    const sets = params.get('sets')?.split(',');
    const ids = (sets
      ? await sql`select id from catalog.cards where set_id = any(${sets}) order by id`
      : await sql`select id from catalog.cards order by id`).map((r) => r.id as string);
    const result = await syncPrices(new TcgdexPriceProvider(httpClient), {
      async upsertPrices(rows: PriceRow[], day: string) {
        const json = sql.json(rows as never);
        await sql.begin(async (tx) => {
          await tx`insert into catalog.card_prices (card_id, source, currency, low, mid, high, market, trend, avg1, avg7, avg30, updated_at)
                   select card_id, source, currency, low, mid, high, market, trend, avg1, avg7, avg30, now()
                   from jsonb_populate_recordset(null::catalog.card_prices, ${json})
                   on conflict (card_id, source) do update set currency = excluded.currency, low = excluded.low,
                     mid = excluded.mid, high = excluded.high, market = excluded.market, trend = excluded.trend,
                     avg1 = excluded.avg1, avg7 = excluded.avg7, avg30 = excluded.avg30, updated_at = excluded.updated_at`;
          await tx`insert into catalog.price_history (card_id, source, day, price)
                   select card_id, source, ${day}::date, market
                   from jsonb_populate_recordset(null::catalog.card_prices, ${json}) where market is not null
                   on conflict (card_id, source, day) do update set price = excluded.price`;
        });
      },
    }, ids);
    return Response.json({ ...result, fx }, { status: result.failed > 0 ? 207 : 200 });
  } finally {
    await sql.end();
  }
});
