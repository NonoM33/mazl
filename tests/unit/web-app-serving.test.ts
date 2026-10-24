import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createWebApp } from "../../src/features/web-app";

// The web client is served under /app with its own strict headers, and only
// on its host once WEB_ORIGIN is set (docs/web/adr/W01-hebergement.md).

let dist = "";
beforeAll(async () => {
  dist = await mkdtemp(join(tmpdir(), "mazl-dist-"));
  await writeFile(join(dist, "index.html"), "<!doctype html><title>mazl</title>");
  await writeFile(join(dist, "index-abcd1234.js"), "console.log(1)");
  await writeFile(join(dist, "index-abcd1234.js.gz"), Bun.gzipSync(new TextEncoder().encode("console.log(1)")));
  await mkdir(join(dist, "fonts"));
  await writeFile(join(dist, "fonts", "Geist-400.ttf"), "font");
});
afterAll(async () => { await rm(dist, { recursive: true, force: true }); });

const get = (url: string, host = new URL(url).host) => new Request(url, { headers: { host } });

describe("web client serving without WEB_ORIGIN", () => {
  const web = () => createWebApp({ distDir: dist, webOrigin: null });

  test("a client route returns the page with a strict CSP and no caching", async () => {
    const res = await web().handle(get("http://localhost:3000/app/messages/12"));
    expect(res?.status).toBe(200);
    const csp = res?.headers.get("content-security-policy") ?? "";
    expect(csp).toContain("frame-ancestors 'none'");
    expect(csp).toContain("default-src 'self'");
    expect(csp).not.toMatch(/script-src[^;]*'unsafe-inline'/);
    expect(res?.headers.get("cache-control")).toBe("no-store");
    expect(res?.headers.get("x-frame-options")).toBe("DENY");
  });

  test("hashed files and fonts are cached for a year", async () => {
    expect((await web().handle(get("http://localhost:3000/app/index-abcd1234.js")))?.headers.get("cache-control")).toContain("immutable");
    expect((await web().handle(get("http://localhost:3000/app/fonts/Geist-400.ttf")))?.headers.get("cache-control")).toContain("immutable");
  });

  test("a browser accepting gzip gets the precompressed script, others the plain one", async () => {
    const gzip = await web().handle(new Request("http://localhost:3000/app/index-abcd1234.js", { headers: { "accept-encoding": "gzip, br" } }));
    expect(gzip?.headers.get("content-encoding")).toBe("gzip");
    expect(gzip?.headers.get("vary")).toBe("Accept-Encoding");
    expect(new TextDecoder().decode(Bun.gunzipSync(new Uint8Array(await gzip?.arrayBuffer() ?? new ArrayBuffer(0))))).toBe("console.log(1)");
    const plain = await web().handle(get("http://localhost:3000/app/index-abcd1234.js"));
    expect(plain?.headers.get("content-encoding")).toBeNull();
    expect(await plain?.text()).toBe("console.log(1)");
  });

  test("a missing hashed file is a 404, never the page", async () => {
    expect((await web().handle(get("http://localhost:3000/app/index-zzzz9999.js")))?.status).toBe(404);
  });

  test("a path escaping the dist folder gets the page, not a file", async () => {
    for (const path of ["/app/..%2f..%2f..%2fetc%2fpasswd", "/app/%2e%2e/%2e%2e/package.json"]) {
      const res = await web().handle(get(`http://localhost:3000${path}`));
      const body = res === null ? "" : await res.text();
      expect(body).not.toContain("root:");
      expect(body).not.toContain('"name": "mazl"');
    }
  });

  test("the API, the landing and writes are left to the server", async () => {
    expect(await web().handle(get("http://localhost:3000/api/health"))).toBeNull();
    expect(await web().handle(get("http://localhost:3000/"))).toBeNull();
    expect(await web().handle(new Request("http://localhost:3000/app", { method: "POST" }))).toBeNull();
  });
});

describe("web client serving with WEB_ORIGIN", () => {
  const web = () => createWebApp({ distDir: dist, webOrigin: "https://app.mazl.app" });

  test("/app on the landing host redirects to the web host", async () => {
    const res = await web().handle(get("https://mazl.app/app/decouvrir?x=1", "mazl.app"));
    expect(res?.status).toBe(301);
    expect(res?.headers.get("location")).toBe("https://app.mazl.app/app/decouvrir?x=1");
  });

  test("on the web host, the landing and the admin console are not served", async () => {
    for (const path of ["/", "/admin", "/admin/dashboard", "/cgu"]) {
      const res = await web().handle(get(`https://app.mazl.app${path}`, "app.mazl.app"));
      expect(res?.status).toBe(302);
      expect(res?.headers.get("location")).toBe("https://app.mazl.app/app");
    }
  });

  test("on the web host, the API, the socket and signed media pass through", async () => {
    for (const path of ["/api/health", "/ws", "/media/photos/1?exp=1&sig=x"]) {
      expect(await web().handle(get(`https://app.mazl.app${path}`, "app.mazl.app"))).toBeNull();
    }
  });

  test("signed media on the API host are allowed as images and sound, and only there", async () => {
    const withMedia = createWebApp({ distDir: dist, webOrigin: "https://app.mazl.app", mediaBaseUrl: "https://api.mazl.app" });
    const csp = (await withMedia.handle(get("https://app.mazl.app/app", "app.mazl.app")))?.headers.get("content-security-policy") ?? "";
    expect(csp).toMatch(/img-src [^;]*https:\/\/api\.mazl\.app/);
    expect(csp).toMatch(/media-src [^;]*https:\/\/api\.mazl\.app/);
    expect(csp).not.toMatch(/(script|connect)-src [^;]*api\.mazl\.app/);
  });

  test("HTTPS adds HSTS", async () => {
    const res = await web().handle(get("https://app.mazl.app/app", "app.mazl.app"));
    expect(res?.headers.get("strict-transport-security")).toContain("max-age=31536000");
  });
});
