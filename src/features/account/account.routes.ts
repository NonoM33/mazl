import type { Hono } from "hono";
import { z } from "zod";
import type { Sql } from "postgres";
import { deleteUserCompletely } from "../../db";
import type { UserErasure } from "../admin/admin.erasure";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";

// Self-service account deletion: GDPR right to erasure, and required by the
// App Store. The app has always called DELETE /api/users/me.

const bodySchema = z.object({ reason: z.string().trim().max(500).optional() }).passthrough();

export async function ensureAccountSchema(sql: Sql): Promise<void> {
  // Why members leave, kept WITHOUT any identifier: no user id, no email.
  await sql`
    CREATE TABLE IF NOT EXISTS account_deletion_feedback (
      id SERIAL PRIMARY KEY,
      reason VARCHAR(500) NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )
  `;
}

export function registerAccountRoutes(app: Hono<{ Variables: AppVariables }>, sql: Sql, erasure: UserErasure): void {
  app.delete("/api/users/me", requireAuth, async (c) => {
    const userId = c.get("userId");
    const parsed = bodySchema.safeParse(await c.req.json().catch(() => ({})));
    const reason = parsed.success ? parsed.data.reason : undefined;

    const [exists] = await sql`SELECT 1 FROM users WHERE id = ${userId}`;
    if (!exists) return c.json({ success: false, error: "Compte introuvable" }, 404);

    try {
      await erasure.around(userId, () => deleteUserCompletely(userId, "self-service"));
      if (reason) await sql`INSERT INTO account_deletion_feedback (reason) VALUES (${reason})`;
      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Self account deletion failed:", error instanceof Error ? error.name : "unknown");
      return c.json({ success: false, error: "La suppression a échoué, réessayez." }, 500);
    }
  });
}
