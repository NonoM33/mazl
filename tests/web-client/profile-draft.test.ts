import { describe, expect, test } from "bun:test";
import { ageFromBirthdate, changedFields, draftFromRow, fieldOfServerError, validateChanges, type ProfileDraft } from "../../web/src/features/profile/profile-draft";

const saved: ProfileDraft = { displayName: "Léa", birthdate: "1994-03-12", gender: "female", location: "Paris 11e", bio: "Bonjour", denomination: "Massorti", kashrutLevel: "A la maison", shabbatObservance: "Partiellement", relationshipIntention: "" };
const open = { birthdateLocked: false, practiceAllowed: true };

describe("changedFields", () => {
  test("nothing changed sends nothing", () => {
    expect(changedFields(saved, { ...saved }, open)).toEqual({});
  });
  test("only the edited fields are sent, trimmed", () => {
    expect(changedFields(saved, { ...saved, bio: "  Nouvelle bio ", location: "Lyon" }, open)).toEqual({ bio: "Nouvelle bio", location: "Lyon" });
  });
  test("a locked birth date is never sent", () => {
    expect(changedFields(saved, { ...saved, birthdate: "1990-01-01" }, { ...open, birthdateLocked: true })).toEqual({});
  });
  test("practice is not sent without the article 9 consent", () => {
    expect(changedFields(saved, { ...saved, denomination: "Habad", bio: "x" }, { ...open, practiceAllowed: false })).toEqual({ bio: "x" });
  });
  test("a cleared choice is not sent as an empty value but a cleared bio is", () => {
    expect(changedFields(saved, { ...saved, denomination: "", bio: "" }, open)).toEqual({ bio: "" });
  });
  test("the intention travels as relationshipIntention", () => {
    expect(changedFields(saved, { ...saved, relationshipIntention: "marriage" }, open)).toEqual({ relationshipIntention: "marriage" });
  });
});

describe("validateChanges", () => {
  test("length limits of the server", () => {
    expect(validateChanges({ displayName: "x".repeat(51) }).displayName).toBeDefined();
    expect(validateChanges({ displayName: "x".repeat(50) }).displayName).toBeUndefined();
    expect(validateChanges({ bio: "x".repeat(1001) }).bio).toBeDefined();
    expect(validateChanges({ bio: "x".repeat(1000) }).bio).toBeUndefined();
    expect(validateChanges({ location: "x".repeat(101) }).location).toBeDefined();
  });
  test("an empty first name is refused", () => {
    expect(validateChanges({ displayName: "" }).displayName).toBeDefined();
  });
  test("birth date must be real and 18 or older", () => {
    expect(validateChanges({ birthdate: "1994-02-31" }).birthdate).toBeDefined();
    expect(validateChanges({ birthdate: "pas une date" }).birthdate).toBeDefined();
    expect(validateChanges({ birthdate: `${new Date().getFullYear() - 10}-01-01` }).birthdate).toBeDefined();
    expect(validateChanges({ birthdate: "1994-03-12" })).toEqual({});
  });
});

describe("ageFromBirthdate", () => {
  test("birthday not yet reached this year", () => {
    expect(ageFromBirthdate("2000-06-15", new Date(2026, 5, 14))).toBe(25);
    expect(ageFromBirthdate("2000-06-15", new Date(2026, 5, 15))).toBe(26);
  });
});

describe("server errors and rows", () => {
  test("the field is read in front of the server message", () => {
    expect(fieldOfServerError("bio: Too big")).toBe("bio");
    expect(fieldOfServerError("displayName: x")).toBe("displayName");
    expect(fieldOfServerError("Invalid JSON body")).toBeNull();
    expect(fieldOfServerError(undefined)).toBeNull();
  });
  test("a stored row becomes a draft with a plain date", () => {
    const draft = draftFromRow({ user_id: 1, display_name: "Léa", birthdate: "1994-03-12T00:00:00.000Z", gender: "female", bio: null, location: null, latitude: null, longitude: null, denomination: null, kashrut_level: null, shabbat_observance: null, looking_for: null, age_min: null, age_max: null, distance_max: null, is_complete: true, is_verified: false, verification_level: null });
    expect(draft.birthdate).toBe("1994-03-12");
    expect(draft.bio).toBe("");
  });
});
