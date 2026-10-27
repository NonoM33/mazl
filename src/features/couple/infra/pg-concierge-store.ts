import type { Sql } from "postgres";
import type { ConciergeStore, CoupleSummary, MessageRecord, NewRequest, RequestRecord, StaffListFilter } from "../application/concierge-ports";
import { optionSchema, type ConciergeOption, type MessageRole, type RequestKind, type RequestStatus } from "../domain/concierge";
import { z } from "zod";

interface RequestRow {
  id: number;
  couple_id: number;
  created_by: number | null;
  title: string;
  brief: string;
  kind: RequestKind;
  wanted_at: string | null;
  city: string | null;
  constraints: unknown;
  status: RequestStatus;
  options: unknown;
  chosen_index: number | null;
  staff_note: string | null;
  assigned_to: string | null;
  created_at: Date;
  updated_at: Date;
}

const constraintsSchema = z.object({ kosher: z.boolean().optional(), budget: z.string().optional() }).passthrough();
const optionsSchema = z.array(optionSchema);

// Columns written by this feature only; a row that fails to parse yields no options.
function toRecord(row: RequestRow): RequestRecord {
  const constraints = constraintsSchema.safeParse(row.constraints);
  const options = optionsSchema.safeParse(row.options);
  return {
    id: Number(row.id),
    coupleId: Number(row.couple_id),
    createdBy: row.created_by === null ? null : Number(row.created_by),
    title: row.title,
    brief: row.brief,
    kind: row.kind,
    wantedAt: row.wanted_at,
    city: row.city,
    constraints: constraints.success ? { ...(constraints.data.kosher === undefined ? {} : { kosher: constraints.data.kosher }), ...(constraints.data.budget === undefined ? {} : { budget: constraints.data.budget }) } : {},
    status: row.status,
    options: options.success ? options.data : [],
    chosenIndex: row.chosen_index,
    staffNote: row.staff_note,
    assignedTo: row.assigned_to,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

const COLUMNS = (sql: Sql) => sql`id, couple_id, created_by, title, brief, kind, to_char(wanted_at, 'YYYY-MM-DD') AS wanted_at, city, constraints, status, options, chosen_index, staff_note, assigned_to,
  (created_at AT TIME ZONE 'UTC') AS created_at, (updated_at AT TIME ZONE 'UTC') AS updated_at`;

function firstName(displayName: string | null): string {
  return (displayName ?? "").trim().split(/\s+/)[0] ?? "";
}

export class PgConciergeStore implements ConciergeStore {
  constructor(private readonly sql: Sql) {}

  async create(request: NewRequest): Promise<RequestRecord> {
    const [row] = await this.sql<RequestRow[]>`
      INSERT INTO concierge_requests (couple_id, created_by, title, brief, kind, wanted_at, city, constraints)
      VALUES (${request.coupleId}, ${request.createdBy}, ${request.title}, ${request.brief}, ${request.kind}, ${request.wantedAt}, ${request.city},
              ${this.sql.json(request.constraints as Record<string, string | boolean>)})
      RETURNING ${COLUMNS(this.sql)}`;
    if (row === undefined) throw new Error("request not written");
    return toRecord(row);
  }

  async find(id: number): Promise<RequestRecord | null> {
    const [row] = await this.sql<RequestRow[]>`SELECT ${COLUMNS(this.sql)} FROM concierge_requests WHERE id = ${id}`;
    return row === undefined ? null : toRecord(row);
  }

  async listForCouple(coupleId: number): Promise<RequestRecord[]> {
    const rows = await this.sql<RequestRow[]>`SELECT ${COLUMNS(this.sql)} FROM concierge_requests WHERE couple_id = ${coupleId} ORDER BY updated_at DESC, id DESC`;
    return rows.map(toRecord);
  }

  async listAll(filter: StaffListFilter): Promise<RequestRecord[]> {
    const status = filter.status ?? null;
    const rows = await this.sql<RequestRow[]>`
      SELECT ${COLUMNS(this.sql)} FROM concierge_requests
      WHERE (${status}::text IS NULL OR status = ${status})
      ORDER BY updated_at DESC, id DESC LIMIT 200`;
    return rows.map(toRecord);
  }

  async thread(requestId: number): Promise<MessageRecord[]> {
    const rows = await this.sql<{ id: number; role: MessageRole; author_id: number | null; text: string; created_at: Date }[]>`
      SELECT id, role, author_id, text, (created_at AT TIME ZONE 'UTC') AS created_at FROM concierge_messages WHERE request_id = ${requestId} ORDER BY id`;
    return rows.map((row) => ({
      id: Number(row.id),
      role: row.role,
      authorId: row.author_id === null ? null : Number(row.author_id),
      text: row.text,
      createdAt: new Date(row.created_at).toISOString(),
    }));
  }

  async addMessage(requestId: number, role: MessageRole, authorId: number | null, text: string): Promise<MessageRecord> {
    const [row] = await this.sql<{ id: number; created_at: Date }[]>`
      INSERT INTO concierge_messages (request_id, role, author_id, text) VALUES (${requestId}, ${role}, ${authorId}, ${text})
      RETURNING id, (created_at AT TIME ZONE 'UTC') AS created_at`;
    if (row === undefined) throw new Error("message not written");
    await this.sql`UPDATE concierge_requests SET updated_at = NOW() WHERE id = ${requestId}`;
    return { id: Number(row.id), role, authorId, text, createdAt: new Date(row.created_at).toISOString() };
  }

  async memberMessagesToday(coupleId: number, since: Date): Promise<number> {
    const [row] = await this.sql<{ total: string }[]>`
      SELECT COUNT(*)::text AS total FROM concierge_messages m JOIN concierge_requests r ON r.id = m.request_id
      WHERE r.couple_id = ${coupleId} AND m.role = 'member' AND m.created_at > ${since.toISOString()}::timestamptz AT TIME ZONE 'UTC'`;
    return Number(row?.total ?? 0);
  }

  async setProposal(id: number, status: RequestStatus, options: readonly ConciergeOption[]): Promise<void> {
    await this.sql`UPDATE concierge_requests SET status = ${status}, options = ${this.sql.json(options as unknown as Record<string, string>[])}, chosen_index = NULL, updated_at = NOW() WHERE id = ${id}`;
  }

  async setStatus(id: number, status: RequestStatus, chosenIndex?: number | null): Promise<RequestRecord | null> {
    const chosen = chosenIndex === undefined ? null : chosenIndex;
    const [row] = await this.sql<RequestRow[]>`
      UPDATE concierge_requests SET status = ${status}, chosen_index = CASE WHEN ${chosenIndex !== undefined} THEN ${chosen}::int ELSE chosen_index END, updated_at = NOW()
      WHERE id = ${id} RETURNING ${COLUMNS(this.sql)}`;
    return row === undefined ? null : toRecord(row);
  }

  async patchStaff(id: number, patch: { status?: RequestStatus; staffNote?: string; assignedTo?: string | null }): Promise<RequestRecord | null> {
    const assignedGiven = patch.assignedTo !== undefined;
    const [row] = await this.sql<RequestRow[]>`
      UPDATE concierge_requests SET
        status = COALESCE(${patch.status ?? null}::text, status),
        staff_note = COALESCE(${patch.staffNote ?? null}::text, staff_note),
        assigned_to = CASE WHEN ${assignedGiven} THEN ${patch.assignedTo ?? null}::text ELSE assigned_to END,
        updated_at = NOW()
      WHERE id = ${id} RETURNING ${COLUMNS(this.sql)}`;
    return row === undefined ? null : toRecord(row);
  }

  // First names of the two members, whole months since the couple started.
  async coupleSummary(coupleId: number): Promise<CoupleSummary | null> {
    const rows = await this.sql<{ user_id: number; display_name: string | null; started_at: Date | null }[]>`
      SELECT u.id AS user_id, p.display_name, c.started_at
      FROM couples c JOIN users u ON u.id IN (c.user1_id, c.user2_id)
      LEFT JOIN profiles p ON p.user_id = u.id
      WHERE c.id = ${coupleId} ORDER BY u.id`;
    const first = rows[0];
    if (first === undefined) return null;
    const started = first.started_at === null ? null : new Date(first.started_at);
    const now = new Date();
    const months = started === null ? 0 : Math.max(0, (now.getUTCFullYear() - started.getUTCFullYear()) * 12 + now.getUTCMonth() - started.getUTCMonth() - (now.getUTCDate() < started.getUTCDate() ? 1 : 0));
    return { firstNames: rows.map((row) => firstName(row.display_name)), months, memberIds: rows.map((row) => Number(row.user_id)) };
  }
}
