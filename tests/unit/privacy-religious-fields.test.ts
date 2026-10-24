import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import { createReligiousFieldsGuard } from "../../src/features/privacy/presentation/religious-fields-guard";
import type { AppVariables } from "../../src/shared/http/middleware";

// Security review M4: without a valid art. 9 consent, PUT /api/profile must not
// store denomination, kashrut, Shabbat or intention. The app has no consent
// screen yet: the fields are dropped silently, never a 4xx.

function app(consented: boolean) {
  const server = new Hono<{ Variables: AppVariables }>();
  const authenticate = createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    c.set("userId", 3);
    await next();
  });
  server.put("/api/profile", authenticate, createReligiousFieldsGuard({ allowsReligiousData: () => Promise.resolve(consented) }));
  // Stands for the profile handler: it reads the body again.
  server.put("/api/profile", async (c) => c.json({ stored: await c.req.json() }));
  return server;
}

const put = (server: Hono<{ Variables: AppVariables }>, body: string) =>
  server.request("/api/profile", { method: "PUT", headers: { "Content-Type": "application/json" }, body });

const full = { displayName: "Léa", bio: "Bonjour", denomination: "Massorti", kashrutLevel: "Strict", shabbatObservance: "Observant", relationshipIntention: "serious" };

describe("religious fields of the profile", () => {
  test("without consent they are dropped, the rest is kept, and the answer is not an error", async () => {
    const res = await put(app(false), JSON.stringify(full));
    expect(res.status).toBe(200);
    expect(((await res.json()) as { stored: unknown }).stored).toEqual({ displayName: "Léa", bio: "Bonjour" });
  });

  test("with consent they go through untouched", async () => {
    expect(((await (await put(app(true), JSON.stringify(full))).json()) as { stored: unknown }).stored).toEqual(full);
  });

  test("a malformed body is left to the profile route", async () => {
    const res = await put(app(false), "{");
    expect(res.status).toBe(500);
  });
});
