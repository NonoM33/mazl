import { describe, expect, test } from "bun:test";
import { ApiError, classifyLoadFailure, describeError, describeMissingField } from "../../web/src/shared/api/errors";

describe("409 profile_incomplete from the feeds", () => {
  const body = { success: false, error: "profile_incomplete", missing: ["gender", "looking_for"] };

  test("the generic wording it used to get is not what the member sees", () => {
    expect(describeError(new ApiError(409, "profile_incomplete", null, body))).toBe("La demande n'a pas abouti.");
    expect(classifyLoadFailure(new ApiError(409, "profile_incomplete", null, body)).kind).toBe("profile_incomplete");
  });

  test("other failures stay generic errors", () => {
    expect(classifyLoadFailure(new ApiError(409, "something_else", null, body))).toEqual({ kind: "error", message: "La demande n'a pas abouti." });
    expect(classifyLoadFailure(new ApiError(500, "boom")).kind).toBe("error");
  });

  test("a body without a readable list still gives the incomplete state", () => {
    expect(classifyLoadFailure(new ApiError(409, "profile_incomplete", null, {}))).toEqual({ kind: "profile_incomplete", missing: [] });
  });

  test("labels in French, unknown values do not break", () => {
    expect(describeMissingField("gender")).toBe("Votre genre");
    expect(describeMissingField("looking_for")).toBe("Qui vous recherchez");
    expect(describeMissingField("birthdate")).toBe("Une information de votre profil");
  });
});
