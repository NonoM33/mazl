// Thèmes saisonniers : source unique docs/storefront/themes.json (serveur, console et app).
import themesFile from "../../../docs/storefront/themes.json";
import type { GlyphId, ThemeId } from "./types";

interface ThemeJson {
  readonly id: ThemeId;
  readonly glyph: GlyphId;
  readonly accent: string;
  readonly rule: { readonly type: string };
  readonly window: readonly [number, number];
}

export interface ThemeDef {
  readonly id: ThemeId;
  readonly glyph: GlyphId;
  readonly accent: string;
  readonly label: string;
  /** Fête juive : la campagne commence la veille au soir. */
  readonly hebrew: boolean;
}

const LABELS: Readonly<Record<ThemeId, string>> = {
  valentine: "Saint-Valentin",
  tu_bav: "Tou be-Av",
  rosh_hashana: "Roch Hachana",
  hanukkah: "Hanoucca",
  christmas: "Noël",
  new_year: "Nouvel An",
  purim: "Pourim",
  passover: "Pessah",
  mothers_day: "Fête des mères",
  summer: "Été",
  black_friday: "Black Friday",
};

export const THEMES: readonly ThemeDef[] = (themesFile.themes as unknown as readonly ThemeJson[]).map((theme) => ({
  id: theme.id,
  glyph: theme.glyph,
  accent: theme.accent,
  label: LABELS[theme.id],
  hebrew: theme.rule.type === "hebrew",
}));

export function themeById(id: ThemeId): ThemeDef {
  const found = THEMES.find((theme) => theme.id === id);
  if (found === undefined) throw new Error(`Thème inconnu : ${id}`);
  return found;
}

/** Le thème « Black Friday » a une icône inversée (fond clair, « m » encre). */
export const isInverseTheme = (id: ThemeId): boolean => id === "black_friday";
