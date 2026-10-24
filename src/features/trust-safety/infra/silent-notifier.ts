import type { AppealOutcomeNotice, MemberNotifier } from "../application/ports";
import type { StatementOfReasons } from "../domain/types";

// Sends nothing: no e-mail, no push. Logs the event without any member data
// (a statement holds facts about a person). The real channel is plugged in
// later, with the member's contact details taken at that moment.
export class SilentNotifier implements MemberNotifier {
  async sanctionIssued(_userId: number, statement: StatementOfReasons): Promise<void> {
    console.info(`trust-safety: sanction issued (${statement.decision}), notice not sent`);
  }

  async appealDecided(_userId: number, notice: AppealOutcomeNotice): Promise<void> {
    console.info(`trust-safety: appeal decided (${notice.outcome}), notice not sent`);
  }
}
