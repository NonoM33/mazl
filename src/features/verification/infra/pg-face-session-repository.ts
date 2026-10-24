import type { Sql } from "postgres";
import type {
  FaceSession,
  FaceSessionRepository,
  SessionConsumption,
  SessionCreation,
} from "../application/ports";
import type { Challenge, FacePurpose } from "../domain/types";

// Timestamps are stored as TIMESTAMP in the server's time zone (NOW()).
// Re-attaching that zone in SQL gives postgres.js an unambiguous instant.
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const LOCK_NAMESPACE = 0x6661; // "fa": advisory locks of this feature

interface SessionRow {
  id: string;
  user_id: number;
  purpose: FacePurpose;
  challenges: Challenge[];
  expires_at: Date;
}

const toSession = (row: SessionRow): FaceSession => ({
  id: row.id,
  userId: row.user_id,
  purpose: row.purpose,
  challenges: row.challenges,
  expiresAt: row.expires_at,
});

export class PgFaceSessionRepository implements FaceSessionRepository {
  constructor(private readonly sql: Sql) {}

  async createWithinDailyQuota(input: {
    userId: number;
    purpose: FacePurpose;
    challenges: readonly Challenge[];
    ttlSeconds: number;
    dailyLimit: number;
  }): Promise<SessionCreation> {
    return this.sql.begin(async (transaction): Promise<SessionCreation> => {
      // postgres.js types TransactionSql without its call signature; it is one.
      const tx = transaction as unknown as Sql;
      // Serialises concurrent requests of one user so the count cannot be raced.
      await tx`SELECT pg_advisory_xact_lock(${LOCK_NAMESPACE}, ${input.userId})`;
      const [counted] = await tx<{ count: number }[]>`
        SELECT COUNT(*)::int AS count FROM face_verification_sessions
        WHERE user_id = ${input.userId} AND purpose = ${input.purpose}
          AND created_at >= DATE_TRUNC('day', NOW())
      `;
      if ((counted?.count ?? 0) >= input.dailyLimit) {
        return { ok: false, nextAttemptTime: await this.nextMidnight(tx) };
      }
      const rows = await tx<SessionRow[]>`
        INSERT INTO face_verification_sessions (id, user_id, purpose, challenges, expires_at)
        VALUES (${crypto.randomUUID()}, ${input.userId}, ${input.purpose},
                ${tx.json([...input.challenges])}, NOW() + make_interval(secs => ${input.ttlSeconds}))
        RETURNING id, user_id, purpose, challenges,
                  expires_at AT TIME ZONE current_setting('TimeZone') AS expires_at
      `;
      const row = rows[0];
      if (!row) throw new Error("face session insert returned no row");
      return { ok: true, session: toSession(row) };
    });
  }

  async consume(sessionId: string, userId: number, purpose: FacePurpose): Promise<SessionConsumption> {
    if (!UUID.test(sessionId)) return { ok: false, reason: "session_not_found" };
    const claimed = await this.sql<SessionRow[]>`
      UPDATE face_verification_sessions SET consumed_at = NOW()
      WHERE id = ${sessionId} AND user_id = ${userId} AND purpose = ${purpose}
        AND consumed_at IS NULL AND expires_at > NOW()
      RETURNING id, user_id, purpose, challenges,
                expires_at AT TIME ZONE current_setting('TimeZone') AS expires_at
    `;
    if (claimed[0]) return { ok: true, session: toSession(claimed[0]) };

    const [existing] = await this.sql<{ consumed: boolean }[]>`
      SELECT (consumed_at IS NOT NULL) AS consumed FROM face_verification_sessions
      WHERE id = ${sessionId} AND user_id = ${userId} AND purpose = ${purpose}
    `;
    if (!existing) return { ok: false, reason: "session_not_found" };
    return { ok: false, reason: existing.consumed ? "session_used" : "session_expired" };
  }

  async recordOutcome(sessionId: string, outcome: string): Promise<void> {
    await this.sql`UPDATE face_verification_sessions SET outcome = ${outcome.slice(0, 40)} WHERE id = ${sessionId}`;
  }

  async countToday(userId: number, purpose: FacePurpose): Promise<number> {
    const [row] = await this.sql<{ count: number }[]>`
      SELECT COUNT(*)::int AS count FROM face_verification_sessions
      WHERE user_id = ${userId} AND purpose = ${purpose} AND created_at >= DATE_TRUNC('day', NOW())
    `;
    return row?.count ?? 0;
  }

  async nextMidnight(db: Sql = this.sql): Promise<Date> {
    const [row] = await db<{ next: Date }[]>`
      SELECT DATE_TRUNC('day', NOW()) + INTERVAL '1 day' AS next
    `;
    return row?.next ?? new Date();
  }
}
