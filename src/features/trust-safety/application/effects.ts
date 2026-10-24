import type { SanctionDto } from "../presentation/dto";
import type { AccountEnforcement, MemberNotifier, SanctionsRepository } from "./ports";

// What a sanction does to the account, and the notice to the member. Runs after
// the transaction committed.
export class SanctionEffects {
  constructor(
    private readonly enforcement: AccountEnforcement,
    private readonly sanctions: Pick<SanctionsRepository, "hasActiveBlocking">,
    private readonly notifier: MemberNotifier,
  ) {}

  async issued(sanction: SanctionDto, appealCode: string): Promise<void> {
    if (sanction.kind === "suspension") {
      await this.enforcement.disable(sanction.memberId);
      await this.enforcement.onDisabled(sanction.memberId);
    } else if (sanction.kind === "ban") {
      await this.enforcement.ban(sanction.memberId, `${sanction.statement.reference}: ${sanction.ground}`, sanction.decidedBy);
      await this.enforcement.onDisabled(sanction.memberId);
    }
    await this.notifySafely(() => this.notifier.sanctionIssued(sanction.memberId, sanction.statement, appealCode));
  }

  // A revoked suspension or ban re-enables the account unless another one stands.
  async lifted(sanction: SanctionDto): Promise<void> {
    if (sanction.kind !== "suspension" && sanction.kind !== "ban") return;
    if (await this.sanctions.hasActiveBlocking(sanction.memberId)) return;
    await this.enforcement.enable(sanction.memberId);
  }

  async notifySafely(send: () => Promise<void>): Promise<void> {
    try {
      await send();
    } catch (error) {
      // A failed notice never undoes a decision. No member data in the log.
      console.error("trust-safety: member notice failed", error instanceof Error ? error.name : "unknown");
    }
  }
}
