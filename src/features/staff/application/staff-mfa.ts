import type { AuditLog } from "../../audit/application/ports";
import type { AttemptGuard } from "../../../shared/http/rate-limit";
import { base32Encode } from "../domain/base32";
import { generateSecret, otpauthUri, verifyTotp, type RandomSource } from "../domain/totp";
import type { ResolvedStaff, StaffDirectory } from "./staff-directory";
import type { SecretSealer, StaffRepository } from "./staff-repository";

const SEALING_CONTEXT = "staff-totp";
const SYSTEM_ACTOR = "system";

export interface StaffMfaDeps {
  readonly repository: StaffRepository;
  readonly directory: StaffDirectory;
  readonly sealer: SecretSealer;
  readonly audit: AuditLog;
  // 5 wrong codes lock the account for 15 minutes.
  readonly guard: AttemptGuard;
  readonly now: () => Date;
  readonly random?: RandomSource;
}

export type CodeCheck = { readonly kind: "valid" } | { readonly kind: "invalid" } | { readonly kind: "locked"; readonly retryAfter: number };

export type EnrollResult =
  | { readonly ok: true; readonly secret: string; readonly otpauthUri: string }
  | { readonly ok: false; readonly reason: "already_enrolled" };

export type ConfirmResult =
  | { readonly ok: true; readonly staff: ResolvedStaff }
  | { readonly ok: false; readonly reason: "invalid_code" | "no_enrollment" | "locked"; readonly retryAfter?: number };

// Binding the email as context keeps a sealed secret from being moved to
// another account's row.
const contextOf = (email: string): string => `${SEALING_CONTEXT}:${email}`;

export class StaffMfa {
  constructor(private readonly deps: StaffMfaDeps) {}

  // Checks a code against the member's secret (confirmed or not) with the
  // lockout and the anti-replay memory; audits each failure.
  async checkCode(staff: ResolvedStaff, code: string, requireEnrolled: boolean): Promise<CodeCheck> {
    const { guard, repository, sealer } = this.deps;
    const lockedFor = guard.lockedFor(staff.email);
    if (lockedFor !== null) return { kind: "locked", retryAfter: lockedFor };

    const state = await repository.totpState(staff.email);
    const secret = state?.sealedSecret != null && (!requireEnrolled || state.enrolled) ? state.sealedSecret : null;
    const step = secret === null ? null : verifyTotp(sealer.open(secret, contextOf(staff.email)), code, this.deps.now());
    const accepted = step !== null && (await repository.claimTotpStep(staff.email, step));
    if (accepted) {
      guard.forget(staff.email);
      return { kind: "valid" };
    }
    guard.recordFailure(staff.email);
    await this.deps.audit.record({
      actor: staff.email,
      action: "mfa.failure",
      targetType: "staff",
      targetId: staff.email,
      details: { reason: step === null ? "wrong_code" : "replayed_code" },
    });
    return { kind: "invalid" };
  }

  async enroll(staff: ResolvedStaff): Promise<EnrollResult> {
    const { repository, sealer } = this.deps;
    if (staff.fromEnvironment) await repository.ensureRow(staff.email, "super_admin", SYSTEM_ACTOR);
    const secret = generateSecret(this.deps.random);
    const stored = await repository.storeUnconfirmedSecret(staff.email, sealer.seal(secret, contextOf(staff.email)));
    if (!stored) return { ok: false, reason: "already_enrolled" };
    return { ok: true, secret: base32Encode(secret), otpauthUri: otpauthUri(staff.email, secret) };
  }

  async confirm(staff: ResolvedStaff, code: string): Promise<ConfirmResult> {
    const state = await this.deps.repository.totpState(staff.email);
    if (!state || state.sealedSecret === null || state.enrolled) return { ok: false, reason: "no_enrollment" };
    const check = await this.checkCode(staff, code, false);
    if (check.kind === "locked") return { ok: false, reason: "locked", retryAfter: check.retryAfter };
    if (check.kind === "invalid") return { ok: false, reason: "invalid_code" };
    await this.deps.repository.confirmEnrollment(staff.email);
    await this.deps.audit.record({ actor: staff.email, action: "mfa.enrolled", targetType: "staff", targetId: staff.email });
    const refreshed = await this.deps.directory.resolve(staff.email);
    return { ok: true, staff: refreshed ?? { ...staff, mfaEnrolled: true } };
  }
}
