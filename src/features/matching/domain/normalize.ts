import type { OrdinalScale } from "./params";

const ACCENTS: Readonly<Record<string, string>> = {
  à: "a", â: "a", ç: "c", é: "e", è: "e", ê: "e", ë: "e", î: "i", ï: "i", ô: "o", ù: "u", û: "u",
};

export function answerKey(raw: string): string {
  const lower = raw.trim().toLowerCase();
  const plain = Array.from(lower, (ch) => ACCENTS[ch] ?? ch).join("");
  return plain.replace(/[\s-]+/g, "_");
}

export function rankOf(scale: OrdinalScale, raw: string | null | undefined): number | null {
  if (raw === null || raw === undefined) return null;
  const key = answerKey(raw);
  if (key === "" || key === "autre") return null;
  return Object.hasOwn(scale, key) ? (scale[key] ?? null) : null;
}
