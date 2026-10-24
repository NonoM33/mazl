import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createWebApp } from "../../src/features/web-app";

// The showcase is served at the root of the web host and under /l/; everything
// else behaves as before (web-app-serving.test.ts).

let root = "";
let landing = "";
let client = "";
beforeAll(async () => {
  root = await mkdtemp(join(tmpdir(), "mazl-landing-"));
  landing = join(root, "landing");
  client = join(root, "web");
  await mkdir(join(landing, "fonts"), { recursive: true });
  await mkdir(client);
  await writeFile(join(landing, "index.html"), "<!doctype html><title>vitrine</title>");
  await writeFile(join(landing, "main-abcd1234.js"), "console.log(1)");
  await writeFile(join(landing, "main-abcd1234.js.gz"), Bun.gzipSync(new TextEncoder().encode("console.log(1)")));
  await writeFile(join(landing, "fonts", "Geist-700.ttf"), "font");
  await writeFile(join(client, "index.html"), "<!doctype html><title>client</title>");
  await writeFile(join(root, "secret.txt"), "root:secret");
});
afterAll(async () => { await rm(root, { recursive: true, force: true }); });

const get = (url: string, host = new URL(url).host, headers: Record<string, string> = {}) => new Request(url, { headers: { host, ...headers } });
const site = (mediaBaseUrl: string | null = null) =>
  createWebApp({ distDir: client, landingDistDir: landing, webOrigin: "https://mazl.app", mediaBaseUrl });

describe("showcase at the root of mazl.app", () => {
  test("/ serves the showcase, uncached, with the strict headers", async () => {
    const res = await site().handle(get("https://mazl.app/"));
    expect(res?.status).toBe(200);
    expect(await res?.text()).toContain("vitrine");
    expect(res?.headers.get("cache-control")).toBe("no-store");
    expect(res?.headers.get("content-type")).toContain("text/html");
    const csp = res?.headers.get("content-security-policy") ?? "";
    expect(csp).toContain("frame-ancestors 'none'");
    expect(csp).not.toMatch(/script-src[^;]*('unsafe-inline'|blob:|wasm-unsafe-eval)/);
    expect(res?.headers.get("strict-transport-security")).toContain("max-age=");
  });

  test("hashed files under /l/ are immutable, fonts too, and gzip is honoured", async () => {
    const js = await site().handle(get("https://mazl.app/l/main-abcd1234.js"));
    expect(js?.status).toBe(200);
    expect(js?.headers.get("cache-control")).toContain("immutable");
    const gz = await site().handle(get("https://mazl.app/l/main-abcd1234.js", "mazl.app", { "accept-encoding": "gzip" }));
    expect(gz?.headers.get("content-encoding")).toBe("gzip");
    const font = await site().handle(get("https://mazl.app/l/fonts/Geist-700.ttf"));
    expect(font?.headers.get("cache-control")).toContain("immutable");
  });

  test("a missing file under /l/ is a 404, never the page, and the folder cannot be escaped", async () => {
    for (const path of ["/l/nope-zzzz9999.js", "/l/", "/l/..%2fsecret.txt", "/l/main-abcd1234.js.gz"]) {
      const res = await site().handle(get(`https://mazl.app${path}`));
      expect([path, res?.status]).toEqual([path, 404]);
      expect(await res?.text()).not.toContain("root:secret");
    }
  });

  test("a dot-dot path normalised by the URL parser leaves the showcase and leaks nothing", async () => {
    const res = await site().handle(get("https://mazl.app/l/%2e%2e/secret.txt"));
    expect(res?.status).not.toBe(200);
    expect(await res?.text()).not.toContain("root:secret");
  });

  test("only the web host serves the showcase files", async () => {
    expect(await site().handle(get("https://api.mazl.app/l/main-abcd1234.js"))).toBeNull();
  });

  test("the client under /app is unchanged", async () => {
    const res = await site().handle(get("https://mazl.app/app/messages"));
    expect(res?.status).toBe(200);
    expect(await res?.text()).toContain("client");
    expect((await site().handle(get("https://api.mazl.app/app")))?.headers.get("location")).toBe("https://mazl.app/app");
  });

  test("an unknown path still redirects to the client", async () => {
    const res = await site().handle(get("https://mazl.app/n-importe-quoi"));
    expect(res?.status).toBe(302);
    expect(res?.headers.get("location")).toBe("https://mazl.app/app");
  });

  test("the legal pages and the API pass through to the server", async () => {
    for (const path of ["/cgu", "/cgv", "/confidentialite", "/api/health", "/ws", "/style.css"]) {
      expect([path, await site().handle(get(`https://mazl.app${path}`))]).toEqual([path, null]);
    }
  });

  test("the console, the document link and the old admin still go to the API host", async () => {
    const withApi = site("https://api.mazl.app");
    for (const path of ["/console", "/console/reports?page=2", "/verify?token=abc", "/admin"]) {
      const res = await withApi.handle(get(`https://mazl.app${path}`));
      expect([path, res?.status, res?.headers.get("location")]).toEqual([path, 302, `https://api.mazl.app${path}`]);
    }
  });

  test("the API host is not concerned by the showcase", async () => {
    expect(await site("https://api.mazl.app").handle(get("https://api.mazl.app/"))).toBeNull();
  });

  test("writes are left to the server", async () => {
    expect(await site().handle(new Request("https://mazl.app/", { method: "POST", headers: { host: "mazl.app" } }))).toBeNull();
  });
});

describe("www host", () => {
  test("redirects permanently to the web origin, path and query kept", async () => {
    for (const path of ["/", "/cgu", "/app/decouvrir?x=1", "/l/main-abcd1234.js", "/console?a=b"]) {
      const res = await site().handle(get(`https://www.mazl.app${path}`));
      expect([path, res?.status, res?.headers.get("location")]).toEqual([path, 301, `https://mazl.app${path}`]);
    }
  });
});

describe("showcase not built", () => {
  const unbuilt = (landingDistDir?: string | null) =>
    createWebApp({ distDir: client, webOrigin: "https://mazl.app", ...(landingDistDir === undefined ? {} : { landingDistDir }) });

  test("/ redirects to the client as before, without a 503", async () => {
    for (const app of [unbuilt(), unbuilt(null), unbuilt(join(root, "absent"))]) {
      const res = await app.handle(get("https://mazl.app/"));
      expect(res?.status).toBe(302);
      expect(res?.headers.get("location")).toBe("https://mazl.app/app");
    }
  });

  test("files under /l/ are a 404", async () => {
    expect((await unbuilt().handle(get("https://mazl.app/l/main-abcd1234.js")))?.status).toBe(404);
  });
});

describe("without WEB_ORIGIN", () => {
  test("/ is left to the server", async () => {
    const dev = createWebApp({ distDir: client, landingDistDir: landing, webOrigin: null });
    expect(await dev.handle(get("http://localhost:3000/"))).toBeNull();
  });
});
