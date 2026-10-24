import { describe, expect, test } from "bun:test";
import { buildHash, parseHash } from "../../console/src/app/router";
import { can, firstAccessible, SECTIONS, visibleSections } from "../../console/src/app/permissions";
import { ROLE_PERMISSIONS } from "../../src/features/staff/domain/roles";

describe("routeur par hash", () => {
  test("racine = tableau de bord", () => {
    expect(parseHash("")).toEqual({ section: "tableau-de-bord", id: null, params: {} });
    expect(parseHash("#/")).toMatchObject({ section: "tableau-de-bord" });
  });
  test("section + identifiant + paramètres", () => {
    expect(parseHash("#/signalements/42?statut=pending")).toEqual({ section: "signalements", id: 42, params: { statut: "pending" } });
  });
  test("section inconnue et identifiant non numérique", () => {
    expect(parseHash("#/nimportequoi").section).toBeNull();
    expect(parseHash("#/membres/abc").id).toBeNull();
  });
  test("construction inverse de l'analyse", () => {
    expect(buildHash("signalements", 7)).toBe("#/signalements/7");
    expect(buildHash("membres", null, { q: "Jeanne Exemple" })).toBe("#/membres?q=Jeanne+Exemple");
    expect(parseHash(buildHash("membres", 3, { q: "a b" }))).toEqual({ section: "membres", id: 3, params: { q: "a b" } });
  });
});

describe("garde de permissions", () => {
  test("le support voit tableau de bord, membres, signalements et transparence — pas l'équipe ni les sanctions", () => {
    const me = { permissions: ROLE_PERMISSIONS.support };
    expect(visibleSections(me).map((s) => s.id)).toEqual(["tableau-de-bord", "signalements", "membres", "transparence"]);
    expect(can(me, "reports.decide")).toBe(false);
  });
  test("le vérificateur ne voit pas les signalements", () => {
    const me = { permissions: ROLE_PERMISSIONS.verifier };
    expect(visibleSections(me).map((s) => s.id)).not.toContain("signalements");
    expect(visibleSections(me).map((s) => s.id)).toContain("verification");
  });
  test("le super-administrateur voit tout, l'administrateur tout sauf l'équipe", () => {
    expect(visibleSections({ permissions: ROLE_PERMISSIONS.super_admin })).toHaveLength(SECTIONS.length);
    expect(visibleSections({ permissions: ROLE_PERMISSIONS.admin }).map((s) => s.id)).not.toContain("equipe");
  });
  test("aucune permission : aucune section", () => {
    expect(firstAccessible({ permissions: [] })).toBeNull();
  });
});
