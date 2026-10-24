import { describe, expect, test } from "bun:test";
import { exclusionReason } from "../../src/features/matching/domain/filters";
import { DEFAULT_PARAMS } from "../../src/features/matching/domain/params";
import { context, profile } from "./matching-support";

const viewer = profile({ userId: 1, gender: "male", lookingFor: "female" });
const woman = (o = {}) => profile({ userId: 2, gender: "female", lookingFor: "male", ...o });
const reason = (c = woman(), v = viewer, ctx = context(), p = DEFAULT_PARAMS) => exclusionReason(v, c, ctx, p);

describe("exclusionReason", () => {
  test("compatible candidate passes", () => {
    expect(reason()).toBeNull();
  });
  test("excluded list and the viewer themself", () => {
    expect(reason(woman(), viewer, context([2]))).toBe("excluded");
    expect(reason(viewer)).toBe("excluded");
  });
  test("excluded wins over every other reason", () => {
    expect(reason(woman({ gender: "male", age: 80 }), viewer, context([2]))).toBe("excluded");
  });
  test("gender: viewer's lookingFor", () => {
    expect(reason(woman({ gender: "male" }))).toBe("gender");
  });
  test("gender: reciprocal lookingFor of the candidate", () => {
    expect(reason(woman({ lookingFor: "female" }))).toBe("gender");
  });
  test("lookingFor null or all accepts everyone; null gender does not filter", () => {
    expect(reason(woman({ gender: "male" }), profile({ lookingFor: "all" }))).toBeNull();
    expect(reason(woman({ gender: "male" }), profile({ lookingFor: null }))).toBeNull();
    expect(reason(woman({ lookingFor: "all" }))).toBeNull();
    expect(reason(woman({ gender: null }))).toBeNull();
    expect(reason(woman(), profile({ gender: null }))).toBeNull();
  });
  test("age: inside the range inclusive, outside rejected, unknown ignored", () => {
    expect(reason(woman({ age: 25 }))).toBeNull();
    expect(reason(woman({ age: 35 }))).toBeNull();
    expect(reason(woman({ age: 24 }))).toBe("age");
    expect(reason(woman({ age: 36 }))).toBe("age");
    expect(reason(woman({ age: null }))).toBeNull();
  });
  test("mutual age follows the parameter", () => {
    const picky = woman({ ageMin: 20, ageMax: 28 });
    expect(reason(picky)).toBe("age");
    const loose = { ...DEFAULT_PARAMS, filters: { ...DEFAULT_PARAMS.filters, mutualAge: false } };
    expect(reason(picky, viewer, context(), loose)).toBeNull();
    expect(reason(woman({ ageMin: 20, ageMax: 28 }), profile({ age: null }))).toBeNull();
  });
  test("distance: viewer limit, mutual limit, unknown positions, no limit", () => {
    const lyon = { latitude: 45.764, longitude: 4.8357 };
    expect(reason(woman({ location: lyon }), profile({ distanceMaxKm: 100 }))).toBe("distance");
    expect(reason(woman({ location: lyon }), profile({ distanceMaxKm: null }))).toBe("distance"); // candidate limit 50
    expect(reason(woman({ location: lyon, distanceMaxKm: null }), profile({ distanceMaxKm: null }))).toBeNull();
    expect(reason(woman({ location: lyon, distanceMaxKm: 500 }), profile({ distanceMaxKm: 500 }))).toBeNull();
    expect(reason(woman({ location: null }), profile({ distanceMaxKm: 1 }))).toBeNull();
    const loose = { ...DEFAULT_PARAMS, filters: { ...DEFAULT_PARAMS.filters, mutualDistance: false } };
    expect(reason(woman({ location: lyon, distanceMaxKm: 10 }), profile({ distanceMaxKm: 500 }), context(), loose)).toBeNull();
  });
});
