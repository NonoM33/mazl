import { timingSafeEqual } from "node:crypto";
import { isAppealWindowOpen } from "../domain/appeal-window";
import type { AppealStatus } from "../domain/types";
import type { AppealDto } from "../presentation/dto";
import { notFound, TrustSafetyError } from "./errors";
import type { SanctionEffects } from "./effects";
import type { AppealsRepository, Clock, MemberNotifier, SanctionsRepository } from "./ports";
import { hashAppealCode } from "./sanction-factory";

export type PublicAppealResult = "accepted" | "ignored" | "expired" | "duplicate";

// Compared for every request, even when the reference is unknown, so the time
// taken does not tell the two cases apart.
const DUMMY_HASH = hashAppealCode("00000000-0000");

function sameHash(a: string, b: string): boolean {
  const left = Buffer.from(a, "utf8");
  const right = Buffer.from(b, "utf8");
  return left.length === right.length && timingSafeEqual(left, right);
}

export class AppealsService {
  constructor(
    private readonly appeals: AppealsRepository,
    private readonly sanctions: SanctionsRepository,
    private readonly effects: SanctionEffects,
    private readonly notifier: MemberNotifier,
    private readonly clock: Clock,
  ) {}

  list(status: AppealStatus | undefined, limit: number, offset: number): ReturnType<AppealsRepository["list"]> {
    return this.appeals.list(status, limit, offset);
  }

  // "ignored" covers an unknown reference and a wrong code alike: the caller
  // answers 202 for both, so the route is no oracle on references.
  async submit(input: { reference: string; appealCode: string; message: string }): Promise<PublicAppealResult> {
    const found = await this.sanctions.findByReference(input.reference);
    const valid = sameHash(hashAppealCode(input.appealCode), found ? found.appealCodeHash : DUMMY_HASH);
    if (!found || !valid) return "ignored";
    const issuedAt = new Date(found.sanction.statement.issuedAt);
    if (!isAppealWindowOpen(issuedAt, this.clock())) return "expired";
    const created = await this.appeals.create({
      sanctionId: found.sanction.id,
      memberId: found.sanction.memberId,
      message: input.message,
    });
    return created ? "accepted" : "duplicate";
  }

  async decide(id: number, outcome: "upheld" | "overturned", note: string, staffEmail: string): Promise<AppealDto> {
    const appeal = await this.appeals.find(id);
    if (!appeal) throw notFound("Contestation");
    if (appeal.sanctionDecidedBy.toLowerCase() === staffEmail.toLowerCase()) {
      throw new TrustSafetyError("same_decider", 409, "Une contestation doit être décidée par une autre personne que l'auteur de la sanction");
    }
    const result = await this.appeals.decide({ id, outcome, by: staffEmail, note });
    if (result.kind === "not_found") throw notFound("Contestation");
    if (result.kind === "already_decided") throw new TrustSafetyError("already_decided", 409, "Cette contestation est déjà décidée");
    if (outcome === "overturned") await this.effects.lifted(result.sanction);
    await this.effects.notifySafely(() =>
      this.notifier.appealDecided(result.appeal.memberId, {
        appealId: result.appeal.id,
        reference: result.sanction.statement.reference,
        outcome,
      }),
    );
    return result.appeal;
  }
}
