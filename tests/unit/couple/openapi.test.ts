import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { buildOpenApi } from "../../../src/features/couple/presentation/openapi";
import { OPERATIONS, honoPath } from "../../../src/features/couple/presentation/operations";
import { envelope } from "../../../src/features/couple/presentation/schemas";
import { registerSpaceRoutes } from "../../../src/features/couple/presentation/space.routes";
import { registerStaffConciergeRoutes } from "../../../src/features/couple/presentation/concierge-staff.routes";
import * as examples from "../../../src/features/couple/presentation/examples";

// Convention of the repository (CLAUDE.md section 10bis): every operation is
// complete, every example is synthetic and valid against the schema it
// illustrates, and the exported file is up to date. Zero debt: no ratchet list.

const document = buildOpenApi() as { paths: Record<string, Record<string, any>> };

describe("completeness", () => {
  test.each(OPERATIONS.map((o) => [o.operationId, o] as const))("%s carries every element", (_id, operation) => {
    const doc = document.paths[operation.path]?.[operation.method];
    expect(doc).toBeDefined();
    expect(doc.tags.length).toBeGreaterThan(0);
    expect(doc.summary.length).toBeGreaterThan(10);
    expect(doc.description.length).toBeGreaterThan(120);
    expect(doc.description).toContain("Qui :");
    expect(doc.description).toMatch(/Effets de bord/i);
    expect(doc.security).toEqual([operation.audience === "staff" ? { staffBearer: [] } : { memberBearer: [] }]);
    if (operation.premium) {
      expect(doc.description).toContain("MAZL Couple");
      expect(Object.keys(doc.responses)).toContain("402");
    }
    for (const parameter of doc.parameters ?? []) {
      expect(parameter.description.length).toBeGreaterThan(5);
      expect(parameter.example).toBeDefined();
    }
    for (const placeholder of operation.path.match(/\{(\w+)\}/g) ?? []) {
      expect((doc.parameters ?? []).some((p: { name: string; in: string }) => `{${p.name}}` === placeholder && p.in === "path")).toBe(true);
    }
    if (operation.body !== undefined) {
      const content = doc.requestBody.content["application/json"];
      expect(content.schema).toBeDefined();
      expect(Object.keys(content.examples).length).toBeGreaterThan(0);
    }
    const ok = doc.responses[String(operation.success.status)].content["application/json"];
    expect(ok.schema).toBeDefined();
    expect(ok.example.success).toBe(true);
    const statuses = Object.keys(doc.responses).filter((s) => !s.startsWith("2"));
    expect(statuses).toContain("500");
    expect(statuses).toContain("401");
    if (operation.audience === "staff") expect(statuses).toContain("403");
    for (const status of statuses) {
      const response = doc.responses[status];
      expect(response.content["application/json"].schema.properties.success).toBeDefined();
      for (const example of Object.values(response.content["application/json"].examples) as { value: { success: boolean; error: string } }[]) {
        expect(example.value.success).toBe(false);
        expect(example.value.error.length).toBeGreaterThan(0);
      }
    }
  });

  test("a body route documents its 400 and a path-id route its 404 or 403", () => {
    for (const operation of OPERATIONS) {
      if (operation.body !== undefined) expect(operation.errors.some((e) => e.status === 400)).toBe(true);
      if (operation.path.includes("{")) expect(operation.errors.some((e) => e.status === 404 || e.status === 403)).toBe(true);
    }
  });

  test("operation ids are unique and every route has a distinct method and path", () => {
    expect(new Set(OPERATIONS.map((o) => o.operationId)).size).toBe(OPERATIONS.length);
    expect(new Set(OPERATIONS.map((o) => `${o.method} ${o.path}`)).size).toBe(OPERATIONS.length);
  });

  test("the contract's routes are all there", () => {
    const routes = new Set(OPERATIONS.map((o) => `${o.method.toUpperCase()} ${o.path}`));
    for (const expected of [
      "GET /api/couple/today", "POST /api/couple/mood", "GET /api/couple/rituals", "POST /api/couple/rituals", "PATCH /api/couple/rituals/{id}", "DELETE /api/couple/rituals/{id}",
      "GET /api/couple/outings", "GET /api/couple/checkin", "POST /api/couple/checkin", "GET /api/couple/{coupleId}/question", "GET /api/couple/{coupleId}/questions",
      "GET /api/couple/concierge", "POST /api/couple/concierge", "GET /api/couple/concierge/{id}", "POST /api/couple/concierge/{id}/messages",
      "POST /api/couple/concierge/{id}/choose", "POST /api/couple/concierge/{id}/cancel",
      "GET /api/backoffice/concierge/requests", "GET /api/backoffice/concierge/requests/{id}", "PATCH /api/backoffice/concierge/requests/{id}",
      "POST /api/backoffice/concierge/requests/{id}/messages", "GET /api/backoffice/concierge/staff",
    ]) expect(routes.has(expected)).toBe(true);
  });
});

describe("every documented operation is served, and nothing else", () => {
  const fakeDeps = new Proxy({}, { get: () => undefined }) as never;

  test("the member router registers exactly the member operations", () => {
    const app = new Hono<{ Variables: { userId: number } }>();
    registerSpaceRoutes(app, { ...(fakeDeps as object), authenticate: async (_c: unknown, next: () => Promise<void>) => next() } as never);
    const served = [...new Set(app.routes.filter((r) => r.method !== "ALL").map((r) => `${r.method} ${r.path}`))];
    const wanted = OPERATIONS.filter((o) => o.audience === "member").map((o) => `${o.method.toUpperCase()} ${honoPath(o.path)}`);
    expect(served.sort()).toEqual(wanted.sort());
  });

  test("the staff router registers exactly the staff operations, each behind its permission", () => {
    const asked: string[] = [];
    const app = new Hono();
    registerStaffConciergeRoutes(app, {
      requirePermission: (permission) => {
        asked.push(permission);
        return async (_c, next) => next();
      },
      concierge: undefined as never, audit: undefined as never, assignableStaff: async () => [], exposeOpenApi: true,
    });
    const served = [...new Set(app.routes.filter((r) => r.method !== "ALL").map((r) => `${r.method} ${r.path}`))];
    const wanted = OPERATIONS.filter((o) => o.audience === "staff").map((o) => `${o.method.toUpperCase()} ${honoPath(o.path)}`);
    expect(served.sort()).toEqual(wanted.sort());
    expect(new Set(asked)).toEqual(new Set(["concierge.manage", "operations.manage"]));
    expect(asked.filter((p) => p === "concierge.manage")).toHaveLength(OPERATIONS.filter((o) => o.permission === "concierge.manage").length);
  });
});

describe("examples are valid against their schema", () => {
  for (const operation of OPERATIONS) {
    test(`${operation.operationId}: request examples`, () => {
      for (const [name, example] of Object.entries(operation.body?.examples ?? {})) {
        const parsed = operation.body?.schema.safeParse(example.value);
        expect([name, parsed?.success, parsed?.success === false ? JSON.stringify(parsed.error.issues) : ""]).toEqual([name, true, ""]);
      }
      for (const parameter of operation.parameters) expect(parameter.schema.safeParse(parameter.example).success).toBe(true);
    });

    test(`${operation.operationId}: the success example`, () => {
      const parsed = envelope(operation.success.schema).safeParse({ success: true, data: operation.success.example });
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

  test("no token, key, phone number or real company", () => {
    expect(everything).not.toMatch(/eyJ[A-Za-z0-9_-]{10,}/);
    expect(everything).not.toMatch(/\b(sk|rk|pk)_(live|test)_/);
    expect(everything).not.toMatch(/sk-ant-/);
    expect(everything).not.toMatch(/Bearer\s+\S{10,}/);
    expect(everything).not.toMatch(/\+?\d[\d .]{9,}\d/);
    expect(everything).not.toMatch(/mazl\.(app|com)|one-bk|bk-/i);
  });
});

describe("the exported document", () => {
  test("docs/api/couple-openapi.json is up to date (run: bun scripts/export-couple-openapi.ts)", async () => {
    const committed = await Bun.file(new URL("../../../docs/api/couple-openapi.json", import.meta.url)).text();
    expect(committed).toBe(`${JSON.stringify(buildOpenApi(), null, 2)}\n`);
  });

  test("is OpenAPI 3.1 with the member and staff security schemes", () => {
    const doc = buildOpenApi() as { openapi: string; components: { securitySchemes: Record<string, unknown> } };
    expect(doc.openapi).toBe("3.1.0");
    expect(Object.keys(doc.components.securitySchemes).sort()).toEqual(["memberBearer", "staffBearer"]);
  });
});
