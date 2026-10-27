import type { CreditsGateway } from "../../credits/application/ports";
import type { BoostRecord } from "../../engagement/boost.routes";
import type { BoostLauncher, LaunchOutcome } from "../application/ports";

export interface BoostStorage {
  getActive(userId: number): Promise<BoostRecord | null>;
  activate(userId: number, durationMinutes: number): Promise<BoostRecord>;
}

// Starts a programmed Boost the way POST /api/boost/activate does: the credit is
// taken first (once per running Boost) and given back if the Boost cannot start.
export class CreditsBoostLauncher implements BoostLauncher {
  constructor(
    private readonly credits: CreditsGateway,
    private readonly boosts: BoostStorage,
    private readonly minutes: number,
  ) {}

  async available(userId: number): Promise<number> {
    return (await this.credits.credits(userId)).boost.available;
  }

  async launch(userId: number): Promise<LaunchOutcome> {
    if ((await this.boosts.getActive(userId)) !== null) return "already_active";
    const spent = await this.credits.spend(userId, "boost", undefined, { kind: "once_within", minutes: this.minutes });
    if (!spent.ok) return spent.reason === "already_spent" ? "already_active" : "no_credit";
    try {
      await this.boosts.activate(userId, this.minutes);
    } catch (error: unknown) {
      await this.credits.cancelSpend(userId, spent.spendId).catch(() => undefined);
      throw error;
    }
    return "started";
  }
}
