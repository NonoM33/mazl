import { describe, expect, test } from "bun:test";
import {
  AB_SHARE_MAX,
  DEFAULT_PREVIEW_SIZE,
  PREVIEW_SIZES,
  abTestBody,
  activateBody,
  createVersionBody,
  parseIntegerInput,
  previewBody,
  validateNote,
} from "../../console/src/matching/requests";
import { DEFAULT_PARAMS } from "../../src/features/matching/domain/params";
import { setParam } from "../../src/features/matching/domain/validate-params";
import { PREVIEW_MAX_SIZE, PREVIEW_MIN_SIZE } from "../../src/features/matching/application/preview";
import { abTestBody as serverAbBody, activateBody as serverActivateBody, createVersionBody as serverCreateBody, previewBody as serverPreviewBody } from "../../src/features/matching/presentation/matching-admin.schemas";

// Les schémas du serveur (zod) arbitrent : un corps construit par la console doit y passer, un corps refusé par la console y échouerait.
describe("note de version obligatoire", () => {
  test("vide, espaces, trop courte, trop longue", () => {
    expect(validateNote("")).toContain("obligatoire");
    expect(validateNote("    ")).toContain("obligatoire");
    expect(validateNote("ab")).toContain("obligatoire");
    expect(validateNote("a".repeat(501))).toContain("trop longue");
  });
  test("acceptée entre 3 et 500 caractères, même verdict que le serveur", () => {
    for (const note of ["abc", "  abc  ", "a".repeat(500), "ab", "  ab ", "a".repeat(501)]) {
      expect(validateNote(note) === null).toBe(serverActivateBody.safeParse({ note }).success);
    }
  });
});

describe("construction des requêtes d'écriture", () => {
  test("création : la note est nettoyée, l'activation explicite", () => {
    const body = createVersionBody(DEFAULT_PARAMS, "  Distance revue  ", false);
    expect(body).toEqual({ params: DEFAULT_PARAMS, note: "Distance revue", activate: false });
    expect(serverCreateBody.safeParse(body).success).toBe(true);
    expect(serverCreateBody.safeParse(createVersionBody(DEFAULT_PARAMS, "ok ok", true)).success).toBe(true);
  });
  test("activation / retour arrière : seulement la note", () => {
    expect(activateBody(" Retour arrière ")).toEqual({ note: "Retour arrière" });
    expect(serverActivateBody.safeParse(activateBody("Retour arrière")).success).toBe(true);
  });
});

describe("test A/B", () => {
  test("part de 1 à 50 % seulement, entière", () => {
    const verdict = (text: string): boolean => abTestBody(7, text).ok;
    expect([verdict("1"), verdict("50"), verdict(" 25 ")]).toEqual([true, true, true]);
    expect([verdict("0"), verdict("51"), verdict("12,5"), verdict("abc"), verdict("")]).toEqual([false, false, false, false, false]);
    expect(AB_SHARE_MAX).toBe(50);
  });
  test("même verdict que le serveur pour chaque part de -1 à 60", () => {
    for (let share = -1; share <= 60; share += 1) {
      const mine = abTestBody(3, String(share)).ok;
      expect(mine).toBe(serverAbBody.safeParse({ variantId: 3, sharePercent: share }).success);
    }
  });
  test("une version est obligatoire", () => {
    const result = abTestBody(null, "10");
    expect(result.ok).toBe(false);
    const ok = abTestBody(3, "10");
    expect(ok.ok && ok.value).toEqual({ variantId: 3, sharePercent: 10 });
  });
});

describe("simulation en direct", () => {
  const active = DEFAULT_PARAMS;
  const draft = setParam(DEFAULT_PARAMS, "weights.distance", 8);
  const choice = (seedText: string, indexText: string, size = DEFAULT_PREVIEW_SIZE) => ({ seedText, indexText, size });

  test("envoie les réglages en cours ET la version active en comparaison, sur la population fictive", () => {
    const result = previewBody(draft, active, choice("42", "3"));
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.value.params).toBe(draft);
    expect(result.value.compareWith).toBe(active);
    expect(result.value).toMatchObject({ seed: 42, viewer: 3, size: DEFAULT_PREVIEW_SIZE });
    expect(serverPreviewBody.safeParse(result.value).success).toBe(true);
  });
  test("toutes les tailles proposées sont acceptées par le serveur, dans ses bornes", () => {
    for (const size of PREVIEW_SIZES) {
      expect(size).toBeGreaterThanOrEqual(PREVIEW_MIN_SIZE);
      expect(size).toBeLessThanOrEqual(PREVIEW_MAX_SIZE);
      const body = previewBody(draft, active, choice("1", String(size - 1), size));
      expect(body.ok && serverPreviewBody.safeParse(body.value).success).toBe(true);
    }
  });
  test("index du membre : 0 à taille − 1", () => {
    expect(previewBody(draft, active, choice("1", "119", 120)).ok).toBe(true);
    expect(previewBody(draft, active, choice("1", "120", 120))).toEqual({ ok: false, error: "Index du membre : Entre 0 et 119." });
    expect(previewBody(draft, active, choice("1", "120", 400)).ok).toBe(true);
    expect(previewBody(draft, active, choice("1", "-1")).ok).toBe(false);
  });
  test("graine : entier dans les bornes du serveur", () => {
    expect(previewBody(draft, active, choice("-5", "0")).ok).toBe(true);
    expect(previewBody(draft, active, choice("4294967295", "0")).ok).toBe(true);
    expect(previewBody(draft, active, choice("4294967296", "0")).ok).toBe(false);
    const word = previewBody(draft, active, choice("abc", "0"));
    expect(word.ok).toBe(false);
    expect(!word.ok && word.error).toContain("Graine");
  });
});

describe("saisie d'entiers", () => {
  test("refuse décimaux, notation scientifique et texte", () => {
    for (const text of ["1.5", "1e3", "0x10", "", " ", "12a"]) expect(parseIntegerInput(text, 0, 1000).ok).toBe(false);
    expect(parseIntegerInput(" 12 ", 0, 20)).toEqual({ ok: true, value: 12 });
  });
});
