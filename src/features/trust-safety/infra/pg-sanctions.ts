import type { Sql } from "postgres";
import type { SanctionDto } from "../presentation/dto";
import type { NewSanction, RevokeResult, SanctionsRepository } from "../application/ports";
import { sanctionFrom } from "./mappers";

type Executor = Sql;

// A sanction with its appeal, as one row. Shared by the sanction and appeal repositories.
export function selectSanctions(sql: Executor) {
  return sql`
    SELECT s.id, s.user_id, s.kind, s.ground, s.starts_at, s.ends_at, s.decided_by, s.report_id,
           s.statement, s.revoked_at, s.revoked_by,
           a.id AS a_id, a.message AS a_message, a.status AS a_status, a.decided_by AS a_decided_by,
           a.decided_at AS a_decided_at, a.decision_note AS a_decision_note, a.created_at AS a_created_at
    FROM member_sanctions s
    LEFT JOIN sanction_appeals a ON a.sanction_id = s.id
  `;
}

export async function loadSanction(sql: Executor, id: number): Promise<SanctionDto | null> {
  const rows = await sql`${selectSanctions(sql)} WHERE s.id = ${id}`;
  const row = rows[0];
  return row ? sanctionFrom(row) : null;
}

// Runs inside the caller's transaction when given one.
export async function insertSanction(sql: Executor, sanction: NewSanction): Promise<SanctionDto> {
  const rows = await sql`
    INSERT INTO member_sanctions
      (user_id, kind, ground, starts_at, ends_at, decided_by, report_id, statement, appeal_code_hash, note)
    VALUES
      (${sanction.memberId}, ${sanction.kind}, ${sanction.ground}, ${sanction.startsAt}, ${sanction.endsAt},
       ${sanction.decidedBy}, ${sanction.reportId}, ${JSON.stringify(sanction.statement)}::text::jsonb,
       ${sanction.appealCodeHash}, ${sanction.note})
    RETURNING id
  `;
  const id = rows[0]?.id;
  if (typeof id !== "number") throw new Error("sanction insert returned no id");
  const stored = await loadSanction(sql, id);
  if (!stored) throw new Error("sanction vanished after insert");
  return stored;
}

export class PgSanctionsRepository implements SanctionsRepository {
  constructor(private readonly sql: Sql) {}

  insert(sanction: NewSanction): Promise<SanctionDto> {
    return insertSanction(this.sql, sanction);
  }

  find(id: number): Promise<SanctionDto | null> {
    return loadSanction(this.sql, id);
  }

  async listForMember(memberId: number): Promise<readonly SanctionDto[]> {
    const rows = await this.sql`${selectSanctions(this.sql)} WHERE s.user_id = ${memberId} ORDER BY s.created_at DESC, s.id DESC`;
    return rows.map(sanctionFrom);
  }

  async revoke(id: number, by: string, note: string): Promise<RevokeResult> {
    const updated = await this.sql`
      UPDATE member_sanctions SET revoked_at = now(), revoked_by = ${by}, revoke_note = ${note}
      WHERE id = ${id} AND revoked_at IS NULL RETURNING id
    `;
    const sanction = await loadSanction(this.sql, id);
    if (updated.length > 0 && sanction) return { kind: "revoked", sanction };
    return sanction ? { kind: "already_revoked" } : { kind: "not_found" };
  }

  async findByReference(reference: string) {
    const rows = await this.sql`
      SELECT appeal_code_hash, id FROM member_sanctions WHERE statement->>'reference' = ${reference}
    `;
    const row = rows[0];
    if (!row || typeof row.appeal_code_hash !== "string" || typeof row.id !== "number") return null;
    const sanction = await loadSanction(this.sql, row.id);
    return sanction ? { sanction, appealCodeHash: row.appeal_code_hash } : null;
  }

  async hasActiveBlocking(memberId: number): Promise<boolean> {
    const rows = await this.sql`
      SELECT 1 FROM member_sanctions
      WHERE user_id = ${memberId} AND kind IN ('suspension', 'ban') AND revoked_at IS NULL
        AND starts_at <= now() AND (ends_at IS NULL OR ends_at > now())
      LIMIT 1
    `;
    return rows.length > 0;
  }
}
