import { sql } from "../../../db";
import type {
  DocumentRepository,
  NewDocument,
  PurgeScope,
  PurgeTarget,
} from "../application/ports";
import type { DecisionStatus, DocumentRecord, ReviewStatus } from "../domain/types";

interface DocumentRow {
  id: number;
  waitlist_id: number;
  type: string;
  filename: string | null;
  mime_type: string | null;
  status: ReviewStatus;
  encrypted: boolean;
  purged_at: Date | null;
  created_at: Date;
}

const COLUMNS = sql`id, waitlist_id, type, filename, mime_type, status, encrypted, purged_at, created_at`;

function toRecord(row: DocumentRow): DocumentRecord {
  return {
    id: row.id,
    waitlistId: row.waitlist_id,
    type: row.type,
    filename: row.filename,
    mimeType: row.mime_type,
    status: row.status,
    encrypted: row.encrypted,
    purgedAt: row.purged_at,
    createdAt: row.created_at,
  };
}

function toTarget(row: { id: number; filename: string | null }): PurgeTarget {
  return { id: row.id, filename: row.filename };
}

export class PostgresDocumentRepository implements DocumentRepository {
  async insert(doc: NewDocument): Promise<number> {
    // original_name is deliberately not stored: a file name can carry a name.
    const rows = await sql<{ id: number }[]>`
      INSERT INTO documents (waitlist_id, type, filename, mime_type, encrypted)
      VALUES (${doc.waitlistId}, ${doc.type}, ${doc.fileName}, ${doc.mimeType}, true)
      RETURNING id
    `;
    const row = rows[0];
    if (!row) throw new Error("document insert returned no row");
    return row.id;
  }

  async delete(id: number): Promise<void> {
    await sql`DELETE FROM documents WHERE id = ${id}`;
  }

  async findById(id: number): Promise<DocumentRecord | null> {
    const rows = await sql<DocumentRow[]>`SELECT ${COLUMNS} FROM documents WHERE id = ${id}`;
    return rows[0] ? toRecord(rows[0]) : null;
  }

  async latestByType(waitlistId: number): Promise<Record<string, DocumentRecord>> {
    const rows = await sql<DocumentRow[]>`
      SELECT DISTINCT ON (type) ${COLUMNS}
      FROM documents
      WHERE waitlist_id = ${waitlistId}
      ORDER BY type, created_at DESC, id DESC
    `;
    return Object.fromEntries(rows.map((row) => [row.type, toRecord(row)]));
  }

  async typesByIds(waitlistId: number, ids: readonly number[]): Promise<string[]> {
    if (ids.length === 0) return [];
    const rows = await sql<{ type: string }[]>`
      SELECT type FROM documents WHERE waitlist_id = ${waitlistId} AND id IN ${sql([...ids])}
    `;
    return rows.map((row) => row.type);
  }

  async decide(params: {
    ids: readonly number[];
    waitlistId?: number;
    status: DecisionStatus;
    notes: string | null;
  }): Promise<void> {
    if (params.ids.length === 0) return;
    const ids = [...params.ids];
    const scope = params.waitlistId === undefined ? sql`TRUE` : sql`waitlist_id = ${params.waitlistId}`;
    await sql`
      UPDATE documents
      SET status = ${params.status}, reviewed_at = NOW(), reviewer_notes = ${params.notes}
      WHERE id IN ${sql(ids)} AND ${scope}
    `;
  }

  async approveAllNotRejected(waitlistId: number): Promise<void> {
    await sql`
      UPDATE documents
      SET status = 'approved', reviewed_at = NOW(), reviewer_notes = NULL
      WHERE waitlist_id = ${waitlistId} AND status != 'rejected'
    `;
  }

  async rejectAll(waitlistId: number, notes: string | null): Promise<void> {
    await sql`
      UPDATE documents
      SET status = 'rejected', reviewed_at = NOW(), reviewer_notes = ${notes}
      WHERE waitlist_id = ${waitlistId}
    `;
  }

  async findDecidedUnpurged(scope: PurgeScope): Promise<PurgeTarget[]> {
    let where;
    if (scope === "all") where = sql`TRUE`;
    else if ("ids" in scope) {
      if (scope.ids.length === 0) return [];
      where = sql`id IN ${sql([...scope.ids])}`;
    } else where = sql`waitlist_id = ${scope.waitlistId}`;

    const rows = await sql<{ id: number; filename: string | null }[]>`
      SELECT id, filename FROM documents
      WHERE status IN ('approved', 'rejected') AND purged_at IS NULL AND ${where}
    `;
    return rows.map(toTarget);
  }

  async findStaleUndecided(maxAgeDays: number): Promise<PurgeTarget[]> {
    const rows = await sql<{ id: number; filename: string | null }[]>`
      SELECT id, filename FROM documents
      WHERE status = 'pending' AND purged_at IS NULL
        AND created_at < NOW() - make_interval(days => ${maxAgeDays})
    `;
    return rows.map(toTarget);
  }

  async markPurged(ids: readonly number[]): Promise<void> {
    if (ids.length === 0) return;
    await sql`
      UPDATE documents
      SET filename = NULL, original_name = NULL, purged_at = NOW()
      WHERE id IN ${sql([...ids])}
    `;
  }

  async findPlaintext(): Promise<DocumentRecord[]> {
    const rows = await sql<DocumentRow[]>`
      SELECT ${COLUMNS} FROM documents
      WHERE encrypted = false AND purged_at IS NULL AND filename IS NOT NULL
      ORDER BY id
    `;
    return rows.map(toRecord);
  }

  async replaceWithEncrypted(id: number, fileName: string): Promise<void> {
    // original_name may hold a client file name: dropped along the way.
    await sql`
      UPDATE documents SET filename = ${fileName}, encrypted = true, original_name = NULL
      WHERE id = ${id}
    `;
  }

  async referencedFileNames(): Promise<Set<string>> {
    const rows = await sql<{ filename: string }[]>`
      SELECT filename FROM documents WHERE filename IS NOT NULL
    `;
    return new Set(rows.map((row) => row.filename));
  }
}
