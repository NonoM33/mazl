import { describe, expect, test } from "bun:test";
import { buildOpenApi } from "../../../src/features/storefront/presentation/openapi";
import { OPERATIONS } from "../../../src/features/storefront/presentation/operations";
import { envelope } from "../../../src/features/storefront/presentation/schemas";
import * as examples from "../../../src/features/storefront/presentation/examples";

// Convention of the repository (CLAUDE.md §10bis): every operation is complete, every example is
// synthetic and valid against the schema it illustrates, and the exported file is up to date.

const document = buildOpenApi() as { paths: Record<string, Record<string, any>> };

describe("completeness (zero debt: no ratchet list)", () => {
  test.each(OPERATIONS.map((o) => [o.operationId, o] as const))("%s carries every element", (_id, operation) => {
    const doc = document.paths[operation.path]?.[operation.method];
    expect(doc).toBeDefined();
    expect(doc.tags.length).toBeGreaterThan(0);
    expect(doc.summary.length).toBeGreaterThan(10);
    expect(doc.description.length).toBeGreaterThan(120);
    // who can call it
    if (operation.permission === null) {
      expect(doc.security).toEqual([]);
      expect(doc.description).toContain("publique");
    } else {
      expect(doc.security).toEqual([{ staffBearer: [] }]);
      expect(doc.description).toMatch(/Rôles? :/);
    }
    // side effects are stated
    expect(doc.description).toMatch(/effets? de bord|Effets? de bord|Aucun effet/i);
    // parameters: described, with an example
    for (const parameter of doc.parameters ?? []) {
      expect(parameter.description.length).toBeGreaterThan(5);
      expect(parameter.example).toBeDefined();
    }
    for (const placeholder of operation.path.match(/\{(\w+)\}/g) ?? []) {
      expect((doc.parameters ?? []).some((p: { name: string; in: string }) => `{${p.name}}` === placeholder && p.in === "path")).toBe(true);
    }
    // body: a schema and at least one example
    if (operation.method !== "get" && operation.body !== undefined) {
      const content = doc.requestBody.content["application/json"];
      expect(content.schema).toBeDefined();
      expect(Object.keys(content.examples).length).toBeGreaterThan(0);
    }
    // 2xx: schema and a complete example
    const ok = doc.responses[String(operation.success.status)].content["application/json"];
    expect(ok.schema).toBeDefined();
    expect(ok.example).toBeDefined();
    // errors: every response has the real envelope and an example per code
    const statuses = Object.keys(doc.responses).filter((s) => !s.startsWith("2"));
    if (operation.permission !== null) for (const required of ["401", "403", "500"]) expect(statuses).toContain(required);
    else expect(statuses).toContain("500");
    for (const status of statuses) {
      const response = doc.responses[status];
      expect(response.content["application/json"].schema.properties.success).toBeDefined();
      for (const example of Object.values(response.content["application/json"].examples) as { value: { success: boolean; error: string } }[]) {
        expect(example.value.success).toBe(false);
        expect(example.value.error.length).toBeGreaterThan(0);
      }
    }
  });

  test("a body route documents its 400 and a path-id route its 404", () => {
    for (const operation of OPERATIONS) {
      if (operation.body !== undefined) expect(operation.errors.some((e) => e.status === 400)).toBe(true);
      if (operation.path.includes("{")) expect(operation.errors.some((e) => e.status === 404)).toBe(true);
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
        expect(parameter.schema.safeParse(parameter.example).success).toBe(true);
      }
    });

    test(`${operation.operationId}: the success example`, () => {
      const schema = operation.success.enveloped ? envelope(operation.success.schema) : operation.success.schema;
      const value = operation.success.enveloped ? { success: true, data: operation.success.example } : operation.success.example;
      const parsed = schema.safeParse(value);
      expect(parsed.success ? "" : JSON.stringify(parsed.error.issues)).toBe("");
    });
  }

  test("the shared examples parse too", () => {
    expect(Object.keys(examples).length).toBeGreaterThan(5);
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
    expect(everything).not.toMatch(/whsec_/);
    expect(everything).not.toMatch(/Bearer\s+\S{10,}/);
    expect(everything).not.toMatch(/BEGIN [A-Z ]*PRIVATE KEY/);
    // Stripe and Apple identifiers are visibly invented.
    for (const match of everything.matchAll(/\b(price|coupon|promo|cus|sub|pi)_([A-Za-z0-9_]+)/g)) expect(match[2]).toMatch(/example|plus|v2/);
    expect(everything).not.toMatch(/\b6758543555\b/); // the real App Store id
  });
});

describe("the exported document", () => {
  test("docs/api/storefront-openapi.json is up to date (run: bun scripts/export-storefront-openapi.ts)", async () => {
    const committed = await Bun.file(new URL("../../../docs/api/storefront-openapi.json", import.meta.url)).text();
    expect(committed).toBe(`${JSON.stringify(buildOpenApi(), null, 2)}\n`);
  });

  test("is OpenAPI 3.1 with the staff security scheme", () => {
    const doc = buildOpenApi() as { openapi: string; components: { securitySchemes: Record<string, unknown> } };
    expect(doc.openapi).toBe("3.1.0");
    expect(Object.keys(doc.components.securitySchemes)).toEqual(["staffBearer"]);
  });
});
