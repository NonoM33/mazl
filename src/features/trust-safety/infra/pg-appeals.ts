import type { Sql } from "postgres";
import type { AppealDto } from "../presentation/dto";
import type { AppealDecisionResult, AppealsRepository } from "../application/ports";
import type { AppealStatus } from "../domain/types";
import { appealFrom, num } from "./mappers";
import { loadSanction, selectSanctions } from "./pg-sanctions";

const UNIQUE_VIOLATION = "23505";

function isUniqueViolation(error: unknown): boolean {
  return typeof error === "object" && error !== null && "code" in error && error.code === UNIQUE_VIOLATION;
}

export class PgAppealsRepository implements AppealsRepository {
  constructor(private readonly sql: Sql) {}

  async create(input: { sanctionId: number; memberId: number; message: string }): Promise<AppealDto | null> {
    try {
      const rows = await this.sql`
        INSERT INTO sanction_appeals (sanction_id, user_id, message)
        VALUES (${input.sanctionId}, ${input.memberId}, ${input.message}) RETURNING id
      `;
      return this.find(num(rows[0]?.id));
    } catch (error) {
      if (isUniqueViolation(error)) return null;
      throw error;
    }
  }

  async find(id: number): Promise<AppealDto | null> {
    const rows = await this.sql`${selectSanctions(this.sql)} WHERE a.id = ${id}`;
    const row = rows[0];
    return row ? appealFrom(row) : null;
  }

  async list(status: AppealStatus | undefined, limit: number, offset: number) {
    const filter = status ? this.sql`AND a.status = ${status}` : this.sql``;
    const rows = await this.sql`
      ${selectSanctions(this.sql)} WHERE a.id IS NOT NULL ${filter}
      ORDER BY (a.status = 'pending') DESC, a.created_at ASC LIMIT ${limit} OFFSET ${offset}
    `;
    const counted = await this.sql`SELECT COUNT(*)::int AS total FROM sanction_appeals a WHERE true ${filter}`;
    const appeals = rows.map(appealFrom).filter((appeal): appeal is AppealDto => appeal !== null);
    return { appeals, total: num(counted[0]?.total) };
  }

  async decide(input: { id: number; outcome: "upheld" | "overturned"; by: string; note: string }): Promise<AppealDecisionResult> {
    const sanctionId = await this.sql.begin(async (transaction) => {
      // postgres.js types TransactionSql without its call signature; it is one.
      const tx = transaction as unknown as Sql;
      const updated = await tx`
        UPDATE sanction_appeals SET status = ${input.outcome}, decided_by = ${input.by}, decided_at = now(), decision_note = ${input.note}
        WHERE id = ${input.id} AND status = 'pending' RETURNING sanction_id
      `;
      const row = updated[0];
      if (!row) return null;
      const target = num(row.sanction_id);
      if (input.outcome === "overturned") {
        await tx`
          UPDATE member_sanctions SET revoked_at = now(), revoked_by = ${input.by}, revoke_note = ${"Contestation admise #" + input.id}
          WHERE id = ${target} AND revoked_at IS NULL
        `;
      }
      return target;
    });
    if (sanctionId === null) {
      return (await this.find(input.id)) ? { kind: "already_decided" } : { kind: "not_found" };
    }
    const [appeal, sanction] = await Promise.all([this.find(input.id), loadSanction(this.sql, sanctionId)]);
    if (!appeal || !sanction) return { kind: "not_found" };
    return { kind: "decided", appeal, sanction };
  }
}
