import { randomUUID } from "node:crypto";
import { constantTimeEqual, randomToken, sha256Hex } from "../domain/hashing";
import { PAIRING_TTL_MS, viewOf, type Pairing, type PairingView } from "../domain/pairing";
import type { Clock, MemberDirectory, OpenedSession, PairingRepository, SessionOpener, WebMember } from "./ports";

export interface CreatedPairing {
  readonly id: string;
  readonly code: string;
  readonly browserSecret: string;
  readonly expiresAt: Date;
}

export type PollOutcome =
  | { readonly kind: "not_found" }
  | { readonly kind: "status"; readonly status: Exclude<PairingView, "approved"> }
  | { readonly kind: "account_disabled" }
  | { readonly kind: "signed_in"; readonly member: WebMember; readonly opened: OpenedSession };

export type DecisionOutcome = "ok" | "not_found" | "not_pending";

const PURGE_EVERY_MS = 10 * 60_000;
const PURGE_AFTER_MS = 60 * 60_000;

export class PairingService {
  private lastPurge = 0;

  constructor(
    private readonly pairings: PairingRepository,
    private readonly members: MemberDirectory,
    private readonly openSession: SessionOpener,
    private readonly now: Clock,
  ) {}

  async create(browserLabel: string, addressHint: string | null = null): Promise<CreatedPairing> {
    const now = this.now();
    const code = randomToken();
    const browserSecret = randomToken();
    const pairing: Pairing = {
      id: randomUUID(),
      codeHash: sha256Hex(code),
      browserSecretHash: sha256Hex(browserSecret),
      browserLabel,
      addressHint,
      status: "pending",
      userId: null,
      createdAt: now,
      expiresAt: new Date(now.getTime() + PAIRING_TTL_MS),
    };
    await this.pairings.insert(pairing);
    await this.purgeOccasionally(now);
    return { id: pairing.id, code, browserSecret, expiresAt: pairing.expiresAt };
  }

  scan(userId: number, code: string): Promise<Pairing | null> {
    return this.pairings.markScanned(sha256Hex(code), userId, this.now());
  }

  // Only the member who scanned may decide; anyone else sees a 404.
  async decide(userId: number, id: string, status: "approved" | "denied"): Promise<DecisionOutcome> {
    const pairing = await this.pairings.findById(id);
    if (!pairing || pairing.userId !== userId) return "not_found";
    const done = await this.pairings.decide(id, userId, status, this.now());
    return done ? "ok" : "not_pending";
  }

  async poll(id: string, browserSecret: string): Promise<PollOutcome> {
    const pairing = await this.pairings.findById(id);
    if (!pairing || !constantTimeEqual(pairing.browserSecretHash, sha256Hex(browserSecret))) {
      return { kind: "not_found" };
    }
    const now = this.now();
    const view = viewOf(pairing, now);
    if (view !== "approved") return { kind: "status", status: view };
    return this.signIn(pairing, now);
  }

  private async signIn(pairing: Pairing, now: Date): Promise<PollOutcome> {
    const userId = await this.pairings.consume(pairing.id, now);
    if (userId === null) return { kind: "status", status: "expired" };
    const lookup = await this.members.findById(userId);
    if (lookup.kind !== "found") return { kind: "account_disabled" };
    const opened = await this.openSession(lookup.member, "qr", pairing.browserLabel);
    return { kind: "signed_in", member: lookup.member, opened };
  }

  private async purgeOccasionally(now: Date): Promise<void> {
    if (now.getTime() - this.lastPurge < PURGE_EVERY_MS) return;
    this.lastPurge = now.getTime();
    await this.pairings.purgeExpiredBefore(new Date(now.getTime() - PURGE_AFTER_MS));
  }
}

