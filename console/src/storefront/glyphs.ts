// Glyphes des thèmes : SVG importés tels quels (texte) depuis ./glyphs, remplacés à la fusion par les vrais dessins.
import type { GlyphId } from "./types";
import heart from "./glyphs/heart.svg" with { type: "text" };
import two_hearts from "./glyphs/two_hearts.svg" with { type: "text" };
import pomegranate from "./glyphs/pomegranate.svg" with { type: "text" };
import flame from "./glyphs/flame.svg" with { type: "text" };
import fir from "./glyphs/fir.svg" with { type: "text" };
import sparkle from "./glyphs/sparkle.svg" with { type: "text" };
import mask from "./glyphs/mask.svg" with { type: "text" };
import matzah from "./glyphs/matzah.svg" with { type: "text" };
import flower from "./glyphs/flower.svg" with { type: "text" };
import sun from "./glyphs/sun.svg" with { type: "text" };
import bolt from "./glyphs/bolt.svg" with { type: "text" };

export const GLYPH_SVG: Readonly<Record<GlyphId, string>> = { heart, two_hearts, pomegranate, flame, fir, sparkle, mask, matzah, flower, sun, bolt };

/** Le SVG complet, placé et dimensionné pour se nicher dans un autre SVG (icône d'app) : ses attributs (fill, stroke…) restent ceux du dessin. */
export function nestedSvg(svg: string, x: number, y: number, size: number): string {
  return svg.trim().replace(/<svg/, `<svg x="${x}" y="${y}" width="${size}" height="${size}"`);
}
