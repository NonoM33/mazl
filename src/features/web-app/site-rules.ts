// Which paths the website host (mazl.app) serves itself and which it sends to
// the API host. One definition for the API process (web-app.ts) and for the
// website container, so the two cannot drift
// (docs/web/adr/W01-hebergement.md).

// Legal pages: static, without any script, with their stylesheet and icon.
export const LEGAL_PAGES = ["cgu", "cgv", "confidentialite", "mentions-legales", "cookies"] as const;
// style.css: the document drop page and the old admin; legal.css: the legal pages (scripts/legal).
export const SITE_STATIC_FILES = ["style.css", "legal.css", "favicon.svg"] as const;
export const LEGAL_REDIRECTS: Readonly<Record<string, string>> = { "/terms": "/cgu", "/privacy": "/confidentialite" };

// Pages with their own scripts and a looser CSP (the waitlist document link,
// the staff console, the old admin) never share the client's origin: on the
// site host they redirect to the API host, query kept (security review M5).
export const API_HOST_PREFIXES = ["verify", "admin", "console"] as const;
export const API_HOST_ONLY = new RegExp(`^/(?:${API_HOST_PREFIXES.join("|")})(?:$|[/.-])`);

// Paths served by the API process whatever the host.
export const PROXIED_PREFIXES = ["/api/", "/ws", "/media/"] as const;

export const WEB_HOST_PAGES: ReadonlySet<string> = new Set([
  ...LEGAL_PAGES.flatMap((page) => [`/${page}`, `/${page}.html`]),
  ...Object.keys(LEGAL_REDIRECTS),
  ...SITE_STATIC_FILES.map((file) => `/${file}`),
]);

export const apiHostOnly = (path: string): boolean => API_HOST_ONLY.test(path);

// The showcase (landing/dist): index.html at the root of the site host, every
// other file under /l/ (a missing one is a 404, never the page; the .gz copies
// are only served as the Content-Encoding of their script or stylesheet).
export const LANDING_PREFIX = "/l/";
export const isLandingPath = (path: string): boolean => path.startsWith(LANDING_PREFIX);

// www.<site host> only redirects to the site host, path and query kept.
export const wwwHost = (host: string): string => `www.${host}`;
