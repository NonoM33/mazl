import { LEGAL_PAGES, LEGAL_REDIRECTS, isLandingPath, wwwHost } from "./site-rules";

// Whether this process also serves the website (the client under /app, the
// landing and the legal pages), or only the API. Default: it does, so nothing
// changes before the website container takes over mazl.app
// (docs/web/adr/W01-hebergement.md, 2026-10-24 decoupling; docs/deploy/README.md).

const OFF_VALUES = new Set(["false", "0", "no", "off"]);

export function websiteServed(env: Record<string, string | undefined> = process.env): boolean {
  return !OFF_VALUES.has((env.SERVE_WEBSITE ?? "").trim().toLowerCase());
}

// What the API host keeps serving for itself once the website has moved: the
// document drop link (verify), the staff console's assets and the old admin,
// with the stylesheet and the icon the drop page uses.
export const API_HOST_STATIC_FILES: ReadonlySet<string> = new Set([
  "/verify.html", "/verify.js", "/admin-escape.js", "/admin-login.html", "/admin-login.js", "/admin.html", "/style.css", "/favicon.svg",
]);

const MOVED_PAGES: ReadonlySet<string> = new Set([
  "/",
  "/index.html",
  ...LEGAL_PAGES.flatMap((page) => [`/${page}`, `/${page}.html`]),
  ...Object.keys(LEGAL_REDIRECTS),
]);

const PREFIX = "/app";

// Old links to the website made against the API host (a bookmarked /app, the
// showcase files under /l/, the legal pages cited by the stores) go to the website host, path and query kept.
// Without WEB_ORIGIN there is nowhere to send them: the answer is a plain 404.
export function createWebsiteMoved(webOrigin: string | null) {
  const origin = webOrigin === null ? null : new URL(webOrigin).origin;

  function handle(req: Request): Response | null {
    if (origin === null || (req.method !== "GET" && req.method !== "HEAD")) return null;
    const url = new URL(req.url);
    // www.<site host> was only ever a redirect to the site host (web-app.ts).
    if (req.headers.get("host") === wwwHost(new URL(origin).host)) return Response.redirect(`${origin}${url.pathname}${url.search}`, 301);
    const underApp = url.pathname === PREFIX || url.pathname.startsWith(`${PREFIX}/`);
    if (!underApp && !isLandingPath(url.pathname) && !MOVED_PAGES.has(url.pathname)) return null;
    return Response.redirect(`${origin}${url.pathname}${url.search}`, url.pathname === "/" ? 302 : 301);
  }

  return { handle };
}
