import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import postgres, { type Sql } from "postgres";
import { PgAuditLog } from "../src/features/audit/infra/pg-audit-log";
import { ensureAuditSchema } from "../src/features/audit/infra/schema";
import { GENESIS_HASH } from "../src/features/audit/domain/chain";
import { PgStaffRepository } from "../src/features/staff/infra/pg-staff-repository";
import { ensureStaffSchema } from "../src/features/staff/infra/schema";
import { StaffDirectory } from "../src/features/staff/application/staff-directory";

// Integration against a throwaway Postgres (TEST_DATABASE_URL). Each run works
// in its own schema, dropped at the end, so runs never see each other's rows
// and the append-only table needs no cleaning.
const url = process.env.TEST_DATABASE_URL;
const suite = url ? describe : describe.skip;
if (!url) console.warn("staff-audit-pg: TEST_DATABASE_URL is not set, the Postgres integration tests are SKIPPED");

suite("staff and audit on Postgres", () => {
  const schema = `t_staff_audit_${Date.now()}_${Math.floor(Math.random() * 1e6)}`;
  let admin: Sql;
  let sql: Sql;

  beforeAll(async () => {
    admin = postgres(url as string, { max: 1, onnotice: () => {} });
    await admin.unsafe(`CREATE SCHEMA ${schema}`);
    sql = postgres(url as string, { max: 20, onnotice: () => {}, connection: { search_path: schema } });
    await ensureAuditSchema(sql);
    await ensureStaffSchema(sql);
  });

  afterAll(async () => {
    await sql?.end();
    if (admin) {
      await admin.unsafe(`DROP SCHEMA IF EXISTS ${schema} CASCADE`);
      await admin.end();
    }
  });

  const entry = (n: number) => ({ actor: "a@example.com", action: "member.read", targetType: "member" as const, targetId: String(n), details: { n } });

  describe("schema", () => {
    test("is idempotent: two more calls change nothing and keep the rows", async () => {
      const audit = new PgAuditLog(sql);
      await audit.record(entry(0));
      await ensureAuditSchema(sql);
      await ensureAuditSchema(sql);
      await ensureStaffSchema(sql);
      await ensureStaffSchema(sql);
      expect((await audit.list({ limit: 10, offset: 0 })).total).toBeGreaterThanOrEqual(1);
    });
  });

  describe("audit_log is append-only", () => {
    test("UPDATE is refused by the trigger", async () => {
      await new PgAuditLog(sql).record(entry(1));
      await expect(sql`UPDATE audit_log SET actor = 'evil'`).rejects.toThrow(/append-only/);
      await expect(sql`UPDATE audit_log SET hash = 'x'`).rejects.toThrow(/append-only/);
    });

    test("DELETE is refused by the trigger", async () => {
      await expect(sql`DELETE FROM audit_log`).rejects.toThrow(/append-only/);
      await expect(sql`DELETE FROM audit_log WHERE id = 1`).rejects.toThrow(/append-only/);
    });

    test("TRUNCATE is refused by the trigger", async () => {
      await expect(sql`TRUNCATE audit_log`).rejects.toThrow(/append-only/);
    });
  });

  describe("chain", () => {
    test("50 concurrent records give one intact chain", async () => {
      const audit = new PgAuditLog(sql);
      const before = (await audit.verify()).entries;
      const written = await Promise.all(Array.from({ length: 50 }, (_, i) => audit.record(entry(i))));
      expect(new Set(written.map((w) => w.id)).size).toBe(50);
      const result = await audit.verify();
      expect(result.ok).toBe(true);
      expect(result.entries).toBe(before + 50);
      // Each entry chains on the one before it, in id order.
      const all = (await audit.list({ limit: 200, offset: 0 })).entries.toReversed();
      expect(all[0]?.previousHash).toBe(GENESIS_HASH);
      for (let i = 1; i < all.length; i += 1) expect(all[i]?.previousHash).toBe(all[i - 1]?.hash);
    });

    test("created_at never decreases along the chain", async () => {
      const all = (await new PgAuditLog(sql).list({ limit: 200, offset: 0 })).entries.toReversed();
      for (let i = 1; i < all.length; i += 1) {
        expect(Date.parse(all[i]?.createdAt ?? "")).toBeGreaterThanOrEqual(Date.parse(all[i - 1]?.createdAt ?? ""));
      }
    });

    test("details and justification survive the round trip and are hashed as stored", async () => {
      const audit = new PgAuditLog(sql);
      const written = await audit.record({
        actor: "a@example.com",
        action: "conversation.read",
        targetType: "conversation",
        targetId: "77",
        justification: "Signalement 12, motif légitime",
        details: { zeta: [1, { b: 2, a: 1 }], alpha: "é", flag: true, nothing: null },
      });
      const listed = (await audit.list({ targetType: "conversation", targetId: "77", limit: 5, offset: 0 })).entries[0];
      expect(listed).toEqual(written);
      expect((await audit.verify()).ok).toBe(true);
    });

    test("forbidden detail keys are refused before anything is written", async () => {
      const audit = new PgAuditLog(sql);
      const before = (await audit.list({ limit: 1, offset: 0 })).total;
      await expect(audit.record({ ...entry(1), details: { message: "bonjour" } })).rejects.toThrow(/message/);
      expect((await audit.list({ limit: 1, offset: 0 })).total).toBe(before);
    });

    test("filters and pagination", async () => {
      const audit = new PgAuditLog(sql);
      await audit.record({ actor: "filter@example.com", action: "report.decide", targetType: "report", targetId: "r1" });
      const page = await audit.list({ actor: "filter@example.com", action: "report.decide", targetType: "report", targetId: "r1", limit: 1, offset: 0 });
      expect(page.total).toBe(1);
      expect(page.entries[0]?.targetId).toBe("r1");
      expect((await audit.list({ actor: "filter@example.com", limit: 1, offset: 1 })).entries).toHaveLength(0);
    });

    test("a hand-inserted row with a wrong hash is detected and located", async () => {
      // A separate schema: this chain is deliberately broken.
      const broken = `${schema}_broken`;
      await admin.unsafe(`CREATE SCHEMA ${broken}`);
      const other = postgres(url as string, { max: 2, onnotice: () => {}, connection: { search_path: broken } });
      try {
        await ensureAuditSchema(other);
        const audit = new PgAuditLog(other);
        await audit.record(entry(1));
        const second = await audit.record(entry(2));
        // INSERT is allowed (append-only); a forger can add a line that does not chain.
        const forged = await other<{ id: string }[]>`
          INSERT INTO audit_log (actor, action, target_type, target_id, previous_hash, hash)
          VALUES ('forger@example.com', 'staff.update', 'staff', 'x', ${second.hash}, ${"ab".repeat(32)})
          RETURNING id
        `;
        await audit.record(entry(3));
        const result = await audit.verify();
        expect(result).toMatchObject({ ok: false, brokenAtId: Number(forged[0]?.id), entries: 3 });
      } finally {
        await other.end();
        await admin.unsafe(`DROP SCHEMA ${broken} CASCADE`);
      }
    });

    test("a row that skips the chain (wrong previous_hash) is detected", async () => {
      const broken = `${schema}_skip`;
      await admin.unsafe(`CREATE SCHEMA ${broken}`);
      const other = postgres(url as string, { max: 2, onnotice: () => {}, connection: { search_path: broken } });
      try {
        await ensureAuditSchema(other);
        const audit = new PgAuditLog(other);
        await audit.record(entry(1));
        const forged = await other<{ id: string }[]>`
          INSERT INTO audit_log (actor, action, target_type, previous_hash, hash)
          VALUES ('forger@example.com', 'x', 'system', ${GENESIS_HASH}, ${"cd".repeat(32)}) RETURNING id
        `;
        expect(await audit.verify()).toMatchObject({ ok: false, brokenAtId: Number(forged[0]?.id) });
      } finally {
        await other.end();
        await admin.unsafe(`DROP SCHEMA ${broken} CASCADE`);
      }
    });
  });

  describe("staff_members", () => {
    test("CRUD: insert, find, duplicate, update, list", async () => {
      const repo = new PgStaffRepository(sql);
      const created = await repo.insert({ email: "crud@example.com", role: "moderator", createdBy: "owner@example.com" });
      expect(created).toMatchObject({ email: "crud@example.com", role: "moderator", active: true, mfaEnrolledAt: null, createdBy: "owner@example.com", lastSeenAt: null });
      expect(await repo.insert({ email: "crud@example.com", role: "admin", createdBy: "x" })).toBeNull();
      expect(await repo.find("crud@example.com")).toEqual(created);
      expect(await repo.find("ghost@example.com")).toBeNull();

      expect(await repo.update("crud@example.com", { role: "analyst" })).toMatchObject({ role: "analyst", active: true });
      expect(await repo.update("crud@example.com", { active: false })).toMatchObject({ role: "analyst", active: false });
      expect(await repo.update("crud@example.com", { role: "support", active: true })).toMatchObject({ role: "support", active: true });
      expect(await repo.update("ghost@example.com", { active: false })).toBeNull();
      expect((await repo.list()).map((r) => r.email)).toContain("crud@example.com");
    });

    test("the table refuses an unknown role and a non-normalised e-mail", async () => {
      await expect(sql`INSERT INTO staff_members (email, role) VALUES ('bad@example.com', 'root')`).rejects.toThrow();
      await expect(sql`INSERT INTO staff_members (email, role) VALUES ('Bad@Example.com', 'admin')`).rejects.toThrow();
    });

    test("touch sets last_seen_at; ensureRow does not overwrite", async () => {
      const repo = new PgStaffRepository(sql);
      await repo.ensureRow("env@example.com", "super_admin", "system");
      await repo.update("env@example.com", { active: false });
      await repo.ensureRow("env@example.com", "super_admin", "system");
      expect((await repo.find("env@example.com"))?.active).toBe(false);
      await repo.touch("env@example.com");
      expect((await repo.find("env@example.com"))?.lastSeenAt).not.toBeNull();
    });

    test("directory resolves an inactive member to null and an environment address to super_admin", async () => {
      const repo = new PgStaffRepository(sql);
      const directory = new StaffDirectory({ repository: repo, audit: new PgAuditLog(sql), environmentAdmins: ["envroot@example.com"] });
      await directory.create("envroot@example.com", { email: "dir@example.com", role: "verifier" });
      expect(await directory.resolve("DIR@example.com")).toMatchObject({ role: "verifier", fromEnvironment: false });
      await directory.update("envroot@example.com", "dir@example.com", { active: false });
      expect(await directory.resolve("dir@example.com")).toBeNull();
      expect(await directory.resolve("envroot@example.com")).toMatchObject({ role: "super_admin", fromEnvironment: true });
      const trail = (await new PgAuditLog(sql).list({ targetType: "staff", targetId: "dir@example.com", limit: 10, offset: 0 })).entries;
      expect(trail.map((e) => e.action).toReversed()).toEqual(["staff.create", "staff.update"]);
    });
  });

  describe("TOTP persistence", () => {
    test("secret is stored as bytes, confirmed once, and cannot be replaced afterwards", async () => {
      const repo = new PgStaffRepository(sql);
      await repo.insert({ email: "totp@example.com", role: "admin", createdBy: "x" });
      expect(await repo.totpState("totp@example.com")).toEqual({ sealedSecret: null, enrolled: false });
      expect(await repo.totpState("ghost@example.com")).toBeNull();

      const sealed = Uint8Array.from([1, 2, 3, 250, 251, 0, 7]);
      expect(await repo.storeUnconfirmedSecret("totp@example.com", sealed)).toBe(true);
      const stored = await repo.totpState("totp@example.com");
      expect([...(stored?.sealedSecret ?? [])]).toEqual([...sealed]);
      expect(stored?.enrolled).toBe(false);

      await repo.confirmEnrollment("totp@example.com");
      expect((await repo.totpState("totp@example.com"))?.enrolled).toBe(true);
      expect((await repo.find("totp@example.com"))?.mfaEnrolledAt).not.toBeNull();
      expect(await repo.storeUnconfirmedSecret("totp@example.com", Uint8Array.from([9, 9]))).toBe(false);
      expect([...((await repo.totpState("totp@example.com"))?.sealedSecret ?? [])]).toEqual([...sealed]);
    });

    test("confirming without a secret enrols nobody", async () => {
      const repo = new PgStaffRepository(sql);
      await repo.insert({ email: "nosecret@example.com", role: "admin", createdBy: "x" });
      await repo.confirmEnrollment("nosecret@example.com");
      expect((await repo.find("nosecret@example.com"))?.mfaEnrolledAt).toBeNull();
    });

    test("anti-replay persists: a step is claimed once, older or equal steps never", async () => {
      const repo = new PgStaffRepository(sql);
      await repo.insert({ email: "replay@example.com", role: "admin", createdBy: "x" });
      expect(await repo.claimTotpStep("replay@example.com", 100)).toBe(true);
      expect(await repo.claimTotpStep("replay@example.com", 100)).toBe(false);
      expect(await repo.claimTotpStep("replay@example.com", 99)).toBe(false);
      expect(await repo.claimTotpStep("replay@example.com", 101)).toBe(true);
      // A second repository over the same database (a restart) sees the memory.
      expect(await new PgStaffRepository(sql).claimTotpStep("replay@example.com", 101)).toBe(false);
      expect(await repo.claimTotpStep("ghost@example.com", 1)).toBe(false);
    });

    test("concurrent claims of the same step: exactly one wins", async () => {
      const repo = new PgStaffRepository(sql);
      await repo.insert({ email: "race@example.com", role: "admin", createdBy: "x" });
      const results = await Promise.all(Array.from({ length: 10 }, () => repo.claimTotpStep("race@example.com", 5000)));
      expect(results.filter(Boolean)).toHaveLength(1);
    });
  });
  describe("whole feature on Postgres (real secret box, real guard)", () => {
    test("password, enrolment, challenge, audit routes and verify", async () => {
      const { Hono } = await import("hono");
      const { createAuditModule } = await import("../src/features/audit/audit.module");
      const { createStaffModule } = await import("../src/features/staff/staff.module");
      const { totpAt } = await import("../src/features/staff/domain/totp");
      const { base32Decode } = await import("../src/features/staff/domain/base32");

      const owner = "renaudlemagicien@gmail.com";
      const audit = createAuditModule({ sql });
      const staff = createStaffModule({
        sql,
        env: { ADMIN_EMAIL: owner, ADMIN_PASSWORD: "integration-password", NODE_ENV: "test", JWT_SECRET: "test-secret-l2" },
        google: { verifyIdToken: async () => null, verifyAccessToken: async () => null },
        audit: audit.audit,
      });
      await audit.ensureSchema();
      await staff.ensureSchema();
      const app = new Hono();
      staff.registerRoutes(app);
      audit.registerRoutes(app, staff.requirePermission);

      type Reply = { success: boolean; data?: { token?: string; challenge?: string; secret?: string; kind?: string; entries?: { action: string }[]; ok?: boolean } };
      const call = async (path: string, init: { method?: string; body?: unknown; token?: string } = {}) => {
        const res = await app.request(path, {
          method: init.method ?? "GET",
          headers: { "content-type": "application/json", "x-forwarded-for": "203.0.113.50", ...(init.token ? { authorization: `Bearer ${init.token}` } : {}) },
          ...(init.body === undefined ? {} : { body: JSON.stringify(init.body) }),
        });
        return { status: res.status, body: (await res.json()) as Reply };
      };
      const password = { email: owner, password: "integration-password" };

      const first = await call("/api/backoffice/auth/password", { method: "POST", body: password });
      expect(first.body.data?.kind).toBe("session");
      const enrolled = await call("/api/backoffice/mfa/enroll", { method: "POST", token: first.body.data?.token });
      const secret = enrolled.body.data?.secret ?? "";
      const key = base32Decode(secret);
      const confirmed = await call("/api/backoffice/mfa/confirm", { method: "POST", token: first.body.data?.token, body: { code: totpAt(key, Date.now() / 1000) } });
      expect(confirmed.status).toBe(200);

      // The secret really is sealed at rest.
      const raw = await sql<{ totp_secret: Uint8Array }[]>`SELECT totp_secret FROM staff_members WHERE email = ${owner}`;
      expect(Buffer.from(raw[0]?.totp_secret ?? []).includes(Buffer.from(key))).toBe(false);

      const challenge = await call("/api/backoffice/auth/password", { method: "POST", body: password });
      expect(challenge.body.data?.kind).toBe("mfa_challenge");
      // Same 30 s step as the confirmation: replay refused. The next step's code passes.
      const replay = await call("/api/backoffice/auth/mfa", { method: "POST", body: { challenge: challenge.body.data?.challenge, code: totpAt(key, Date.now() / 1000) } });
      expect(replay.status).toBe(401);
      const next = await call("/api/backoffice/auth/mfa", { method: "POST", body: { challenge: challenge.body.data?.challenge, code: totpAt(key, Date.now() / 1000 + 30) } });
      // Accepted only if the clock tolerance window reaches the next step (it does: +-1 step).
      expect(next.status).toBe(200);

      const list = await call("/api/backoffice/audit?limit=200", { token: next.body.data?.token });
      expect(list.status).toBe(200);
      const actions = (list.body.data?.entries ?? []).map((e) => e.action);
      expect(actions).toEqual(expect.arrayContaining(["auth.success", "mfa.enrolled", "mfa.failure"]));
      const verified = await call("/api/backoffice/audit/verify", { token: next.body.data?.token });
      expect(verified.body.data?.ok).toBe(true);
    });
  });
});
