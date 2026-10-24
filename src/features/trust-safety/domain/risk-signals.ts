import type { RiskSignal } from "./types";

// Weak signals of romance scam or fake profile, from aggregated data. They are
// shown to the moderator and decide nothing. The evidence is a COUNT, never the
// text of a message.

export interface RecentMessage {
  readonly text: string;
  readonly conversationId: number;
}

export interface RiskInput {
  readonly messages: readonly RecentMessage[];
  readonly accountAgeDays: number;
  readonly reportsCount: number;
  readonly blocksReceived: number;
  readonly verified: boolean;
}

const MONEY = /\b(argent|virement|western\s*union|carte\s*cadeau|pcs|transcash)\b/;
const CRYPTO = /\b(crypto\w*|bitcoin|usdt|binance|investissement\w*)\b/;
const MESSENGER = /\b(whatsapp|telegram|signal|snap|snapchat)\b/;
const FRENCH_PHONE = /(?:\+33|0033|\b0)\s?[1-9](?:[\s.-]?\d{2}){4}\b/;
const INTERNATIONAL_PHONE = /\+\d{1,3}[\s.-]?\d(?:[\s.-]?\d){7,12}/;

const NEW_ACCOUNT_DAYS = 7;
const MANY_REPORTS = 3;
const MANY_BLOCKS = 3;
const COPY_PASTE_MIN = 3;
const COPY_PASTE_MIN_LENGTH = 12;

function fold(text: string): string {
  return text.normalize("NFD").replace(/\p{Diacritic}/gu, "").toLowerCase();
}

function countMatching(messages: readonly RecentMessage[], test: (folded: string) => boolean): number {
  return messages.filter((message) => test(fold(message.text))).length;
}

function plural(count: number, one: string, many: string): string {
  return count === 1 ? one : many;
}

function messageSignal(
  code: RiskSignal["code"],
  label: string,
  weight: number,
  count: number,
  what: string,
): RiskSignal | null {
  if (count === 0) return null;
  const verb = plural(count, "message mentionne", "messages mentionnent");
  return { code, label, weight, evidence: `${count} ${verb} ${what}` };
}

function normalizedForCopy(text: string): string {
  return fold(text).replace(/[^\p{L}\p{N}]+/gu, " ").trim();
}

function copyPasteCount(messages: readonly RecentMessage[]): number {
  const groups = new Map<string, { count: number; conversations: Set<number> }>();
  for (const message of messages) {
    const key = normalizedForCopy(message.text);
    if (key.length < COPY_PASTE_MIN_LENGTH) continue;
    const group = groups.get(key) ?? { count: 0, conversations: new Set<number>() };
    group.count += 1;
    group.conversations.add(message.conversationId);
    groups.set(key, group);
  }
  let largest = 0;
  for (const group of groups.values()) {
    if (group.count >= COPY_PASTE_MIN && group.conversations.size >= COPY_PASTE_MIN) largest = Math.max(largest, group.count);
  }
  return largest;
}

function messageSignals(messages: readonly RecentMessage[]): RiskSignal[] {
  const money = countMatching(messages, (text) => MONEY.test(text));
  const crypto = countMatching(messages, (text) => CRYPTO.test(text));
  const external = countMatching(messages, (text) => MESSENGER.test(text) || FRENCH_PHONE.test(text) || INTERNATIONAL_PHONE.test(text));
  const copies = copyPasteCount(messages);
  const found = [
    messageSignal("money_request", "Demande d'argent", 3, money, "de l'argent ou un moyen de paiement"),
    messageSignal("crypto", "Cryptomonnaie ou investissement", 2, crypto, "une cryptomonnaie ou un investissement"),
    messageSignal("off_platform", "Sortie de la plateforme", 2, external, "une messagerie externe ou un numéro de téléphone"),
    copies > 0
      ? {
          code: "copy_paste" as const,
          label: "Message copié-collé",
          weight: 3,
          evidence: `${copies} messages identiques envoyés à des destinataires différents`,
        }
      : null,
  ];
  return found.filter((signal): signal is RiskSignal => signal !== null);
}

function profileSignals(input: RiskInput): RiskSignal[] {
  const signals: RiskSignal[] = [];
  if (input.accountAgeDays < NEW_ACCOUNT_DAYS) {
    signals.push({ code: "new_account", label: "Compte récent", weight: 1, evidence: `Compte créé il y a ${Math.max(0, Math.floor(input.accountAgeDays))} jour(s)` });
  }
  if (input.reportsCount >= MANY_REPORTS) {
    signals.push({ code: "many_reports", label: "Signalements multiples", weight: 2, evidence: `${input.reportsCount} signalements reçus` });
  }
  if (input.blocksReceived >= MANY_BLOCKS) {
    signals.push({ code: "many_blocks", label: "Blocages multiples", weight: 2, evidence: `${input.blocksReceived} blocages reçus` });
  }
  if (!input.verified) {
    signals.push({ code: "no_verification", label: "Profil non vérifié", weight: 1, evidence: "Aucune vérification d'identité ou de photo" });
  }
  return signals;
}

export function detectRiskSignals(input: RiskInput): RiskSignal[] {
  return [...messageSignals(input.messages), ...profileSignals(input)].sort((a, b) => b.weight - a.weight);
}
