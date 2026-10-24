import { describe, expect, test } from "bun:test";
import { appealDeadline, isAppealWindowOpen } from "../../src/features/trust-safety/domain/appeal-window";
import { buildAppealCode, buildReference, normalizeAppealCode, REFERENCE_PATTERN } from "../../src/features/trust-safety/domain/references";
import { buildStatement, type StatementInput } from "../../src/features/trust-safety/domain/statement";
import { DECISION_GROUNDS } from "../../src/features/trust-safety/domain/types";
import { GROUND_TEXT } from "../../src/features/trust-safety/domain/grounds";

const issuedAt = new Date("2026-10-24T09:00:00Z");

function input(overrides: Partial<StatementInput> = {}): StatementInput {
  return {
    reference: "MZ-2026-7K4Q9X",
    kind: "suspension",
    ground: "harassment",
    facts: "Plusieurs messages insultants envoyés à un autre membre.",
    startsAt: issuedAt,
    endsAt: new Date("2026-11-12T09:00:00Z"),
    origin: "member_report",
    issuedAt,
    ...overrides,
  };
}

describe("statement of reasons (DSA art. 17)", () => {
  test("carries every mandatory element", () => {
    const statement = buildStatement(input());
    expect(statement.reference).toBe("MZ-2026-7K4Q9X");
    expect(statement.decision).toBe("suspension");
    expect(statement.facts).toContain("insultants");
    expect(statement.ground).toBe("harassment");
    expect(statement.groundText.length).toBeGreaterThan(20);
    expect(statement.scope.length).toBeGreaterThan(10);
    expect(statement.redress.length).toBeGreaterThan(50);
    expect(statement.issuedAt).toBe("2026-10-24T09:00:00.000Z");
  });

  test("the decision is never automated; detection follows the origin", () => {
    expect(buildStatement(input()).automatedDecision).toBe(false);
    expect(buildStatement(input({ origin: "automated_detection" })).automatedDecision).toBe(false);
    expect(buildStatement(input({ origin: "member_report" })).automatedDetection).toBe(false);
    expect(buildStatement(input({ origin: "staff_initiative" })).automatedDetection).toBe(false);
    expect(buildStatement(input({ origin: "automated_detection" })).automatedDetection).toBe(true);
  });

  test("scope states the end date in fr-FR, Europe/Paris", () => {
    // 23:30 UTC on the 11th is already the 12th in Paris.
    const statement = buildStatement(input({ endsAt: new Date("2026-11-11T23:30:00Z") }));
    expect(statement.scope).toContain("jusqu'au 12/11/2026");
    expect(statement.scope).toContain("24/10/2026");
  });

  test("scope by kind", () => {
    expect(buildStatement(input({ kind: "warning", endsAt: null })).scope).toContain("Avertissement");
    expect(buildStatement(input({ kind: "ban", endsAt: null })).scope).toContain("définitivement");
    expect(buildStatement(input({ kind: "restriction" })).scope).toContain("Restriction");
  });

  test("redress: free internal appeal for six months with reference and code, out-of-court body, court", () => {
    const { redress } = buildStatement(input());
    expect(redress).toContain("gratuite");
    expect(redress).toContain("24/04/2027");
    expect(redress).toContain("MZ-2026-7K4Q9X");
    expect(redress).toContain("code de contestation");
    expect(redress).toContain("extrajudiciaire");
    expect(redress).toContain("tribunal");
  });

  test("every ground has a clause in French", () => {
    for (const ground of DECISION_GROUNDS) {
      expect(GROUND_TEXT[ground]).toContain("Conditions générales");
    }
  });
});

describe("references and appeal codes", () => {
  test("reference: MZ-year-6 unambiguous base32 characters", () => {
    const reference = buildReference(2026, Uint8Array.from([0, 1, 2, 31, 255, 128]));
    expect(reference).toMatch(REFERENCE_PATTERN);
    expect(reference).toBe("MZ-2026-012ZZ0");
    expect(/[ILOU]/.test(reference.slice(8))).toBe(false);
  });

  test("the alphabet never produces I, L, O or U", () => {
    const all = Uint8Array.from({ length: 256 }, (_, index) => index);
    expect(buildReference(2026, all.slice(0, 6))).toMatch(REFERENCE_PATTERN);
    const code = buildAppealCode(all.slice(0, 12));
    expect(code).toMatch(/^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$/);
  });

  test("the code a member types is normalised", () => {
    expect(normalizeAppealCode(" abcd-ef12 gh34 ")).toBe("ABCDEF12GH34");
  });

  test("the appeal window is six months", () => {
    expect(appealDeadline(issuedAt).toISOString()).toBe("2027-04-24T09:00:00.000Z");
    expect(isAppealWindowOpen(issuedAt, new Date("2027-04-24T08:59:00Z"))).toBe(true);
    expect(isAppealWindowOpen(issuedAt, new Date("2027-04-24T09:00:01Z"))).toBe(false);
  });
});
