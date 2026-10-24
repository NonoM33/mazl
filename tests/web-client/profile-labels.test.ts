import { describe, expect, test } from "bun:test";
import { answerKey, profileLabels } from "../../web/src/shared/lib/profile-labels";

// Same expectations as mobile/test for ProfileLabels: the forms stored over
// time read the same, hidden answers give no chip.
describe("profile labels", () => {
  test("every stored spelling of one answer reads the same", () => {
    expect(profileLabels.kashrut("A la maison")).toBe("Cacher à la maison");
    expect(profileLabels.kashrut("kasher_a_la_maison")).toBe("Cacher à la maison");
    expect(profileLabels.shabbat("Tres observant")).toBe("Shabbat strict");
    expect(profileLabels.shabbat("Très Observant")).toBe("Shabbat strict");
    expect(profileLabels.denomination("Modern Orthodox")).toBe("Orthodoxe moderne");
    expect(profileLabels.denomination("Laique")).toBe("Laïque");
    expect(profileLabels.intention("friends_first")).toBe("Amitié d'abord");
  });

  test("empty, 'Non' and 'Autre' give no chip", () => {
    expect(profileLabels.kashrut("Non")).toBeNull();
    expect(profileLabels.denomination("Autre")).toBeNull();
    expect(profileLabels.shabbat("Non observant")).toBeNull();
    expect(profileLabels.shabbat("  ")).toBeNull();
    expect(profileLabels.shabbat(null)).toBeNull();
  });

  test("an unknown value stays readable", () => {
    expect(profileLabels.denomination("sefarade_traditionnel")).toBe("Sefarade traditionnel");
    expect(answerKey("Très - Observant")).toBe("tres_observant");
  });
});
