import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import { createBoostTimingService } from "../../src/features/boost-timing/application/boost-timing-service";
import { createActivityRecorder } from "../../src/features/boost-timing/application/activity-recorder";
import { registerBoostTimingRoutes } from "../../src/features/boost-timing/presentation/boost-timing.routes";
import { PremiumSettingsService } from "../../src/features/premium-settings/application/premium-settings-service";
import { registerPremiumSettingsRoutes } from "../../src/features/premium-settings/presentation/settings.routes";
import { buildOpenApi } from "../../src/features/premium-docs/openapi";
import { OPERATIONS } from "../../src/features/premium-docs/operations";
import * as examples from "../../src/features/premium-docs/examples";
import { envelope } from "../../src/features/premium-docs/schemas";
import { SwipeUndoService } from "../../src/features/swipe-undo/application/swipe-undo-service";
import { registerSwipeUndoRoute } from "../../src/features/swipe-undo/presentation/undo.routes";
import type { AppVariables } from "../../src/shared/http/middleware";

// Convention of the repository (CLAUDE.md §10bis) for the routes of the revenue features: every
// operation is complete, every example is synthetic and valid against the schema it illustrates,
// every route that is documented exists, and the exported file is up to date.

const document = buildOpenApi() as { paths: Record<string, Record<string, any>> };

describe("completeness (zero debt: no ratchet list)", () => {
  test.each(OPERATIONS.map((o) => [o.operationId, o] as const))("%s carries every element", (_id, operation) => {
    const doc = document.paths[operation.path]?.[operation.method];
    expect(doc).toBeDefined();
    expect(doc.tags.length).toBeGreaterThan(0);
    expect(doc.summary.length).toBeGreaterThan(10);
    expect(doc.description.length).toBeGreaterThan(120);
    // who can call it, and the isolation rule
    expect(doc.description).toContain("Qui :");
    // side effects are stated
    expect(doc.description).toMatch(/effets? de bord|Effets? de bord|Aucun effet/i);
    // security
    if (operation.auth === "signature") expect(doc.security).toEqual([]);
    else expect(doc.security.length).toBeGreaterThan(0);
    // parameters: described, with an example
    for (const parameter of doc.parameters ?? []) {
      expect(parameter.description.length).toBeGreaterThan(5);
      expect(parameter.example).toBeDefined();
    }
    for (const placeholder of operation.path.match(/\{(\w+)\}/g) ?? []) {
      expect((doc.parameters ?? []).some((p: { name: string; in: string }) => `{${p.name}}` === placeholder && p.in === "path")).toBe(true);
    }
    // body: a schema and at least one example
    if (operation.body !== undefined) {
      const content = doc.requestBody.content["application/json"];
      expect(content.schema).toBeDefined();
      expect(Object.keys(content.examples).length).toBeGreaterThan(0);
    }
    // 2xx: schema and a complete example
    const ok = doc.responses[String(operation.success.status)].content[operation.success.image ? "image/jpeg" : "application/json"];
    expect(ok.schema).toBeDefined();
    if (!operation.success.image) expect(ok.example).toBeDefined();
    // errors: an example per code
    const statuses = Object.keys(doc.responses).filter((status) => !status.startsWith("2"));
    expect(statuses.length).toBeGreaterThan(0);
    for (const status of statuses) {
      const examplesOfStatus = Object.values(doc.responses[status].content["application/json"].examples) as { value: Record<string, unknown> }[];
      expect(examplesOfStatus.length).toBeGreaterThan(0);
      for (const example of examplesOfStatus) expect(Object.keys(example.value).length).toBeGreaterThan(0);
    }
  });

  test("an authenticated route documents its 401, a body route its 400, a path-id route its 404", () => {
    for (const operation of OPERATIONS) {
      if (operation.auth === "member" || operation.auth === "admin") expect([operation.operationId, operation.errors.some((e) => e.status === 401)]).toEqual([operation.operationId, true]);
      if (operation.body !== undefined) expect([operation.operationId, operation.errors.some((e) => e.status === 400)]).toEqual([operation.operationId, true]);
      if (operation.path.includes("{")) expect([operation.operationId, operation.errors.some((e) => e.status === 404 || e.status === 400)]).toEqual([operation.operationId, true]);
    }
  });

  test("a route that asks for mazl+ documents the 402 mazl_plus_required", () => {
    for (const id of ["setPassport", "setIncognito"]) {
      expect(OPERATIONS.find((o) => o.operationId === id)?.errors.some((e) => e.status === 402 && e.code === "mazl_plus_required")).toBe(true);
    }
  });

  test("operation ids are unique and every route has a distinct method and path", () => {
    expect(new Set(OPERATIONS.map((o) => o.operationId)).size).toBe(OPERATIONS.length);
    expect(new Set(OPERATIONS.map((o) => `${o.method} ${o.path}`)).size).toBe(OPERATIONS.length);
  });
});

describe("examples are valid against their schema", () => {
  for (const operation of OPERATIONS) {
    test(`${operation.operationId}: request examples`, () => {
      for (const [name, example] of Object.entries(operation.body?.examples ?? {})) {
        const parsed = operation.body?.schema.safeParse(example.value);
        expect([name, parsed?.success, parsed?.success === false ? JSON.stringify(parsed.error.issues) : ""]).toEqual([name, true, ""]);
      }
      for (const parameter of operation.parameters) {
        expect([parameter.name, parameter.schema.safeParse(parameter.example).success]).toEqual([parameter.name, true]);
      }
    });

    if (operation.success.image) continue;
    test(`${operation.operationId}: the success example`, () => {
      const schema = operation.success.enveloped ? envelope(operation.success.schema) : operation.success.schema;
      const value = operation.success.enveloped ? { success: true, data: operation.success.example } : operation.success.example;
      const parsed = schema.safeParse(value);
      expect(parsed.success ? "" : JSON.stringify(parsed.error.issues)).toBe("");
    });
  }

  test("the shared examples exist", () => {
    expect(Object.keys(examples).length).toBeGreaterThan(10);
  });
});

describe("examples are synthetic", () => {
  const everything = JSON.stringify({ operations: OPERATIONS.map((o) => ({ ...o, body: o.body?.examples, schema: undefined, success: o.success.example, parameters: o.parameters.map((p) => p.example) })), examples });

  test("only example.com addresses and domains", () => {
    for (const match of everything.matchAll(/[\w.+-]+@([\w.-]+)/g)) expect(match[1]).toBe("example.com");
    for (const match of everything.matchAll(/https?:\/\/([\w.-]+)/g)) expect(match[1]).toEndWith("example.com");
  });

  test("no token, key or identifier that looks real", () => {
    expect(everything).not.toMatch(/eyJ[A-Za-z0-9_-]{10,}/); // a JWT
    expect(everything).not.toMatch(/\b(sk|rk|pk)_(live|test)_/); // a Stripe key
    expect(everything).not.toMatch(/Bearer\s+\S{10,}/);
    expect(everything).not.toMatch(/BEGIN [A-Z ]*PRIVATE KEY/);
    expect(everything).not.toMatch(/\b6758543555\b/); // the real App Store id
    // The signatures are visibly invented.
    for (const match of everything.matchAll(/sig=([\w-]+)/g)) expect(match[1]).toStartWith("exemple");
  });

  test("no personal data of a free member in the example of a free answer", () => {
    const free = JSON.stringify(examples.receivedFree);
    expect(free).not.toMatch(/user_id|"picture"|"age"|"note"/);
    expect(free).not.toMatch(/\/media\/photos\/\d+\?/);
  });
});

describe("every documented route of the revenue features exists", () => {
  const authenticate = createMiddleware<{ Variables: AppVariables }>(async (c, next) => { c.set("userId", 1); await next(); });
  const app = new Hono<{ Variables: AppVariables }>();
  registerPremiumSettingsRoutes(app, { authenticate, settings: new PremiumSettingsService({ read: async () => ({ passport: null, incognito: false, sendReadReceipts: true }), setPassport: async () => undefined, setIncognito: async () => undefined, setReadReceipts: async () => undefined }, { isPlus: async () => true }) });
  registerSwipeUndoRoute(app, { authenticate, undo: new SwipeUndoService({ undoLast: async () => ({ kind: "nothing_to_undo" }) }, { isPlus: async () => true }) });
  const store = { record: async () => undefined, cityOf: async () => null, counts: async () => [] };
  registerBoostTimingRoutes(app, {
    authenticate,
    activity: createActivityRecorder(store),
    timing: createBoostTimingService({
      activity: store,
      schedules: { schedule: async () => "scheduled", get: async () => null, cancel: async () => undefined, claimDue: async () => [], forgetRun: async () => undefined },
      boosts: { available: async () => 1, launch: async () => "started" },
      notifier: { started: async () => undefined, notStarted: async () => undefined },
    }),
  });
  const registered = new Set(app.routes.filter((route) => route.method !== "ALL").map((route) => `${route.method.toLowerCase()} ${route.path.replace(/:(\w+)/g, "{$1}")}`));
  const newRoutes = ["getPremiumSettings", "setPassport", "setIncognito", "setReadReceipts", "undoSwipe", "getBoostBestTime", "scheduleBoost", "cancelBoostSchedule"];

  test.each(newRoutes)("%s is registered", (id) => {
    const operation = OPERATIONS.find((o) => o.operationId === id);
    expect(operation).toBeDefined();
    expect(registered.has(`${operation?.method} ${operation?.path}`)).toBe(true);
  });

  test("and nothing is registered that the document does not know", () => {
    const documented = new Set(OPERATIONS.map((o) => `${o.method} ${o.path}`));
    for (const route of registered) expect([route, documented.has(route)]).toEqual([route, true]);
  });
});

describe("the exported document", () => {
  test("docs/api/premium-openapi.json is up to date (run: bun scripts/export-premium-openapi.ts)", async () => {
    const committed = await Bun.file(new URL("../../docs/api/premium-openapi.json", import.meta.url)).text();
    expect(committed).toBe(`${JSON.stringify(buildOpenApi(), null, 2)}\n`);
  });

  test("is OpenAPI 3.1 with the member and admin security schemes", () => {
    const doc = buildOpenApi() as { openapi: string; components: { securitySchemes: Record<string, unknown> } };
    expect(doc.openapi).toBe("3.1.0");
    expect(Object.keys(doc.components.securitySchemes)).toEqual(["memberBearer", "adminBearer"]);
  });
});
