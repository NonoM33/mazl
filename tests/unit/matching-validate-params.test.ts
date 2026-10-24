import { describe, expect, test } from "bun:test";
import { DEFAULT_PARAMS, NUMERIC_PARAMS, type MatchingParams } from "../../src/features/matching/domain/params";
import { getParam, setParam, validateParams } from "../../src/features/matching/domain/validate-params";

const clone = (): Record<string, unknown> => structuredClone(DEFAULT_PARAMS) as unknown as Record<string, unknown>;
const errorsOf = (input: unknown): readonly string[] => {
  const v = validateParams(input);
  if (v.ok) throw new Error("devait echouer");
  return v.errors;
};

describe("getParam / setParam", () => {
  test("read every numeric spec", () => {
    for (const spec of NUMERIC_PARAMS) expect(typeof getParam(DEFAULT_PARAMS, spec.path)).toBe("number");
    expect(getParam(DEFAULT_PARAMS, "weights.age")).toBe(3);
    expect(getParam(DEFAULT_PARAMS, "freshness.halfLifeDays")).toBe(14);
  });
  test("setParam is immutable", () => {
    const next = setParam(DEFAULT_PARAMS, "weights.age", 7);
    expect(next.weights.age).toBe(7);
    expect(DEFAULT_PARAMS.weights.age).toBe(3);
    expect(next.weights.kashrut).toBe(DEFAULT_PARAMS.weights.kashrut);
    expect(next.scales).toBe(DEFAULT_PARAMS.scales);
  });
});

describe("validateParams", () => {
  test("defaults are valid and returned as a copy", () => {
    const v = validateParams(DEFAULT_PARAMS);
    expect(v.ok).toBe(true);
    if (v.ok) {
      expect(v.params).toEqual(DEFAULT_PARAMS);
      expect(v.params).not.toBe(DEFAULT_PARAMS);
      expect(v.params.scales).not.toBe(DEFAULT_PARAMS.scales);
    }
  });
  test("accepts a JSON round trip", () => {
    expect(validateParams(JSON.parse(JSON.stringify(DEFAULT_PARAMS))).ok).toBe(true);
  });

  for (const spec of NUMERIC_PARAMS) {
    describe(spec.path, () => {
      const attempt = (value: number) => validateParams(setParam(DEFAULT_PARAMS, spec.path, value) as MatchingParams);
      // keep the weight sum positive when probing a weight at its minimum
      const withValue = (value: number): ReturnType<typeof validateParams> => attempt(value);
      test("min and max accepted", () => {
        if (spec.group === "weights") {
          expect(withValue(spec.max).ok).toBe(true);
        } else {
          expect(withValue(spec.min).ok).toBe(true);
          expect(withValue(spec.max).ok).toBe(true);
        }
      });
      test("min - step and max + step rejected with a French bounds message", () => {
        for (const value of [spec.min - spec.step, spec.max + spec.step]) {
          const v = withValue(value);
          expect(v.ok).toBe(false);
          if (!v.ok) expect(v.errors).toContain(`${spec.path} = ${value} : hors bornes [${spec.min}, ${spec.max}]`);
        }
      });
      test("off-step value rejected", () => {
        const v = withValue(spec.min + spec.step / 2);
        expect(v.ok).toBe(false);
      });
    });
  }

  test("the example message from the spec", () => {
    expect(errorsOf(setParam(DEFAULT_PARAMS, "weights.age", 12))).toContain("weights.age = 12 : hors bornes [0, 10]");
  });
  test("non-object input", () => {
    expect(errorsOf(null).length).toBeGreaterThan(0);
    expect(errorsOf("x").length).toBeGreaterThan(0);
    expect(errorsOf([]).length).toBeGreaterThan(0);
  });
  test("missing key, wrong type, NaN", () => {
    const missing = clone();
    delete (missing["weights"] as Record<string, unknown>)["age"];
    expect(errorsOf(missing).some((e) => e.startsWith("weights.age"))).toBe(true);
    const wrong = clone();
    (wrong["weights"] as Record<string, unknown>)["age"] = "3";
    expect(errorsOf(wrong).some((e) => e.startsWith("weights.age"))).toBe(true);
    const nan = clone();
    (nan["freshness"] as Record<string, unknown>)["floor"] = Number.NaN;
    expect(errorsOf(nan).some((e) => e.startsWith("freshness.floor"))).toBe(true);
    const noGroup = clone();
    delete noGroup["religion"];
    expect(errorsOf(noGroup).some((e) => e.startsWith("religion"))).toBe(true);
  });
  test("booleans and modes", () => {
    const b = clone();
    (b["filters"] as Record<string, unknown>)["mutualAge"] = "yes";
    expect(errorsOf(b).some((e) => e.startsWith("filters.mutualAge"))).toBe(true);
    const m = clone();
    (m["reciprocity"] as Record<string, unknown>)["mode"] = "arithmetic";
    expect(errorsOf(m).some((e) => e.startsWith("reciprocity.mode"))).toBe(true);
    for (const mode of ["harmonic", "geometric", "min", "forward_only"]) {
      const ok = clone();
      (ok["reciprocity"] as Record<string, unknown>)["mode"] = mode;
      expect(validateParams(ok).ok).toBe(true);
    }
  });
  test("scales: malformed keys, ranks, size", () => {
    const badKey = clone();
    (badKey["scales"] as Record<string, Record<string, number>>)["kashrut"] = { "Kasher Strict": 2, non: 0 };
    expect(errorsOf(badKey).some((e) => e.startsWith("scales.kashrut"))).toBe(true);
    const badRank = clone();
    (badRank["scales"] as Record<string, Record<string, number>>)["shabbat"] = { a: 0, b: 11 };
    expect(errorsOf(badRank).some((e) => e.startsWith("scales.shabbat"))).toBe(true);
    const fractional = clone();
    (fractional["scales"] as Record<string, Record<string, number>>)["shabbat"] = { a: 0, b: 1.5 };
    expect(errorsOf(fractional).some((e) => e.startsWith("scales.shabbat"))).toBe(true);
    const tiny = clone();
    (tiny["scales"] as Record<string, Record<string, number>>)["intention"] = { open: 0 };
    expect(errorsOf(tiny).some((e) => e.startsWith("scales.intention"))).toBe(true);
    const missing = clone();
    delete (missing["scales"] as Record<string, unknown>)["intention"];
    expect(errorsOf(missing).some((e) => e.startsWith("scales.intention"))).toBe(true);
    const arr = clone();
    (arr["scales"] as Record<string, unknown>)["intention"] = [0, 1];
    expect(errorsOf(arr).some((e) => e.startsWith("scales.intention"))).toBe(true);
  });
  test("weights summing to zero", () => {
    let p: MatchingParams = DEFAULT_PARAMS;
    for (const c of Object.keys(DEFAULT_PARAMS.weights)) p = setParam(p, `weights.${c}`, 0);
    expect(errorsOf(p).some((e) => e.includes("somme des poids"))).toBe(true);
  });
  test("reports one error per problem", () => {
    let p = setParam(DEFAULT_PARAMS, "weights.age", 12);
    p = setParam(p, "safety.floor", 5);
    expect(errorsOf(p).length).toBe(2);
  });
  test("returned copy is detached from the input", () => {
    const input = clone();
    const v = validateParams(input);
    (input["weights"] as Record<string, number>)["age"] = 9;
    if (v.ok) expect(v.params.weights.age).toBe(3);
  });
});
