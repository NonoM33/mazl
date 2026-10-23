// Where a server-side fetch is allowed to go, before any network traffic
// (CONTRAT.md §0.5): http/https only, ports 80 and 443 only, no credentials.
// The WHATWG parser normalises every alternative spelling of an IPv4 address
// (decimal, hex, octal, short forms) and of IPv6, so the address check that
// follows always sees the canonical text.

export interface FetchTarget {
  readonly secure: boolean;
  // Lower-case host name, or the bare IP literal (no brackets).
  readonly hostname: string;
  readonly port: number;
  // Value for the Host header: brackets kept for IPv6, port only when explicit.
  readonly hostHeader: string;
  readonly path: string;
}

export type TargetRefusal = "invalid" | "bad_scheme" | "bad_port" | "credentials";

export type FetchTargetResult =
  | { readonly ok: true; readonly target: FetchTarget }
  | { readonly ok: false; readonly reason: TargetRefusal };

const MAX_URL_LENGTH = 2048;
const ALLOWED_PORTS = new Set([80, 443]);

export function parseFetchTarget(raw: string): FetchTargetResult {
  if (raw.length === 0 || raw.length > MAX_URL_LENGTH) return { ok: false, reason: "invalid" };
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    return { ok: false, reason: "invalid" };
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") return { ok: false, reason: "bad_scheme" };
  if (url.username !== "" || url.password !== "") return { ok: false, reason: "credentials" };

  const secure = url.protocol === "https:";
  const port = url.port === "" ? (secure ? 443 : 80) : Number(url.port);
  if (!ALLOWED_PORTS.has(port)) return { ok: false, reason: "bad_port" };

  const bare = url.hostname.startsWith("[") ? url.hostname.slice(1, -1) : url.hostname;
  const hostname = bare.replace(/\.$/, "");
  if (hostname === "") return { ok: false, reason: "invalid" };

  const shownHost = url.hostname.startsWith("[") ? url.hostname : hostname;
  return {
    ok: true,
    target: {
      secure,
      hostname,
      port,
      hostHeader: url.port === "" ? shownHost : `${shownHost}:${url.port}`,
      path: `${url.pathname}${url.search}`,
    },
  };
}
