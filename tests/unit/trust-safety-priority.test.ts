import { describe, expect, test } from "bun:test";
import { comparePriority, computePriority, dueAt, escalate, isOverdue, normalizeReason, SLA_HOURS } from "../../src/features/trust-safety/domain/priority";
import { suggestSanction } from "../../src/features/trust-safety/domain/ladder";
import type { Priority, ReportReason } from "../../src/features/trust-safety/domain/types";

const calm = { openReportsOnMember: 1, sanctionedRecently: false };

describe("priority of a report (CADRAGE §6)", () => {
  const table: ReadonlyArray<readonly [ReportReason, Priority]> = [
    ["underage", "P1"],
    ["offline_behavior", "P1"],
    ["harassment", "P2"],
    ["scam", "P2"],
    ["fake_profile", "P3"],
    ["inappropriate_photos", "P3"],
    ["spam", "P4"],
    ["other", "P4"],
  ];
  for (const [reason, priority] of table) {
    test(`${reason} is ${priority} for a member without history`, () => {
      expect(computePriority(reason, calm)).toBe(priority);
    });
  }

  test("three open reports on the member raise the priority one notch", () => {
    expect(computePriority("harassment", { openReportsOnMember: 3, sanctionedRecently: false })).toBe("P1");
    expect(computePriority("spam", { openReportsOnMember: 4, sanctionedRecently: false })).toBe("P3");
    expect(computePriority("spam", { openReportsOnMember: 2, sanctionedRecently: false })).toBe("P4");
  });

  test("a sanction in the last 90 days raises it one notch only, never above P1", () => {
    expect(computePriority("fake_profile", { openReportsOnMember: 1, sanctionedRecently: true })).toBe("P2");
    expect(computePriority("underage", { openReportsOnMember: 5, sanctionedRecently: true })).toBe("P1");
    expect(computePriority("scam", { openReportsOnMember: 5, sanctionedRecently: true })).toBe("P1");
    expect(escalate("P1")).toBe("P1");
  });

  test("an unknown reason is filed under other", () => {
    expect(normalizeReason("made_up")).toBe("other");
    expect(normalizeReason(null)).toBe("other");
    expect(normalizeReason("  Harassment ")).toBe("harassment");
  });

  test("SLA: 4 h, 24 h, 72 h, 7 days", () => {
    expect(SLA_HOURS).toEqual({ P1: 4, P2: 24, P3: 72, P4: 168 });
    const created = new Date("2026-10-01T10:00:00Z");
    expect(dueAt(created, "P1").toISOString()).toBe("2026-10-01T14:00:00.000Z");
    expect(dueAt(created, "P2").toISOString()).toBe("2026-10-02T10:00:00.000Z");
    expect(dueAt(created, "P3").toISOString()).toBe("2026-10-04T10:00:00.000Z");
    expect(dueAt(created, "P4").toISOString()).toBe("2026-10-08T10:00:00.000Z");
  });

  test("overdue only strictly after the due date", () => {
    const due = new Date("2026-10-01T14:00:00Z");
    expect(isOverdue(due, new Date("2026-10-01T14:00:00Z"))).toBe(false);
    expect(isOverdue(due, new Date("2026-10-01T14:00:01Z"))).toBe(true);
  });

  test("P1 sorts before P4", () => {
    expect(comparePriority("P1", "P4")).toBeLessThan(0);
    expect(comparePriority("P3", "P2")).toBeGreaterThan(0);
  });
});

describe("suggested sanction (never decided here)", () => {
  test("no history: a warning", () => {
    expect(suggestSanction("harassment", [])).toBe("warning");
  });
  test("climbs the ladder with the standing sanctions", () => {
    expect(suggestSanction("spam", [{ kind: "warning", revoked: false }])).toBe("restriction");
    expect(suggestSanction("spam", [{ kind: "restriction", revoked: false }])).toBe("suspension");
    expect(suggestSanction("spam", [{ kind: "suspension", revoked: false }])).toBe("ban");
    expect(suggestSanction("spam", [{ kind: "ban", revoked: false }])).toBe("ban");
  });
  test("a revoked sanction does not count", () => {
    expect(suggestSanction("spam", [{ kind: "suspension", revoked: true }])).toBe("warning");
  });
  test("underage: suspension at once, even with no history", () => {
    expect(suggestSanction("underage", [])).toBe("suspension");
  });
  test("a threat with a previous sanction: ban", () => {
    expect(suggestSanction("offline_behavior", [])).toBe("warning");
    expect(suggestSanction("offline_behavior", [{ kind: "warning", revoked: false }])).toBe("ban");
  });
});
