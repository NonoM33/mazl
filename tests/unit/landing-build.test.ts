import { beforeAll, describe, expect, test } from "bun:test";
import { readdir } from "node:fs/promises";
import { join } from "node:path";

// Builds the showcase for real and reads what a visitor (and the strict CSP)
// would get: no third-party script or font, the key texts, the legal links.

const dist = join(import.meta.dir, "..", "..", "landing", "dist");
let html = "";
let files: string[] = [];

beforeAll(async () => {
  const build = Bun.spawn(["bun", "landing/build.ts"], { cwd: join(import.meta.dir, "..", ".."), stdout: "pipe", stderr: "pipe", env: { ...process.env, NODE_ENV: "production" } });
  expect(await build.exited).toBe(0);
  html = await Bun.file(join(dist, "index.html")).text();
  files = await readdir(dist);
}, 60_000);

const THIRD_PARTY = /googleapis|gstatic|cdn\.|unpkg|jsdelivr|cdnjs|google-analytics|googletagmanager/i;
const text = (value: string): string => value.replace(/&nbsp;|&#8239;| | /g, " ").replace(/<[^>]+>/g, "").replace(/\s+/g, " ");

describe("showcase build", () => {
  test("code, styles and fonts are local, hashed files served under /l/", () => {
    expect(files.some((f) => /^index-[a-z0-9]{8}\.js$/.test(f))).toBe(true);
    expect(files.some((f) => /^index-[a-z0-9]{8}\.css$/.test(f))).toBe(true);
    expect(files).toContain("fonts");
    expect(html).toMatch(/<script[^>]+src="\/l\/index-[a-z0-9]{8}\.js"/);
    expect(html).toMatch(/<link[^>]+href="\/l\/index-[a-z0-9]{8}\.css"/);
  });

  test("no external script, stylesheet, font, frame or image anywhere", async () => {
    expect(html).not.toMatch(THIRD_PARTY);
    expect(html).not.toMatch(/<(script|iframe|img)[^>]+src="(https?:)?\/\//);
    expect(html).not.toMatch(/<link[^>]+rel="(stylesheet|preload|modulepreload|icon)"[^>]+href="(https?:)?\/\//);
    expect(html).not.toMatch(/<iframe|<img/);
    for (const file of files.filter((f) => /\.(js|css)$/.test(f))) {
      expect([file, THIRD_PARTY.test(await Bun.file(join(dist, file)).text())]).toEqual([file, false]);
    }
  });

  test("no inline script: the strict CSP forbids it", () => {
    for (const script of html.matchAll(/<script\b[^>]*>/g)) expect(script[0]).toContain("src=");
    expect(html).not.toMatch(/<script[^>]*>\s*[^<\s]/);
    expect(html).not.toMatch(/\son[a-z]+="/);
  });

  test("the key texts are real HTML, in French", () => {
    const visible = text(html);
    for (const expected of [
      "Trouvez votre mazal", "Des profils vérifiés", "Un selfie en direct", "La puce NFC", "Une compatibilité qui comprend votre pratique",
      "Orthodoxe moderne", "Habad", "Chabbat chalom", "passe en mode couple", "Votre mère sera ravie", "chez les parents", "scannez le QR code", "Une modération humaine", "consentement explicite", "Votre mazal vous attend",
    ]) expect([expected, visible.includes(expected)]).toEqual([expected, true]);
    expect(html).toContain('<html lang="fr">');
    expect(html).toMatch(/<meta name="description" content="[^"]{60,}/);
    expect(html).toContain('property="og:title"');
    expect(html).toContain('property="og:description"');
  });

  test("links go to the client, the legal pages and the store; no placeholder is left", () => {
    for (const href of ["/app", "/cgu", "/cgv", "/confidentialite", "/mentions-legales", "/cookies"]) expect(html).toContain(`href="${href}"`);
    expect(html).toMatch(/href="https:\/\/apps\.apple\.com\/app\/id\d+"/);
    expect(html).not.toContain("{{");
    expect(html).not.toContain("TODO_APP_STORE_URL");
  });

  test("the page has one h1 and its sections are titled", () => {
    expect(html.match(/<h1[\s>]/g)?.length).toBe(1);
    expect(html.match(/<h2[\s>]/g)?.length ?? 0).toBeGreaterThanOrEqual(6);
  });

  test("the page stays light: no 3D engine, the stylesheet carries no inlined image", async () => {
    const script = files.find((f) => /^index-[a-z0-9]{8}\.js$/.test(f)) ?? "";
    const style = files.find((f) => /^index-[a-z0-9]{8}\.css$/.test(f)) ?? "";
    expect(Bun.file(join(dist, `${script}.gz`)).size).toBeLessThan(20 * 1024);
    expect(Bun.file(join(dist, `${style}.gz`)).size).toBeLessThan(20 * 1024);
    expect(await Bun.file(join(dist, style)).text()).not.toContain("data:image");
  });

  test("every photo the stylesheet asks for is a local file under /l/photos/, named after its source", async () => {
    const style = files.find((f) => /^index-[a-z0-9]{8}\.css$/.test(f)) ?? "";
    const photos = [...(await Bun.file(join(dist, style)).text()).matchAll(/url\("?([^")]+\.webp)"?\)/g)].map((match) => match[1] ?? "");
    expect(photos.length).toBeGreaterThanOrEqual(3);
    for (const photo of photos) {
      expect(photo).toMatch(/^\/l\/photos\/[a-z-]+-\d{13}\.webp$/);
      expect([photo, await Bun.file(join(dist, photo.slice(3))).exists()]).toEqual([photo, true]);
    }
    expect(await readdir(join(dist, "photos"))).not.toContain("SOURCES.md");
  });

  test("the precompressed copies are really gzip", async () => {
    const script = files.find((f) => /^index-[a-z0-9]{8}\.js$/.test(f)) ?? "";
    const plain = await Bun.file(join(dist, script)).text();
    expect(new TextDecoder().decode(Bun.gunzipSync(await Bun.file(join(dist, `${script}.gz`)).bytes()))).toBe(plain);
  });
});
