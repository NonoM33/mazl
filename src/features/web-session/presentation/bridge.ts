import type { WebSessionConfig } from "../application/config";
import type { TokenSigner } from "../application/ports";
import type { SessionService } from "../application/session-service";
import { COOKIE_NAME, SESSION_HEADER, WEB_CLIENT_HEADER, readCookie } from "./cookie";
import { hostAllowed, originAllowed } from "./origin";

const SAFE_METHODS = new Set(["GET", "HEAD", "OPTIONS"]);
export const BRIDGE_TOKEN_TTL_SECONDS = 60;
// Audience of the bridge's tokens: routes kept for the phone refuse it.
export const BRIDGE_AUDIENCE = "web-bridge";

export interface BridgeDeps {
  readonly sessions: SessionService;
  readonly config: WebSessionConfig;
  readonly sign: TokenSigner;
}

// Runs before Hono. Turns a web session cookie into a 60-second JWT so every
// existing route and requireAuth work unchanged. The cookie only counts when
// the request also says it comes from the site (X-Mazl-Web) and, for unsafe
// methods, carries the site's own Origin.
export function createBridge(deps: BridgeDeps): (req: Request) => Promise<void> {
  return async (req) => {
    req.headers.delete(SESSION_HEADER);
    if (!isCandidate(req, deps.config)) return;
    const token = readCookie(req.headers.get("cookie"), COOKIE_NAME);
    if (!token) return;
    const live = await deps.sessions.resolve(token);
    if (!live) return;
    req.headers.set("authorization", `Bearer ${deps.sign(live.member, BRIDGE_TOKEN_TTL_SECONDS, { aud: BRIDGE_AUDIENCE, sid: live.session.id })}`);
    req.headers.set(SESSION_HEADER, live.session.id);
  };
}

function isCandidate(req: Request, config: WebSessionConfig): boolean {
  if (!new URL(req.url).pathname.startsWith("/api/")) return false;
  if (req.headers.has("authorization")) return false;
  if (req.headers.get(WEB_CLIENT_HEADER) !== "1") return false;
  const host = req.headers.get("host");
  if (!hostAllowed(config, host)) return false;
  if (SAFE_METHODS.has(req.method)) return true;
  return originAllowed(config, req.headers.get("origin"), host);
}
