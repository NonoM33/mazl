import { sql } from "../../../db";

// CONTRAT §5 ("documents"). The table itself is created by initDb(); this
// adds what the encrypted/purged flow needs. Idempotent, run at every boot
// after initDb().
export async function ensureDocumentsSchema(db: typeof sql = sql): Promise<void> {
  await db`ALTER TABLE documents ALTER COLUMN filename DROP NOT NULL`;
  await db`ALTER TABLE documents ADD COLUMN IF NOT EXISTS encrypted BOOLEAN NOT NULL DEFAULT false`;
  await db`ALTER TABLE documents ADD COLUMN IF NOT EXISTS purged_at TIMESTAMP`;
}
