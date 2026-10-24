import { describe, expect, test } from "bun:test";
import type { OwnProfileRow } from "../../web/src/shared/api/types";
import { chooseShadchan } from "../../web/src/features/discover/shadchan";
import { card } from "./discover-fixtures";

const me = { denomination: "Massorti", kashrut_level: "A la maison", shabbat_observance: "Partiellement", relationship_intention: "serious" } as OwnProfileRow;

describe("Shadchan choice", () => {
  test("picks the profile sharing the most, and names only the shared answers", () => {
    const a = card(1, { denomination: "Massorti", kashrut_level: "Strict" });
    const b = card(2, { denomination: "Massorti", kashrut_level: "A la maison", shabbat_observance: "Partiellement" });
    const choice = chooseShadchan(me, [a, b]);
    expect(choice?.pick.user_id).toBe(2);
    expect(choice?.shared).toEqual(["Massorti", "Cacher à la maison", "Shabbat en partie"]);
  });

  test("a tie keeps the first selection", () => {
    const a = card(1, { denomination: "Massorti" });
    const b = card(2, { denomination: "Massorti" });
    expect(chooseShadchan(me, [a, b])?.pick.user_id).toBe(1);
  });

  test("with nothing in common the first selection is presented with no criterion", () => {
    const choice = chooseShadchan(me, [card(1, { denomination: "Laique" }), card(2)]);
    expect(choice?.pick.user_id).toBe(1);
    expect(choice?.shared).toEqual([]);
  });

  test("hidden answers (« Non ») are never counted as shared", () => {
    const quiet = { denomination: null, kashrut_level: "Non", shabbat_observance: null, relationship_intention: null } as OwnProfileRow;
    expect(chooseShadchan(quiet, [card(1, { kashrut_level: "Non" })])?.shared).toEqual([]);
  });

  test("no selection, no choice; my profile missing still works", () => {
    expect(chooseShadchan(me, [])).toBeNull();
    expect(chooseShadchan(null, [card(5)])?.pick.user_id).toBe(5);
  });
});
