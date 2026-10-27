import { FONTS_DIRECTORY, HASHED_ASSET, IMMUTABLE, NO_STORE, PHOTOS_DIRECTORY } from "../../src/features/web-app/cache-rules";
import { mediaOriginFor, webSecurityHeaders } from "../../src/features/web-app/security-headers";
import { API_HOST_ONLY, LANDING_PREFIX, LEGAL_PAGES, LEGAL_REDIRECTS, PROXIED_PREFIXES, SITE_STATIC_FILES, wwwHost } from "../../src/features/web-app/site-rules";
import type { FrontConfig } from "./config";

// The Caddyfile of the website container, rendered at start from the same
// modules the API process uses to serve the website: the headers, the cache
// rules and the host rules cannot drift from it (docs/web/adr/W01-hebergement.md,
// 2026-10-24 decoupling). Pure: no file, no environment.

export interface FrontPaths {
  // The built web client (web/dist), served under /app.
  readonly appDir: string;
  // The legal pages with their stylesheet and icon (public/).
  readonly siteDir: string;
  // The built showcase (landing/dist): index.html at "/", the rest under /l/.
  readonly landingDir: string;
}

export const DEFAULT_PATHS: FrontPaths = { appDir: "/srv/app", siteDir: "/srv/site", landingDir: "/srv/landing" };

export const CLIENT_PREFIX = "/app";
export const SECURITY_HEADERS_SNIPPET = "web_headers";

// A value written between double quotes. Braces would read as Caddy placeholders.
function quoted(value: string): string {
  if (/["\\{}\r\n]/.test(value)) throw new Error(`Caddyfile: value cannot be written safely: ${value}`);
  return `"${value}"`;
}

function indent(lines: readonly string[], depth: number): string[] {
  return lines.map((line) => (line.length === 0 ? line : `${"\t".repeat(depth)}${line}`));
}

// The headers of the API's web-app feature, as a snippet imported by every handler that serves the site.
function securityHeadersSnippet(config: FrontConfig): string[] {
  const secure = config.webOrigin.protocol === "https:";
  const mediaOrigin = mediaOriginFor(config.apiOrigin.origin, config.webOrigin);
  const headers = webSecurityHeaders(secure, mediaOrigin);
  const lines = Object.entries(headers).map(([name, value]) => `${name} ${quoted(value)}`);
  return [`(${SECURITY_HEADERS_SNIPPET}) {`, "\theader {", ...indent(lines, 2), "\t}", "}"];
}

const globalOptions = (config: FrontConfig): string[] => [
  "{",
  "\tadmin off",
  "\tauto_https off",
  "\tpersist_config off",
  "\tservers {",
  // The last hop is Traefik: it appends the real client to X-Forwarded-For, so
  // the entries are read from the right and the first untrusted one is the client.
  `\t\ttrusted_proxies static ${config.trustedProxies.join(" ")}`,
  "\t\ttrusted_proxies_strict",
  "\t\ttimeouts {",
  "\t\t\tread_header 10s",
  "\t\t\tidle 5m",
  "\t\t}",
  "\t}",
  "}",
];

function proxyBlock(config: FrontConfig): string[] {
  const paths = PROXIED_PREFIXES.map((prefix) => (prefix.endsWith("/") ? `${prefix}*` : prefix));
  // A public https upstream (staging) is routed by its own host name.
  const publicUpstream = config.apiUpstream.protocol === "https:";
  return [
    `@proxied path ${paths.join(" ")}`,
    "handle @proxied {",
    `\treverse_proxy ${config.apiUpstream.origin} {`,
    // The API swaps containers on each deploy: a connection refused during the
    // switch is retried for a few seconds instead of reaching the member as a 502.
    "\t\tlb_try_duration 5s",
    "\t\tlb_try_interval 250ms",
    // The API reads the LAST entry of X-Forwarded-For as the client (one hop):
    // send exactly one, the real client, never what the browser wrote.
    "\t\theader_up X-Forwarded-For {client_ip}",
    "\t\theader_up -Forwarded",
    "\t\theader_up -X-Real-Ip",
    ...(publicUpstream ? ["\t\theader_up X-Forwarded-Host {host}", "\t\theader_up Host {upstream_hostport}"] : []),
    "\t}",
    "}",
  ];
}

// Hashed files, fonts and photos under a root: cached a year when they exist, a 404 that
// is never cached when they do not (never the page, which would be cached as JS).
function immutableFiles(scope: string): string[] {
  const directories = [FONTS_DIRECTORY, PHOTOS_DIRECTORY].map((directory) => directory.replace(/\/$/, "")).join("|");
  return [
    `@${scope}Immutable path_regexp ${scope}Immutable ${HASHED_ASSET.source}|^/(?:${directories})/`,
    `handle @${scope}Immutable {`,
    `\t@${scope}Present file`,
    `\thandle @${scope}Present {`,
    `\t\theader Cache-Control ${quoted(IMMUTABLE)}`,
    "\t\tfile_server {",
    "\t\t\tprecompressed gzip",
    "\t\t\tdisable_canonical_uris",
    "\t\t}",
    "\t}",
    "\thandle {",
    `\t\theader Cache-Control ${quoted(NO_STORE)}`,
    '\t\trespond "Not found" 404',
    "\t}",
    "}",
  ];
}

function clientBlock(paths: FrontPaths): string[] {
  return [
    `@client path ${CLIENT_PREFIX} ${CLIENT_PREFIX}/*`,
    "handle @client {",
    `\timport ${SECURITY_HEADERS_SNIPPET}`,
    `\troot * ${paths.appDir}`,
    `\turi strip_prefix ${CLIENT_PREFIX}`,
    ...indent(immutableFiles("client"), 1),
    "\thandle {",
    `\t\theader Cache-Control ${quoted(NO_STORE)}`,
    "\t\ttry_files {path} /index.html",
    "\t\tfile_server",
    "\t}",
    "}",
  ];
}

// The showcase, served exactly as web-app.ts serves it: the page at "/" (never
// cached), every other file under /l/ with the cache rules of the client; a
// missing file, the folder itself and the .gz copies are a 404, never the page.
function landingBlock(paths: FrontPaths): string[] {
  const prefix = LANDING_PREFIX.replace(/\/$/, "");
  return [
    "handle / {",
    `\timport ${SECURITY_HEADERS_SNIPPET}`,
    `\theader Cache-Control ${quoted(NO_STORE)}`,
    `\troot * ${paths.landingDir}`,
    "\trewrite * /index.html",
    "\tfile_server {",
    "\t\tdisable_canonical_uris",
    "\t}",
    "}",
    `@landing path ${LANDING_PREFIX}*`,
    "handle @landing {",
    `\troot * ${paths.landingDir}`,
    `\turi strip_prefix ${prefix}`,
    "\t@unserved path / *.gz",
    "\thandle @unserved {",
    `\t\theader Cache-Control ${quoted(NO_STORE)}`,
    '\t\trespond "Not found" 404',
    "\t}",
    `\timport ${SECURITY_HEADERS_SNIPPET}`,
    ...indent(immutableFiles("landing"), 1),
    "\thandle {",
    `\t\theader Cache-Control ${quoted(NO_STORE)}`,
    "\t\tfile_server {",
    "\t\t\tdisable_canonical_uris",
    "\t\t}",
    "\t}",
    "}",
  ];
}

function siteFilesBlock(paths: FrontPaths): string[] {
  const pages = LEGAL_PAGES.map((page) => `/${page}`);
  const files = [...LEGAL_PAGES.map((page) => `/${page}.html`), ...SITE_STATIC_FILES.map((file) => `/${file}`)];
  const serve = [
    `\timport ${SECURITY_HEADERS_SNIPPET}`,
    `\theader Cache-Control ${quoted("no-cache")}`,
    `\troot * ${paths.siteDir}`,
  ];
  return [
    ...Object.entries(LEGAL_REDIRECTS).flatMap(([from, to]) => [`handle ${from} {`, `\tredir * ${to} 301`, "}"]),
    `@legal path ${pages.join(" ")}`,
    "handle @legal {",
    ...serve,
    "\trewrite * {path}.html",
    "\tfile_server",
    "}",
    `@siteFiles path ${files.join(" ")}`,
    "handle @siteFiles {",
    ...serve,
    "\tfile_server",
    "}",
  ];
}

export function renderCaddyfile(config: FrontConfig, paths: FrontPaths = DEFAULT_PATHS): string {
  const site = [
    "header -Server",
    // www.<site host> only redirects to the site host, path and query kept.
    `@www host ${wwwHost(config.webOrigin.hostname)}`,
    "handle @www {",
    `\tredir ${config.webOrigin.origin}{uri} 301`,
    "}",
    "handle /health {",
    `\theader Cache-Control ${quoted(NO_STORE)}`,
    '\trespond "ok" 200',
    "}",
    // Staff console, document drop page and old admin: scripts and a looser CSP, never on this origin.
    `@apiHost path_regexp apiHost ${API_HOST_ONLY.source}`,
    "handle @apiHost {",
    `\tredir ${config.apiOrigin.origin}{uri} 302`,
    "}",
    ...proxyBlock(config),
    ...landingBlock(paths),
    ...clientBlock(paths),
    ...siteFilesBlock(paths),
    "handle {",
    `\tredir ${config.webOrigin.origin}${CLIENT_PREFIX} 302`,
    "}",
  ];
  return [...globalOptions(config), "", ...securityHeadersSnippet(config), "", `:${config.port} {`, ...indent(site, 1), "}", ""].join("\n");
}
