import themesFile from "../../../../docs/storefront/themes.json";

export const THEME_IDS = [
  "valentine",
  "tu_bav",
  "rosh_hashana",
  "hanukkah",
  "christmas",
  "new_year",
  "purim",
  "passover",
  "mothers_day",
  "summer",
  "black_friday",
] as const;
export type ThemeId = (typeof THEME_IDS)[number];

export type HebrewMonthName = "tishrei" | "kislev" | "adar" | "nisan" | "av";
const HEBREW_MONTHS: readonly HebrewMonthName[] = ["tishrei", "kislev", "adar", "nisan", "av"];

export type ThemeRule =
  | { readonly type: "fixed"; readonly month: number; readonly day: number; readonly days: number }
  | { readonly type: "hebrew"; readonly month: HebrewMonthName; readonly day: number; readonly days: number }
  | { readonly type: "fr_mothers_day"; readonly days: number }
  | { readonly type: "black_friday"; readonly days: number };

export interface Theme {
  readonly id: ThemeId;
  readonly glyph: string;
  readonly accent: string;
  readonly rule: ThemeRule;
  // Days before the first day of the event and after its last day.
  readonly window: readonly [number, number];
}

export function isThemeId(value: string): value is ThemeId {
  return (THEME_IDS as readonly string[]).includes(value);
}

interface RawTheme {
  readonly id: string;
  readonly glyph: string;
  readonly accent: string;
  readonly rule: { readonly type: string; readonly month?: string | number; readonly day?: number; readonly days?: number };
  readonly window: readonly number[];
}

function parseRule(raw: RawTheme["rule"], id: string): ThemeRule {
  const days = raw.days ?? 1;
  if (raw.type === "fixed" && typeof raw.month === "number" && typeof raw.day === "number") {
    return { type: "fixed", month: raw.month, day: raw.day, days };
  }
  if (raw.type === "hebrew" && typeof raw.day === "number" && HEBREW_MONTHS.includes(raw.month as HebrewMonthName)) {
    return { type: "hebrew", month: raw.month as HebrewMonthName, day: raw.day, days };
  }
  if (raw.type === "fr_mothers_day") return { type: "fr_mothers_day", days };
  if (raw.type === "black_friday") return { type: "black_friday", days };
  throw new Error(`themes.json: unusable rule for theme ${id}`);
}

export function parseThemes(raw: { readonly themes: readonly RawTheme[] }): readonly Theme[] {
  return raw.themes.map((theme) => {
    if (!isThemeId(theme.id)) throw new Error(`themes.json: unknown theme id ${theme.id}`);
    const [before, after] = theme.window;
    if (before === undefined || after === undefined) throw new Error(`themes.json: window of ${theme.id}`);
    return { id: theme.id, glyph: theme.glyph, accent: theme.accent, rule: parseRule(theme.rule, theme.id), window: [before, after] as const };
  });
}

export const THEMES: readonly Theme[] = parseThemes(themesFile);

export function themeById(id: ThemeId): Theme {
  const theme = THEMES.find((candidate) => candidate.id === id);
  if (theme === undefined) throw new Error(`Theme ${id} missing from themes.json`);
  return theme;
}
