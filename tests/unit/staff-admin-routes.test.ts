import { describe, expect, test } from "bun:test";
import { buildStaffFixture, ENV_ADMIN, type Data, type StaffFixture } from "./support/staff-fixture";

const P = "/api/backoffice";
const script = { "x-admin-password": "correct horse battery staple" };

// A DB super-admin with a session, besides the environment one.
async function withSuperAdmin(f: StaffFixture) {
  await f.directory.create(ENV_ADMIN, { email: "boss@example.com", role: "super_admin" });
  return f.bearer(f.tokens.signSession({ email: "boss@example.com", mfa: true }));
}

const listOf = (body: { data?: Data }) => body.data as unknown as Data[];

describe("GET /staff", () => {
  test("lists environment super-admins first, flagged, then the members", async () => {
    const f = buildStaffFixture();
    await f.directory.create(ENV_ADMIN, { email: "mod@example.com", role: "moderator" });
    const res = await f.call("GET", `${P}/staff`, undefined, script);
    expect(res.status).toBe(200);
    const rows = listOf(res.body);
    expect(rows.map((r) => r.email)).toEqual([ENV_ADMIN, "mod@example.com"]);
    expect(rows[0]).toMatchObject({ role: "super_admin", roleLabel: "Super-administrateur", fromEnvironment: true, active: true, mfaEnrolled: false });
    expect(rows[1]).toMatchObject({ role: "moderator", fromEnvironment: false, createdBy: ENV_ADMIN });
  });

  test("needs staff.manage: admin and moderator get 403, no token 401", async () => {
    const f = buildStaffFixture();
    await f.directory.create(ENV_ADMIN, { email: "adm@example.com", role: "admin" });
    await f.directory.create(ENV_ADMIN, { email: "mod@example.com", role: "moderator" });
    for (const email of ["adm@example.com", "mod@example.com"]) {
      const headers = f.bearer(f.tokens.signSession({ email, mfa: true }));
      expect((await f.call("GET", `${P}/staff`, undefined, headers)).status).toBe(403);
      expect((await f.call("POST", `${P}/staff`, { email: "x@example.com", role: "support" }, headers)).status).toBe(403);
      expect((await f.call("PATCH", `${P}/staff/mod@example.com`, { active: false }, headers)).status).toBe(403);
    }
    expect((await f.call("GET", `${P}/staff`)).status).toBe(401);
  });

  test("in production a session without mfa is refused", async () => {
    const f = buildStaffFixture({ env: { NODE_ENV: "production" } });
    const headers = f.bearer(f.tokens.signSession({ email: ENV_ADMIN, mfa: false }));
    const res = await f.call("GET", `${P}/staff`, undefined, headers);
    expect(res.status).toBe(403);
    expect(res.body.error).toBe("mfa_required");
  });
});

describe("POST /staff", () => {
  test("creates a member (e-mail normalised), 201, audited with the actor", async () => {
    const f = buildStaffFixture();
    const res = await f.call("POST", `${P}/staff`, { email: "  New.Mod@Example.com ", role: "moderator" }, script);
    expect(res.status).toBe(201);
    expect(res.body.data).toMatchObject({ email: "new.mod@example.com", role: "moderator", active: true, mfaEnrolled: false, fromEnvironment: false });
    expect(f.audit.entries).toHaveLength(1);
    expect(f.audit.entries[0]).toMatchObject({
      action: "staff.create",
      actor: ENV_ADMIN,
      targetType: "staff",
      targetId: "new.mod@example.com",
      details: { role: "moderator" },
    });
  });

  test("a created member can then sign in with Google", async () => {
    const f = buildStaffFixture();
    await f.call("POST", `${P}/staff`, { email: "new@example.com", role: "support" }, script);
    f.google.accepted("t", "new@example.com");
    const res = await f.call("POST", `${P}/auth/google`, { credential: "t" });
    expect(res.body.data?.me).toMatchObject({ role: "support" });
  });

  test("409 environment_member for an environment address, 409 already_exists for a duplicate", async () => {
    const f = buildStaffFixture();
    const env = await f.call("POST", `${P}/staff`, { email: ENV_ADMIN.toUpperCase(), role: "admin" }, script);
    expect(env.status).toBe(409);
    expect(env.body.error).toBe("environment_member");
    await f.call("POST", `${P}/staff`, { email: "dup@example.com", role: "admin" }, script);
    const dup = await f.call("POST", `${P}/staff`, { email: "DUP@example.com", role: "support" }, script);
    expect(dup.status).toBe(409);
    expect(dup.body.error).toBe("already_exists");
    expect(f.audit.actions()).toEqual(["staff.create"]);
  });

  test("400 for an unknown role, a bad e-mail or no body", async () => {
    const f = buildStaffFixture();
    expect((await f.call("POST", `${P}/staff`, { email: "a@example.com", role: "root" }, script)).status).toBe(400);
    expect((await f.call("POST", `${P}/staff`, { email: "nope", role: "admin" }, script)).status).toBe(400);
    expect((await f.call("POST", `${P}/staff`, undefined, script)).status).toBe(400);
  });
});

describe("PATCH /staff/:email", () => {
  test("changes the role and deactivates; both audited; takes effect on the next request", async () => {
    const f = buildStaffFixture();
    await f.directory.create(ENV_ADMIN, { email: "mod@example.com", role: "moderator" });
    const memberHeaders = f.bearer(f.tokens.signSession({ email: "mod@example.com", mfa: true }));
    expect((await f.call("GET", `${P}/me`, undefined, memberHeaders)).status).toBe(200);

    const promoted = await f.call("PATCH", `${P}/staff/mod%40example.com`, { role: "analyst" }, script);
    expect(promoted.status).toBe(200);
    expect(promoted.body.data).toMatchObject({ role: "analyst" });
    expect((await f.call("GET", `${P}/me`, undefined, memberHeaders)).body.data?.role).toBe("analyst");

    const off = await f.call("PATCH", `${P}/staff/mod@example.com`, { active: false }, script);
    expect(off.body.data).toMatchObject({ active: false });
    expect((await f.call("GET", `${P}/me`, undefined, memberHeaders)).status).toBe(401);

    expect(f.audit.entries.slice(-2)).toMatchObject([
      { action: "staff.update", targetId: "mod@example.com", details: { role: "analyst" } },
      { action: "staff.update", targetId: "mod@example.com", details: { active: false } },
    ]);
  });

  test("409 environment_member for an environment address", async () => {
    const f = buildStaffFixture();
    const res = await f.call("PATCH", `${P}/staff/${ENV_ADMIN}`, { active: false }, script);
    expect(res.status).toBe(409);
    expect(res.body.error).toBe("environment_member");
  });

  test("404 for an unknown member, 400 for an empty or invalid patch", async () => {
    const f = buildStaffFixture();
    expect((await f.call("PATCH", `${P}/staff/ghost@example.com`, { active: false }, script)).status).toBe(404);
    await f.directory.create(ENV_ADMIN, { email: "mod@example.com", role: "moderator" });
    expect((await f.call("PATCH", `${P}/staff/mod@example.com`, {}, script)).status).toBe(400);
    expect((await f.call("PATCH", `${P}/staff/mod@example.com`, { role: "root" }, script)).status).toBe(400);
    expect((await f.call("PATCH", `${P}/staff/mod@example.com`, { active: "no" }, script)).status).toBe(400);
  });

  test("409 self_lockout: nobody removes their own staff.manage, by role or by deactivation", async () => {
    const f = buildStaffFixture();
    const boss = await withSuperAdmin(f);
    const demote = await f.call("PATCH", `${P}/staff/boss@example.com`, { role: "admin" }, boss);
    expect(demote.status).toBe(409);
    expect(demote.body.error).toBe("self_lockout");
    expect((await f.call("PATCH", `${P}/staff/boss@example.com`, { active: false }, boss)).status).toBe(409);
    // Keeping the role is fine, and another super-admin can still demote them.
    expect((await f.call("PATCH", `${P}/staff/boss@example.com`, { role: "super_admin" }, boss)).status).toBe(200);
    expect((await f.call("PATCH", `${P}/staff/boss@example.com`, { role: "admin" }, script)).status).toBe(200);
    expect(f.audit.actions().filter((a) => a === "staff.update")).toHaveLength(2);
  });
});
