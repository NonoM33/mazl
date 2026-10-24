import { beforeEach, describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { MatchingTuning } from "../../src/features/matching/application/tuning";
import { DEFAULT_PARAMS } from "../../src/features/matching/domain/params";
import { setParam } from "../../src/features/matching/domain/validate-params";
import { registerMatchingAdminRoutes } from "../../src/features/matching/presentation/matching-admin.routes";
import type { StaffVariables } from "../../src/features/staff/application/ports";
import { FakeAudit, fakeRequirePermission, InMemoryParams } from "./support/matching-fakes";

const BASE = "/api/backoffice/matching";
const guard = fakeRequirePermission({ reader: ["matching.read"], tuner: ["matching.read", "matching.tune"] });

let params: InMemoryParams;
let audit: FakeAudit;
let app: Hono<{ Variables: StaffVariables }>;

beforeEach(() => {
  params = new InMemoryParams();
  audit = new FakeAudit();
  app = new Hono<{ Variables: StaffVariables }>();
  registerMatchingAdminRoutes(app, { requirePermission: guard, audit, tuning: new MatchingTuning({ params, audit }) });
});

async function call(method: string, path: string, role: string | null, body?: unknown): Promise<{ status: number; json: any }> {
  const headers: Record<string, string> = { "content-type": "application/json" };
  if (role !== null) headers["x-role"] = role;
  const res = await app.request(`${BASE}${path}`, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  return { status: res.status, json: await res.json() };
}

describe("authentication and permissions", () => {
  const writes: Array<[string, string, unknown]> = [
    ["POST", "/versions", { params: DEFAULT_PARAMS, note: "une note" }],
    ["POST", "/versions/1/activate", { note: "une note" }],
    ["POST", "/ab-test", { variantId: 2, sharePercent: 10 }],
    ["DELETE", "/ab-test", undefined],
  ];
  const reads: Array<[string, string, unknown]> = [
    ["GET", "", undefined],
    ["GET", "/versions", undefined],
    ["POST", "/preview", { params: DEFAULT_PARAMS, seed: 1, viewer: 0 }],
  ];

  test("no staff session: 401 everywhere", async () => {
    for (const [method, path, body] of [...reads, ...writes]) expect((await call(method, path, null, body)).status).toBe(401);
  });

  test("a reader reads and previews but cannot tune: 403", async () => {
    for (const [method, path, body] of reads) expect((await call(method, path, "reader", body)).status).toBe(200);
    for (const [method, path, body] of writes) expect((await call(method, path, "reader", body)).status).toBe(403);
    expect(params.versions).toHaveLength(1);
    expect(audit.entries).toHaveLength(0);
  });
});

describe("reading", () => {
  test("GET / returns the active version, no A/B, specs and defaults in the envelope", async () => {
    const { status, json } = await call("GET", "", "reader");
    expect(status).toBe(200);
    expect(json.success).toBe(true);
    expect(json.data.active.id).toBe(1);
    expect(json.data.abTest).toBeNull();
    expect(json.data.specs.length).toBeGreaterThan(10);
    expect(json.data.defaults).toEqual(DEFAULT_PARAMS);
  });

  test("GET /versions pages the list", async () => {
    await call("POST", "/versions", "tuner", { params: DEFAULT_PARAMS, note: "deuxième" });
    const { json } = await call("GET", "/versions?limit=1&offset=0", "reader");
    expect(json.data.total).toBe(2);
    expect(json.data.versions.map((v: { id: number }) => v.id)).toEqual([2]);
  });
});

describe("publishing", () => {
  test("out-of-bounds parameters: 400 invalid_params listing every error", async () => {
    const bad = setParam(setParam(DEFAULT_PARAMS, "boost.factor", 99), "freshness.floor", 5);
    const { status, json } = await call("POST", "/versions", "tuner", { params: bad, note: "trop haut" });
    expect(status).toBe(400);
    expect(json.success).toBe(false);
    expect(json.error).toBe("invalid_params");
    expect(json.message).toContain("boost.factor");
    expect(json.message).toContain("freshness.floor");
    expect(json.message).toContain(" ; ");
    expect(params.versions).toHaveLength(1);
  });

  test("a short note or a missing body: 400 invalid_body", async () => {
    expect((await call("POST", "/versions", "tuner", { params: DEFAULT_PARAMS, note: "x" })).json.error).toBe("invalid_body");
    expect((await call("POST", "/versions", "tuner", {})).json.error).toBe("invalid_body");
  });

  test("create with activate publishes and audits under the staff e-mail", async () => {
    const { status, json } = await call("POST", "/versions", "tuner", { params: DEFAULT_PARAMS, note: "publication", activate: true });
    expect(status).toBe(201);
    expect(json.data.id).toBe(2);
    expect(params.activeId).toBe(2);
    expect(audit.entries.map((e) => [e.actor, e.action])).toEqual([
      ["tuner@example.com", "matching.version.create"],
      ["tuner@example.com", "matching.activate"],
    ]);
  });

  test("activating an older version (rollback) audits previous and new ids", async () => {
    await call("POST", "/versions", "tuner", { params: DEFAULT_PARAMS, note: "version deux", activate: true });
    const { status, json } = await call("POST", "/versions/1/activate", "tuner", { note: "retour arrière" });
    expect(status).toBe(200);
    expect(json.data.active.id).toBe(1);
    expect(audit.entries.at(-1)).toMatchObject({ action: "matching.activate", details: { versionId: 1, previousVersionId: 2 } });
  });

  test("unknown or malformed version id: 404", async () => {
    expect((await call("POST", "/versions/77/activate", "tuner", { note: "inconnue" })).status).toBe(404);
    expect((await call("POST", "/versions/abc/activate", "tuner", { note: "invalide" })).status).toBe(404);
  });
});

describe("A/B test", () => {
  test("start, then stop", async () => {
    await call("POST", "/versions", "tuner", { params: DEFAULT_PARAMS, note: "variante" });
    const started = await call("POST", "/ab-test", "tuner", { variantId: 2, sharePercent: 25 });
    expect(started.status).toBe(200);
    expect(started.json.data.abTest).toMatchObject({ sharePercent: 25, variant: { id: 2 } });
    const stopped = await call("DELETE", "/ab-test", "tuner");
    expect(stopped.json.data.abTest).toBeNull();
    expect(audit.entries.map((e) => e.action)).toEqual(["matching.version.create", "matching.ab.start", "matching.ab.stop"]);
  });

  test("the active version as variant: 409", async () => {
    const { status, json } = await call("POST", "/ab-test", "tuner", { variantId: 1, sharePercent: 10 });
    expect(status).toBe(409);
    expect(json.error).toBe("variant_is_active");
  });

  test("a share above 50 or below 1: 400", async () => {
    await call("POST", "/versions", "tuner", { params: DEFAULT_PARAMS, note: "variante" });
    expect((await call("POST", "/ab-test", "tuner", { variantId: 2, sharePercent: 51 })).status).toBe(400);
    expect((await call("POST", "/ab-test", "tuner", { variantId: 2, sharePercent: 0 })).status).toBe(400);
  });

  test("unknown variant: 404; stop without test: 404", async () => {
    expect((await call("POST", "/ab-test", "tuner", { variantId: 9, sharePercent: 10 })).status).toBe(404);
    expect((await call("DELETE", "/ab-test", "tuner")).status).toBe(404);
  });
});

describe("preview", () => {
  const request = { params: DEFAULT_PARAMS, seed: 5, viewer: 2, size: 60 };

  test("deterministic and complete, and the member repository is never read", async () => {
    const reads = params.stateReads;
    const first = await call("POST", "/preview", "reader", request);
    const second = await call("POST", "/preview", "reader", request);
    expect(first.status).toBe(200);
    expect(second.json).toEqual(first.json);
    expect(first.json.data.population).toHaveLength(60);
    expect(Object.keys(first.json.data.labels)).toHaveLength(60);
    expect(first.json.data.result.ranked.length).toBeGreaterThan(0);
    expect(first.json.data.compare).toBeNull();
    expect(params.stateReads).toBe(reads);
  });

  test("comparison with a second parameter set", async () => {
    const { json } = await call("POST", "/preview", "reader", { ...request, compareWith: setParam(DEFAULT_PARAMS, "boost.factor", 1.5) });
    expect(json.data.compare.ranked.length).toBeGreaterThan(0);
  });

  test("invalid params, size out of range, bad viewer index: 400", async () => {
    expect((await call("POST", "/preview", "reader", { ...request, params: setParam(DEFAULT_PARAMS, "boost.factor", 99) })).json.error).toBe("invalid_params");
    expect((await call("POST", "/preview", "reader", { ...request, size: 10 })).json.error).toBe("invalid_preview");
    expect((await call("POST", "/preview", "reader", { ...request, viewer: 500 })).json.error).toBe("invalid_preview");
  });

  test("a custom viewer is validated", async () => {
    const bad = await call("POST", "/preview", "reader", { ...request, viewer: { userId: 1 } });
    expect(bad.json.error).toBe("invalid_body");
  });
});
