import { describe, expect, test } from "bun:test";
import { Glob } from "bun";
import { join } from "node:path";

// Renaud, 2026-10-27: the showcase follows the app's spelling, "Shabbat",
// "cacher", "cacherout" (docs/marque/BIBLE-MARQUE.md §6). The server's
// versioned consent wording is left out: changing it would ask every member
// to consent again.
const root = join(import.meta.dir, "..", "..");
const LEGACY = /chabbat|chalom|cashrout|cachrout|kashrout/i;
const SURFACES = ["landing/index.html", "public/*.html", "docs/legal/*.md", "web/src/**/*.{ts,tsx}"];

describe("the showcase, the legal pages and the web client spell like the app", () => {
  test("no Chabbat, chalom or cashrout left", async () => {
    const offenders: string[] = [];
    for (const pattern of SURFACES) {
      for await (const path of new Glob(pattern).scan({ cwd: root })) {
        const lines = (await Bun.file(join(root, path)).text()).split("\n");
        lines.forEach((line, i) => { if (LEGACY.test(line)) offenders.push(`${path}:${i + 1}`); });
      }
    }
    expect(offenders).toEqual([]);
  });
});
