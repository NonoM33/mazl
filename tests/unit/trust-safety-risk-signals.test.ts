import { describe, expect, test } from "bun:test";
import { detectRiskSignals, type RiskInput } from "../../src/features/trust-safety/domain/risk-signals";

function facts(overrides: Partial<RiskInput> = {}): RiskInput {
  return { messages: [], accountAgeDays: 90, reportsCount: 0, blocksReceived: 0, verified: true, ...overrides };
}

const codes = (input: RiskInput) => detectRiskSignals(input).map((signal) => signal.code);
const say = (...texts: string[]) => texts.map((text, index) => ({ text, conversationId: index + 1 }));

describe("risk signals", () => {
  test("a quiet, verified, old account raises nothing", () => {
    expect(detectRiskSignals(facts({ messages: say("Salut, ça va ?", "On se voit samedi ?") }))).toEqual([]);
  });

  test("money keywords", () => {
    for (const text of ["Tu peux m'envoyer de l'argent ?", "fais un virement", "Western Union stp", "une carte cadeau", "un ticket PCS", "recharge Transcash"]) {
      expect(codes(facts({ messages: say(text) }))).toContain("money_request");
    }
  });

  test("crypto keywords", () => {
    for (const text of ["j'investis en bitcoin", "de la crypto", "paie en USDT", "sur Binance", "un investissement sûr"]) {
      expect(codes(facts({ messages: say(text) }))).toContain("crypto");
    }
  });

  test("leaving the platform: messengers and phone numbers", () => {
    for (const text of ["écris-moi sur WhatsApp", "ajoute-moi sur Telegram", "mon snap", "sur Signal", "appelle le 06 12 34 56 78", "0612345678", "+33 6 12 34 56 78", "+1 415 555 2671"]) {
      expect(codes(facts({ messages: say(text) }))).toContain("off_platform");
    }
  });

  test("three identical messages to three different people", () => {
    const text = "Bonjour, je suis militaire à l'étranger et je cherche l'amour";
    const same = [1, 2, 3].map((conversationId) => ({ text: i(text, conversationId), conversationId }));
    expect(codes(facts({ messages: same }))).toContain("copy_paste");
  });

  test("three identical messages to the same person are not a copy-paste campaign", () => {
    const text = "Bonjour, je suis militaire à l'étranger et je cherche l'amour";
    const same = [1, 1, 1].map((conversationId) => ({ text, conversationId }));
    expect(codes(facts({ messages: same }))).not.toContain("copy_paste");
  });

  test("two copies are not enough", () => {
    const text = "Bonjour, je suis militaire à l'étranger et je cherche l'amour";
    expect(codes(facts({ messages: [{ text, conversationId: 1 }, { text, conversationId: 2 }] }))).not.toContain("copy_paste");
  });

  test("profile signals: new account, reports, blocks, no verification", () => {
    expect(codes(facts({ accountAgeDays: 2 }))).toContain("new_account");
    expect(codes(facts({ accountAgeDays: 7 }))).not.toContain("new_account");
    expect(codes(facts({ reportsCount: 3 }))).toContain("many_reports");
    expect(codes(facts({ reportsCount: 2 }))).not.toContain("many_reports");
    expect(codes(facts({ blocksReceived: 3 }))).toContain("many_blocks");
    expect(codes(facts({ blocksReceived: 2 }))).not.toContain("many_blocks");
    expect(codes(facts({ verified: false }))).toContain("no_verification");
  });

  test("the evidence is a count and never quotes a message", () => {
    const secret = "mon numéro 0612345678 et ma carte cadeau";
    const signals = detectRiskSignals(facts({ messages: say(secret, secret, "écris-moi sur WhatsApp") }));
    expect(signals.length).toBeGreaterThan(0);
    for (const signal of signals) {
      expect(signal.evidence).not.toContain("0612345678");
      expect(signal.evidence).not.toContain("carte cadeau");
      expect(signal.evidence).not.toContain("WhatsApp");
    }
    const external = signals.find((signal) => signal.code === "off_platform");
    expect(external?.evidence).toBe("3 messages mentionnent une messagerie externe ou un numéro de téléphone");
  });

  test("heaviest signal first", () => {
    const signals = detectRiskSignals(facts({ messages: say("fais un virement"), verified: false }));
    expect(signals[0]?.code).toBe("money_request");
    expect(signals.map((signal) => signal.weight)).toEqual([...signals.map((signal) => signal.weight)].sort((a, b) => b - a));
  });
});

// Makes the text differ only by letter case and spacing: still the same message once normalised.
function i(text: string, seed: number): string {
  return seed % 2 === 0 ? text.toUpperCase() : `  ${text}  `;
}
