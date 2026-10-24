import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createAuthenticate, createRequirePermission, type GuardDeps } from "../../src/features/staff/presentation/require-permission";
import type { StaffRole } from "../../src/features/staff/domain/roles";
import { createTokenSigner } from "../../src/features/staff/domain/session-token";
import type { StaffVariables } from "../../src/features/staff/application/ports";
import { Hono as H } from "hono";

const NOW = new Date("2026-10-24T10:00:00.000Z");
let clockMs = NOW.getTime();
const tokens = createTokenSigner("guard-key", () => new Date(clockMs));

interface Setup {
  roles?: Record<string, StaffRole>;
  mfaRequired?: boolean;
  isProduction?: boolean;
  script?: boolean;
}

function build(setup: Setup = {}) {
  clockMs = NOW.getTime();
  const roles = setup.roles ?? { "mod@example.com": "moderator", "root@example.com": "super_admin" };
  const touched: string[] = [];
  const deps: GuardDeps = {
    resolveStaff: async (email) => {
      const role = roles[email];
      return role ? { email, role } : null;
    },
    verifySession: tokens.verifySession,
    mfaRequired: setup.mfaRequired ?? false,
    touch: async (email) => {
      touched.push(email);
    },
    isProduction: setup.isProduction ?? false,
    ...(setup.script === false ? {} : { scriptAccess: { email: "root@example.com", password: "script-pass", secretsMatch: (a: string, b: string) => a === b } }),
    now: () => clockMs,
  };
  const requirePermission = createRequirePermission(deps);
  const app = new Hono<{ Variables: StaffVariables }>();
  app.get("/reports", requirePermission("reports.decide"), (c) => c.json({ ok: true, staff: c.get("staff") }));
  app.get("/staff", requirePermission("staff.manage"), (c) => c.json({ ok: true }));
  app.get("/me", createAuthenticate(deps), (c) => c.json({ staff: c.get("staff") }));
  const get = async (path: string, headers: Record<string, string> = {}) => {
    const res = await app.request(path, { headers });
    return { status: res.status, body: (await res.json()) as { error?: string; ok?: boolean; success?: boolean; staff?: { email: string; role: string; mfa: boolean } } };
  };
  return { get, touched };
}

const session = (email: string, mfa = true) => ({ authorization: `Bearer ${tokens.signSession({ email, mfa })}` });

describe("401 unauthorized", () => {
  test("no credentials", async () => {
    const { get } = build();
    const res = await get("/reports");
    expect(res.status).toBe(401);
    expect(res.body).toMatchObject({ success: false, error: "unauthorized" });
  });

  test("garbage, wrong scheme, another key, challenge token", async () => {
    const { get } = build();
    expect((await get("/reports", { authorization: "Bearer nope" })).status).toBe(401);
    expect((await get("/reports", { authorization: `Basic ${tokens.signSession({ email: "mod@example.com", mfa: true })}` })).status).toBe(401);
    const foreign = createTokenSigner("other-key", () => NOW).signSession({ email: "mod@example.com", mfa: true });
    expect((await get("/reports", { authorization: `Bearer ${foreign}` })).status).toBe(401);
    expect((await get("/reports", { authorization: `Bearer ${tokens.signChallenge("mod@example.com")}` })).status).toBe(401);
  });

  test("expired token", async () => {
    const { get } = build();
    const headers = session("mod@example.com");
    clockMs += 12 * 3600 * 1000 + 1000;
    expect((await get("/reports", headers)).status).toBe(401);
  });

  test("valid token of a member that is unknown or deactivated (resolve gives null)", async () => {
    const { get } = build();
    expect((await get("/reports", session("ghost@example.com"))).status).toBe(401);
  });
});

describe("403", () => {
  test("a role without the permission: forbidden", async () => {
    const { get } = build();
    const res = await get("/staff", session("mod@example.com"));
    expect(res.status).toBe(403);
    expect(res.body.error).toBe("forbidden");
  });

  test("mfa_required when the policy asks for it and the session has none", async () => {
    const { get } = build({ mfaRequired: true });
    const res = await get("/reports", session("mod@example.com", false));
    expect(res.status).toBe(403);
    expect(res.body.error).toBe("mfa_required");
    expect((await get("/reports", session("mod@example.com", true))).status).toBe(200);
  });

  test("mfa_required is reported before forbidden", async () => {
    const { get } = build({ mfaRequired: true });
    expect((await get("/staff", session("mod@example.com", false))).body.error).toBe("mfa_required");
  });

  test("without the policy a session without mfa goes through", async () => {
    const { get } = build({ mfaRequired: false });
    expect((await get("/reports", session("mod@example.com", false))).status).toBe(200);
  });

  test("the authenticate guard needs no permission and no second factor", async () => {
    const { get } = build({ mfaRequired: true });
    const res = await get("/me", session("mod@example.com", false));
    expect(res.status).toBe(200);
    expect(res.body.staff).toEqual({ email: "mod@example.com", role: "moderator", mfa: false });
    expect((await get("/me")).status).toBe(401);
  });

  test("the principal carries the role read at request time, not a role in the token", async () => {
    const { get } = build({ roles: { "mod@example.com": "support" } });
    expect((await get("/reports", session("mod@example.com"))).status).toBe(403);
  });
});

describe("x-admin-password", () => {
  test("outside production it is a super-admin session with mfa", async () => {
    const { get } = build({ mfaRequired: true });
    const res = await get("/staff", { "x-admin-password": "script-pass" });
    expect(res.status).toBe(200);
    const me = await get("/me", { "x-admin-password": "script-pass" });
    expect(me.body.staff).toEqual({ email: "root@example.com", role: "super_admin", mfa: true });
  });

  test("a wrong password is a 401", async () => {
    const { get } = build();
    expect((await get("/staff", { "x-admin-password": "nope" })).status).toBe(401);
  });

  test("in production the header is ignored, even with the right password", async () => {
    const { get } = build({ isProduction: true });
    expect((await get("/staff", { "x-admin-password": "script-pass" })).status).toBe(401);
    expect((await get("/me", { "x-admin-password": "script-pass" })).status).toBe(401);
  });

  test("ignored when no script credentials are configured", async () => {
    const { get } = build({ script: false });
    expect((await get("/staff", { "x-admin-password": "script-pass" })).status).toBe(401);
  });
});

describe("last_seen_at", () => {
  test("written at most once a minute per member", async () => {
    const { get, touched } = build();
    const headers = session("mod@example.com");
    await get("/reports", headers);
    await get("/reports", headers);
    clockMs += 59_000;
    await get("/reports", headers);
    expect(touched).toEqual(["mod@example.com"]);
    clockMs += 1_000;
    await get("/reports", headers);
    expect(touched).toEqual(["mod@example.com", "mod@example.com"]);
  });

  test("not written for refused requests", async () => {
    const { get, touched } = build();
    await get("/reports", { authorization: "Bearer junk" });
    expect(touched).toEqual([]);
  });

  test("a failing write does not fail the request", async () => {
    const deps: GuardDeps = {
      resolveStaff: async (email) => ({ email, role: "moderator" }),
      verifySession: tokens.verifySession,
      mfaRequired: false,
      touch: async () => {
        throw new Error("db down");
      },
      isProduction: false,
    };
    const app = new H<{ Variables: StaffVariables }>();
    app.get("/x", createRequirePermission(deps)("reports.read"), (c) => c.json({ ok: true }));
    const res = await app.request("/x", { headers: session("mod@example.com") });
    expect(res.status).toBe(200);
  });
});
