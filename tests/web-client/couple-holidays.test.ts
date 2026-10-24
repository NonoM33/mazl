import { describe, expect, test } from "bun:test";
import { daysUntil, holidayDates, upcomingHolidays } from "../../web/src/features/couple/holidays";

// Dates taken from the calendar, not from the code: Hanoucca 5787 starts the
// evening of Friday 4 December 2026 and runs eight days; 5787 is a leap year,
// so Pessah 5787 starts late, the evening of Wednesday 21 April 2027 (15 Nisan =
// 22 April), and lasts eight days in the diaspora; Rosh Hashana 5787 is 12-13 September 2026; Yom Kippour is
// Monday 21 September 2026.
const day = (y: number, m: number, d: number) => new Date(y, m - 1, d);

describe("fêtes juives à venir", () => {
  test("Hanoucca 5787 commence le soir du 4 décembre 2026 et dure huit jours", () => {
    const hanoucca = upcomingHolidays(day(2026, 11, 20)).find((holiday) => holiday.name === "Hanoucca");
    expect(hanoucca).toBeDefined();
    expect(hanoucca?.eve).toEqual(day(2026, 12, 4));
    expect(hanoucca?.start).toEqual(day(2026, 12, 5));
    expect(hanoucca?.end).toEqual(day(2026, 12, 12));
  });

  test("Pessah 5787 (année embolismique) commence le soir du 21 avril 2027, huit jours regroupés en une seule fête", () => {
    const list = upcomingHolidays(day(2027, 4, 1), 3);
    const pessah = list.filter((holiday) => holiday.name === "Pessah");
    expect(pessah).toHaveLength(1);
    expect(pessah[0]?.eve).toEqual(day(2027, 4, 21));
    expect(pessah[0]?.start).toEqual(day(2027, 4, 22));
    expect(pessah[0]?.end).toEqual(day(2027, 4, 29));
  });

  test("Rosh Hashana (2 jours) puis Yom Kippour, depuis la fin août 2026", () => {
    const [first, second] = upcomingHolidays(day(2026, 8, 25));
    expect(first?.name).toBe("Rosh Hashana");
    expect(first?.start).toEqual(day(2026, 9, 12));
    expect(first?.end).toEqual(day(2026, 9, 13));
    expect(second?.name).toBe("Yom Kippour");
    expect(second?.start).toEqual(day(2026, 9, 21));
    expect(second?.end).toBeNull();
  });

  test("Souccot regroupe les jours intermédiaires et Hoshana Rabba, Shemini Atseret reste à part", () => {
    const list = upcomingHolidays(day(2026, 9, 22), 3);
    expect(list.map((holiday) => holiday.name)).toEqual(["Souccot", "Shemini Atseret", "Simhat Torah"]);
    expect(list[0]?.start).toEqual(day(2026, 9, 26));
    expect(list[0]?.end).toEqual(day(2026, 10, 2));
  });

  test("cinq fêtes par défaut, dans l'ordre, sans doublon", () => {
    const list = upcomingHolidays(day(2026, 10, 24));
    expect(list).toHaveLength(5);
    const starts = list.map((holiday) => holiday.start.getTime());
    expect([...starts].sort((a, b) => a - b)).toEqual(starts);
    expect(new Set(list.map((holiday) => holiday.name)).size).toBe(5);
  });

  test("les libellés et les idées sont ceux de l'app", () => {
    const [hanoucca] = upcomingHolidays(day(2026, 12, 1), 1);
    expect(hanoucca?.description).toBe("Fête des lumières");
    expect(hanoucca?.ideas).toEqual(["Allumer les bougies ensemble", "Soufganiot maison"]);
  });
});

describe("compte à rebours et dates", () => {
  test("jours jusqu'au soir de début", () => {
    const [hanoucca] = upcomingHolidays(day(2026, 12, 1), 1);
    expect(hanoucca && daysUntil(hanoucca, day(2026, 12, 1))).toBe(3);
    expect(hanoucca && daysUntil(hanoucca, day(2026, 12, 4))).toBe(0);
  });
  test("libellé de période", () => {
    const [hanoucca] = upcomingHolidays(day(2026, 12, 1), 1);
    expect(hanoucca && holidayDates(hanoucca)).toBe("4 – 12 déc.");
  });
});
