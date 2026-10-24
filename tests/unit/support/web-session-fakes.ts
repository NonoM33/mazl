import type {
  MemberDirectory,
  MemberLookup,
  PairingRepository,
  SessionRecord,
  SessionRepository,
  WebMember,
} from "../../../src/features/web-session/application/ports";
import type { Pairing } from "../../../src/features/web-session/domain/pairing";
import type { WebSession } from "../../../src/features/web-session/domain/session";

export class FakeClock {
  constructor(private current: Date = new Date("2026-10-24T12:00:00.000Z")) {}
  readonly now = (): Date => new Date(this.current);
  advance(ms: number): void {
    this.current = new Date(this.current.getTime() + ms);
  }
}

export const ALICE: WebMember = { id: 1, email: "alice@example.com", name: "Alice Exemple", provider: "google", providerId: "g-1" };
export const BOB: WebMember = { id: 2, email: "bob@example.com", name: "Bob Exemple", provider: "apple", providerId: "a-2" };

export class InMemoryMembers implements MemberDirectory {
  readonly disabled = new Set<number>();
  constructor(private readonly members: readonly WebMember[] = [ALICE, BOB]) {}

  async findByProvider(provider: "google" | "apple", providerId: string): Promise<MemberLookup> {
    return this.lookup(this.members.find((m) => m.provider === provider && m.providerId === providerId));
  }

  async findById(userId: number): Promise<MemberLookup> {
    return this.lookup(this.members.find((m) => m.id === userId));
  }

  private lookup(member: WebMember | undefined): MemberLookup {
    if (!member) return { kind: "absent" };
    return this.disabled.has(member.id) ? { kind: "disabled" } : { kind: "found", member };
  }
}

export class InMemoryPairings implements PairingRepository {
  readonly rows = new Map<string, Pairing>();

  async insert(pairing: Pairing): Promise<void> {
    this.rows.set(pairing.id, pairing);
  }
  async findById(id: string): Promise<Pairing | null> {
    return this.rows.get(id) ?? null;
  }
  async markScanned(codeHash: string, userId: number, now: Date): Promise<Pairing | null> {
    const found = [...this.rows.values()].find(
      (p) => p.codeHash === codeHash && p.status === "pending" && p.expiresAt > now,
    );
    return found ? this.put({ ...found, status: "scanned", userId }) : null;
  }
  async decide(id: string, userId: number, status: "approved" | "denied", now: Date): Promise<boolean> {
    const found = this.rows.get(id);
    if (!found || found.userId !== userId || found.status !== "scanned" || found.expiresAt <= now) return false;
    this.put({ ...found, status });
    return true;
  }
  async consume(id: string, now: Date): Promise<number | null> {
    const found = this.rows.get(id);
    if (!found || found.status !== "approved" || found.expiresAt <= now) return null;
    this.put({ ...found, status: "consumed" });
    return found.userId;
  }
  async purgeExpiredBefore(limit: Date): Promise<void> {
    for (const [id, p] of this.rows) if (p.expiresAt < limit) this.rows.delete(id);
  }
  private put(pairing: Pairing): Pairing {
    this.rows.set(pairing.id, pairing);
    return pairing;
  }
}

interface StoredSession {
  session: WebSession;
  tokenHash: string;
}

export class InMemorySessions implements SessionRepository {
  readonly rows = new Map<string, StoredSession>();
  touches = 0;

  constructor(private readonly members: InMemoryMembers) {}

  async insert(session: WebSession, tokenHash: string): Promise<void> {
    this.rows.set(session.id, { session, tokenHash });
  }
  async findByTokenHash(tokenHash: string): Promise<SessionRecord | null> {
    return this.record([...this.rows.values()].find((r) => r.tokenHash === tokenHash));
  }
  async findById(id: string): Promise<SessionRecord | null> {
    return this.record(this.rows.get(id));
  }
  async touch(id: string, lastSeenAt: Date, idleExpiresAt: Date): Promise<void> {
    const row = this.rows.get(id);
    if (!row || row.session.revokedAt) return;
    this.touches += 1;
    row.session = { ...row.session, lastSeenAt, idleExpiresAt };
  }
  async revoke(userId: number, id: string, now: Date): Promise<boolean> {
    const row = this.rows.get(id);
    if (!row || row.session.userId !== userId || row.session.revokedAt || row.session.expiresAt <= now) return false;
    row.session = { ...row.session, revokedAt: now };
    return true;
  }
  async revokeMany(userId: number, exceptId: string | null, now: Date): Promise<string[]> {
    const ids: string[] = [];
    for (const row of this.rows.values()) {
      const s = row.session;
      if (s.userId === userId && !s.revokedAt && s.expiresAt > now && s.id !== exceptId) {
        row.session = { ...s, revokedAt: now };
        ids.push(s.id);
      }
    }
    return ids;
  }
  async listActive(userId: number, now: Date): Promise<WebSession[]> {
    return [...this.rows.values()]
      .map((r) => r.session)
      .filter((s) => s.userId === userId && !s.revokedAt && s.idleExpiresAt > now && s.expiresAt > now)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }
  async purgeEndedBefore(limit: Date): Promise<void> {
    for (const [id, r] of this.rows) if (r.session.expiresAt < limit) this.rows.delete(id);
  }

  private async record(row: StoredSession | undefined): Promise<SessionRecord | null> {
    if (!row) return null;
    const lookup = await this.members.findById(row.session.userId);
    if (lookup.kind === "absent") return null;
    const member = this.members_(row.session.userId);
    return { session: row.session, member, memberActive: lookup.kind === "found" };
  }
  private members_(userId: number): WebMember {
    return userId === BOB.id ? BOB : ALICE;
  }
}
