// Frankfurter (ECB rates), the plan's default. A failed fetch leaves the stored rate alone.
const CURRENCIES = ['USD', 'EUR'];

export async function refreshFx(
  fetchFn: (url: string) => Promise<Response>,
  save: (currency: string, rate: number) => Promise<void>,
): Promise<{ updated: number; failed: number }> {
  let updated = 0;
  let failed = 0;
  for (const currency of CURRENCIES) {
    try {
      const res = await fetchFn(`https://api.frankfurter.dev/v1/latest?base=${currency}&symbols=MYR`);
      if (!res.ok) throw new Error(`FX ${res.status}`);
      const rate = (await res.json()).rates?.MYR;
      if (typeof rate !== 'number' || rate <= 0) throw new Error('bad rate');
      await save(currency, rate);
      updated++;
    } catch {
      failed++;
    }
  }
  return { updated, failed };
}
