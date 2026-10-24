import type { Sql } from "postgres";

// Append-only audit journal (docs/backoffice/CADRAGE.md §5). Idempotent: safe
// to run at every boot. The triggers refuse UPDATE, DELETE and TRUNCATE for
// every role, the application's included.
export async function ensureAuditSchema(sql: Sql): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS audit_log (
      id BIGSERIAL PRIMARY KEY,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      actor TEXT NOT NULL,
      action TEXT NOT NULL,
      target_type TEXT NOT NULL,
      target_id TEXT,
      justification TEXT,
      details JSONB,
      previous_hash TEXT NOT NULL,
      hash TEXT NOT NULL UNIQUE
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_audit_log_target ON audit_log (target_type, target_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_audit_log_actor ON audit_log (actor)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log (created_at)`;
  await sql`
    CREATE OR REPLACE FUNCTION audit_log_refuse_change() RETURNS trigger AS $$
    BEGIN
      RAISE EXCEPTION 'audit_log is append-only';
    END;
    $$ LANGUAGE plpgsql
  `;
  await sql`DROP TRIGGER IF EXISTS audit_log_no_row_change ON audit_log`;
  await sql`
    CREATE TRIGGER audit_log_no_row_change
    BEFORE UPDATE OR DELETE ON audit_log
    FOR EACH ROW EXECUTE FUNCTION audit_log_refuse_change()
  `;
  await sql`DROP TRIGGER IF EXISTS audit_log_no_truncate ON audit_log`;
  await sql`
    CREATE TRIGGER audit_log_no_truncate
    BEFORE TRUNCATE ON audit_log
    FOR EACH STATEMENT EXECUTE FUNCTION audit_log_refuse_change()
  `;
}
