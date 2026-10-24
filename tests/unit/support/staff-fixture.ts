import { Hono } from "hono";
import type { GoogleIdentity, GoogleVerifier } from "../../../src/features/auth/google-token";
import { createAttemptGuard } from "../../../src/shared/http/rate-limit";
import { isMfaRequired } from "../../../src/features/staff/application/mfa-policy";
import { StaffAuth } from "../../../src/features/staff/application/staff-auth";
import { StaffDirectory } from "../../../src/features/staff/application/staff-directory";
import { StaffMfa } from "../../../src/features/staff/application/staff-mfa";
import { createTokenSigner } from "../../../src/features/staff/domain/session-token";
import { base32Decode } from "../../../src/features/staff/domain/base32";
import { totpAt } from "../../../src/features/staff/domain/totp";
import { createAuthenticate, createRequirePermission } from "../../../src/features/staff/presentation/require-permission";
import { registerStaffRoutes } from "../../../src/features/staff/presentation/staff.routes";
import { MemoryAuditLog } from "./memory-audit-log";
import { fakeSealer, MemoryStaffRepository } from "./memory-staff-repository";

export interface Data {
  kind?: string;
  token?: string;
  challenge?: string;
  secret?: string;
  otpauthUri?: string;
  email?: string;
  role?: string;
  roleLabel?: string;
  permissions?: string[];
  mfa?: boolean;
  mfaEnrolled?: boolean;
  mfaRequired?: boolean;
  active?: boolean;
  fromEnvironment?: boolean;
  me?: Data;
}

export interface Body {
  success: boolean;
  error?: string;
  message?: string;
  data?: Data;
}

export const ENV_ADMIN = "owner@example.com";
export const ENV_PASSWORD = "correct horse battery staple";
export const KEY = "fixture-staff-key";

export class FakeClock {
  constructor(public current = new Date("2026-10-24T10:00:00.000Z")) {}
  now = (): Date => this.current;
  advance(ms: number): void {
    this.current = new Date(this.current.getTime() + ms);
  }
}

export class FakeGoogle implements GoogleVerifier {
  identities = new Map<string, GoogleIdentity>();
  accepted(token: string, email: string): void {
    this.identities.set(token, { sub: `sub-${token}`, email });
  }
  async verifyIdToken(idToken: string) {
    return this.identities.get(idToken) ?? null;
  }
  async verifyAccessToken() {
    return null;
  }
}

export interface FixtureOptions {
  readonly env?: Record<string, string | undefined>;
  readonly environmentAdmins?: readonly string[];
}

// The whole feature wired with in-memory ports. `clock` drives both the TOTP
// verification and the token lifetimes.
export function buildStaffFixture(options: FixtureOptions = {}) {
  const env = { ADMIN_EMAIL: ENV_ADMIN, ADMIN_PASSWORD: ENV_PASSWORD, NODE_ENV: "test", ...options.env };
  const clock = new FakeClock();
  const repository = new MemoryStaffRepository();
  const audit = new MemoryAuditLog(clock.now);
  const google = new FakeGoogle();
  const tokens = createTokenSigner(KEY, clock.now);
  const directory = new StaffDirectory({ repository, audit, environmentAdmins: options.environmentAdmins ?? [ENV_ADMIN] });
  const window = { maxFailures: 5, windowMs: 15 * 60_000, now: () => clock.now().getTime() };
  const mfa = new StaffMfa({
    repository,
    directory,
    sealer: fakeSealer,
    audit,
    guard: createAttemptGuard(window),
    now: clock.now,
    random: (size) => new Uint8Array(size).fill(9),
  });
  const auth = new StaffAuth({
    directory,
    mfa,
    tokens,
    google,
    audit,
    adminEmail: env.ADMIN_EMAIL,
    adminPassword: env.ADMIN_PASSWORD,
    secretsMatch: (a, b) => a === b,
    passwordGuard: createAttemptGuard(window),
  });
  const mfaRequired = isMfaRequired(env);
  const guardDeps = {
    resolveStaff: (email: string) => directory.resolve(email),
    verifySession: tokens.verifySession,
    mfaRequired,
    touch: (email: string) => repository.touch(email),
    isProduction: env.NODE_ENV === "production",
    scriptAccess: { email: ENV_ADMIN, password: ENV_PASSWORD, secretsMatch: (a: string, b: string) => a === b },
    now: () => clock.now().getTime(),
  };
  const requirePermission = createRequirePermission(guardDeps);
  const authenticate = createAuthenticate(guardDeps);
  const app = new Hono();
  registerStaffRoutes(app, { auth, mfa, directory, requirePermission, authenticate, mfaRequired });

  const call = async (method: string, path: string, body?: unknown, headers: Record<string, string> = {}) => {
    const response = await app.request(path, {
      method,
      headers: { "content-type": "application/json", "x-forwarded-for": "203.0.113.7", ...headers },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
    return { status: response.status, headers: response.headers, body: (await response.json()) as Body };
  };
  const bearer = (token: string) => ({ authorization: `Bearer ${token}` });
  // Code an authenticator app would show for a base32 secret at `clock`.
  const codeFor = (base32Secret: string, offsetSteps = 0) => totpAt(base32Decode(base32Secret), clock.now().getTime() / 1000 + offsetSteps * 30);

  return { env, clock, repository, audit, google, tokens, directory, mfa, auth, app, call, bearer, codeFor, mfaRequired };
}

export type StaffFixture = ReturnType<typeof buildStaffFixture>;
