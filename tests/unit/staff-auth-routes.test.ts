import { describe, expect, test } from "bun:test";
import { buildStaffFixture, ENV_ADMIN, ENV_PASSWORD, type StaffFixture } from "./support/staff-fixture";

const P = "/api/backoffice";

async function loginEnvAdmin(f: StaffFixture) {
  const res = await f.call("POST", `${P}/auth/password`, { email: ENV_ADMIN, password: ENV_PASSWORD });
  return res;
}

// Logs in, enrols a second factor and returns the base32 secret.
async function enrol(f: StaffFixture): Promise<{ secret: string; token: string }> {
  const login = await loginEnvAdmin(f);
  const token = login.body.data?.token ?? "";
  const enrolment = await f.call("POST", `${P}/mfa/enroll`, undefined, f.bearer(token));
  const secret = enrolment.body.data?.secret ?? "";
  const confirm = await f.call("POST", `${P}/mfa/confirm`, { code: f.codeFor(secret) }, f.bearer(token));
  expect(confirm.status).toBe(200);
  f.clock.advance(30_000);
  return { secret, token };
}

describe("password login", () => {
  test("ADMIN_EMAIL + ADMIN_PASSWORD open a session without mfa", async () => {
    const f = buildStaffFixture();
    const res = await loginEnvAdmin(f);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data?.kind).toBe("session");
    expect(res.body.data?.me).toMatchObject({ email: ENV_ADMIN, role: "super_admin", mfa: false, mfaEnrolled: false, mfaRequired: false });
    expect(res.body.data?.me?.permissions).toContain("staff.manage");
    expect(f.tokens.verifySession(res.body.data?.token ?? "")).toEqual({ email: ENV_ADMIN, mfa: false });
  });

  test("the e-mail is compared case-insensitively", async () => {
    const f = buildStaffFixture();
    const res = await f.call("POST", `${P}/auth/password`, { email: ` ${ENV_ADMIN.toUpperCase()} `, password: ENV_PASSWORD });
    expect(res.status).toBe(200);
  });

  test("a wrong password is a 401 and is audited without the password", async () => {
    const f = buildStaffFixture();
    const res = await f.call("POST", `${P}/auth/password`, { email: ENV_ADMIN, password: "hunter2-attempt" });
    expect(res.status).toBe(401);
    expect(res.body).toMatchObject({ success: false, error: "invalid_credentials" });
    expect(f.audit.entries).toHaveLength(1);
    expect(f.audit.entries[0]).toMatchObject({ action: "auth.failure", actor: ENV_ADMIN, targetType: "staff" });
    expect(JSON.stringify(f.audit.entries)).not.toContain("hunter2");
  });

  test("another address with the right password is refused (password login is ADMIN_EMAIL only)", async () => {
    const f = buildStaffFixture();
    await f.directory.create("seed", { email: "mod@example.com", role: "moderator" });
    const res = await f.call("POST", `${P}/auth/password`, { email: "mod@example.com", password: ENV_PASSWORD });
    expect(res.status).toBe(401);
  });

  test("5 failures lock the address for 15 minutes, right password included", async () => {
    const f = buildStaffFixture();
    for (let i = 0; i < 5; i += 1) {
      expect((await f.call("POST", `${P}/auth/password`, { email: ENV_ADMIN, password: `wrong-${i}` })).status).toBe(401);
    }
    const locked = await loginEnvAdmin(f);
    expect(locked.status).toBe(429);
    expect(locked.body.error).toBe("rate_limited");
    expect(Number(locked.headers.get("retry-after"))).toBeGreaterThan(0);
    f.clock.advance(15 * 60_000 + 1000);
    expect((await loginEnvAdmin(f)).status).toBe(200);
  });

  test("the lock is per client address", async () => {
    const f = buildStaffFixture();
    for (let i = 0; i < 5; i += 1) await f.call("POST", `${P}/auth/password`, { email: ENV_ADMIN, password: "x" });
    const other = await f.call("POST", `${P}/auth/password`, { email: ENV_ADMIN, password: ENV_PASSWORD }, { "x-forwarded-for": "198.51.100.9" });
    expect(other.status).toBe(200);
  });

  test("a malformed body is a 400 and writes nothing", async () => {
    const f = buildStaffFixture();
    expect((await f.call("POST", `${P}/auth/password`, { email: "not-an-email", password: "x" })).status).toBe(400);
    expect((await f.call("POST", `${P}/auth/password`, { email: ENV_ADMIN })).status).toBe(400);
    expect(f.audit.entries).toHaveLength(0);
  });

  test("without ADMIN_PASSWORD configured, nothing logs in", async () => {
    const f = buildStaffFixture({ env: { ADMIN_PASSWORD: undefined } });
    const res = await f.call("POST", `${P}/auth/password`, { email: ENV_ADMIN, password: "" + "x" });
    expect(res.status).toBe(503);
  });
});

describe("Google login", () => {
  test("a verified e-mail of a staff member opens a session", async () => {
    const f = buildStaffFixture();
    await f.directory.create(ENV_ADMIN, { email: "mod@example.com", role: "moderator" });
    f.google.accepted("good-token", "Mod@Example.com");
    const res = await f.call("POST", `${P}/auth/google`, { credential: "good-token" });
    expect(res.status).toBe(200);
    expect(res.body.data?.me).toMatchObject({ email: "mod@example.com", role: "moderator" });
    expect(f.audit.actions()).toContain("auth.success");
  });

  test("an environment admin address is super_admin", async () => {
    const f = buildStaffFixture();
    f.google.accepted("t", ENV_ADMIN);
    const res = await f.call("POST", `${P}/auth/google`, { credential: "t" });
    expect(res.body.data?.me?.role).toBe("super_admin");
  });

  test("a token Google does not vouch for is a 401", async () => {
    const f = buildStaffFixture();
    const res = await f.call("POST", `${P}/auth/google`, { credential: "forged" });
    expect(res.status).toBe(401);
    expect(res.body.error).toBe("invalid_google_token");
    expect(f.audit.entries[0]).toMatchObject({ action: "auth.failure", details: { method: "google", reason: "invalid_token" } });
  });

  test("a Google account that is not staff is a 403, audited", async () => {
    const f = buildStaffFixture();
    f.google.accepted("t", "stranger@example.com");
    const res = await f.call("POST", `${P}/auth/google`, { credential: "t" });
    expect(res.status).toBe(403);
    expect(res.body.error).toBe("not_staff");
    expect(f.audit.entries[0]).toMatchObject({ action: "auth.failure", actor: "stranger@example.com" });
  });

  test("a deactivated member is refused", async () => {
    const f = buildStaffFixture();
    await f.directory.create(ENV_ADMIN, { email: "mod@example.com", role: "moderator" });
    await f.directory.update(ENV_ADMIN, "mod@example.com", { active: false });
    f.google.accepted("t", "mod@example.com");
    expect((await f.call("POST", `${P}/auth/google`, { credential: "t" })).status).toBe(403);
  });
});

describe("second factor", () => {
  test("enrol, confirm: the confirmation answers a session with mfa", async () => {
    const f = buildStaffFixture();
    const login = await loginEnvAdmin(f);
    const token = login.body.data?.token ?? "";
    const enrolment = await f.call("POST", `${P}/mfa/enroll`, undefined, f.bearer(token));
    expect(enrolment.status).toBe(200);
    const secret = enrolment.body.data?.secret ?? "";
    expect(secret).toMatch(/^[A-Z2-7]{32}$/);
    expect(enrolment.body.data?.otpauthUri).toStartWith("otpauth://totp/");
    // The environment admin got a row to hold the secret.
    expect(f.repository.rows.get(ENV_ADMIN)?.role).toBe("super_admin");

    const wrong = await f.call("POST", `${P}/mfa/confirm`, { code: "000000" }, f.bearer(token));
    expect(wrong.status).toBe(401);
    expect(wrong.body.error).toBe("invalid_code");

    const confirmed = await f.call("POST", `${P}/mfa/confirm`, { code: f.codeFor(secret) }, f.bearer(token));
    expect(confirmed.status).toBe(200);
    expect(confirmed.body.data?.me).toMatchObject({ mfa: true, mfaEnrolled: true });
    expect(f.tokens.verifySession(confirmed.body.data?.token ?? "")).toEqual({ email: ENV_ADMIN, mfa: true });
    expect(f.audit.actions()).toContain("mfa.enrolled");
    expect(f.audit.actions()).toContain("mfa.failure");
  });

  test("the secret is stored sealed, never in clear", async () => {
    const f = buildStaffFixture();
    const login = await loginEnvAdmin(f);
    const enrolment = await f.call("POST", `${P}/mfa/enroll`, undefined, f.bearer(login.body.data?.token ?? ""));
    const state = await f.repository.totpState(ENV_ADMIN);
    const stored = Buffer.from(state?.sealedSecret ?? []).toString("latin1");
    expect(stored).toStartWith("staff-totp");
    expect(stored).not.toContain(enrolment.body.data?.secret ?? "unreachable");
  });

  test("once enrolled, a first-factor login answers a challenge, not a session", async () => {
    const f = buildStaffFixture();
    await enrol(f);
    const res = await loginEnvAdmin(f);
    expect(res.body.data?.kind).toBe("mfa_challenge");
    expect(res.body.data?.token).toBeUndefined();
    expect(f.tokens.verifyChallenge(res.body.data?.challenge ?? "")).toBe(ENV_ADMIN);
  });

  test("challenge + right code opens an mfa session; the same code cannot be replayed", async () => {
    const f = buildStaffFixture();
    const { secret } = await enrol(f);
    const challenge = (await loginEnvAdmin(f)).body.data?.challenge ?? "";
    const code = f.codeFor(secret);
    const ok = await f.call("POST", `${P}/auth/mfa`, { challenge, code });
    expect(ok.status).toBe(200);
    expect(ok.body.data).toMatchObject({ kind: "session", me: { mfa: true } });
    const replay = await f.call("POST", `${P}/auth/mfa`, { challenge, code });
    expect(replay.status).toBe(401);
    expect(f.audit.entries.at(-1)).toMatchObject({ action: "mfa.failure", details: { reason: "replayed_code" } });
    // The next step's code is fine again.
    f.clock.advance(30_000);
    expect((await f.call("POST", `${P}/auth/mfa`, { challenge, code: f.codeFor(secret) })).status).toBe(200);
  });

  test("anti-replay holds against a code of an earlier step too", async () => {
    const f = buildStaffFixture();
    const { secret } = await enrol(f);
    const challenge = (await loginEnvAdmin(f)).body.data?.challenge ?? "";
    const older = f.codeFor(secret, -1);
    expect((await f.call("POST", `${P}/auth/mfa`, { challenge, code: f.codeFor(secret) })).status).toBe(200);
    expect((await f.call("POST", `${P}/auth/mfa`, { challenge, code: older })).status).toBe(401);
  });

  test("a wrong code is a 401 audited as mfa.failure; 5 wrong codes lock the account for 15 minutes", async () => {
    const f = buildStaffFixture();
    const { secret } = await enrol(f);
    const challenge = (await loginEnvAdmin(f)).body.data?.challenge ?? "";
    for (let i = 0; i < 5; i += 1) {
      const res = await f.call("POST", `${P}/auth/mfa`, { challenge, code: "000000" });
      expect(res.status).toBe(401);
      expect(res.body.error).toBe("invalid_code");
    }
    const locked = await f.call("POST", `${P}/auth/mfa`, { challenge, code: f.codeFor(secret) });
    expect(locked.status).toBe(429);
    expect(locked.body.error).toBe("rate_limited");
    expect(f.audit.actions().filter((a) => a === "mfa.failure")).toHaveLength(5);
    f.clock.advance(15 * 60_000 + 1000);
    const fresh = (await loginEnvAdmin(f)).body.data?.challenge ?? "";
    expect((await f.call("POST", `${P}/auth/mfa`, { challenge: fresh, code: f.codeFor(secret) })).status).toBe(200);
  });

  test("an invalid, expired or foreign challenge is refused", async () => {
    const f = buildStaffFixture();
    const { secret } = await enrol(f);
    const challenge = (await loginEnvAdmin(f)).body.data?.challenge ?? "";
    expect((await f.call("POST", `${P}/auth/mfa`, { challenge: "junk", code: f.codeFor(secret) })).body.error).toBe("invalid_challenge");
    const session = f.tokens.signSession({ email: ENV_ADMIN, mfa: false });
    expect((await f.call("POST", `${P}/auth/mfa`, { challenge: session, code: f.codeFor(secret) })).status).toBe(401);
    f.clock.advance(5 * 60_000 + 1000);
    const late = await f.call("POST", `${P}/auth/mfa`, { challenge, code: f.codeFor(secret) });
    expect(late.status).toBe(401);
    expect(late.body.error).toBe("invalid_challenge");
  });

  test("a deactivated member cannot finish a challenge", async () => {
    const f = buildStaffFixture();
    await f.directory.create(ENV_ADMIN, { email: "mod@example.com", role: "moderator" });
    f.google.accepted("g", "mod@example.com");
    const login = await f.call("POST", `${P}/auth/google`, { credential: "g" });
    const token = login.body.data?.token ?? "";
    const secret = (await f.call("POST", `${P}/mfa/enroll`, undefined, f.bearer(token))).body.data?.secret ?? "";
    await f.call("POST", `${P}/mfa/confirm`, { code: f.codeFor(secret) }, f.bearer(token));
    f.clock.advance(30_000);
    const challenge = (await f.call("POST", `${P}/auth/google`, { credential: "g" })).body.data?.challenge ?? "";
    await f.directory.update(ENV_ADMIN, "mod@example.com", { active: false });
    expect((await f.call("POST", `${P}/auth/mfa`, { challenge, code: f.codeFor(secret) })).status).toBe(401);
  });

  test("enrolling again once enrolled is a 409 and keeps the secret", async () => {
    const f = buildStaffFixture();
    const { secret, token } = await enrol(f);
    const again = await f.call("POST", `${P}/mfa/enroll`, undefined, f.bearer(token));
    expect(again.status).toBe(409);
    expect(again.body.error).toBe("already_enrolled");
    const challenge = (await loginEnvAdmin(f)).body.data?.challenge ?? "";
    expect((await f.call("POST", `${P}/auth/mfa`, { challenge, code: f.codeFor(secret) })).status).toBe(200);
  });

  test("confirm without a started enrolment is a 409", async () => {
    const f = buildStaffFixture();
    const token = (await loginEnvAdmin(f)).body.data?.token ?? "";
    const res = await f.call("POST", `${P}/mfa/confirm`, { code: "123456" }, f.bearer(token));
    expect(res.status).toBe(409);
    expect(res.body.error).toBe("no_enrollment");
  });

  test("confirm is rate-limited too: 5 wrong codes lock it", async () => {
    const f = buildStaffFixture();
    const token = (await loginEnvAdmin(f)).body.data?.token ?? "";
    const secret = (await f.call("POST", `${P}/mfa/enroll`, undefined, f.bearer(token))).body.data?.secret ?? "";
    for (let i = 0; i < 5; i += 1) await f.call("POST", `${P}/mfa/confirm`, { code: "000000" }, f.bearer(token));
    expect((await f.call("POST", `${P}/mfa/confirm`, { code: f.codeFor(secret) }, f.bearer(token))).status).toBe(429);
  });

  test("enrol and confirm need a session", async () => {
    const f = buildStaffFixture();
    expect((await f.call("POST", `${P}/mfa/enroll`)).status).toBe(401);
    expect((await f.call("POST", `${P}/mfa/confirm`, { code: "123456" })).status).toBe(401);
  });
});

describe("GET /me", () => {
  test("answers the member, their permissions and the MFA policy, even without a second factor in production", async () => {
    const f = buildStaffFixture({ env: { NODE_ENV: "production" } });
    const token = (await loginEnvAdmin(f)).body.data?.token ?? "";
    const res = await f.call("GET", `${P}/me`, undefined, f.bearer(token));
    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({
      email: ENV_ADMIN,
      role: "super_admin",
      roleLabel: "Super-administrateur",
      mfa: false,
      mfaEnrolled: false,
      mfaRequired: true,
    });
  });

  test("401 without a token", async () => {
    const f = buildStaffFixture();
    expect((await f.call("GET", `${P}/me`)).status).toBe(401);
  });
});
