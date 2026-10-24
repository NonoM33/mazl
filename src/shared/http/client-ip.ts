import type { Context } from "hono";
import { getConnInfo } from "hono/bun";

// The address of the client, for limits on public routes. Behind Coolify,
// Traefik is the TCP peer and appends the real client to X-Forwarded-For;
// anything the client wrote in that header comes before the proxy's entry, so
// only the last TRUSTED_PROXY_HOPS entries are trusted (default 1). With 0, the
// header is ignored and the socket peer is used, for a server exposed directly.

const DEFAULT_PROXY_HOPS = 1;

export function trustedProxyHops(env: Record<string, string | undefined> = process.env): number {
  const parsed = Number.parseInt(env.TRUSTED_PROXY_HOPS ?? "", 10);
  return Number.isInteger(parsed) && parsed >= 0 && parsed <= 5 ? parsed : DEFAULT_PROXY_HOPS;
}

const PROXY_HOPS = trustedProxyHops();

function socketPeer(c: Context): string | undefined {
  try {
    return getConnInfo(c).remote.address;
  } catch {
    // No Bun server in the context (in-process requests in tests).
    return undefined;
  }
}

export function clientIp(c: Context, hops: number = PROXY_HOPS): string {
  if (hops > 0) {
    const chain = (c.req.header("x-forwarded-for") ?? "")
      .split(",")
      .map((entry) => entry.trim())
      .filter((entry) => entry.length > 0);
    const trusted = chain[Math.max(0, chain.length - hops)];
    if (trusted) return trusted;
  }
  return socketPeer(c) ?? "unknown";
}
