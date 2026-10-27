export const LANGUAGES = ["fr", "en", "he", "es", "ru"] as const;
export type Language = (typeof LANGUAGES)[number];
export const DEFAULT_LANGUAGE: Language = "fr";

// Texts a member can read, per language. French is always there: it is the fallback.
export type LocalizedText = { readonly fr: string } & Partial<Record<Exclude<Language, "fr">, string>>;

export function isLanguage(value: string): value is Language {
  return (LANGUAGES as readonly string[]).includes(value);
}

export function pickText(texts: LocalizedText, language: Language): string {
  return texts[language] ?? texts.fr;
}

// The first supported language of an Accept-Language header, by quality; French otherwise.
export function negotiateLanguage(header: string | null | undefined): Language {
  if (header === null || header === undefined) return DEFAULT_LANGUAGE;
  const ranked = header
    .split(",")
    .map((part, index) => {
      const [tag = "", ...params] = part.trim().split(";");
      const quality = params.map((p) => p.trim()).find((p) => p.startsWith("q="));
      const q = quality === undefined ? 1 : Number(quality.slice(2));
      return { language: tag.trim().toLowerCase().split("-")[0] ?? "", q: Number.isFinite(q) ? q : 0, index };
    })
    .filter((entry) => entry.q > 0)
    .sort((a, b) => b.q - a.q || a.index - b.index);
  for (const entry of ranked) {
    // The old ISO code of Hebrew.
    const code = entry.language === "iw" ? "he" : entry.language;
    if (isLanguage(code)) return code;
  }
  return DEFAULT_LANGUAGE;
}
