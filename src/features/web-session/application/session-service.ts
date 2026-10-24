import { randomUUID } from "node:crypto";
import { randomToken, sha256Hex } from "../domain/hashing";
import {
  absoluteDeadline,
  idleDeadline,
  isActive,
  needsTouch,
  type SignInMethod,
  type WebSession,
} from "../domain/session";
import type {
  Clock,
  OpenedSession,
  SessionRecord,
  SessionRepository,
  SessionRevocationListener,
  WebMember,
} from "./ports";

export interface LiveSession {
  readonly session: WebSession;
  readonly member: WebMember;
}

const PURGE_EVERY_MS = 60 * 60_000;
const PURGE_AFTER_MS = 30 * 24 * 60 * 60_000;

export class SessionService {
  private lastPurge = 0;

  constructor(
    private readonly sessions: SessionRepository,
    private readonly listener: SessionRevocationListener,
    private readonly now: Clock,
  ) {}

  async open(member: WebMember, method: SignInMethod, browserLabel: string): Promise<OpenedSession> {
    const now = this.now();
    const token = randomToken();
    const session: WebSession = {
      id: randomUUID(),
      userId: member.id,
      browserLabel,
      method,
      createdAt: now,
      lastSeenAt: now,
      idleExpiresAt: idleDeadline(now),
      expiresAt: absoluteDeadline(now),
      revokedAt: null,
    };
    await this.sessions.insert(session, sha256Hex(token));
    await this.purgeOccasionally(now);
    return { token, session };
  }

  // The session behind a cookie value, refreshed at most once a minute.
  async resolve(token: string): Promise<LiveSession | null> {
    const record = await this.sessions.findByTokenHash(sha256Hex(token));
    return this.liveOrNull(record, true);
  }

  async get(sessionId: string): Promise<LiveSession | null> {
    return this.liveOrNull(await this.sessions.findById(sessionId), false);
  }

  list(userId: number): Promise<WebSession[]> {
    return this.sessions.listActive(userId, this.now());
  }

  async revoke(userId: number, sessionId: string): Promise<boolean> {
    const revoked = await this.sessions.revoke(userId, sessionId, this.now());
    if (revoked) this.listener.sessionsRevoked([sessionId]);
    return revoked;
  }

  async revokeAll(userId: number, exceptId: string | null): Promise<void> {
    const ids = await this.sessions.revokeMany(userId, exceptId, this.now());
    if (ids.length > 0) this.listener.sessionsRevoked(ids);
  }

  private async liveOrNull(record: SessionRecord | null, touch: boolean): Promise<LiveSession | null> {
    const now = this.now();
    if (!record || !record.memberActive || !isActive(record.session, now)) return null;
    if (touch && needsTouch(record.session, now)) {
      await this.sessions.touch(record.session.id, now, idleDeadline(now));
    }
    return { session: record.session, member: record.member };
  }

  private async purgeOccasionally(now: Date): Promise<void> {
    if (now.getTime() - this.lastPurge < PURGE_EVERY_MS) return;
    this.lastPurge = now.getTime();
    await this.sessions.purgeEndedBefore(new Date(now.getTime() - PURGE_AFTER_MS));
  }
}
