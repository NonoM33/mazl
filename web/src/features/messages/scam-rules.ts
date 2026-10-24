// Anti-scam detector, ported from mobile/lib/core/chat/scam_rules.dart
// (docs/chat/CONTRAT.md §4). Pure and local: it reads a RECEIVED message and
// says whether it looks like the usual romance-scam openers. It warns, it never
// blocks, and nothing it reads leaves the page. French and English, accent- and
// case-insensitive, whole words only.

export const SCAM_EARLY_MESSAGE_COUNT = 20;

export type ScamKind = "money" | "giftCard" | "crypto" | "investment" | "offPlatform";

interface Rule { readonly kind: ScamKind; readonly pattern: RegExp; readonly earlyOnly: boolean }

// A "word" is a run of [a-z0-9]; these guards give \b semantics on text that
// has already been lower-cased and stripped of accents.
const S = "(?<![a-z0-9])";
const E = "(?![a-z0-9])";
const SEP = "[' ]?";

const rule = (kind: ScamKind, source: string, earlyOnly = false): Rule => ({ kind, pattern: new RegExp(source), earlyOnly });

const RULES: readonly Rule[] = [
  rule("giftCard", `${S}(?:cartes? cadeaux?|gift[ -]?cards?|itunes cards?|google play cards?)${E}`),
  rule("crypto", `${S}(?:crypto(?:monnaies?|currenc(?:y|ies))?s?|bitcoins?|btc|ethereum|usdt|binance|nfts?)${E}`),
  rule("investment", `${S}(?:`
    + "opportunites? d'? ?investissements?|investment opportunit(?:y|ies)|investment platform|"
    + "plateformes? d'? ?investissements?|rendements? garantis?|gains? garantis?|guaranteed (?:returns?|profits?)|"
    + "trading(?! card)|forex|revenus? passifs?|passive income|"
    + `doubl(?:er|e|ez) (?:ton|votre|son) argent|double your money)${E}`),
  rule("money", `${S}(?:`
    + "virements?|iban|rib|western union|moneygram|mandat cash|bank transfer|wire transfer|money transfer|"
    + `besoin d'? ?argent|(?:envoy|vir|pret|don|transf)\\w*(?:[- ]moi)?(?: de)? l${SEP}argent|`
    + "need (?:some )?(?:money|cash)|(?:send|wire|transfer|lend|give)(?: me)? (?:some |the )?(?:money|cash)|"
    + `lend me)${E}`),
  rule("offPlatform", `${S}(?:whats ?app|watsap|telegram|viber|wechat)${E}`, true),
  // "signal" is also a plain word: only when it names the app.
  rule("offPlatform",
    `(?:${S}(?:sur|via|par|on|through|over|to|en|vers) (?:the |l'?|app )?signal${E})|`
    + `(?:${S}(?:t'?as|tu as|do you have|you have|have you got) signal${E})|`
    + `(?:${S}signal (?:app|messenger)${E})`, true),
  // 9+ digits, optionally grouped: a phone number, not a date or a year.
  rule("offPlatform", "(?<![0-9])(?:\\+|00)?[0-9](?:[ .\\-]?[0-9]){8,}(?![0-9])", true),
  rule("offPlatform",
    `${S}(?:donne|passe|envoie|file|give|send|share)\\w*(?:-| )?(?:moi|me)? ?(?:ton|ta|votre|your) (?:numero|num|tel|telephone|phone|number)${E}`, true),
];

const ACCENTS: Readonly<Record<string, string>> = {
  à: "a", â: "a", ä: "a", á: "a", ã: "a", å: "a",
  é: "e", è: "e", ê: "e", ë: "e",
  î: "i", ï: "i", í: "i", ì: "i",
  ô: "o", ö: "o", ó: "o", ò: "o", õ: "o",
  ù: "u", û: "u", ü: "u", ú: "u",
  ç: "c", ñ: "n", ÿ: "y", œ: "oe", æ: "ae",
  "’": "'", "‘": "'", "`": "'", "´": "'",
};

function normalize(text: string): string {
  let out = "";
  for (const ch of text.toLowerCase()) out += ACCENTS[ch] ?? ch;
  return out.replace(/\s+/g, " ").trim();
}

// `position` is the 0-based rank of the message in the conversation.
// Returns the kind detected, never any part of the text.
export function detectScam(text: string, position: number): ScamKind | null {
  const normalized = normalize(text);
  if (normalized.length === 0) return null;
  const early = position < SCAM_EARLY_MESSAGE_COUNT;
  for (const item of RULES) {
    if (item.earlyOnly && !early) continue;
    if (item.pattern.test(normalized)) return item.kind;
  }
  return null;
}
