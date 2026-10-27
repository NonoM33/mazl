import { describe, expect, test } from "bun:test";
import { campaignState, countdown, editability } from "../../console/src/storefront/campaign-state";
import { formatLastDay, formatSpan, isoToParisLocal, parisLocalToIso, parisToday } from "../../console/src/storefront/paris-time";
import { findOverlaps, layoutYear, monthColumns } from "../../console/src/storefront/timeline";

describe("heure de Paris", () => {
  test("en hiver Paris est à UTC+1 : minuit le 14 février = 23 h la veille en UTC", () => {
    expect(parisLocalToIso("2027-02-14T00:00")).toBe("2027-02-13T23:00:00.000Z");
  });
  test("en été Paris est à UTC+2 : minuit le 1er juillet = 22 h la veille en UTC", () => {
    expect(parisLocalToIso("2027-07-01T00:00")).toBe("2027-06-30T22:00:00.000Z");
  });
  test("le 31 octobre 2027 (fin de l'heure d'été) midi est à UTC+1, la veille à midi encore à UTC+2", () => {
    expect(parisLocalToIso("2027-10-31T12:00")).toBe("2027-10-31T11:00:00.000Z");
    expect(parisLocalToIso("2027-10-30T12:00")).toBe("2027-10-30T10:00:00.000Z");
  });
  test("une heure qui n'existe pas (saut du 28 mars 2027) ne plante pas et donne un instant de cette nuit", () => {
    const iso = parisLocalToIso("2027-03-28T02:30");
    expect(iso).not.toBeNull();
    expect(Date.parse(iso ?? "")).toBeGreaterThanOrEqual(Date.parse("2027-03-28T00:30:00Z"));
    expect(Date.parse(iso ?? "")).toBeLessThanOrEqual(Date.parse("2027-03-28T01:30:00Z"));
  });
  test("aller-retour entre l'instant et la saisie", () => {
    for (const local of ["2027-02-14T00:00", "2027-07-14T23:59", "2027-12-25T08:30"]) {
      expect(isoToParisLocal(parisLocalToIso(local) ?? "")).toBe(local);
    }
  });
  test("une date impossible est refusée", () => {
    expect(parisLocalToIso("2027-02-30T10:00")).toBeNull();
    expect(parisLocalToIso("2027-13-01T10:00")).toBeNull();
    expect(parisLocalToIso("2027-02-14")).toBeNull();
    expect(parisLocalToIso("2027-02-14T24:00")).toBeNull();
  });
  test("« jusqu'au » : une fin à minuit pile désigne la veille", () => {
    expect(formatLastDay("2027-02-14T23:00:00Z")).toBe("14 février");
    expect(formatLastDay(parisLocalToIso("2027-02-15T00:00") ?? "")).toBe("14 février");
    expect(formatLastDay(parisLocalToIso("2027-02-14T18:00") ?? "")).toBe("14 février");
  });
  test("le jour courant est celui de Paris, pas celui d'UTC", () => {
    expect(parisToday(new Date("2027-02-13T23:30:00Z"))).toBe("2027-02-14");
  });
  test("durées lisibles", () => {
    expect(formatSpan(3 * 86_400_000 + 4 * 3_600_000)).toBe("3 j 4 h");
    expect(formatSpan(5 * 3_600_000 + 12 * 60_000)).toBe("5 h 12 min");
    expect(formatSpan(20_000)).toBe("1 min");
  });
});

describe("état et compte à rebours", () => {
  const dates = { startsAt: "2027-02-06T23:00:00Z", endsAt: "2027-02-14T23:00:00Z" };
  test("brouillon et annulée ne dépendent pas de l'horloge", () => {
    const now = new Date("2027-02-10T00:00:00Z");
    expect(campaignState({ status: "draft", ...dates }, now)).toBe("draft");
    expect(campaignState({ status: "cancelled", ...dates }, now)).toBe("cancelled");
  });
  test("programmée → en cours → terminée, bornes comprises (début inclus, fin exclue)", () => {
    const scheduled = { status: "scheduled" as const, ...dates };
    expect(campaignState(scheduled, new Date("2027-02-06T22:59:59Z"))).toBe("scheduled");
    expect(campaignState(scheduled, new Date("2027-02-06T23:00:00Z"))).toBe("live");
    expect(campaignState(scheduled, new Date("2027-02-14T22:59:59Z"))).toBe("live");
    expect(campaignState(scheduled, new Date("2027-02-14T23:00:00Z"))).toBe("ended");
  });
  test("compte à rebours", () => {
    const scheduled = { status: "scheduled" as const, ...dates };
    expect(countdown(scheduled, new Date("2027-02-04T19:00:00Z"))).toBe("commence dans 2 j 4 h");
    expect(countdown(scheduled, new Date("2027-02-14T20:00:00Z"))).toBe("se termine dans 3 h");
    expect(countdown(scheduled, new Date("2027-02-16T23:00:00Z"))).toBe("terminée depuis 2 j");
    expect(countdown({ status: "draft", ...dates })).toBeNull();
  });
  test("seul un brouillon se modifie ; une campagne en cours ne se raccourcit que par sa fin", () => {
    const at = new Date("2027-02-10T00:00:00Z");
    expect(editability({ status: "draft", ...dates }, at)).toBe("full");
    expect(editability({ status: "scheduled", ...dates }, at)).toBe("end-only");
    expect(editability({ status: "scheduled", ...dates }, new Date("2027-02-01T00:00:00Z"))).toBe("locked");
    expect(editability({ status: "cancelled", ...dates }, at)).toBe("locked");
  });
});

describe("frise de l'année", () => {
  const span = (key: number, from: string, to: string): { key: number; startsAt: string; endsAt: string } => ({ key, startsAt: parisLocalToIso(`${from}T00:00`) ?? "", endsAt: parisLocalToIso(`${to}T00:00`) ?? "" });
  test("les douze colonnes couvrent exactement l'année, bissextile ou non", () => {
    for (const year of [2027, 2028]) {
      const columns = monthColumns(year);
      expect(columns).toHaveLength(12);
      expect(columns.reduce((sum, column) => sum + column.width, 0)).toBeCloseTo(1, 10);
      expect(columns[1]?.width).toBeCloseTo((year === 2028 ? 29 : 28) / (year === 2028 ? 366 : 365), 10);
    }
  });
  test("une campagne du 7 au 15 février (fin exclue) occupe 8 jours à partir du 38e jour", () => {
    const placed = layoutYear([span(1, "2027-02-07", "2027-02-15")], 2027);
    expect(placed).toHaveLength(1);
    expect(placed[0]?.start).toBeCloseTo(37 / 365, 10);
    expect(placed[0]?.end).toBeCloseTo(45 / 365, 10);
  });
  test("deux campagnes qui se chevauchent sont sur deux lignes, deux campagnes disjointes sur la même", () => {
    const placed = layoutYear([span(1, "2027-12-02", "2027-12-14"), span(2, "2027-12-15", "2027-12-27"), span(3, "2027-12-20", "2027-12-31")], 2027);
    const lane = (key: number): number | undefined => placed.find((entry) => entry.item.key === key)?.lane;
    expect(lane(1)).toBe(0);
    expect(lane(2)).toBe(0);
    expect(lane(3)).toBe(1);
  });
  test("une campagne à cheval sur deux années est coupée et signalée", () => {
    const placed = layoutYear([span(1, "2027-12-26", "2028-01-04")], 2027);
    expect(placed[0]?.end).toBe(1);
    expect(placed[0]?.clippedEnd).toBe(true);
    const next = layoutYear([span(1, "2027-12-26", "2028-01-04")], 2028);
    expect(next[0]?.start).toBe(0);
    expect(next[0]?.clippedStart).toBe(true);
    expect(layoutYear([span(1, "2027-12-26", "2028-01-04")], 2029)).toHaveLength(0);
  });
  test("chevauchements : fin exclue, donc deux campagnes qui se touchent ne se chevauchent pas", () => {
    const touching = findOverlaps([span(1, "2027-12-02", "2027-12-15"), span(2, "2027-12-15", "2027-12-27")]);
    expect(touching.size).toBe(0);
    const crossing = findOverlaps([span(1, "2027-12-02", "2027-12-16"), span(2, "2027-12-15", "2027-12-27")]);
    expect(crossing.get(1)).toEqual([2]);
    expect(crossing.get(2)).toEqual([1]);
  });
});
