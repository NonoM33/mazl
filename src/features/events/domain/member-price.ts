// The reduced rate of mazl+ members for a paying event (docs/premium/MONETISATION.md
// section 10): whole cents of the event's currency, never above the normal price.

const MAX_CENTS = 10_000_000;

export type MemberPriceInput =
  | { readonly kind: "unchanged" }
  | { readonly kind: "remove" }
  | { readonly kind: "set"; readonly cents: number }
  | { readonly kind: "invalid" };

// undefined: the field is absent. null: remove the rate.
export function readMemberPrice(raw: unknown): MemberPriceInput {
  if (raw === undefined) return { kind: "unchanged" };
  if (raw === null) return { kind: "remove" };
  if (typeof raw !== "number" || !Number.isInteger(raw) || raw < 0 || raw > MAX_CENTS) return { kind: "invalid" };
  return { kind: "set", cents: raw };
}

// `price` is the decimal column: a number or the numeric string Postgres returns.
export function priceInCents(price: unknown): number {
  const amount = Number(price);
  return Number.isFinite(amount) ? Math.round(amount * 100) : 0;
}

// A rate above the normal price would be a surcharge, not a reduction.
export function isReduction(memberPriceCents: number, price: unknown): boolean {
  return memberPriceCents <= priceInCents(price);
}
