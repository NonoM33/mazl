import type { Pairing } from "../domain/pairing";
import type { SignInMethod, WebSession } from "../domain/session";

export interface WebMember {
  readonly id: number;
  readonly email: string;
  readonly name: string | null;
  readonly provider: "google" | "apple";
  readonly providerId: string;
}

export type MemberLookup =
  | { readonly kind: "found"; readonly member: WebMember }
  | { readonly kind: "disabled" }
  | { readonly kind: "absent" };

// Looks accounts up and never creates one: the web only signs in members who
// already joined from the app (ADR-W03).
export interface MemberDirectory {
  findByProvider(provider: "google" | "apple", providerId: string): Promise<MemberLookup>;
  findById(userId: number): Promise<MemberLookup>;
}

export interface PairingRepository {
  insert(pairing: Pairing): Promise<void>;
  findById(id: string): Promise<Pairing | null>;
  // pending -> scanned, bound to the member; null when no open pairing has this code.
  markScanned(codeHash: string, userId: number, now: Date): Promise<Pairing | null>;
  // scanned -> approved|denied for the member who scanned; false when not possible.
  decide(id: string, userId: number, status: "approved" | "denied", now: Date): Promise<boolean>;
  // approved -> consumed, once; returns the member id of the winner.
  consume(id: string, now: Date): Promise<number | null>;
  purgeExpiredBefore(limit: Date): Promise<void>;
}

export interface SessionRecord {
  readonly session: WebSession;
  readonly member: WebMember;
  readonly memberActive: boolean;
}

export interface SessionRepository {
  insert(session: WebSession, tokenHash: string): Promise<void>;
  findByTokenHash(tokenHash: string): Promise<SessionRecord | null>;
  findById(id: string): Promise<SessionRecord | null>;
  touch(id: string, lastSeenAt: Date, idleExpiresAt: Date): Promise<void>;
  revoke(userId: number, id: string, now: Date): Promise<boolean>;
  // Revokes the member's active sessions except `exceptId`; returns their ids.
  revokeMany(userId: number, exceptId: string | null, now: Date): Promise<string[]>;
  listActive(userId: number, now: Date): Promise<WebSession[]>;
  purgeEndedBefore(limit: Date): Promise<void>;
}

export interface SessionRevocationListener {
  sessionsRevoked(sessionIds: readonly string[]): void;
}

export type TokenSigner = (member: WebMember, ttlSeconds: number) => string;

export interface OpenedSession {
  readonly token: string;
  readonly session: WebSession;
}

export type SessionOpener = (member: WebMember, method: SignInMethod, browserLabel: string) => Promise<OpenedSession>;

export type Clock = () => Date;
