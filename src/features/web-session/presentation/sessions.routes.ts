import type { Hono } from "hono";
import { requireAuth, type AppVariables } from "../../../shared/http/middleware";
import type { WebSession } from "../domain/session";
import type { WebSessionModule } from "../web-session.module";
import { SESSION_HEADER, clearedCookie } from "./cookie";

const iso = (date: Date): string => date.toISOString();

function listed(session: WebSession, currentId: string | undefined) {
  return {
    id: session.id,
    browser: session.browserLabel,
    method: session.method,
    created_at: iso(session.createdAt),
    last_seen_at: iso(session.lastSeenAt),
    expires_at: iso(session.expiresAt),
    current: session.id === currentId,
  };
}

export function registerSessionRoutes(app: Hono<{ Variables: AppVariables }>, module: WebSessionModule): void {
  const noSession = { success: false, error: "no_web_session" } as const;

  app.get("/api/web/session", async (c) => {
    const id = c.req.header(SESSION_HEADER);
    const live = id ? await module.sessions.get(id) : null;
    if (!live) return c.json(noSession, 401);
    const { session, member } = live;
    return c.json({
      success: true,
      session: {
        id: session.id,
        browser: session.browserLabel,
        method: session.method,
        created_at: iso(session.createdAt),
        last_seen_at: iso(session.lastSeenAt),
        idle_expires_at: iso(session.idleExpiresAt),
        expires_at: iso(session.expiresAt),
      },
      user: { id: member.id, name: member.name, email: member.email },
    });
  });

  app.post("/api/web/socket-ticket", async (c) => {
    const id = c.req.header(SESSION_HEADER);
    const live = id ? await module.sessions.get(id) : null;
    if (!live) return c.json(noSession, 401);
    const ticket = module.sockets.issue(live.session.id, live.member);
    c.header("Cache-Control", "no-store");
    return c.json({ success: true, token: ticket.token, expires_at: iso(ticket.expiresAt) });
  });

  app.get("/api/web/sessions", requireAuth, async (c) => {
    const current = c.req.header(SESSION_HEADER);
    const sessions = await module.sessions.list(c.get("userId"));
    return c.json({ success: true, sessions: sessions.map((session) => listed(session, current)) });
  });

  app.delete("/api/web/sessions/:id", requireAuth, async (c) => {
    const id = c.req.param("id");
    const revoked = await module.sessions.revoke(c.get("userId"), id);
    if (!revoked) return c.json({ success: false, error: "not_found" }, 404);
    if (id === c.req.header(SESSION_HEADER)) c.header("Set-Cookie", clearedCookie());
    return c.json({ success: true });
  });

  app.delete("/api/web/sessions", requireAuth, async (c) => {
    const current = c.req.header(SESSION_HEADER);
    const others = c.req.query("others") === "true";
    await module.sessions.revokeAll(c.get("userId"), others ? (current ?? null) : null);
    if (!others && current) c.header("Set-Cookie", clearedCookie());
    return c.json({ success: true });
  });
}
