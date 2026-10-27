import { describe, expect, test } from "bun:test";
import { Glob } from "bun";
import { join } from "node:path";

// Décision de Renaud du 2026-10-25 pour la v1 : ni le site ni le client web ne
// promettent ce que l'app ne fait pas. Le mode Shabbat de l'app donne les
// horaires du lieu du membre et un écran de repos, rien de plus ; il n'y a ni
// appel vidéo, ni intelligence artificielle, ni Android, ni connexion par e-mail.

const root = join(import.meta.dir, "..", "..");
const visible = (html: string): string =>
  html.replace(/&nbsp;|&#8239;| | /g, " ").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ");

describe("the showcase promises only what the app does", () => {
  test("Shabbat: times for the member's city, not a paused app", async () => {
    const page = visible(await Bun.file(join(root, "landing", "index.html")).text());
    expect(page).not.toMatch(/se met en pause|met MAZL en pause|se repose|dans les CGU|vous attendront/i);
    expect(page).toMatch(/pour votre ville[^.]*allumage[^.]*havdala/i);
  });

  test("no retired feature is announced", async () => {
    const page = visible(await Bun.file(join(root, "landing", "index.html")).text());
    for (const retired of [/android/i, /google play/i, /appels? vidéo/i, /visio/i, /retour en arrière/i, /annuler le dernier/i, /intelligence artificielle/i, /\bIA\b/, /shadchan/i]) {
      expect([String(retired), retired.test(page)]).toEqual([String(retired), false]);
    }
  });

  test("verification: a badge, since verifying a profile is optional", async () => {
    const page = visible(await Bun.file(join(root, "landing", "index.html")).text());
    expect(page).not.toContain("Chaque profil est vérifié");
  });
});

describe("the web client does not send members to a video call that does not exist", () => {
  test("no source of the web client mentions a video call", async () => {
    const offenders: string[] = [];
    for await (const path of new Glob("web/src/**/*.{ts,tsx}").scan({ cwd: root })) {
      const source = await Bun.file(join(root, path)).text();
      if (/appels? vidéo|video calls?/i.test(source)) offenders.push(path);
    }
    expect(offenders).toEqual([]);
  });
});
