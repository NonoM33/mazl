import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { registerAuditRoutes } from "../../src/features/audit/presentation/audit.routes";
import type { AuditFilter } from "../../src/features/audit/application/ports";
import { MemoryAuditLog } from "./support/memory-audit-log";
import { headerGuard } from "./support/staff-app";

async function setup() {
  const audit = new MemoryAuditLog();
  for (let i = 0; i < 7; i += 1) {
    await audit.record({
      actor: i % 2 === 0 ? "even@example.com" : "odd@example.com",
      action: i < 3 ? "member.read" : "report.decide",
      targetType: i < 3 ? "member" : "report",
      targetId: String(i),
      justification: i === 0 ? "plainte 12" : undefined,
    });
  }
  const app = new Hono();
  registerAuditRoutes(app, { audit, requirePermission: headerGuard });
  const get = (path: string, role = "analyst") => app.request(path, { headers: role ? { "x-test-role": role } : {} });
  return { audit, get };
}

describe("GET /api/backoffice/audit", () => {
  test("lists newest first with an envelope and the DTO shape", async () => {
    const { get } = await setup();
    const res = await get("/api/backoffice/audit");
    expect(res.status).toBe(200);
    const body = (await res.json()) as { success: boolean; data: { total: number; entries: Record<string, unknown>[] } };
    expect(body.success).toBe(true);
    expect(body.data.total).toBe(7);
    expect(body.data.entries.map((e) => e.id)).toEqual([7, 6, 5, 4, 3, 2, 1]);
    const oldest = body.data.entries[6] as Record<string, unknown>;
    expect(oldest.justification).toBe("plainte 12");
    expect(oldest.details).toBeNull();
    expect(Object.keys(oldest).sort()).toEqual(
      ["action", "actor", "createdAt", "details", "hash", "id", "justification", "targetId", "targetType"].sort(),
    );
  });

  test("filters and paginates", async () => {
    const { get } = await setup();
    const res = await get("/api/backoffice/audit?targetType=report&actor=even@example.com&limit=1&offset=1");
    const body = (await res.json()) as { data: { total: number; entries: { targetId: string }[] } };
    expect(body.data.total).toBe(2);
    expect(body.data.entries.map((e) => e.targetId)).toEqual(["4"]);
  });

  test("passes the validated filter to the log", async () => {
    const seen: AuditFilter[] = [];
    const app = new Hono();
    registerAuditRoutes(app, {
      audit: {
        record: async () => {
          throw new Error("unused");
        },
        list: async (f) => {
          seen.push(f);
          return { entries: [], total: 0 };
        },
        verify: async () => ({ ok: true, entries: 0, headHash: "0".repeat(64) }),
      },
      requirePermission: headerGuard,
    });
    await app.request("/api/backoffice/audit", { headers: { "x-test-role": "analyst" } });
    expect(seen[0]).toEqual({ limit: 50, offset: 0 });
  });

  for (const query of ["limit=0", "limit=201", "limit=abc", "offset=-1", "offset=1.5", "targetType=nope"]) {
    test(`rejects ?${query} with 400`, async () => {
      const { get } = await setup();
      const res = await get(`/api/backoffice/audit?${query}`);
      expect(res.status).toBe(400);
      expect(await res.json()).toMatchObject({ success: false, error: "invalid_request" });
    });
  }

  test("accepts the bounds 1 and 200", async () => {
    const { get } = await setup();
    expect((await get("/api/backoffice/audit?limit=1")).status).toBe(200);
    expect((await get("/api/backoffice/audit?limit=200&offset=0")).status).toBe(200);
  });

  test("the guard decides: 401 without credentials, 403 without the permission", async () => {
    const { get } = await setup();
    expect((await get("/api/backoffice/audit", "")).status).toBe(401);
    expect((await get("/api/backoffice/audit", "none")).status).toBe(403);
  });
});

describe("GET /api/backoffice/audit/verify", () => {
  test("reports an intact chain", async () => {
    const { get, audit } = await setup();
    const body = (await (await get("/api/backoffice/audit/verify")).json()) as { success: boolean; data: unknown };
    expect(body).toEqual({ success: true, data: { ok: true, entries: 7, headHash: audit.entries[6]?.hash } });
  });

  test("reports the first broken entry", async () => {
    const { get, audit } = await setup();
    const victim = audit.entries[3];
    if (!victim) throw new Error("missing entry");
    audit.entries[3] = { ...victim, action: "forged" };
    const body = (await (await get("/api/backoffice/audit/verify")).json()) as { data: unknown };
    expect(body.data).toMatchObject({ ok: false, brokenAtId: 4 });
  });

  test("is behind the permission too", async () => {
    const { get } = await setup();
    expect((await get("/api/backoffice/audit/verify", "")).status).toBe(401);
    expect((await get("/api/backoffice/audit/verify", "none")).status).toBe(403);
  });
});
