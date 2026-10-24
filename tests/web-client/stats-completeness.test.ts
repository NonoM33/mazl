import { describe, expect, test } from "bun:test";
import { completenessPercent, completenessSteps } from "../../web/src/features/stats/completeness";

const full = { photos: 6, prompts: 3, hasBio: true, hasPractice: true, verified: true };

describe("profile completeness", () => {
  test("a complete profile is 100 and has no step left", () => {
    expect(completenessPercent(full)).toBe(100);
    expect(completenessSteps(full).every((step) => step.done)).toBe(true);
  });
  test("an empty profile is 0", () => {
    expect(completenessPercent({ photos: 0, prompts: 0, hasBio: false, hasPractice: false, verified: false })).toBe(0);
  });
  test("photos and prompts count by share, beyond the target they stop counting", () => {
    expect(completenessPercent({ ...full, photos: 3, prompts: 0, verified: false })).toBe(Math.round(((0.5 + 0 + 1 + 1 + 0) / 5) * 100));
    expect(completenessPercent({ ...full, photos: 9 })).toBe(100);
  });
  test("missing steps say what to do and where", () => {
    const steps = completenessSteps({ ...full, photos: 4, verified: false });
    const photos = steps.find((step) => step.key === "photos");
    expect(photos).toMatchObject({ done: false, label: "Photos 4/6", to: "/profil/modifier", hint: "Ajoutez 2 photos." });
    expect(steps.find((step) => step.key === "verification")).toMatchObject({ done: false, to: null });
  });
});
