import type { JSONValue, Sql } from "postgres";
import type {
  AuditEntry,
  AuditEntryInput,
  AuditFilter,
  AuditLog,
  AuditTargetType,
  ChainVerification,
} from "../application/ports";
import { buildEntry, ChainVerifier, GENESIS_HASH } from "../domain/chain";

// Constant key of the advisory lock that serialises writers: the chain has one
// head, so two concurrent records must queue.
const CHAIN_LOCK_KEY = 7_203_114;
const VERIFY_BATCH = 500;

interface AuditRow {
  readonly id: string | number;
  readonly created_at: Date;
  readonly actor: string;
  readonly action: string;
  readonly target_type: AuditTargetType;
  readonly target_id: string | null;
  readonly justification: string | null;
  readonly details: Record<string, unknown> | null;
  readonly previous_hash: string;
  readonly hash: string;
}

function toEntry(row: AuditRow): AuditEntry {
  return {
    id: Number(row.id),
    createdAt: row.created_at.toISOString(),
    actor: row.actor,
    action: row.action,
    targetType: row.target_type,
    targetId: row.target_id,
    ...(row.justification === null ? {} : { justification: row.justification }),
    ...(row.details === null ? {} : { details: row.details }),
    previousHash: row.previous_hash,
    hash: row.hash,
  };
}

export class PgAuditLog implements AuditLog {
  constructor(
    private readonly sql: Sql,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async record(input: AuditEntryInput): Promise<AuditEntry> {
    // Validates the details before touching the database.
    buildEntry({ input, previousHash: GENESIS_HASH, createdAt: this.now(), id: 0 });
    const entry = await this.sql.begin(async (transaction) => {
      const tx = transaction as unknown as Sql;
      await tx`SELECT pg_advisory_xact_lock(${CHAIN_LOCK_KEY})`;
      const heads = await tx<{ hash: string }[]>`SELECT hash FROM audit_log ORDER BY id DESC LIMIT 1`;
      const previousHash = heads[0]?.hash ?? GENESIS_HASH;
      // Taken inside the lock so created_at grows with the chain.
      const built = buildEntry({ input, previousHash, createdAt: this.now(), id: 0 });
      const details: JSONValue | null = built.details === undefined ? null : (built.details as JSONValue);
      const rows = await tx<{ id: string | number }[]>`
        INSERT INTO audit_log (created_at, actor, action, target_type, target_id, justification, details, previous_hash, hash)
        VALUES (${built.createdAt}, ${built.actor}, ${built.action}, ${built.targetType}, ${built.targetId},
                ${built.justification ?? null}, ${details === null ? null : tx.json(details)}, ${built.previousHash}, ${built.hash})
        RETURNING id
      `;
      const inserted = rows[0];
      if (!inserted) throw new Error("audit insert returned no row");
      return { ...built, id: Number(inserted.id) };
    });
    return entry;
  }

  async list(filter: AuditFilter): Promise<{ readonly entries: readonly AuditEntry[]; readonly total: number }> {
    const where = this.sql`
      WHERE TRUE
      ${filter.actor === undefined ? this.sql`` : this.sql`AND actor = ${filter.actor}`}
      ${filter.action === undefined ? this.sql`` : this.sql`AND action = ${filter.action}`}
      ${filter.targetType === undefined ? this.sql`` : this.sql`AND target_type = ${filter.targetType}`}
      ${filter.targetId === undefined ? this.sql`` : this.sql`AND target_id = ${filter.targetId}`}
    `;
    const rows = await this.sql<AuditRow[]>`
      SELECT * FROM audit_log ${where} ORDER BY id DESC LIMIT ${filter.limit} OFFSET ${filter.offset}
    `;
    const counts = await this.sql<{ total: string }[]>`SELECT count(*) AS total FROM audit_log ${where}`;
    return { entries: rows.map(toEntry), total: Number(counts[0]?.total ?? 0) };
  }

  async verify(): Promise<ChainVerification> {
    const verifier = new ChainVerifier();
    let afterId = 0;
    for (;;) {
      const rows = await this.sql<AuditRow[]>`
        SELECT * FROM audit_log WHERE id > ${afterId} ORDER BY id ASC LIMIT ${VERIFY_BATCH}
      `;
      for (const row of rows) {
        if (!verifier.accept(toEntry(row))) return verifier.result();
        afterId = Number(row.id);
      }
      if (rows.length < VERIFY_BATCH) return verifier.result();
    }
  }
}
