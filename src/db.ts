import postgres from "postgres";

const connectionString = process.env.DATABASE_URL || "postgres://postgres:postgres@localhost:5432/mazl";

export const sql = postgres(connectionString);

export async function initDb() {
  await sql`
    CREATE TABLE IF NOT EXISTS waitlist (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) UNIQUE NOT NULL,
      token VARCHAR(64) NOT NULL,
      status VARCHAR(20) DEFAULT 'pending',
      created_at TIMESTAMP DEFAULT NOW(),
      confirmed_at TIMESTAMP,
      verification_token VARCHAR(128),
      verification_status VARCHAR(20) DEFAULT 'pending',
      verification_requested_at TIMESTAMP,
      documents_submitted_at TIMESTAMP,
      verified_at TIMESTAMP
    )
  `;

  // Backward-compatible migrations
  await sql`ALTER TABLE waitlist ADD COLUMN IF NOT EXISTS verification_token VARCHAR(128)`;
  await sql`ALTER TABLE waitlist ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) DEFAULT 'pending'`;
  await sql`ALTER TABLE waitlist ADD COLUMN IF NOT EXISTS verification_requested_at TIMESTAMP`;
  await sql`ALTER TABLE waitlist ADD COLUMN IF NOT EXISTS documents_submitted_at TIMESTAMP`;
  await sql`ALTER TABLE waitlist ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP`;

  await sql`
    CREATE TABLE IF NOT EXISTS documents (
      id SERIAL PRIMARY KEY,
      waitlist_id INTEGER REFERENCES waitlist(id) ON DELETE CASCADE,
      type VARCHAR(50) NOT NULL,
      filename VARCHAR(255) NOT NULL,
      original_name VARCHAR(255),
      mime_type VARCHAR(100),
      status VARCHAR(20) DEFAULT 'pending',
      created_at TIMESTAMP DEFAULT NOW(),
      reviewed_at TIMESTAMP,
      reviewer_notes TEXT
    )
  `;

  console.log("Database initialized");
}

function generateVerificationToken() {
  return crypto.randomUUID().replace(/-/g, "") + crypto.randomUUID().replace(/-/g, "");
}

export async function upsertWaitlistAndGetVerification(email: string) {
  const verificationToken = generateVerificationToken();

  const result = await sql`
    INSERT INTO waitlist (email, token, status, confirmed_at, verification_token, verification_status, verification_requested_at)
    VALUES (${email}, ${crypto.randomUUID()}, 'confirmed', NOW(), ${verificationToken}, 'pending', NOW())
    ON CONFLICT (email)
    DO UPDATE SET
      verification_token = ${verificationToken},
      verification_status = 'pending',
      verification_requested_at = NOW()
    RETURNING id, email, verification_token
  `;

  const row = result[0];
  if (!row) throw new Error("Failed to upsert waitlist");

  return { id: row.id as number, email: row.email as string, verificationToken: row.verification_token as string };
}

export async function markVerificationSubmitted(waitlistId: number) {
  await sql`
    UPDATE waitlist
    SET verification_status = 'submitted', documents_submitted_at = NOW()
    WHERE id = ${waitlistId}
  `;
}

export async function findWaitlistByVerificationToken(token: string) {
  const result = await sql`
    SELECT id, email, verification_status FROM waitlist WHERE verification_token = ${token}
  `;
  return result.length ? (result[0] as { id: number; email: string; verification_status: string }) : null;
}

export async function createDocument(params: {
  waitlistId: number;
  type: string;
  filename: string;
  originalName?: string;
  mimeType?: string;
}) {
  const result = await sql`
    INSERT INTO documents (waitlist_id, type, filename, original_name, mime_type)
    VALUES (${params.waitlistId}, ${params.type}, ${params.filename}, ${params.originalName ?? null}, ${params.mimeType ?? null})
    RETURNING id
  `;
  const row = result[0];
  if (!row) throw new Error("Failed to create document");
  return row.id as number;
}

export async function listPendingSubmissions() {
  const rows = await sql`
    SELECT w.id as waitlist_id, w.email, w.verification_status, w.documents_submitted_at,
           d.id as document_id, d.type, d.filename, d.mime_type, d.status as document_status, d.created_at
    FROM waitlist w
    LEFT JOIN documents d ON d.waitlist_id = w.id
    WHERE w.verification_status IN ('submitted')
    ORDER BY w.documents_submitted_at DESC NULLS LAST, w.created_at DESC
  `;

  const grouped = new Map<number, any>();
  for (const row of rows) {
    const id = row.waitlist_id as number;
    if (!grouped.has(id)) {
      grouped.set(id, {
        waitlistId: id,
        email: row.email,
        verificationStatus: row.verification_status,
        submittedAt: row.documents_submitted_at,
        documents: [],
      });
    }
    if (row.document_id) {
      grouped.get(id).documents.push({
        id: row.document_id,
        type: row.type,
        filename: row.filename,
        mimeType: row.mime_type,
        status: row.document_status,
        createdAt: row.created_at,
      });
    }
  }

  return Array.from(grouped.values());
}

export async function setDocumentReview(params: { documentId: number; status: 'approved' | 'rejected'; notes?: string }) {
  await sql`
    UPDATE documents
    SET status = ${params.status}, reviewed_at = NOW(), reviewer_notes = ${params.notes ?? null}
    WHERE id = ${params.documentId}
  `;
}

export async function getDocumentById(documentId: number) {
  const result = await sql`
    SELECT id, waitlist_id, filename, mime_type FROM documents WHERE id = ${documentId}
  `;
  return result.length
    ? (result[0] as { id: number; waitlist_id: number; filename: string; mime_type: string | null })
    : null;
}

export async function getLatestDocumentsByType(waitlistId: number) {
  const rows = await sql`
    SELECT DISTINCT ON (type)
      id, type, filename, mime_type, status, created_at
    FROM documents
    WHERE waitlist_id = ${waitlistId}
    ORDER BY type, created_at DESC
  `;

  const map: Record<
    string,
    { id: number; type: string; filename: string; mimeType: string | null; status: string }
  > = {};

  for (const row of rows as any[]) {
    map[row.type] = {
      id: row.id,
      type: row.type,
      filename: row.filename,
      mimeType: row.mime_type ?? null,
      status: row.status,
    };
  }

  return map;
}

export async function approveAllDocumentsForWaitlist(waitlistId: number) {
  await sql`
    UPDATE documents
    SET status = 'approved', reviewed_at = NOW(), reviewer_notes = NULL
    WHERE waitlist_id = ${waitlistId} AND status != 'rejected'
  `;
}

export async function rejectAllDocumentsForWaitlist(waitlistId: number, notes?: string) {
  await sql`
    UPDATE documents
    SET status = 'rejected', reviewed_at = NOW(), reviewer_notes = ${notes ?? null}
    WHERE waitlist_id = ${waitlistId}
  `;
}

export async function setWaitlistVerificationStatus(waitlistId: number, status: string) {
  const verifiedAt = status === 'verified' || status === 'verified_plus' ? sql`NOW()` : sql`NULL`;
  const submittedAt = status === 'submitted' ? sql`NOW()` : sql`documents_submitted_at`;
  const resetSubmitted = status === 'pending' ? sql`NULL` : submittedAt;

  await sql`
    UPDATE waitlist
    SET verification_status = ${status},
        verified_at = ${verifiedAt},
        documents_submitted_at = ${resetSubmitted}
    WHERE id = ${waitlistId}
  `;
}


export async function confirmEmail(token: string) {
  const result = await sql`
    UPDATE waitlist
    SET status = 'confirmed', confirmed_at = NOW()
    WHERE token = ${token} AND status = 'pending'
    RETURNING email
  `;
  return result.length > 0 ? result[0] : null;
}

export async function getConfirmedCount() {
  const result = await sql`
    SELECT COUNT(*) as count FROM waitlist WHERE status = 'confirmed'
  `;
  const row = result[0];
  return row ? parseInt(row.count) : 0;
}

export async function getTotalCount() {
  const result = await sql`
    SELECT COUNT(*) as count FROM waitlist WHERE status = 'confirmed'
  `;
  const row = result[0];
  return row ? parseInt(row.count) : 0;
}
