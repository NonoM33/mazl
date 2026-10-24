import { describe, expect, test } from "bun:test";
import { createDoubleEscape, DOUBLE_ESCAPE_MS } from "../../web/src/features/discreet/double-escape";

describe("discreet mode shortcut", () => {
  test("two Escape presses close together toggle it, a slow second press does not", () => {
    let clock = 0;
    let toggles = 0;
    const press = createDoubleEscape(() => { toggles += 1; }, () => clock);
    press("Escape");
    clock += DOUBLE_ESCAPE_MS + 1;
    press("Escape");
    expect(toggles).toBe(0);
    clock += 100;
    expect(press("Escape")).toBe(true);
    expect(toggles).toBe(1);
  });

  test("a third quick press starts a new pair instead of toggling back", () => {
    let clock = 0;
    let toggles = 0;
    const press = createDoubleEscape(() => { toggles += 1; }, () => clock);
    press("Escape"); clock += 50; press("Escape"); clock += 50; press("Escape");
    expect(toggles).toBe(1);
  });

  test("other keys are ignored", () => {
    let toggles = 0;
    const press = createDoubleEscape(() => { toggles += 1; }, () => 0);
    press("Enter"); press("Escape"); press("a"); press("Escape");
    expect(toggles).toBe(1);
  });
});
