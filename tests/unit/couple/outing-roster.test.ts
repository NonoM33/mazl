import { describe, expect, test } from "bun:test";
import {
  COUPLE_ACTIVITY_FIXTURES,
  COUPLE_EVENT_FIXTURES,
  coupleEventDate,
} from "../../../src/features/fixtures/couple-outing-roster";
import { TEST_EVENTS } from "../../../src/features/fixtures/test-event-roster";

const ALL = [...COUPLE_ACTIVITY_FIXTURES, ...COUPLE_EVENT_FIXTURES];
const FREE_PHOTO = "https://images.unsplash.com/photo-";

describe("couple outing roster", () => {
  test("has 12 activities and 6 events", () => {
    expect(COUPLE_ACTIVITY_FIXTURES).toHaveLength(12);
    expect(COUPLE_EVENT_FIXTURES).toHaveLength(6);
  });

  test("keys are unique and prefixed", () => {
    expect(new Set(ALL.map((e) => e.key)).size).toBe(18);
    for (const a of COUPLE_ACTIVITY_FIXTURES) expect(a.key.startsWith("test-couple-activity-")).toBe(true);
    for (const e of COUPLE_EVENT_FIXTURES) expect(e.key.startsWith("test-couple-event-")).toBe(true);
  });

  test("images are free Unsplash photos, distinct from each other and from the test events", () => {
    const urls = ALL.map((e) => e.imageUrl);
    expect(new Set(urls).size).toBe(urls.length);
    const photoId = (u: string): string => u.slice(FREE_PHOTO.length).split("?")[0] ?? "";
    for (const u of urls) {
      expect(u.startsWith(FREE_PHOTO)).toBe(true);
      expect(u.includes("plus.unsplash.com")).toBe(false);
    }
    const taken = new Set(TEST_EVENTS.map((e) => photoId(e.imageUrl)));
    for (const u of urls) expect(taken.has(photoId(u))).toBe(false);
  });

  test("prices are non-negative integers", () => {
    for (const e of ALL) {
      expect(Number.isInteger(e.priceCents)).toBe(true);
      expect(e.priceCents).toBeGreaterThanOrEqual(0);
    }
  });

  test("coordinates are in France", () => {
    for (const e of ALL) {
      expect(e.latitude).toBeGreaterThanOrEqual(41);
      expect(e.latitude).toBeLessThanOrEqual(51);
      expect(e.longitude).toBeGreaterThanOrEqual(-5);
      expect(e.longitude).toBeLessThanOrEqual(10);
    }
  });

  test("offers kosher and cheap activities", () => {
    expect(COUPLE_ACTIVITY_FIXTURES.filter((a) => a.isKosher).length).toBeGreaterThanOrEqual(3);
    expect(COUPLE_ACTIVITY_FIXTURES.filter((a) => a.priceCents <= 4000).length).toBeGreaterThanOrEqual(2);
  });

  test("covers the five cities", () => {
    const cities = new Set(ALL.map((e) => e.city));
    for (const c of ["Paris", "Lyon", "Marseille", "Nice", "Strasbourg"]) expect(cities.has(c)).toBe(true);
  });

  test("texts are filled and carry no e-mail or phone number", () => {
    for (const e of ALL) {
      expect(e.title.trim().length).toBeGreaterThan(0);
      expect(e.description.trim().length).toBeGreaterThan(0);
      const text = `${e.title} ${e.description} ${e.location}`;
      expect(/\S+@\S+\.\S+/.test(text)).toBe(false);
      expect(/(?:\+33|\b0)[1-9](?:[ .-]?\d{2}){4}/.test(text)).toBe(false);
    }
  });

  test("events have valid times and weeksAhead between 1 and 6", () => {
    for (const e of COUPLE_EVENT_FIXTURES) {
      expect(e.time).toMatch(/^\d{2}:\d{2}$/);
      expect(e.endTime).toMatch(/^\d{2}:\d{2}$/);
      expect(e.weeksAhead).toBeGreaterThanOrEqual(1);
      expect(e.weeksAhead).toBeLessThanOrEqual(6);
    }
  });
});

describe("coupleEventDate", () => {
  // Tuesday 2026-10-27, noon UTC.
  const today = new Date("2026-10-27T12:00:00Z");

  test("is a strictly future date on the requested weekday", () => {
    for (const e of COUPLE_EVENT_FIXTURES) {
      const date = coupleEventDate(e, today);
      expect(date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
      expect(date > "2026-10-27").toBe(true);
      expect(new Date(`${date}T00:00:00Z`).getUTCDay()).toBe(e.weekday);
    }
  });

  test("falls in the week that starts weeksAhead weeks from today", () => {
    expect(coupleEventDate({ weeksAhead: 1, weekday: 2 }, today)).toBe("2026-11-03");
    expect(coupleEventDate({ weeksAhead: 1, weekday: 5 }, today)).toBe("2026-11-06");
    expect(coupleEventDate({ weeksAhead: 2, weekday: 0 }, today)).toBe("2026-11-15");
  });
});
