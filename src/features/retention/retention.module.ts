import type { Sql } from "postgres";
import { runRetentionPass } from "./application/purge";
import { RETENTION_INTERVAL_MS, RETENTION_RULES } from "./domain/rules";
import { createPostgresRetentionStore } from "./infra/postgres-retention-store";
import { startRetentionSweeper } from "./infra/sweeper";

export function startRetention(sql: Sql): () => void {
  const store = createPostgresRetentionStore(sql);
  return startRetentionSweeper(() => runRetentionPass(store, RETENTION_RULES), RETENTION_INTERVAL_MS);
}
