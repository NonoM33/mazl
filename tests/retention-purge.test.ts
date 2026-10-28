import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import postgres from "postgres";
import { runRetentionPass } from "../src/features/retention/application/purge";
import { RETENTION_RULES } from "../src/features/retention/domain/rules";
import { createPostgresRetentionStore } from "../src/features/retention/infra/postgres-retention-store";
import { bootServerSchema, createScratchDatabase } from "./support/scratch-database";

// Runs on a database of its own (schema made by the real server). Skipped without
// TEST_DATABASE_URL. Durations below are written from the privacy policy brief:
// location_updates 30 days, face sessions 12 months, moderation logs 12 months,
// banned document fingerprints 5 years.
const scratch = process.env.TEST_DATABASE_URL === undefined ? null : await createScratchDatabase();
if (scratch !== null) await bootServerSchema(scratch.url, "test");
const url = scratch?.url;

describe.skipIf(url === undefined)("retention purge on Postgres", () => {
  const sql = postgres(url ?? "postgres://unused", { onnotice: () => undefined });
  const store = createPostgresRetentionStore(sql);
  let userId = 0;
  const pass = () => runRetentionPass(store, RETENTION_RULES);

  beforeAll(async () => {
    const [user] = await sql<{ id: number }[]>`
      INSERT INTO users (email, name, provider, provider_id) VALUES ('retention@example.test', 'Retention', 'test', 'retention-1') RETURNING id`;
    userId = user!.id;
  });
  afterAll(async () => {
    await sql.end({ timeout: 2 });
    await scratch?.drop();
  });

  const count = async (table: string): Promise<number> => Number((await sql`SELECT COUNT(*) AS n FROM ${sql(table)}`)[0]!.n);

  test("location_updates: 30 days", async () => {
    await sql`INSERT INTO location_updates (user_id, created_at) VALUES (${userId}, now() - interval '30 days 1 hour'), (${userId}, now() - interval '29 days 23 hours')`;
    const report = await pass();
    expect(report.location_updates).toBe(1);
    expect(await count("location_updates")).toBe(1);
  });

  test("moderation_logs: 12 months", async () => {
    await sql`
      INSERT INTO moderation_logs (admin_email, action, target_type, created_at)
      VALUES ('a@example.test', 'old', 'user', now() - interval '12 months 1 day'), ('a@example.test', 'recent', 'user', now() - interval '11 months 29 days')`;
    const report = await pass();
    expect(report.moderation_logs).toBe(1);
    const rows = await sql<{ action: string }[]>`SELECT action FROM moderation_logs`;
    expect(rows.map((r) => r.action)).toEqual(["recent"]);
  });

  test("banned_document_fingerprints: 5 years", async () => {
    await sql`
      INSERT INTO banned_document_fingerprints (doc_fingerprint, banned_at)
      VALUES (${"a".repeat(64)}, now() - interval '5 years 1 day'), (${"b".repeat(64)}, now() - interval '4 years 364 days')`;
    const report = await pass();
    expect(report.banned_document_fingerprints).toBe(1);
    const rows = await sql<{ doc_fingerprint: string }[]>`SELECT doc_fingerprint FROM banned_document_fingerprints`;
    expect(rows.map((r) => r.doc_fingerprint)).toEqual(["b".repeat(64)]);
  });

  test("face_verification_sessions: 12 months, but an unexpired session stays", async () => {
    const session = (id: string, createdAgo: string, expiresIn: string) => sql`
      INSERT INTO face_verification_sessions (id, user_id, purpose, challenges, created_at, expires_at)
      VALUES (${id}, ${userId}, 'photo', '[]'::jsonb, now() - ${createdAgo}::interval, now() + ${expiresIn}::interval)`;
    await session("00000000-0000-4000-8000-000000000001", "12 months 1 day", "-12 months");   // old and expired: deleted
    await session("00000000-0000-4000-8000-000000000002", "11 months 29 days", "-11 months"); // recent: kept
    await session("00000000-0000-4000-8000-000000000003", "12 months 1 day", "1 hour");       // old but not expired: kept
    const report = await pass();
    expect(report.face_verification_sessions).toBe(1);
    const rows = await sql<{ id: string }[]>`SELECT id FROM face_verification_sessions ORDER BY id`;
    expect(rows.map((r) => r.id)).toEqual(["00000000-0000-4000-8000-000000000002", "00000000-0000-4000-8000-000000000003"]);
  });

  test("a second pass deletes nothing", async () => {
    const report = await pass();
    expect(Object.values(report).reduce((a, b) => a + b, 0)).toBe(0);
  });
});
