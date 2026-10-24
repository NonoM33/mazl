import { join, normalize } from "node:path";
import { IMMUTABLE, NO_STORE, webSecurityHeaders } from "./security-headers";

// Serves the built web client (web/dist) under /app, before Hono so its own
// headers are not overwritten by the API's. With WEB_ORIGIN set, the client
// lives on that host only (docs/web/adr/W01-hebergement.md).

export interface WebAppOptions {
  readonly distDir: string;
  // e.g. "https://app.mazl.app"; null in development and tests.
  readonly webOrigin: string | null;
  // Origin of the signed media URLs (PUBLIC_BASE_URL), when it is not the web host.
  readonly mediaBaseUrl?: string | null;
}

const PREFIX = "/app";
// Paths the web host also serves: the API, its socket and signed media.
const WEB_HOST_PASSTHROUGH = ["/api/", "/ws", "/media/"];
const HASHED = /-[a-z0-9]{8}\.(?:js|css|svg|png|woff2?)$/;

function fileUnder(distDir: string, path: string): string | null {
  const relative = normalize(path.slice(PREFIX.length)).replace(/^\/+/, "");
  if (relative.length === 0 || relative.startsWith("..")) return null;
  return join(distDir, relative);
}

function mediaOriginFor(mediaBaseUrl: string | null, webOrigin: URL | null): string | null {
  if (!mediaBaseUrl) return null;
  try {
    const media = new URL(mediaBaseUrl).origin;
    return media === webOrigin?.origin ? null : media;
  } catch {
    return null;
  }
}

function cacheFor(relativePath: string): string {
  return HASHED.test(relativePath) || relativePath.startsWith("fonts/") ? IMMUTABLE : NO_STORE;
}

export function createWebApp(options: WebAppOptions) {
  const origin = options.webOrigin === null ? null : new URL(options.webOrigin);
  const secure = origin?.protocol === "https:";
  const mediaOrigin = mediaOriginFor(options.mediaBaseUrl ?? null, origin);
  const headers = () => webSecurityHeaders(secure, mediaOrigin);

  async function serveIndex(): Promise<Response> {
    const index = Bun.file(join(options.distDir, "index.html"));
    if (!(await index.exists())) return new Response("Web client not built (bun run web:build)", { status: 503 });
    return new Response(index, { headers: { ...headers(), "Content-Type": "text/html; charset=utf-8", "Cache-Control": NO_STORE } });
  }

  // The precompressed copy built beside a script or stylesheet, if accepted.
  async function compressed(file: string, acceptEncoding: string | null): Promise<Response | null> {
    if (!/\.(js|css)$/.test(file) || !/\bgzip\b/.test(acceptEncoding ?? "")) return null;
    const gz = Bun.file(`${file}.gz`);
    if (!(await gz.exists())) return null;
    const type = file.endsWith(".js") ? "text/javascript;charset=utf-8" : "text/css;charset=utf-8";
    return new Response(gz, { headers: { ...headers(), "Content-Type": type, "Content-Encoding": "gzip", Vary: "Accept-Encoding", "Cache-Control": cacheFor(file) } });
  }

  async function serveClient(path: string, acceptEncoding: string | null): Promise<Response> {
    const file = fileUnder(options.distDir, path);
    if (file !== null && !file.endsWith("index.html")) {
      const gz = await compressed(file, acceptEncoding);
      if (gz) return gz;
      const asset = Bun.file(file);
      if (await asset.exists()) {
        return new Response(asset, { headers: { ...headers(), "Cache-Control": cacheFor(file.slice(options.distDir.length + 1)) } });
      }
      // A missing hashed asset is a 404, never the page (it would be cached as JS).
      if (HASHED.test(file) || file.includes("/fonts/")) return new Response("Not found", { status: 404, headers: { "Cache-Control": NO_STORE } });
    }
    return serveIndex();
  }

  // The response for a web client request, or null to let the API handle it.
  async function handle(req: Request): Promise<Response | null> {
    if (req.method !== "GET" && req.method !== "HEAD") return null;
    const url = new URL(req.url);
    const onWebHost = origin !== null && req.headers.get("host") === origin.host;
    const underApp = url.pathname === PREFIX || url.pathname.startsWith(`${PREFIX}/`);
    if (origin !== null && underApp && !onWebHost) return Response.redirect(`${origin.origin}${url.pathname}${url.search}`, 301);
    if (underApp) return serveClient(url.pathname, req.headers.get("accept-encoding"));
    if (onWebHost && !WEB_HOST_PASSTHROUGH.some((prefix) => url.pathname.startsWith(prefix))) return Response.redirect(`${origin.origin}${PREFIX}`, 302);
    return null;
  }

  return { handle };
}
