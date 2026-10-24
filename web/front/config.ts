// Settings of the website container, read from its environment. Everything is
// checked before Caddy starts: a missing or wrong value stops the container
// instead of serving a half-working site (docs/deploy/README.md).

export class FrontConfigError extends Error {
  override readonly name = "FrontConfigError";
}

export interface FrontConfig {
  readonly port: number;
  // The API container the site proxies /api, /ws and /media to.
  readonly apiUpstream: URL;
  // The public address of the site (cookie host, CSRF origin, HSTS).
  readonly webOrigin: URL;
  // The public address of the API (PUBLIC_BASE_URL): staff and document pages redirect there.
  readonly apiOrigin: URL;
  // Addresses allowed to tell us the real client address in X-Forwarded-For (Caddy syntax).
  readonly trustedProxies: readonly string[];
}

type Env = Readonly<Record<string, string | undefined>>;

const DEFAULT_PORT = 8080;
const TRUSTED_PROXY = /^(?:private_ranges|[0-9a-fA-F:.]+(?:\/\d{1,3})?)$/;

function required(env: Env, name: string): string {
  const value = env[name]?.trim();
  if (value === undefined || value.length === 0) throw new FrontConfigError(`${name} is required`);
  return value;
}

function parseUrl(name: string, raw: string, schemes: readonly string[]): URL {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new FrontConfigError(`${name} must be an absolute URL, got "${raw}"`);
  }
  if (!schemes.includes(url.protocol)) throw new FrontConfigError(`${name} must start with ${schemes.join(" or ")}`);
  if (url.username !== "" || url.password !== "" || url.search !== "" || url.hash !== "") {
    throw new FrontConfigError(`${name} must not carry credentials, a query or a fragment`);
  }
  if (url.pathname !== "/") throw new FrontConfigError(`${name} must be an origin without a path`);
  return url;
}

function parsePort(raw: string | undefined): number {
  if (raw === undefined || raw.trim().length === 0) return DEFAULT_PORT;
  const port = Number(raw);
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new FrontConfigError(`PORT must be between 1 and 65535, got "${raw}"`);
  return port;
}

function parseTrustedProxies(raw: string | undefined): readonly string[] {
  const entries = (raw ?? "").split(/[\s,]+/).filter((entry) => entry.length > 0);
  if (entries.length === 0) return ["private_ranges"];
  for (const entry of entries) {
    if (!TRUSTED_PROXY.test(entry)) throw new FrontConfigError(`TRUSTED_PROXIES: "${entry}" is neither private_ranges nor an address or CIDR`);
  }
  return entries;
}

export function readFrontConfig(env: Env): FrontConfig {
  const webOrigin = parseUrl("WEB_ORIGIN", required(env, "WEB_ORIGIN"), ["https:", "http:"]);
  const apiOrigin = parseUrl("PUBLIC_BASE_URL", required(env, "PUBLIC_BASE_URL"), ["https:", "http:"]);
  // Staff and document pages redirect to the API host: the same host would loop.
  if (apiOrigin.origin === webOrigin.origin) {
    throw new FrontConfigError("PUBLIC_BASE_URL must be another host than WEB_ORIGIN (the API host)");
  }
  return {
    port: parsePort(env.PORT),
    apiUpstream: parseUrl("API_UPSTREAM", required(env, "API_UPSTREAM"), ["http:", "https:"]),
    webOrigin,
    apiOrigin,
    trustedProxies: parseTrustedProxies(env.TRUSTED_PROXIES),
  };
}
