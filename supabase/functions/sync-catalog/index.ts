import postgres from 'npm:postgres@3';
import { httpClient } from '../_shared/tcgdex_client.ts';
import { syncCatalog, type CardRow, type Db } from './sync.ts';

// Plain Postgres, so the module schemas need not be exposed through the API. Upsert only, never delete.
export function pgDb(url: string): Db & { close(): Promise<void> } {
  const sql = postgres(url, { prepare: false, max: 1 });
  return {
    async upsertCards(cards: CardRow[]) {
      await sql`
        insert into catalog.cards (id, name, set_id, set_name, number, rarity, hp, image_url, foil_style)
        select id, name, set_id, set_name, number, rarity, hp, image_url, foil_style
        from jsonb_populate_recordset(null::catalog.cards, ${sql.json(cards as never)})
        on conflict (id) do update set
          name = excluded.name, set_id = excluded.set_id, set_name = excluded.set_name,
          number = excluded.number, rarity = excluded.rarity, hp = excluded.hp,
          image_url = excluded.image_url, foil_style = excluded.foil_style`;
    },
    close: () => sql.end(),
  };
}

// Called with the service-role key (Supabase checks the JWT before this runs).
// ?sets=a,b limits the run to those TCGdex set ids, so one call can stay inside the time limit.
Deno.serve(async (req) => {
  const url = Deno.env.get('SUPABASE_DB_URL');
  if (!url) return Response.json({ error: 'SUPABASE_DB_URL is not set' }, { status: 500 });
  const sets = new URL(req.url).searchParams.get('sets');
  const db = pgDb(url);
  try {
    const result = await syncCatalog(httpClient, db, { setIds: sets ? sets.split(',') : undefined });
    return Response.json(result, { status: result.failed > 0 ? 207 : 200 });
  } finally {
    await db.close();
  }
});
