import { describe, expect, test } from "bun:test";
import { readFaceConfig, FaceConfigError } from "../../src/features/verification/infra/config";

describe("readFaceConfig", () => {
  test("defaults: models/ and the thresholds published by OpenCV and the contract", () => {
    expect(readFaceConfig({})).toEqual({ modelsDir: "models", thresholds: { match: 0.363, consistency: 0.5 } });
  });

  test("reads the three variables", () => {
    const c = readFaceConfig({ FACE_MODELS_DIR: "/srv/models", FACE_MATCH_THRESHOLD: "0.4", FACE_CONSISTENCY_THRESHOLD: "0.55" });
    expect(c).toEqual({ modelsDir: "/srv/models", thresholds: { match: 0.4, consistency: 0.55 } });
  });

  test("empty strings fall back to the defaults", () => {
    expect(readFaceConfig({ FACE_MODELS_DIR: "", FACE_MATCH_THRESHOLD: "" }).thresholds.match).toBe(0.363);
  });

  test("a threshold that is not a number in [-1, 1] stops the boot", () => {
    for (const bad of ["abc", "1.5", "-2", "NaN", "Infinity"]) {
      expect(() => readFaceConfig({ FACE_MATCH_THRESHOLD: bad })).toThrow(FaceConfigError);
      expect(() => readFaceConfig({ FACE_CONSISTENCY_THRESHOLD: bad })).toThrow(FaceConfigError);
    }
  });
});
