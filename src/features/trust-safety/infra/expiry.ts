import type { Sql } from "postgres";
import type { AccountEnforcement } from "../application/ports";
import { num } from "./mappers";

// A suspension that ran out re-enables the account, unless another suspension
// or a ban still stands. Each expired suspension is processed once
// (expiry_processed_at), so an account disabled for another reason later is
// never re-enabled by an old sanction. Idempotent. Returns the accounts re-enabled.
export async function reactivateExpiredSuspensions(sql: Sql, enforcement: Pick<AccountEnforcement, "enable">): Promise<number> {
  const due = await sql`
    SELECT DISTINCT user_id FROM member_sanctions
    WHERE kind = 'suspension' AND revoked_at IS NULL AND ends_at IS NOT NULL AND ends_at <= now() AND expiry_processed_at IS NULL
  `;
  let reactivated = 0;
  for (const row of due) {
    const userId = num(row.user_id);
    const blocked = await sql`
      SELECT 1 FROM member_sanctions
      WHERE user_id = ${userId} AND kind IN ('suspension', 'ban') AND revoked_at IS NULL
        AND starts_at <= now() AND (ends_at IS NULL OR ends_at > now())
      LIMIT 1
    `;
    if (blocked.length === 0) {
      await enforcement.enable(userId);
      reactivated += 1;
    }
    await sql`
      UPDATE member_sanctions SET expiry_processed_at = now()
      WHERE user_id = ${userId} AND kind = 'suspension' AND ends_at <= now() AND expiry_processed_at IS NULL
    `;
  }
  return reactivated;
}

export function startSanctionSweeper(run: () => Promise<number>, intervalMs: number): () => void {
  let running = false;
  const timer = setInterval(() => {
    if (running) return;
    running = true;
    run()
      .catch((error: unknown) => console.error("trust-safety: sanction sweep failed", error instanceof Error ? error.name : "unknown"))
      .finally(() => {
        running = false;
      });
  }, intervalMs);
  return () => clearInterval(timer);
}
