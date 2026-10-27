import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { GLYPH_SVG, nestedSvg } from "../../console/src/storefront/glyphs";
import { GLYPHS } from "../../console/src/storefront/types";
import themesFile from "../../docs/storefront/themes.json";

describe("glyphes des thèmes", () => {
  test("chaque glyphe de themes.json a son SVG, 24 × 24, dans la couleur du texte", () => {
    for (const theme of themesFile.themes) {
      const svg = GLYPH_SVG[theme.glyph as (typeof GLYPHS)[number]];
      expect(svg).toBeDefined();
      expect(svg).toContain('viewBox="0 0 24 24"');
      expect(svg).toContain("currentColor");
    }
    expect(Object.keys(GLYPH_SVG).sort()).toEqual([...GLYPHS].sort());
  });
  test("les SVG importés sont ceux du dossier glyphs, sans transformation", () => {
    for (const glyph of GLYPHS) {
      expect(GLYPH_SVG[glyph]).toBe(readFileSync(join(import.meta.dir, "../../console/src/storefront/glyphs", `${glyph}.svg`), "utf8"));
    }
  });
  test("nestedSvg place et dimensionne le dessin sans perdre ses attributs", () => {
    expect(nestedSvg('<svg viewBox="0 0 24 24" fill="currentColor"><path d="M0 0"/></svg>\n', 66, 47, 29)).toBe('<svg x="66" y="47" width="29" height="29" viewBox="0 0 24 24" fill="currentColor"><path d="M0 0"/></svg>');
  });
});
