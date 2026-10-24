import type { AuditLog } from "../../audit/application/ports";
import type { GoogleVerifier } from "../../auth/google-token";
import type { AttemptGuard } from "../../../shared/http/rate-limit";
import { normalizeStaffEmail } from "../domain/email";
import type { TokenSigner } from "../domain/session-token";
import type { ResolvedStaff, StaffDirectory } from "./staff-directory";
import type { StaffMfa } from "./staff-mfa";

export interface StaffAuthDeps {
  readonly directory: StaffDirectory;
  readonly mfa: StaffMfa;
  readonly tokens: TokenSigner;
  readonly google: GoogleVerifier;
  readonly audit: AuditLog;
  // ADMIN_EMAIL / ADMIN_PASSWORD: the only password login there is.
  readonly adminEmail: string | undefined;
  readonly adminPassword: string | undefined;
  readonly secretsMatch: (given: string, expected: string) => boolean;
  // 5 failures / 15 minutes per client address.
  readonly passwordGuard: AttemptGuard;
}

export type LoginOutcome =
  | { readonly ok: true; readonly kind: "session"; readonly token: string; readonly staff: ResolvedStaff }
  | { readonly ok: true; readonly kind: "mfa_challenge"; readonly challenge: string }
  | { readonly ok: false; readonly reason: "invalid_credentials" | "invalid_google_token" | "not_staff" | "not_configured" }
  | { readonly ok: false; readonly reason: "locked"; readonly retryAfter: number };

export type MfaLoginOutcome =
  | { readonly ok: true; readonly token: string; readonly staff: ResolvedStaff }
  | { readonly ok: false; readonly reason: "invalid_challenge" | "invalid_code" }
  | { readonly ok: false; readonly reason: "locked"; readonly retryAfter: number };

const UNVERIFIED_GOOGLE_ACTOR = "google:unverified";

export class StaffAuth {
  constructor(private readonly deps: StaffAuthDeps) {}

  async loginWithPassword(email: string, password: string, address: string): Promise<LoginOutcome> {
    const { adminEmail, adminPassword, passwordGuard, secretsMatch } = this.deps;
    if (!adminEmail || !adminPassword) return { ok: false, reason: "not_configured" };
    const lockedFor = passwordGuard.lockedFor(address);
    if (lockedFor !== null) return { ok: false, reason: "locked", retryAfter: lockedFor };

    const given = normalizeStaffEmail(email);
    // Both comparisons always run: the answer does not tell which one failed.
    const emailMatches = secretsMatch(given, normalizeStaffEmail(adminEmail));
    const passwordMatches = secretsMatch(password, adminPassword);
    if (!emailMatches || !passwordMatches) {
      passwordGuard.recordFailure(address);
      await this.recordFailure(given, "password", "wrong_credentials");
      return { ok: false, reason: "invalid_credentials" };
    }
    passwordGuard.forget(address);
    return this.afterFirstFactor(normalizeStaffEmail(adminEmail), "password");
  }

  async loginWithGoogle(credential: string): Promise<LoginOutcome> {
    const identity = await this.deps.google.verifyIdToken(credential);
    if (!identity) {
      await this.recordFailure(UNVERIFIED_GOOGLE_ACTOR, "google", "invalid_token");
      return { ok: false, reason: "invalid_google_token" };
    }
    return this.afterFirstFactor(normalizeStaffEmail(identity.email), "google");
  }

  async loginWithMfa(challenge: string, code: string): Promise<MfaLoginOutcome> {
    const email = this.deps.tokens.verifyChallenge(challenge);
    const staff = email === null ? null : await this.deps.directory.resolve(email);
    if (!staff) return { ok: false, reason: "invalid_challenge" };
    const check = await this.deps.mfa.checkCode(staff, code, true);
    if (check.kind === "locked") return { ok: false, reason: "locked", retryAfter: check.retryAfter };
    if (check.kind === "invalid") return { ok: false, reason: "invalid_code" };
    await this.recordSuccess(staff.email, "mfa");
    return { ok: true, token: this.deps.tokens.signSession({ email: staff.email, mfa: true }), staff };
  }

  // A new session for a member who just proved a second factor (enrolment).
  sessionFor(staff: ResolvedStaff, mfa: boolean): string {
    return this.deps.tokens.signSession({ email: staff.email, mfa });
  }

  private async afterFirstFactor(email: string, method: "password" | "google"): Promise<LoginOutcome> {
    const staff = await this.deps.directory.resolve(email);
    if (!staff) {
      await this.recordFailure(email, method, "not_staff");
      return { ok: false, reason: "not_staff" };
    }
    if (staff.mfaEnrolled) return { ok: true, kind: "mfa_challenge", challenge: this.deps.tokens.signChallenge(staff.email) };
    await this.recordSuccess(staff.email, method);
    return { ok: true, kind: "session", token: this.sessionFor(staff, false), staff };
  }

  private async recordFailure(actor: string, method: string, reason: string): Promise<void> {
    await this.deps.audit.record({
      actor,
      action: "auth.failure",
      targetType: "staff",
      targetId: actor === UNVERIFIED_GOOGLE_ACTOR ? null : actor,
      details: { method, reason },
    });
  }

  private async recordSuccess(actor: string, method: string): Promise<void> {
    await this.deps.audit.record({ actor, action: "auth.success", targetType: "staff", targetId: actor, details: { method } });
  }
}
