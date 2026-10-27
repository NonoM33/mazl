// Which price is in force today, from the dated prices App Store Connect lists.

export interface DatedPrice<T> {
  readonly startDate: string | null; // YYYY-MM-DD; null = the initial price, in force since always
  readonly endDate?: string | null;
  readonly preserved?: boolean;
  readonly monthlyPlan?: boolean;
  readonly value: T;
}

const since = (price: DatedPrice<unknown>): string => price.startDate ?? "";

export function effectivePrice<T>(prices: readonly DatedPrice<T>[], today: string): T | undefined {
  const inForce = prices.filter(
    (p) => !p.monthlyPlan && since(p) <= today && (p.endDate === undefined || p.endDate === null || p.endDate >= today),
  );
  // A preserved price only protects existing subscribers; new customers pay the other one.
  const forNewCustomers = inForce.some((p) => p.preserved !== true) ? inForce.filter((p) => p.preserved !== true) : inForce;
  const latest = [...forNewCustomers].sort((a, b) => since(b).localeCompare(since(a)))[0];
  return latest?.value;
}

export const todayIso = (clock: () => number): string => new Date(clock()).toISOString().slice(0, 10);
