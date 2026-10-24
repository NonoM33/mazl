export const PAIRING_TTL_MS = 120_000;

export type PairingStatus = "pending" | "scanned" | "approved" | "denied" | "consumed";

// What the browser sees when it polls.
export type PairingView = "pending" | "scanned" | "approved" | "denied" | "expired";

export interface Pairing {
  readonly id: string;
  readonly codeHash: string;
  readonly browserSecretHash: string;
  readonly browserLabel: string;
  // Masked address the request came from (« 198.51.100.x »), shown on the phone.
  readonly addressHint: string | null;
  readonly status: PairingStatus;
  readonly userId: number | null;
  readonly createdAt: Date;
  readonly expiresAt: Date;
}

export function isExpired(pairing: Pick<Pairing, "expiresAt">, now: Date): boolean {
  return pairing.expiresAt.getTime() <= now.getTime();
}

// A consumed pairing reads as expired (single use); a decision already taken
// stays visible after the deadline, anything still open is expired.
export function viewOf(pairing: Pairing, now: Date): PairingView {
  if (pairing.status === "consumed") return "expired";
  if (pairing.status === "denied") return "denied";
  if (isExpired(pairing, now)) return "expired";
  return pairing.status;
}
