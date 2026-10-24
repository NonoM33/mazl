import { beforeAll, describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { buildConsole, type ConsoleBuild } from "../../src/features/console/console.bundle";
import { registerConsoleRoutes } from "../../src/features/console/console.routes";

let build: ConsoleBuild;
let app: Hono;
let buildCalls = 0;

beforeAll(async () => {
  build = await buildConsole({ development: false });
  app = new Hono();
  registerConsoleRoutes(app, {
    development: false,
    build: async () => {
      buildCalls += 1;
      return build;
    },
  });
}, 60_000);

const assetPaths = (html: string): string[] => [...html.matchAll(/(?:src|href)="(\/console\/[^"]+)"/g)].map((match) => match[1] ?? "");

describe("console — page", () => {
  test("GET /console et /console/ servent index.html sans cache", async () => {
    for (const path of ["/console", "/console/"]) {
      const res = await app.request(path);
      expect(res.status).toBe(200);
      expect(res.headers.get("content-type")).toContain("text/html");
      expect(res.headers.get("cache-control")).toBe("no-store");
      const html = await res.text();
      expect(html).toContain('<div id="root">');
      expect(html).toContain('lang="fr"');
    }
  });

  test("le HTML ne référence que des fichiers sous /console/assets/", async () => {
    const html = await (await app.request("/console")).text();
    const paths = assetPaths(html);
    expect(paths.length).toBeGreaterThanOrEqual(2);
    for (const path of paths) expect(path.startsWith("/console/assets/")).toBe(true);
  });
});

describe("console — fichiers", () => {
  test("script et feuille de style servis avec le bon type, cachés à vie", async () => {
    const html = await (await app.request("/console")).text();
    const script = assetPaths(html).find((path) => path.endsWith(".js"));
    const style = assetPaths(html).find((path) => path.endsWith(".css"));
    expect(script).toBeDefined();
    expect(style).toBeDefined();
    const js = await app.request(script ?? "");
    expect(js.status).toBe(200);
    expect(js.headers.get("content-type")).toContain("javascript");
    expect(js.headers.get("cache-control")).toContain("immutable");
    const css = await app.request(style ?? "");
    expect(css.status).toBe(200);
    expect(css.headers.get("content-type")).toContain("text/css");
  });

  test("les polices Geist et Geist Mono sont servies depuis /console/fonts/", async () => {
    for (const name of ["Geist-400.ttf", "Geist-700.ttf", "GeistMono-500.ttf"]) {
      const res = await app.request(`/console/fonts/${name}`);
      expect(res.status).toBe(200);
      expect(res.headers.get("content-type")).toBe("font/ttf");
      expect((await res.arrayBuffer()).byteLength).toBeGreaterThan(50_000);
    }
  });

  test("le CSS référence les polices en fichiers (la CSP interdit data: pour font-src)", async () => {
    const html = await (await app.request("/console")).text();
    const style = assetPaths(html).find((path) => path.endsWith(".css")) ?? "";
    const css = await (await app.request(style)).text();
    expect(css).toContain("/console/fonts/Geist-400.ttf");
    expect(css).not.toContain("data:font");
    expect(css).not.toContain("data:application/font");
  });
});

describe("console — 404 et confidentialité", () => {
  test("fichier inconnu, chemin remonté, autre chemin sous /console/ : 404", async () => {
    expect((await app.request("/console/assets/inconnu.js")).status).toBe(404);
    expect((await app.request("/console/fonts/inconnue.ttf")).status).toBe(404);
    expect((await app.request("/console/assets/..%2F..%2Fpackage.json")).status).toBe(404);
    expect((await app.request("/console/src/main.tsx")).status).toBe(404);
    expect((await app.request("/console/index.html")).status).toBe(404);
  });

  test("aucun appel à Google Fonts ni à un CDN dans le bundle servi", async () => {
    const forbidden = ["fonts.googleapis.com", "fonts.gstatic.com", "cdn.jsdelivr", "unpkg.com", "cdnjs"];
    for (const [name, asset] of build.files) {
      if (!asset.type.startsWith("text/") && !asset.type.includes("javascript")) continue;
      const text = new TextDecoder().decode(asset.bytes);
      for (const host of forbidden) expect(`${name}:${text.includes(host)}`).toBe(`${name}:false`);
    }
    const html = new TextDecoder().decode(build.index.bytes);
    for (const host of forbidden) expect(html.includes(host)).toBe(false);
  });

  test("pas d'eval ni de new Function dans le script (CSP sans unsafe-eval)", () => {
    const js = [...build.files.entries()].filter(([name]) => name.endsWith(".js"));
    expect(js.length).toBeGreaterThan(0);
    for (const [, asset] of js) {
      const text = new TextDecoder().decode(asset.bytes);
      expect(/\beval\s*\(/.test(text)).toBe(false);
      expect(/new Function\s*\(/.test(text)).toBe(false);
    }
  });

  test("le bundle de production est construit une seule fois", async () => {
    await app.request("/console");
    await app.request("/console");
    expect(buildCalls).toBe(1);
  });
});

describe("console — développement", () => {
  test("reconstruit à chaque chargement de la page", async () => {
    let calls = 0;
    const dev = new Hono();
    registerConsoleRoutes(dev, {
      development: true,
      build: async () => {
        calls += 1;
        return build;
      },
    });
    await dev.request("/console");
    await dev.request("/console");
    expect(calls).toBe(2);
  });

  test("un échec de construction répond 503 sans fuite de détail, puis se rétablit", async () => {
    let fail = true;
    const flaky = new Hono();
    registerConsoleRoutes(flaky, {
      development: true,
      build: async () => {
        if (fail) throw new Error("secret interne");
        return build;
      },
    });
    const bad = await flaky.request("/console");
    expect(bad.status).toBe(503);
    expect(await bad.text()).not.toContain("secret");
    fail = false;
    expect((await flaky.request("/console")).status).toBe(200);
  });
});
