import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { renderCaddyfile } from "../../web/front/caddyfile";
import { readFrontConfig } from "../../web/front/config";
import { cacheControlFor, IMMUTABLE, NO_STORE } from "../../src/features/web-app/cache-rules";
import { mediaOriginFor, webSecurityHeaders } from "../../src/features/web-app/security-headers";
import { LEGAL_PAGES, LEGAL_REDIRECTS, SITE_STATIC_FILES, WEB_HOST_PAGES } from "../../src/features/web-app/site-rules";
import { createWebApp } from "../../src/features/web-app";

// The website container serves what the API's web-app feature serves today
// (docs/web/adr/W01-hebergement.md). Its Caddyfile is generated from the same
// modules; these tests read the TEXT that Caddy will read and compare it with
// the implementation, so a drift in either side fails here.

const repo = join(import.meta.dir, "../..");
const baseEnv = { API_UPSTREAM: "http://mazl-api-internal:3000", WEB_ORIGIN: "https://mazl.app", PUBLIC_BASE_URL: "https://api.mazl.app" };
const caddyfile = (env: Record<string, string> = {}) => renderCaddyfile(readFrontConfig({ ...baseEnv, ...env }));

// The `header { Name "value" }` lines of the web_headers snippet.
function snippetHeaders(text: string): Record<string, string> {
  const block = /\(web_headers\) \{\n\theader \{\n([\s\S]*?)\n\t\}\n\}/.exec(text);
  if (block?.[1] === undefined) throw new Error("web_headers snippet not found");
  const headers: Record<string, string> = {};
  for (const line of block[1].split("\n")) {
    const match = /^\t\t(\S+) "(.*)"$/.exec(line);
    if (match?.[1] === undefined || match[2] === undefined) throw new Error(`unreadable header line: ${line}`);
    headers[match[1]] = match[2];
  }
  return headers;
}

// The arguments of a named matcher line such as `@legal path /cgu /cgv`.
function matcherArgs(text: string, name: string, kind: string): string[] {
  const line = text.split("\n").find((candidate) => candidate.trim().startsWith(`@${name} ${kind} `));
  if (line === undefined) throw new Error(`matcher @${name} not found`);
  return line.trim().split(/\s+/).slice(2);
}

describe("security headers: the website container sends what the API's web client feature sends", () => {
  test("https site: every header and value equal to webSecurityHeaders, media origin included", () => {
    const expected = webSecurityHeaders(true, mediaOriginFor("https://api.mazl.app", new URL("https://mazl.app")));
    expect(snippetHeaders(caddyfile())).toEqual(expected);
  });

  test("http site (staging without TLS): no HSTS, the rest unchanged", () => {
    const headers = snippetHeaders(caddyfile({ WEB_ORIGIN: "http://front.test:8080", PUBLIC_BASE_URL: "http://api.test:3000" }));
    expect(headers).toEqual(webSecurityHeaders(false, "http://api.test:3000"));
    expect(headers["Strict-Transport-Security"]).toBeUndefined();
  });

  test("the policy itself, from the decision of W01 and not from the code: strict CSP, no framing", () => {
    const headers = snippetHeaders(caddyfile());
    const csp = headers["Content-Security-Policy"] ?? "";
    expect(csp).toContain("frame-ancestors 'none'");
    expect(csp).toContain("default-src 'self'");
    expect(csp).toContain("object-src 'none'");
    expect(csp).not.toMatch(/script-src[^;]*'unsafe-inline'/);
    expect(csp).toMatch(/img-src [^;]*https:\/\/api\.mazl\.app/);
    expect(csp).not.toMatch(/(script|connect)-src [^;]*api\.mazl\.app/);
    expect(headers["X-Frame-Options"]).toBe("DENY");
    expect(headers["Strict-Transport-Security"]).toContain("max-age=31536000");
  });

  test("the snippet is imported by every handler that serves the showcase, the client or the legal pages", () => {
    const text = caddyfile();
    // "/", /l/*, /app*, the legal pages and the static files of the site.
    expect(text.match(/import web_headers/g)?.length).toBe(5);
  });
});

describe("cache rules", () => {
  test.each(["client", "landing"])("the Caddy matcher for immutable files of the %s says what cacheControlFor says", (scope) => {
    const text = caddyfile();
    const pattern = new RegExp(`@${scope}Immutable path_regexp ${scope}Immutable (.+)$`, "m").exec(text)?.[1];
    expect(pattern).toBeDefined();
    const immutable = new RegExp(pattern ?? "");
    const paths = [
      "index-azgcf9mr.js", "index-ftknadgb.css", "favicon-x6de2fnb.svg", "logo-12345678.png", "font-abcdefgh.woff2", "font-abcdefgh.woff",
      "fonts/Geist-400.ttf", "fonts/x/y.woff2", "photos/lea-1494790108377.webp", "photographs/a.webp", "index.html", "index.js", "index-AZGCF9MR.js", "index-short.js", "index-azgcf9mr.js.gz", "messages/12", "",
    ];
    for (const path of paths) {
      expect([path, immutable.test(`/${path}`)]).toEqual([path, cacheControlFor(path) === IMMUTABLE]);
    }
  });

  test("the showcase photos are cached a year, like the fonts", () => {
    expect(cacheControlFor("photos/lea-1494790108377.webp")).toBe(IMMUTABLE);
    expect(cacheControlFor("photographs/a.webp")).not.toBe(IMMUTABLE);
  });

  test("a missing hashed file or font is a 404 that is never cached (not the page, not immutable)", () => {
    const text = caddyfile();
    for (const scope of ["client", "landing"]) {
      expect(text).toContain(`@${scope}Present file`);
      const start = text.indexOf(`handle @${scope}Present {`);
      const block = text.slice(start, text.indexOf('respond "Not found" 404', start));
      expect(block).toContain(`header Cache-Control "${IMMUTABLE}"`);
      expect(block).toContain('handle {\n\t\t\t\theader Cache-Control "no-store"'.replace(/\\n/g, "\n").replace(/\\t/g, "\t"));
    }
  });

  test("hashed files are cached a year and the page never, in the Caddyfile text", () => {
    const text = caddyfile();
    expect(text).toContain(`header Cache-Control "${IMMUTABLE}"`);
    expect(text).toContain(`header Cache-Control "${NO_STORE}"`);
    expect(text).toContain("precompressed gzip");
  });
});

describe("host rules of the site", () => {
  const paths = [
    "/verify", "/verify.html", "/verify.js", "/verify-x", "/verify/abc", "/verifyx", "/admin", "/admin/dashboard", "/admin-escape.js", "/admin.html",
    "/administrator", "/console", "/console/reports", "/consoles", "/cgu", "/app", "/", "/api/health",
  ];

  test("staff, document and old admin pages are redirected exactly where the API's implementation redirects them", async () => {
    const pattern = /@apiHost path_regexp apiHost (.+)$/m.exec(caddyfile())?.[1];
    const apiHost = new RegExp(pattern ?? "");
    const web = createWebApp({ distDir: "/nonexistent", webOrigin: "https://mazl.app", mediaBaseUrl: "https://api.mazl.app" });
    for (const path of paths) {
      const res = await web.handle(new Request(`https://mazl.app${path}`, { headers: { host: "mazl.app" } }));
      const redirectedToApi = res?.headers.get("location")?.startsWith("https://api.mazl.app") ?? false;
      expect([path, apiHost.test(path)]).toEqual([path, redirectedToApi]);
    }
  });

  test("they go to the API host with the path and query kept", () => {
    expect(caddyfile()).toContain("redir https://api.mazl.app{uri} 302");
    expect(caddyfile({ PUBLIC_BASE_URL: "https://stg-api.example.test" })).toContain("redir https://stg-api.example.test{uri} 302");
  });

  test("the pages the site serves itself are exactly the ones the API serves on the site host", () => {
    const text = caddyfile();
    const served = new Set([...matcherArgs(text, "legal", "path"), ...matcherArgs(text, "siteFiles", "path"), ...Object.keys(LEGAL_REDIRECTS)]);
    expect(served).toEqual(new Set(WEB_HOST_PAGES));
    expect(matcherArgs(text, "legal", "path")).toEqual(LEGAL_PAGES.map((page) => `/${page}`));
  });

  test("the legal redirects are permanent and point where the API pointed", () => {
    const text = caddyfile();
    for (const [from, to] of Object.entries(LEGAL_REDIRECTS)) {
      expect(text).toContain(`handle ${from} {\n\t\tredir * ${to} 301\n\t}`);
    }
  });

  test("/ and unknown paths go to the client, on the public origin", () => {
    expect(caddyfile()).toMatch(/\thandle \{\n\t\tredir https:\/\/mazl\.app\/app 302\n\t\}\n\}\n$/);
  });

  test("the API, its socket and the signed media are proxied, nothing else", () => {
    expect(matcherArgs(caddyfile(), "proxied", "path")).toEqual(["/api/*", "/ws", "/media/*"]);
  });
});

describe("showcase at the root and under /l/", () => {
  test("/ serves landing/index.html uncached with the strict headers; /l/* is served from the showcase folder", () => {
    const text = caddyfile();
    expect(text).toContain('\thandle / {\n\t\timport web_headers\n\t\theader Cache-Control "no-store"\n\t\troot * /srv/landing\n\t\trewrite * /index.html');
    expect(text).toContain("@landing path /l/*");
    expect(text).toContain("uri strip_prefix /l");
  });

  test("the folder itself and the .gz copies under /l/ are a 404, as in the API", () => {
    expect(caddyfile()).toContain("@unserved path / *.gz");
  });

  test("www.<site host> redirects to the site host, path and query kept", () => {
    expect(caddyfile()).toContain("@www host www.mazl.app\n\thandle @www {\n\t\tredir https://mazl.app{uri} 301");
  });

  test("the paths the API's implementation answers for the showcase agree with the Caddy matchers", async () => {
    const root = await mkdtemp(join(tmpdir(), "mazl-front-landing-"));
    try {
      await mkdir(join(root, "fonts"));
      await writeFile(join(root, "index.html"), "<title>vitrine</title>");
      await writeFile(join(root, "main-abcd1234.js"), "1");
      await writeFile(join(root, "main-abcd1234.js.gz"), "1");
      const web = createWebApp({ distDir: root, landingDistDir: root, webOrigin: "https://mazl.app" });
      const status = async (path: string) => (await web.handle(new Request(`https://mazl.app${path}`, { headers: { host: "mazl.app" } })))?.status;
      expect(await status("/")).toBe(200);
      expect(await status("/l/main-abcd1234.js")).toBe(200);
      expect(await status("/l/")).toBe(404);
      expect(await status("/l/main-abcd1234.js.gz")).toBe(404);
      expect(await status("/l/absent-zzzz9999.js")).toBe(404);
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  });
});

describe("what the client address looks like to the API", () => {
  test("the container sends the API exactly one X-Forwarded-For, the client's, read right to left past the trusted proxies", () => {
    const text = caddyfile();
    expect(text).toContain("trusted_proxies static private_ranges");
    expect(text).toContain("trusted_proxies_strict");
    expect(text).toContain("header_up X-Forwarded-For {client_ip}");
    expect(text).toContain("header_up -Forwarded");
    expect(text).toContain("header_up -X-Real-Ip");
  });

  test("the trusted proxies can be narrowed", () => {
    expect(caddyfile({ TRUSTED_PROXIES: "10.0.0.0/8 172.16.0.0/12" })).toContain("trusted_proxies static 10.0.0.0/8 172.16.0.0/12");
  });
});

describe("the API upstream", () => {
  test("the internal Docker address keeps the browser's Host header (the API checks it against WEB_ORIGIN)", () => {
    const text = caddyfile();
    expect(text).toContain("reverse_proxy http://mazl-api-internal:3000 {");
    expect(text).not.toContain("header_up Host");
  });

  test("a connection refused during an API deploy is retried for a few seconds, not shown as a 502", () => {
    expect(caddyfile()).toContain("lb_try_duration 5s");
    expect(caddyfile()).toContain("lb_try_interval 250ms");
  });

  test("a public https upstream is addressed by its own host name and told the original one", () => {
    const text = caddyfile({ API_UPSTREAM: "https://stg-api.example.test" });
    expect(text).toContain("reverse_proxy https://stg-api.example.test {");
    expect(text).toContain("header_up Host {upstream_hostport}");
    expect(text).toContain("header_up X-Forwarded-Host {host}");
  });
});

describe("container", () => {
  test("health is answered by the front itself, without the API, and not cached", () => {
    expect(caddyfile()).toContain('handle /health {\n\t\theader Cache-Control "no-store"\n\t\trespond "ok" 200\n\t}');
  });

  test("the listening port follows PORT; no access log (query strings carry one-time tokens), no admin API, no automatic TLS", () => {
    const text = caddyfile({ PORT: "9000" });
    expect(text).toContain("\n:9000 {");
    expect(text).not.toMatch(/^\s*log\b/m);
    expect(text).toContain("admin off");
    expect(text).toContain("auto_https off");
  });

  test("every file the page and the legal routes need is copied into the image", () => {
    const dockerfile = readFileSync(join(repo, "web/Dockerfile"), "utf8");
    for (const file of [...LEGAL_PAGES.map((page) => `${page}.html`), ...SITE_STATIC_FILES]) {
      expect(dockerfile).toContain(`public/${file}`);
      expect(Bun.file(join(repo, "public", file)).size).toBeGreaterThan(0);
    }
    expect(dockerfile).toContain("RUN bun landing/build.ts");
    expect(dockerfile).toContain("/app/landing/dist /srv/landing");
    for (const shared of ["cache-rules", "security-headers", "site-rules"]) expect(dockerfile).toContain(`src/features/web-app/${shared}.ts`);
  });
});
