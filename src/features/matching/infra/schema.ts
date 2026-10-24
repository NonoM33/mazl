import type { Sql } from "postgres";
import { DEFAULT_PARAMS } from "../domain/params";

// postgres.js types a transaction handle as non-callable; it is the same tag.
export function inTransaction<T>(sql: Sql, work: (tx: Sql) => Promise<T>): Promise<T> {
  return sql.begin((transaction) => work(transaction as unknown as Sql)) as Promise<T>;
}

const INITIAL_NOTE = "Paramètres initiaux";
const INITIAL_AUTHOR = "system";
// Serialises concurrent first starts of several instances.
const SCHEMA_LOCK = 724_001;

// Called at start-up, idempotent. Version 1 holds the default parameters and
// is the active one until staff publish another.
export async function ensureMatchingSchema(sql: Sql): Promise<void> {
  await inTransaction(sql, async (tx) => {
    await tx`SELECT pg_advisory_xact_lock(${SCHEMA_LOCK})`;
    await tx`
      CREATE TABLE IF NOT EXISTS matching_param_versions (
        id SERIAL PRIMARY KEY,
        params JSONB NOT NULL,
        note TEXT NOT NULL,
        author TEXT NOT NULL,
        parent_id INTEGER REFERENCES matching_param_versions(id),
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `;
    await tx`
      CREATE TABLE IF NOT EXISTS matching_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        active_version_id INTEGER NOT NULL REFERENCES matching_param_versions(id),
        activated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        activated_by TEXT NOT NULL,
        ab_variant_id INTEGER REFERENCES matching_param_versions(id),
        ab_share_percent INTEGER CHECK (ab_share_percent BETWEEN 1 AND 50),
        ab_started_at TIMESTAMPTZ,
        ab_started_by TEXT
      )
    `;
    await tx`
      CREATE TABLE IF NOT EXISTS matching_activations (
        id SERIAL PRIMARY KEY,
        version_id INTEGER NOT NULL REFERENCES matching_param_versions(id),
        activated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        activated_by TEXT NOT NULL,
        note TEXT NOT NULL
      )
    `;
    await tx`CREATE INDEX IF NOT EXISTS idx_matching_activations_version ON matching_activations (version_id, activated_at DESC)`;
    await seedInitialVersion(tx);
  });
}

async function seedInitialVersion(tx: Sql): Promise<void> {
  const [existing] = await tx<{ n: number }[]>`SELECT count(*)::int AS n FROM matching_param_versions`;
  if ((existing?.n ?? 0) > 0) return;
  const [created] = await tx<{ id: number }[]>`
    INSERT INTO matching_param_versions (params, note, author)
    VALUES (${tx.json(JSON.parse(JSON.stringify(DEFAULT_PARAMS)))}, ${INITIAL_NOTE}, ${INITIAL_AUTHOR})
    RETURNING id
  `;
  if (created === undefined) throw new Error("Initial matching version not created");
  const inserted = await tx`
    INSERT INTO matching_state (id, active_version_id, activated_by) VALUES (1, ${created.id}, ${INITIAL_AUTHOR})
    ON CONFLICT (id) DO NOTHING
  `;
  if (inserted.count > 0) {
    await tx`INSERT INTO matching_activations (version_id, activated_by, note) VALUES (${created.id}, ${INITIAL_AUTHOR}, ${INITIAL_NOTE})`;
  }
}
