import type { ChipIdentity } from "../types";

// Pure checks the use case applies after passive authentication. Dates are
// ISO yyyy-mm-dd; comparisons use the UTC calendar day of `now`.

function isoDay(now: Date): string {
  return now.toISOString().slice(0, 10);
}

// A document is valid through the whole expiry day.
export function isExpired(identity: Pick<ChipIdentity, "expiryDate">, now: Date): boolean {
  return identity.expiryDate < isoDay(now);
}

export function ageOn(identity: Pick<ChipIdentity, "birthDate">, now: Date): number {
  const [by, bm, bd] = identity.birthDate.split("-").map(Number) as [number, number, number];
  let age = now.getUTCFullYear() - by;
  const monthDelta = now.getUTCMonth() + 1 - bm;
  if (monthDelta < 0 || (monthDelta === 0 && now.getUTCDate() < bd)) age -= 1;
  return age;
}

// Input of the HMAC fingerprint (CONTRAT.md 4, step 4).
export function documentFingerprintMessage(identity: Pick<ChipIdentity, "issuingState" | "documentNumber" | "birthDate">): string {
  return `${identity.issuingState}|${identity.documentNumber}|${identity.birthDate}`;
}
