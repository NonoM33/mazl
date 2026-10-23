import type { Hono } from "hono";
import { z } from "zod";
import { sql, upsertWaitlistAndGetVerification } from "../../../db";
import type { AppVariables } from "../../../shared/http/middleware";
import type { DocumentsModule } from "../composition";

const tokenBody = z.object({ email: z.email() });
const backdateBody = z.object({ days: z.number().int().min(1).max(3650) });

// Test helpers, not mounted in production: the integration tests cannot read
// the emailed token, nor wait 30 days.
export function registerDocumentsDevRoutes(
  app: Hono<{ Variables: AppVariables }>,
  documents: DocumentsModule,
  isProduction: boolean,
): void {
  if (isProduction) return;

  app.post("/api/dev/documents/verification-token", async (c) => {
    const body = tokenBody.safeParse(await c.req.json().catch(() => null));
    if (!body.success) return c.json({ success: false, error: "email required" }, 400);
    const entry = await upsertWaitlistAndGetVerification(body.data.email);
    return c.json({ success: true, waitlist_id: entry.id, token: entry.verificationToken });
  });

  app.post("/api/dev/documents/:id/backdate", async (c) => {
    const id = Number.parseInt(c.req.param("id"), 10);
    const body = backdateBody.safeParse(await c.req.json().catch(() => null));
    if (!Number.isInteger(id) || !body.success) return c.json({ success: false, error: "bad request" }, 400);
    await sql`UPDATE documents SET created_at = NOW() - make_interval(days => ${body.data.days}) WHERE id = ${id}`;
    return c.json({ success: true });
  });

  app.post("/api/dev/documents/purge-sweep", async (c) => {
    return c.json({ success: true, ...(await documents.purger.sweep()) });
  });
}
