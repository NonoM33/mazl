import type { Sql } from "postgres";
import type { SessionRecord, SessionRepository } from "../application/ports";
import type { SignInMethod, WebSession } from "../domain/session";
import { toMember } from "./pg-member-directory";
import { isUuid } from "./pg-pairing-repository";

interface SessionRow {
  id: string;
  user_id: number;
  browser_label: string;
  method: SignInMethod;
  created_at: Date;
  last_seen_at: Date;
  idle_expires_at: Date;
  expires_at: Date;
  revoked_at: Date | null;
}

interface JoinedRow extends SessionRow {
  email: string;
  name: string | null;
  provider: string;
  provider_id: string;
  is_active: boolean | null;
}

const toSession = (row: SessionRow): WebSession => ({
  id: row.id,
  userId: row.user_id,
  browserLabel: row.browser_label,
  method: row.method,
  createdAt: row.created_at,
  lastSeenAt: row.last_seen_at,
  idleExpiresAt: row.idle_expires_at,
  expiresAt: row.expires_at,
  revokedAt: row.revoked_at,
});

const toRecord = (row: JoinedRow): SessionRecord => ({
  session: toSession(row),
  member: toMember({ id: row.user_id, email: row.email, name: row.name, provider: row.provider, provider_id: row.provider_id }),
  memberActive: row.is_active !== false,
});

export class PgSessionRepository implements SessionRepository {
  constructor(private readonly sql: Sql) {}

  async insert(s: WebSession, tokenHash: string): Promise<void> {
    await this.sql`
      INSERT INTO web_sessions (id, token_hash, user_id, browser_label, method, created_at, last_seen_at, idle_expires_at, expires_at)
      VALUES (${s.id}, ${tokenHash}, ${s.userId}, ${s.browserLabel}, ${s.method}, ${s.createdAt}, ${s.lastSeenAt},
              ${s.idleExpiresAt}, ${s.expiresAt})`;
  }

  async findByTokenHash(tokenHash: string): Promise<SessionRecord | null> {
    const rows = await this.sql<JoinedRow[]>`
      SELECT s.*, u.email, u.name, u.provider, u.provider_id, u.is_active
      FROM web_sessions s JOIN users u ON u.id = s.user_id WHERE s.token_hash = ${tokenHash}`;
    return rows[0] ? toRecord(rows[0]) : null;
  }

  async findById(id: string): Promise<SessionRecord | null> {
    if (!isUuid(id)) return null;
    const rows = await this.sql<JoinedRow[]>`
      SELECT s.*, u.email, u.name, u.provider, u.provider_id, u.is_active
      FROM web_sessions s JOIN users u ON u.id = s.user_id WHERE s.id = ${id}`;
    return rows[0] ? toRecord(rows[0]) : null;
  }

  async touch(id: string, lastSeenAt: Date, idleExpiresAt: Date): Promise<void> {
    await this.sql`
      UPDATE web_sessions SET last_seen_at = ${lastSeenAt}, idle_expires_at = ${idleExpiresAt}
      WHERE id = ${id} AND revoked_at IS NULL`;
  }

  async revoke(userId: number, id: string, now: Date): Promise<boolean> {
    if (!isUuid(id)) return false;
    const rows = await this.sql`
      UPDATE web_sessions SET revoked_at = ${now}
      WHERE id = ${id} AND user_id = ${userId} AND revoked_at IS NULL AND expires_at > ${now}
      RETURNING id`;
    return rows.length > 0;
  }

  async revokeMany(userId: number, exceptId: string | null, now: Date): Promise<string[]> {
    const keep = exceptId !== null && isUuid(exceptId) ? exceptId : "00000000-0000-0000-0000-000000000000";
    const rows = await this.sql<{ id: string }[]>`
      UPDATE web_sessions SET revoked_at = ${now}
      WHERE user_id = ${userId} AND revoked_at IS NULL AND expires_at > ${now} AND id <> ${keep}
      RETURNING id`;
    return rows.map((row) => row.id);
  }

  async listActive(userId: number, now: Date): Promise<WebSession[]> {
    const rows = await this.sql<SessionRow[]>`
      SELECT * FROM web_sessions
      WHERE user_id = ${userId} AND revoked_at IS NULL AND idle_expires_at > ${now} AND expires_at > ${now}
      ORDER BY created_at DESC`;
    return rows.map(toSession);
  }

  async purgeEndedBefore(limit: Date): Promise<void> {
    await this.sql`DELETE FROM web_sessions WHERE expires_at < ${limit} OR revoked_at < ${limit}`;
  }
}
