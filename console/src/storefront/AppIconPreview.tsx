import type { CSSProperties, ReactElement } from "react";
import { GLYPH_SVG, innerSvg } from "./glyphs";
import { isInverseTheme, themeById } from "./themes";
import type { ThemeId } from "./types";

const INK = "#0B0B0F";
const PAPER = "#FFFFFF";
const TEKHELET = "#2747F5";

/**
 * Icône de l'app : carré encre arrondi, « m » blanc (Geist 700), le point tekhelet remplacé par le glyphe du thème
 * dans sa couleur d'accent. Le Black Friday est en inverse (fond clair, « m » encre). `themeId` null : l'icône habituelle.
 */
export function AppIconPreview({ themeId, size = 96, label }: { readonly themeId: ThemeId | null; readonly size?: number; readonly label?: string }): ReactElement {
  const theme = themeId === null ? null : themeById(themeId);
  const inverse = themeId !== null && isInverseTheme(themeId);
  const background = inverse ? PAPER : INK;
  const letter = inverse ? INK : PAPER;
  const style: CSSProperties = { width: size, height: size };
  return (
    <svg className="app-icon" style={style} viewBox="0 0 100 100" role="img" aria-label={label ?? (theme === null ? "Icône habituelle de l'app" : `Icône de l'app, thème ${theme.label}`)}>
      <rect x="0.5" y="0.5" width="99" height="99" rx="22" fill={background} stroke={inverse ? "#D4D4DA" : "none"} />
      <text x="14" y="71" fontFamily="Geist, system-ui, sans-serif" fontWeight="700" fontSize="62" letterSpacing="-3" fill={letter}>
        m
      </text>
      {theme === null ? (
        <circle cx="78" cy="66" r="5.5" fill={TEKHELET} />
      ) : (
        <g transform="translate(66 47) scale(1.2)" color={theme.accent} fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" dangerouslySetInnerHTML={{ __html: innerSvg(GLYPH_SVG[theme.glyph]) }} />
      )}
    </svg>
  );
}
