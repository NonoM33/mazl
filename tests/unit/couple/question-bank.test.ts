import { describe, expect, test } from "bun:test";
import {
  QUESTION_BANK,
  QUESTION_LANGUAGES,
  languageFromAcceptLanguage,
  questionByKey,
  questionText,
  type QuestionCategory,
  type QuestionLanguage,
} from "../../../src/features/couple/domain/question-bank";

const CATEGORIES: readonly QuestionCategory[] = [
  "connection",
  "dreams",
  "daily",
  "judaism",
  "appreciation",
  "memories",
  "wellbeing",
  "values",
  "future",
  "family",
  "fun",
];

describe("banque de questions", () => {
  test("contient exactement 120 questions aux clés q001 à q120 consécutives et uniques", () => {
    expect(QUESTION_BANK).toHaveLength(120);
    const keys = QUESTION_BANK.map((question) => question.key);
    expect(new Set(keys).size).toBe(120);
    keys.forEach((key, index) => {
      expect(key).toBe(`q${String(index + 1).padStart(3, "0")}`);
    });
  });

  test("les cinq langues sont présentes, non vides, courtes et terminées par un point d'interrogation", () => {
    for (const question of QUESTION_BANK) {
      for (const language of QUESTION_LANGUAGES) {
        const text = questionText(question, language);
        expect(text.trim().length).toBeGreaterThan(0);
        expect(text.length).toBeLessThanOrEqual(160);
        expect(text.endsWith("?")).toBe(true);
      }
    }
  });

  test("aucun texte dupliqué à l'intérieur d'une langue", () => {
    for (const language of QUESTION_LANGUAGES) {
      const texts = QUESTION_BANK.map((question) => question.text[language]);
      expect(new Set(texts).size).toBe(texts.length);
    }
  });

  test("les textes d'une même question diffèrent d'une langue à l'autre", () => {
    for (const question of QUESTION_BANK) {
      const texts = QUESTION_LANGUAGES.map((language) => question.text[language]);
      expect(new Set(texts).size).toBe(QUESTION_LANGUAGES.length);
    }
  });

  test("hébreu : lettres hébraïques et aucun niqqoud", () => {
    for (const question of QUESTION_BANK) {
      expect(/[א-ת]/.test(question.text.he)).toBe(true);
      expect(/[֑-ׇ]/.test(question.text.he)).toBe(false);
    }
  });

  test("russe : cyrillique et vouvoiement uniquement", () => {
    const tutoiement = /(?<![А-Яа-яЁё])(ты|тебя|тебе|тобой|твой|твоя|твоё|твои|твоих|твоему|твоим)(?![А-Яа-яЁё])/i;
    for (const question of QUESTION_BANK) {
      expect(/[А-Яа-яЁё]/.test(question.text.ru)).toBe(true);
      expect(tutoiement.test(question.text.ru)).toBe(false);
    }
  });

  test("espagnol : tutoiement, jamais « usted »", () => {
    for (const question of QUESTION_BANK) {
      expect(/\busted(es)?\b/i.test(question.text.es)).toBe(false);
    }
  });

  test("chaque catégorie compte au moins 6 questions et le judaïsme au moins 15", () => {
    for (const category of CATEGORIES) {
      const count = QUESTION_BANK.filter((question) => question.category === category).length;
      expect(count).toBeGreaterThanOrEqual(6);
    }
    expect(QUESTION_BANK.filter((question) => question.category === "judaism").length).toBeGreaterThanOrEqual(15);
    for (const question of QUESTION_BANK) {
      expect(CATEGORIES).toContain(question.category);
    }
  });

  test("les dix questions historiques gardent leur clé et leur texte français", () => {
    const historiques = [
      "Quel est ton moment préféré de la semaine ensemble ?",
      "Si on pouvait voyager n'importe où, où irais-tu ?",
      "Qu'est-ce qui t'a fait sourire aujourd'hui ?",
      "Comment aimerais-tu célébrer notre prochain Shabbat ?",
      "Quel trait de caractère admires-tu le plus chez l'autre ?",
      "Qu'est-ce qui te manque le plus quand on n'est pas ensemble ?",
      "Si tu pouvais apprendre une nouvelle compétence, ce serait quoi ?",
      "Quel est ton souvenir préféré de notre relation ?",
      "Comment te sens-tu aujourd'hui sur une échelle de 1 à 10 ?",
      "Quelle est la chose la plus importante dans un couple selon toi ?",
    ];
    historiques.forEach((texte, index) => {
      const key = `q${String(index + 1).padStart(3, "0")}`;
      expect(questionByKey(key)?.text.fr).toBe(texte);
    });
  });

  test("questionByKey", () => {
    expect(questionByKey("q001")).toBeDefined();
    expect(questionByKey("zzz")).toBeUndefined();
  });
});

describe("languageFromAcceptLanguage", () => {
  const cases: ReadonlyArray<readonly [string | null | undefined, QuestionLanguage]> = [
    ["he-IL,he;q=0.9", "he"],
    ["iw", "he"],
    ["ru-RU,ru;q=0.9,en;q=0.8", "ru"],
    ["es-419", "es"],
    ["en-GB,en;q=0.9", "en"],
    ["fr-FR", "fr"],
    ["de-DE", "fr"],
    [null, "fr"],
    [undefined, "fr"],
    ["", "fr"],
    ["de,en;q=0.5", "en"],
    ["*", "fr"],
    ["en;q=0.4,es;q=0.9", "es"],
    ["fr;q=0,en;q=0.5", "en"],
  ];
  for (const [header, expected] of cases) {
    test(`${JSON.stringify(header)} -> ${expected}`, () => {
      expect(languageFromAcceptLanguage(header)).toBe(expected);
    });
  }
});
