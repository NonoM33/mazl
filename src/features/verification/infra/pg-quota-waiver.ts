import type { Sql } from "postgres";
import { isAdminTestAccount } from "../../admin/admin.emails";
import type { QuotaWaiver } from "../application/ports";
import { isQuotaWaived } from "../domain/quota-waiver";

// Lifts the daily limit for an administrator account until [end].
export class PgQuotaWaiver implements QuotaWaiver {
  constructor(
    private readonly sql: Sql,
    private readonly end: Date | null,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async waived(userId: number): Promise<boolean> {
    if (this.end === null) return false;
    const [user] = await this.sql<{ id: number; email: string }[]>`SELECT id, email FROM users WHERE id = ${userId}`;
    return isQuotaWaived(user !== undefined && isAdminTestAccount(user), this.now(), this.end);
  }
}
