import { describe, expect, test } from "bun:test";
import { activeWindow, nextWindow, PARIS, restWindows } from "../../web/src/features/shabbat/rest-windows";

// Expectations taken from the calendar, not from the code: Rosh Hashana 5787
// falls on Saturday 12 and Sunday 13 September 2026 (eve: Friday 11); Yom
// Kippour on Monday 21 September 2026. In Paris the sun sets at 16:54-16:56
// around the December solstice, so candle lighting on Friday 18 December 2026
// is about 16:36.
const paris = (iso: string) => new Date(`${iso}+01:00`);
// Calendar fields as seen in Paris, whatever the time zone of the process.
function inParis(date: Date | undefined) {
  const parts = Object.fromEntries(new Intl.DateTimeFormat("en-GB", { timeZone: "Europe/Paris", weekday: "short", day: "numeric", hour: "numeric", minute: "numeric", hourCycle: "h23" }).formatToParts(date ?? new Date(0)).map((part) => [part.type, part.value]));
  return { weekday: parts.weekday, day: Number(parts.day), minutes: Number(parts.hour) * 60 + Number(parts.minute), hour: Number(parts.hour) };
}
const options = { includeHolidays: true, bufferMin: 0 };

describe("Shabbat windows", () => {
  test("an ordinary Shabbat opens on Friday before sunset and ends on Saturday night", () => {
    const window = nextWindow(paris("2026-12-16T12:00:00"), PARIS, options);
    expect(window).not.toBeNull();
    const start = inParis(window?.start);
    const end = inParis(window?.end);
    expect(start.weekday).toBe("Fri");
    expect(start.day).toBe(18);
    expect(start.minutes).toBeGreaterThanOrEqual(16 * 60 + 33);
    expect(start.minutes).toBeLessThanOrEqual(16 * 60 + 39);
    expect(end.weekday).toBe("Sat");
    expect(end.hour).toBe(17);
    expect(window?.holiday).toBe(false);
  });

  test("the margin opens the window earlier by as many minutes", () => {
    const at = paris("2026-10-28T12:00:00");
    const plain = nextWindow(at, PARIS, options);
    const early = nextWindow(at, PARIS, { includeHolidays: true, bufferMin: 30 });
    expect((plain?.start.getTime() ?? 0) - (early?.start.getTime() ?? 0)).toBe(30 * 60_000);
  });

  test("Shabbat followed by Rosh Hashana is one window to Sunday night, holidays included", () => {
    const window = nextWindow(paris("2026-09-10T12:00:00"), PARIS, options);
    expect(inParis(window?.start).day).toBe(11);
    expect(inParis(window?.end).day).toBe(13);
    expect(window?.holiday).toBe(true);
  });

  test("without holidays, the same weekend ends on Saturday night", () => {
    const window = nextWindow(paris("2026-09-10T12:00:00"), PARIS, { includeHolidays: false, bufferMin: 0 });
    expect(inParis(window?.end).day).toBe(12);
  });

  test("Saturday afternoon is inside the window, Sunday noon is not", () => {
    expect(activeWindow(paris("2026-10-31T15:00:00"), PARIS, options)).not.toBeNull();
    expect(activeWindow(paris("2026-11-01T12:00:00"), PARIS, options)).toBeNull();
  });

  test("a weekday Yom Kippour (Monday 21 September 2026) is its own window", () => {
    const windows = restWindows(paris("2026-09-19T22:00:00"), PARIS, options);
    const kippour = windows.find((window) => inParis(window.end).day === 21);
    expect(inParis(kippour?.start).day).toBe(20);
    expect(kippour?.holiday).toBe(true);
  });
});
