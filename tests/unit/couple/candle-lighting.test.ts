import { describe, expect, test } from "bun:test";
import { candleLightingFor } from "../../../src/features/couple/infra/candle-lighting";
import { localParts, timeZoneFor } from "../../../src/features/couple/domain/local-time";

// Reference values come from published tables, not from the library under test:
// Paris on Friday 2026-10-30 (winter time since the 25th): sunset about 17:30,
// so candle lighting (18 minutes before) about 17:12. Jerusalem the same day:
// sunset about 16:55, lighting (40 minutes before) about 16:15.
describe("candle lighting (kosher-zmanim)", () => {
  test("Paris, Friday 2026-10-30, falls between 17:00 and 17:30 Paris time", () => {
    const at = candleLightingFor(48.8566, 2.3522, "Europe/Paris")({ year: 2026, month: 10, day: 30 });
    expect(at).not.toBeNull();
    const local = localParts(at as Date, "Europe/Paris");
    expect(local.weekday).toBe(5);
    const minutes = local.hour * 60 + local.minute;
    expect(minutes).toBeGreaterThanOrEqual(17 * 60);
    expect(minutes).toBeLessThanOrEqual(17 * 60 + 30);
  });

  test("it moves with the season: much later in June than in December", () => {
    const light = candleLightingFor(48.8566, 2.3522, "Europe/Paris");
    const summer = localParts(light({ year: 2027, month: 6, day: 18 }) as Date, "Europe/Paris");
    const winter = localParts(light({ year: 2026, month: 12, day: 18 }) as Date, "Europe/Paris");
    expect(summer.hour * 60 + summer.minute).toBeGreaterThan(winter.hour * 60 + winter.minute + 180);
  });

  test("Jerusalem lights 40 minutes before sunset, earlier than a 18-minute rule would", () => {
    const jerusalem = localParts(candleLightingFor(31.7683, 35.2137, "Asia/Jerusalem")({ year: 2026, month: 10, day: 30 }) as Date, "Asia/Jerusalem");
    const minutes = jerusalem.hour * 60 + jerusalem.minute;
    expect(minutes).toBeGreaterThanOrEqual(16 * 60);
    expect(minutes).toBeLessThanOrEqual(16 * 60 + 30);
  });

  test("the same calendar can be asked for several days in a row", () => {
    const light = candleLightingFor(48.8566, 2.3522, "Europe/Paris");
    const first = light({ year: 2026, month: 10, day: 30 });
    light({ year: 2026, month: 11, day: 6 });
    expect(light({ year: 2026, month: 10, day: 30 })?.getTime()).toBe(first?.getTime());
  });
});

describe("time zone of a place", () => {
  test("Israel, New York, London, otherwise Paris", () => {
    expect(timeZoneFor(32.08, 34.78)).toBe("Asia/Jerusalem");
    expect(timeZoneFor(40.71, -74.0)).toBe("America/New_York");
    expect(timeZoneFor(51.5, -0.12)).toBe("Europe/London");
    expect(timeZoneFor(45.76, 4.83)).toBe("Europe/Paris");
    expect(timeZoneFor(null, null)).toBe("Europe/Paris");
  });
});
