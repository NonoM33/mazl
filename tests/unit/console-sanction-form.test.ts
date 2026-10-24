import { describe, expect, test } from "bun:test";
import {
  emptyForm,
  isValid,
  toMemberSanctionBody,
  toReportDecisionBody,
  validateDecision,
  validateJustification,
  type DecisionForm,
} from "../../console/src/sanctions/form-model";
import { buildStatementPreview, GROUND_TEXT } from "../../console/src/sanctions/statement";
import { DECISION_GROUNDS } from "../../src/features/trust-safety/domain/types";
import { GROUND_LABELS, GROUND_ORDER } from "../../console/src/shared/labels";
import { nextIndex } from "../../console/src/shared/keyboard";

const valid = (patch: Partial<DecisionForm> = {}): DecisionForm => ({
  ...emptyForm("actioned"),
  kind: "suspension",
  ground: "harassment",
  facts: "Messages répétés après un refus explicite.",
  durationDays: "14",
  note: "Récidive après avertissement.",
  ...patch,
});

describe("validation du formulaire de décision", () => {
  test("une sanction complète est valide", () => {
    expect(isValid(validateDecision(valid(), { canBan: false }))).toBe(true);
  });
  test("la note interne est obligatoire, même pour classer sans suite", () => {
    const errors = validateDecision({ ...emptyForm("dismissed"), note: "  " }, { canBan: false });
    expect(errors.note).toBeDefined();
    expect(isValid(validateDecision({ ...emptyForm("dismissed"), note: "Aucun manquement." }, { canBan: false }))).toBe(true);
  });
  test("faits trop courts, motif et sanction manquants", () => {
    const errors = validateDecision(valid({ facts: "court", ground: null, kind: null }), { canBan: false });
    expect(Object.keys(errors).sort()).toEqual(["facts", "ground", "kind"]);
  });
  test("durée requise et bornée pour restriction et suspension seulement", () => {
    expect(validateDecision(valid({ durationDays: "0" }), { canBan: false }).durationDays).toBeDefined();
    expect(validateDecision(valid({ durationDays: "366" }), { canBan: false }).durationDays).toBeDefined();
    expect(validateDecision(valid({ durationDays: "1,5" }), { canBan: false }).durationDays).toBeDefined();
    expect(validateDecision(valid({ kind: "warning", durationDays: "abc" }), { canBan: false }).durationDays).toBeUndefined();
  });
  test("bannissement : permission et confirmation explicite", () => {
    expect(validateDecision(valid({ kind: "ban", banConfirmed: true }), { canBan: false }).kind).toBeDefined();
    expect(validateDecision(valid({ kind: "ban" }), { canBan: true }).banConfirmed).toBeDefined();
    expect(isValid(validateDecision(valid({ kind: "ban", banConfirmed: true }), { canBan: true }))).toBe(true);
  });
  test("motif de lecture de conversation : 10 à 500 caractères", () => {
    expect(validateJustification("trop cour")).not.toBeNull();
    expect(validateJustification("Vérifier la menace signalée.")).toBeNull();
    expect(validateJustification("x".repeat(501))).not.toBeNull();
  });
});

describe("corps envoyés au serveur", () => {
  test("décision avec sanction : durée seulement pour restriction et suspension", () => {
    expect(toReportDecisionBody(valid())).toEqual({
      outcome: "actioned",
      note: "Récidive après avertissement.",
      sanction: { kind: "suspension", ground: "harassment", facts: "Messages répétés après un refus explicite.", durationDays: 14 },
    });
    const warning = toReportDecisionBody(valid({ kind: "warning" }));
    expect(warning?.sanction).not.toHaveProperty("durationDays");
  });
  test("classement sans suite : aucune sanction", () => {
    expect(toReportDecisionBody({ ...emptyForm("dismissed"), note: "Rien à signaler." })).toEqual({ outcome: "dismissed", note: "Rien à signaler." });
  });
  test("sanction depuis la fiche membre : note incluse", () => {
    expect(toMemberSanctionBody(valid({ kind: "warning" }))).toMatchObject({ kind: "warning", note: "Récidive après avertissement." });
    expect(toMemberSanctionBody(valid({ kind: null }))).toBeNull();
  });
});

describe("aperçu de l'exposé des motifs", () => {
  const now = new Date("2026-10-24T10:00:00Z");
  test("suspension : durée et date de fin, décision humaine", () => {
    const preview = buildStatementPreview({ kind: "suspension", ground: "harassment", facts: " Faits. ", durationDays: 14, now });
    expect(preview.scope).toBe("Compte suspendu pendant 14 jours, jusqu'au 07/11/2026.");
    expect(preview.facts).toBe("Faits.");
    expect(preview.automated).toContain("personne");
    expect(preview.groundText).toBe(GROUND_TEXT.harassment);
  });
  test("bannissement et avertissement n'ont pas de durée", () => {
    expect(buildStatementPreview({ kind: "ban", ground: "scam_or_fraud", facts: "x", durationDays: null, now }).scope).toBe("Compte définitivement fermé.");
    expect(buildStatementPreview({ kind: "warning", ground: "commercial_spam", facts: "x", durationDays: null, now }).scope).toContain("aucune restriction");
  });
  test("chaque motif normalisé du serveur a un libellé et une clause", () => {
    expect([...GROUND_ORDER].sort()).toEqual([...DECISION_GROUNDS].sort());
    for (const ground of DECISION_GROUNDS) {
      expect(GROUND_LABELS[ground].length).toBeGreaterThan(3);
      expect(GROUND_TEXT[ground].length).toBeGreaterThan(20);
    }
  });
});

describe("navigation clavier dans la file", () => {
  test("j / k bornés", () => {
    expect(nextIndex(-1, 1, 5)).toBe(0);
    expect(nextIndex(-1, -1, 5)).toBe(4);
    expect(nextIndex(4, 1, 5)).toBe(4);
    expect(nextIndex(0, -1, 5)).toBe(0);
    expect(nextIndex(2, 1, 0)).toBe(-1);
  });
});
