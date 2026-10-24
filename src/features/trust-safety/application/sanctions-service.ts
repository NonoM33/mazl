import type { SanctionDto, SanctionInput } from "../presentation/dto";
import { notFound, TrustSafetyError } from "./errors";
import type { SanctionEffects } from "./effects";
import type { Clock, MembersRepository, RandomBytes, SanctionsRepository } from "./ports";
import { prepareSanction } from "./sanction-factory";

export interface IssuedSanction {
  readonly sanction: SanctionDto;
  // Shown once to the staff member; only its SHA-256 is stored.
  readonly appealCode: string;
}

export class SanctionsService {
  constructor(
    private readonly sanctions: SanctionsRepository,
    private readonly members: Pick<MembersRepository, "profile">,
    private readonly effects: SanctionEffects,
    private readonly clock: Clock,
    private readonly random: RandomBytes,
  ) {}

  // A sanction decided outside a report, on the moderator's own initiative.
  async issue(memberId: number, input: SanctionInput, note: string, staffEmail: string): Promise<IssuedSanction> {
    if (!(await this.members.profile(memberId))) throw notFound("Membre");
    const prepared = prepareSanction({
      memberId,
      input,
      decidedBy: staffEmail,
      reportId: null,
      note,
      origin: "staff_initiative",
      now: this.clock(),
      random: this.random,
    });
    const sanction = await this.sanctions.insert(prepared.sanction);
    await this.effects.issued(sanction, prepared.appealCode);
    return { sanction, appealCode: prepared.appealCode };
  }

  async revoke(id: number, note: string, staffEmail: string): Promise<SanctionDto> {
    const result = await this.sanctions.revoke(id, staffEmail, note);
    if (result.kind === "not_found") throw notFound("Sanction");
    if (result.kind === "already_revoked") throw new TrustSafetyError("already_revoked", 409, "Cette sanction est déjà levée");
    await this.effects.lifted(result.sanction);
    return result.sanction;
  }
}
