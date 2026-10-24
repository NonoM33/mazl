// Captures of the showcase for review: bun landing/dev/screenshots.ts
// Serves landing/dist the way the API does (index at "/", files under /l/) and
// drives Chromium through Playwright (borrowed from the hermes install).
import { createRequire } from "node:module";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";

const require = createRequire("/Users/nono/.hermes/hermes-agent/node_modules/");
const { chromium } = require("playwright") as typeof import("playwright");

const dist = new URL("../dist", import.meta.url).pathname;
const out = new URL("../../docs/landing/captures", import.meta.url).pathname;
await mkdir(out, { recursive: true });

const server = Bun.serve({
  port: 0,
  async fetch(req) {
    const { pathname } = new URL(req.url);
    if (pathname === "/") return new Response(Bun.file(join(dist, "index.html")), { headers: { "Content-Type": "text/html; charset=utf-8" } });
    if (pathname.startsWith("/l/")) {
      const file = Bun.file(join(dist, pathname.slice(3)));
      if (await file.exists()) return new Response(file);
    }
    return new Response("Not found", { status: 404 });
  },
});
const base = `http://localhost:${server.port}/`;

const browser = await chromium.launch({ args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"] });
const only = process.argv[2];

async function settle(page: import("playwright").Page, ms = 1800): Promise<void> {
  await page.waitForTimeout(ms);
}

async function scrollToSelector(page: import("playwright").Page, selector: string, offset = 0): Promise<void> {
  await page.evaluate(([sel, off]) => {
    const element = document.querySelector(sel as string);
    if (element === null) throw new Error(`missing ${String(sel)}`);
    window.scrollTo({ top: element.getBoundingClientRect().top + window.scrollY - (off as number), behavior: "instant" });
  }, [selector, offset] as const);
}

async function scrollHero(page: import("playwright").Page, fraction: number): Promise<void> {
  await page.evaluate((f) => {
    const hero = document.querySelector<HTMLElement>("[data-hero]");
    if (hero === null) throw new Error("missing hero");
    window.scrollTo({ top: (hero.offsetHeight - window.innerHeight) * f, behavior: "instant" });
  }, fraction);
}

async function desktop(): Promise<void> {
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 });
  const page = await context.newPage();
  page.on("pageerror", (error) => console.error("page error:", error.message));
  page.on("console", (message) => { if (message.type() === "error") console.error("console:", message.text()); });
  await page.goto(base, { waitUntil: "networkidle" });
  await page.mouse.move(900, 380);
  await settle(page, 2600);
  await page.screenshot({ path: join(out, "desktop-01-hero.png") });
  await scrollHero(page, 0.4);
  await settle(page, 2200);
  await page.screenshot({ path: join(out, "desktop-02-hero-rapprochement.png") });
  await scrollHero(page, 1);
  await settle(page, 2200);
  await page.screenshot({ path: join(out, "desktop-03-hero-fil.png") });
  const sections: readonly (readonly [string, string, number])[] = [
    ["04-verification", "#verification", 60], ["05-compatibilite", "#compatibilite", 60], ["06-chabbat", "#chabbat", 0],
    ["07-couple", "#couple", 60], ["08-ordinateur", "#ordinateur", 60], ["09-securite", "#securite", 60], ["10-final", "#telecharger", 0],
  ];
  for (const [name, selector, offset] of sections) {
    await scrollToSelector(page, selector, offset);
    await settle(page);
    await page.screenshot({ path: join(out, `desktop-${name}.png`) });
  }
  await page.evaluate(() => window.scrollTo({ top: document.body.scrollHeight, behavior: "instant" }));
  await settle(page, 900);
  await page.screenshot({ path: join(out, "desktop-11-pied.png") });
  await context.close();
}

async function phone(): Promise<void> {
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
  const page = await context.newPage();
  page.on("pageerror", (error) => console.error("page error:", error.message));
  await page.goto(base, { waitUntil: "networkidle" });
  await settle(page, 2400);
  await page.screenshot({ path: join(out, "iphone-01-hero.png") });
  await scrollHero(page, 1);
  await settle(page, 2200);
  await page.screenshot({ path: join(out, "iphone-02-hero-fil.png") });
  for (const [name, selector, offset] of [["03-verification", "#verification", 60], ["04-compatibilite", "#compatibilite", 60], ["05-chabbat", "#chabbat", 0]] as const) {
    await scrollToSelector(page, selector, offset);
    await settle(page);
    await page.screenshot({ path: join(out, `iphone-${name}.png`) });
  }
  await context.close();
}

async function reduced(): Promise<void> {
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 }, reducedMotion: "reduce" });
  const page = await context.newPage();
  await page.goto(base, { waitUntil: "networkidle" });
  await settle(page, 1200);
  await page.screenshot({ path: join(out, "reduit-01-hero.png") });
  await scrollToSelector(page, "#chabbat", 0);
  await settle(page, 800);
  await page.screenshot({ path: join(out, "reduit-02-chabbat.png") });
  await context.close();
}

if (only === undefined || only === "desktop") await desktop();
if (only === undefined || only === "iphone") await phone();
if (only === undefined || only === "reduit") await reduced();
await browser.close();
server.stop(true);
console.log(`captures: ${out}`);
