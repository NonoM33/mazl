import type { Env, Hono } from "hono";

/**
 * /admin used to be the old sign-in page (violet gradient). The staff console
 * at /console is the current one, so /admin leads there. The old console keeps
 * its own sign-in at /admin/connexion (reached from the console sidebar and
 * from its pages) for events, campaigns and subscriptions until they move.
 */
export function registerAdminEntryRoutes<E extends Env>(app: Hono<E>): void {
  app.get("/admin", (c) => c.redirect("/console", 302));
  app.get("/admin/", (c) => c.redirect("/console", 302));
  app.get("/admin/connexion", () => new Response(Bun.file("./public/admin-login.html"), { headers: { "Content-Type": "text/html; charset=utf-8" } }));
}
