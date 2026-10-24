import type { Sql } from "postgres";
import type { AuthorityInput, AuthorityRepository } from "../application/ports";
import { AUTHORITY_KINDS, AUTHORITY_STATUSES, type AuthorityStatus } from "../domain/types";
import type { AuthorityRequestDto } from "../presentation/dto";
import { iso, isoRequired, num, numOrNull, text, type Row } from "./mappers";

function authorityFrom(row: Row): AuthorityRequestDto {
  const kind = AUTHORITY_KINDS.find((candidate) => candidate === row.kind) ?? "other";
  const status = AUTHORITY_STATUSES.find((candidate) => candidate === row.status) ?? "received";
  return {
    id: num(row.id),
    kind,
    authority: text(row.authority) ?? "",
    reference: text(row.reference) ?? "",
    receivedAt: isoRequired(row.received_at),
    dueAt: iso(row.due_at),
    memberId: numOrNull(row.member_id),
    scope: text(row.scope) ?? "",
    status,
    handledBy: text(row.handled_by),
    notes: text(row.notes),
    createdAt: isoRequired(row.created_at),
  };
}

const COLUMN_OF: Readonly<Record<keyof AuthorityInput, string>> = {
  kind: "kind",
  authority: "authority",
  reference: "reference",
  receivedAt: "received_at",
  dueAt: "due_at",
  memberId: "member_id",
  scope: "scope",
  status: "status",
  handledBy: "handled_by",
  notes: "notes",
};

const FIELDS: readonly (keyof AuthorityInput)[] = [
  "kind",
  "authority",
  "reference",
  "receivedAt",
  "dueAt",
  "memberId",
  "scope",
  "status",
  "handledBy",
  "notes",
];

export class PgAuthorityRepository implements AuthorityRepository {
  constructor(private readonly sql: Sql) {}

  async list(status: AuthorityStatus | undefined, limit: number, offset: number) {
    const filter = status ? this.sql`WHERE status = ${status}` : this.sql``;
    const rows = await this.sql`SELECT * FROM authority_requests ${filter} ORDER BY due_at ASC NULLS LAST, id DESC LIMIT ${limit} OFFSET ${offset}`;
    const counted = await this.sql`SELECT COUNT(*)::int AS total FROM authority_requests ${filter}`;
    return { requests: rows.map(authorityFrom), total: num(counted[0]?.total) };
  }

  async create(input: AuthorityInput): Promise<AuthorityRequestDto> {
    const rows = await this.sql`
      INSERT INTO authority_requests (kind, authority, reference, received_at, due_at, member_id, scope, status, handled_by, notes)
      VALUES (${input.kind}, ${input.authority}, ${input.reference}, ${input.receivedAt}, ${input.dueAt}, ${input.memberId},
              ${input.scope}, ${input.status}, ${input.handledBy}, ${input.notes})
      RETURNING *
    `;
    const row = rows[0];
    if (!row) throw new Error("authority insert returned no row");
    return authorityFrom(row);
  }

  async update(id: number, patch: Partial<AuthorityInput>): Promise<AuthorityRequestDto | null> {
    const fields = FIELDS.filter((field) => patch[field] !== undefined);
    if (fields.length === 0) return this.find(id);
    // Column names come from the fixed map above, values stay parameters.
    const assignments = fields.map((field) => this.sql`${this.sql(COLUMN_OF[field])} = ${patch[field] ?? null}`);
    const set = assignments.reduce((all, next) => this.sql`${all}, ${next}`);
    const rows = await this.sql`UPDATE authority_requests SET ${set} WHERE id = ${id} RETURNING *`;
    const row = rows[0];
    return row ? authorityFrom(row) : null;
  }

  private async find(id: number): Promise<AuthorityRequestDto | null> {
    const rows = await this.sql`SELECT * FROM authority_requests WHERE id = ${id}`;
    const row = rows[0];
    return row ? authorityFrom(row) : null;
  }
}
