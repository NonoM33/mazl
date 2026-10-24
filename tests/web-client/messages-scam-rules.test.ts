import { describe, expect, test } from "bun:test";
import { detectScam, SCAM_EARLY_MESSAGE_COUNT, type ScamKind } from "../../web/src/features/messages/scam-rules";

// Cases taken from mobile/test/core/chat/scam_rules_test.dart, the spec of the rules.
const kindOf = (text: string, position = 0): ScamKind | null => detectScam(text, position);

const MONEY = [
  "Peux-tu me faire un virement ?", "Je t'envoie mon IBAN FR76 3000 6000 0112 3456 7890 189", "donne moi ton RIB",
  "J'ai besoin d'argent pour mon billet", "Peux-tu m'envoyer de l'argent ?", "envoie moi 200 euros par Western Union",
  "Prête-moi de l'argent stp", "Can you send me money for the ticket?", "I need money urgently", "Please do a bank transfer",
  "wire me the money tonight", "Send me cash via MoneyGram",
];
const GIFT = ["Achète-moi une carte cadeau Amazon", "des cartes cadeaux iTunes", "Buy a gift card and send me the code", "Google Play gift-cards please"];
const CRYPTO = ["Je gagne beaucoup avec le bitcoin", "tu connais la crypto ?", "Investis en cryptomonnaie avec moi", "Je trade sur Binance", "Send USDT to my wallet", "BTC is going up"];
const INVEST = [
  "J'ai une opportunité d'investissement incroyable", "rendement garanti de 30 % par mois", "I found an investment opportunity",
  "guaranteed returns every week", "Je fais du trading, ça rapporte", "tu veux doubler ton argent ?", "double your money in a week", "un revenu passif sans effort",
];
const OFF = [
  "On continue sur WhatsApp ?", "Ajoute-moi sur Telegram", "tu as whats app ?", "Mon numéro : 06 12 34 56 78", "Appelle-moi au +33 6 12 34 56 78",
  "Add me on Signal", "tu peux m'écrire sur Signal ?", "Let's move to WhatsApp, this app is slow", "Do you have Signal?", "text me on 0612345678",
  "Passe-moi ton numéro de téléphone", "give me your number", "viber ?",
];
const SAFE = [
  "Je t'ai envoyé un télégramme, hihi", "Telegramme reçu", "Il est argentin", "Je t'envoie une photo argentique",
  "Elle m'a envoyé l'argentier du roi, haha", "Mon grand-père vient d'Argentine", "J'adore l'argent comme couleur de bague",
  "Quel signal fort, ce wifi !", "Le signal est mauvais ici", "Tu fais de la cryptographie ?", "Je travaille dans la banque",
  "On se voit jeudi à 20 h ?", "Mon anniversaire est le 12 03 1995", "La date est 2026-10-23", "Je suis né en 1995, et toi ?",
  "Salut ! Comment ça va ?", "J'aime voyager et la cuisine", "Un café, ça te dit ?", "Shabbat shalom !", "I love hiking on weekends",
  "The signal was great on the hike", "My sister lives in Argentina", "Tu es très virile", "On pourrait investir du temps dans nous deux", "C'est un trading card game ?",
];

describe("scam rules", () => {
  test.each(MONEY)("money: %s", (text) => expect(kindOf(text)).toBe("money"));
  test.each(GIFT)("gift card: %s", (text) => expect(kindOf(text)).toBe("giftCard"));
  test.each(CRYPTO)("crypto: %s", (text) => expect(kindOf(text)).toBe("crypto"));
  test.each(INVEST)("investment: %s", (text) => expect(kindOf(text)).toBe("investment"));
  test.each(OFF)("off platform early: %s", (text) => expect(kindOf(text, 2)).toBe("offPlatform"));
  test.each(SAFE)("no false positive: %s", (text) => expect(kindOf(text)).toBeNull());

  test("leaving the platform is only a signal early in the conversation", () => {
    expect(kindOf("On continue sur WhatsApp ?", SCAM_EARLY_MESSAGE_COUNT)).toBeNull();
    expect(kindOf("On continue sur WhatsApp ?", SCAM_EARLY_MESSAGE_COUNT - 1)).toBe("offPlatform");
    expect(kindOf("Mon numéro : 06 12 34 56 78", 80)).toBeNull();
  });

  test("money stays a signal at any time", () => expect(kindOf("envoie moi un virement", 500)).toBe("money"));

  test("case, accents and typographic apostrophes do not matter", () => {
    expect(kindOf("VIREMENT URGENT")).toBe("money");
    expect(kindOf("Prête-moi de l’argent")).toBe("money");
    expect(kindOf("pret moi de l argent")).toBe("money");
    expect(kindOf("J’ai besoin d’argent")).toBe("money");
  });

  test("empty text signals nothing", () => {
    expect(kindOf("")).toBeNull();
    expect(kindOf("   ")).toBeNull();
  });
});
