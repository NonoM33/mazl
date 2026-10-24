import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { API_HOST_STATIC_FILES, createWebsiteMoved, websiteServed } from "../../src/features/web-app/website-mode";

// SERVE_WEBSITE=false: the API process stops serving the website
// (docs/deploy/README.md). Default: it serves it, as before the cut-over.

const publicDir = join(import.meta.dir, "../../public");
const get = (url: string) => new Request(url);

describe("SERVE_WEBSITE switch", () => {
  test("unset, empty or any other value keeps the website served (nothing changes before the cut-over)", () => {
    for (const value of [undefined, "", "true", "1", "yes", "on", "banana"]) expect(websiteServed({ SERVE_WEBSITE: value })).toBe(true);
  });

  test("false, 0, no and off (any case, spaces ignored) stop serving it", () => {
    for (const value of ["false", "FALSE", " False ", "0", "no", "off"]) expect(websiteServed({ SERVE_WEBSITE: value })).toBe(false);
  });
});

describe("the API host once the website has moved", () => {
  const moved = createWebsiteMoved("https://mazl.app");

  test("the old website addresses go to the website host, path and query kept", () => {
    const cases: ReadonlyArray<readonly [string, number, string]> = [
      ["https://api.mazl.app/", 302, "https://mazl.app/"],
      ["https://api.mazl.app/app", 301, "https://mazl.app/app"],
      ["https://api.mazl.app/app/decouvrir?x=1", 301, "https://mazl.app/app/decouvrir?x=1"],
      ["https://api.mazl.app/cgu", 301, "https://mazl.app/cgu"],
      ["https://api.mazl.app/cgv.html", 301, "https://mazl.app/cgv.html"],
      ["https://api.mazl.app/terms", 301, "https://mazl.app/terms"],
      ["https://api.mazl.app/privacy", 301, "https://mazl.app/privacy"],
      ["https://api.mazl.app/index.html", 301, "https://mazl.app/index.html"],
    ];
    for (const [url, status, location] of cases) {
      const res = moved.handle(get(url));
      expect([url, res?.status, res?.headers.get("location")]).toEqual([url, status, location]);
    }
  });

  test("the API, the socket, the media, the staff console, the document page and the old admin are left to the API", () => {
    for (const path of ["/api/health", "/ws", "/media/photos/1", "/verify?token=abc", "/verify.html", "/console", "/console/reports", "/admin", "/admin/dashboard", "/appx", "/application"]) {
      expect([path, moved.handle(get(`https://api.mazl.app${path}`))]).toEqual([path, null]);
    }
  });

  test("only reads are redirected", () => {
    expect(moved.handle(new Request("https://api.mazl.app/app", { method: "POST" }))).toBeNull();
  });

  test("without WEB_ORIGIN there is nowhere to send them: left to the API (a 404)", () => {
    expect(createWebsiteMoved(null).handle(get("https://api.mazl.app/app"))).toBeNull();
  });
});

describe("files the API host keeps serving", () => {
  test("they exist in public/", () => {
    for (const file of API_HOST_STATIC_FILES) expect([file, Bun.file(join(publicDir, file)).size > 0]).toEqual([file, true]);
  });

  test("the landing and the legal pages are not among them", () => {
    for (const file of ["/index.html", "/script.js", "/cgu.html", "/cgv.html", "/confidentialite.html"]) expect(API_HOST_STATIC_FILES.has(file)).toBe(false);
  });

  test("every local file the document page and the old admin load is among them", () => {
    for (const page of ["verify.html", "admin-login.html", "admin.html"]) {
      const html = readFileSync(join(publicDir, page), "utf8");
      const local = [...html.matchAll(/(?:src|href)="(\/[^"/][^"]*)"/g)].map((match) => (match[1] ?? "").split("?")[0] ?? "");
      for (const path of local) expect([page, path, API_HOST_STATIC_FILES.has(path) || path === "/admin" || path.startsWith("/admin/")]).toEqual([page, path, true]);
    }
  });
});
