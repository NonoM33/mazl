import { describe, expect, test } from "bun:test";
import { TEST_EVENTS, testEventDate } from "../../src/features/fixtures/test-event-roster";
import { TEST_MEMBERS } from "../../src/features/fixtures/test-profile-roster";

// The fake events of the TestFlight phase: varied, in the weeks to come, in the
// cities of the test members, of kinds the app can draw.

const APP_KINDS = new Set(["shabbat_dinner", "speed_dating", "holiday", "lecture", "social"]);

describe("the fake events", () => {
  test("eight to ten events, each with its own key and title", () => {
    expect(TEST_EVENTS.length).toBeGreaterThanOrEqual(8);
    expect(TEST_EVENTS.length).toBeLessThanOrEqual(10);
    expect(new Set(TEST_EVENTS.map((event) => event.key)).size).toBe(TEST_EVENTS.length);
    expect(new Set(TEST_EVENTS.map((event) => event.title)).size).toBe(TEST_EVENTS.length);
    expect(TEST_EVENTS.every((event) => event.key.startsWith("test-event-"))).toBe(true);
  });

  test("of at least four kinds the app knows, in the cities of the test members", () => {
    const cities = new Set(TEST_MEMBERS.map((member) => member.city));
    expect(TEST_EVENTS.every((event) => APP_KINDS.has(event.kind) && cities.has(event.city))).toBe(true);
    // The place shown on the card names the city.
    expect(TEST_EVENTS.every((event) => event.venue.startsWith(event.city))).toBe(true);
    expect(new Set(TEST_EVENTS.map((event) => event.kind)).size).toBeGreaterThanOrEqual(4);
    expect(new Set(TEST_EVENTS.map((event) => event.city)).size).toBeGreaterThanOrEqual(5);
  });

  test("written for a reader: real descriptions, times that make sense, plausible prices", () => {
    for (const event of TEST_EVENTS) {
      expect(event.description.length).toBeGreaterThan(120);
      expect(event.time < event.endTime).toBe(true);
      expect(event.price).toBeGreaterThanOrEqual(0);
      expect(event.price).toBeLessThanOrEqual(50);
      expect(event.maxAttendees).toBeGreaterThan(0);
    }
  });

  test("a Shabbat dinner is on a Friday evening", () => {
    const today = new Date("2026-10-26T10:00:00Z");
    for (const event of TEST_EVENTS.filter((candidate) => candidate.kind === "shabbat_dinner")) {
      expect(new Date(`${testEventDate(event, today)}T12:00:00Z`).getUTCDay()).toBe(5);
      expect(event.time >= "18:00").toBe(true);
    }
  });
});

describe("testEventDate", () => {
  test("puts every event on its weekday, between one and seven weeks ahead", () => {
    for (const today of [new Date("2026-10-26T10:00:00Z"), new Date("2026-10-30T23:30:00Z"), new Date("2027-02-28T00:00:00Z")]) {
      for (const event of TEST_EVENTS) {
        const date = testEventDate(event, today);
        expect(date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
        const days = (Date.parse(`${date}T00:00:00Z`) - Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate())) / 86_400_000;
        expect(days).toBeGreaterThanOrEqual(7);
        expect(days).toBeLessThan(7 * 7);
        expect(new Date(`${date}T12:00:00Z`).getUTCDay()).toBe(event.weekday);
      }
    }
  });

  test("the first event of 2026-10-26 (a Monday) falls on Friday 2026-11-06", () => {
    const shabbat = TEST_EVENTS.find((event) => event.key === "test-event-shabbat-paris");
    if (shabbat === undefined) throw new Error("missing");
    expect(testEventDate(shabbat, new Date("2026-10-26T08:00:00Z"))).toBe("2026-11-06");
  });
});
