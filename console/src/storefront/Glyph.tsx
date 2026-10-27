import type { ReactElement } from "react";
import { GLYPH_SVG } from "./glyphs";
import type { GlyphId } from "./types";

/** Glyphe d'un thème dans la couleur du texte courant (`currentColor`). */
export function Glyph({ glyph, size = 18, label }: { readonly glyph: GlyphId; readonly size?: number; readonly label?: string }): ReactElement {
  return (
    <span
      className="glyph"
      style={{ width: size, height: size }}
      role={label === undefined ? undefined : "img"}
      aria-label={label}
      aria-hidden={label === undefined ? true : undefined}
      dangerouslySetInnerHTML={{ __html: GLYPH_SVG[glyph] }}
    />
  );
}
