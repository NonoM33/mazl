// Which paths the website host (mazl.app) serves itself and which it sends to
// the API host. One definition for the API process (web-app.ts) and for the
// website container, so the two cannot drift
// (docs/web/adr/W01-hebergement.md).

// Legal pages: static, without any script, with their stylesheet and icon.
export const LEGAL_PAGES = ["cgu", "cgv", "confidentialite"] as const;
export const SITE_STATIC_FILES = ["style.css", "favicon.svg"] as const;
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
