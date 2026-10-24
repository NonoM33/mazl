import { describe, expect, test } from "bun:test";
import { generateChallenges } from "../../src/features/verification/domain/challenges";
import { cosineSimilarity } from "../../src/features/verification/domain/similarity";
import {
  eyeDistance,
  yawOf,
  checkPoses,
  MIN_EYE_DISTANCE_PX,
} from "../../src/features/verification/domain/pose";
import {
  toGrayThumbnail,
  meanAbsoluteDifference,
  findDuplicateFrames,
  THUMBNAIL_SIZE,
} from "../../src/features/verification/domain/frames";
import { selectSubjectFace } from "../../src/features/verification/domain/face-selection";
import type { DetectedFace } from "../../src/features/verification/domain/types";

// A random source that replays a fixed script of values in [0, 1).
function scripted(...values: number[]): () => number {
  let i = 0;
  return () => values[i++ % values.length] ?? 0;
}

function landmarks(rightEyeX: number, leftEyeX: number, noseX: number): DetectedFace["landmarks"] {
  return {
    rightEye: { x: rightEyeX, y: 100 },
    leftEye: { x: leftEyeX, y: 100 },
    nose: { x: noseX, y: 140 },
    rightMouth: { x: rightEyeX, y: 180 },
    leftMouth: { x: leftEyeX, y: 180 },
  };
}

describe("generateChallenges", () => {
  test("always starts with front and contains left and right exactly once", () => {
    for (let i = 0; i < 200; i++) {
      const c = generateChallenges(Math.random);
      expect(c[0]).toBe("front");
      expect(c.filter((x) => x === "left")).toHaveLength(1);
      expect(c.filter((x) => x === "right")).toHaveLength(1);
      expect(c.length === 3 || c.length === 4).toBe(true);
      if (c.length === 4) expect(c[3]).toBe("front");
    }
  });

  test("the random source decides the order and the optional final front", () => {
    expect(generateChallenges(scripted(0.1, 0.1))).toEqual(["front", "left", "right"]);
    expect(generateChallenges(scripted(0.9, 0.1))).toEqual(["front", "right", "left"]);
    expect(generateChallenges(scripted(0.1, 0.9))).toEqual(["front", "left", "right", "front"]);
    expect(generateChallenges(scripted(0.9, 0.9))).toEqual(["front", "right", "left", "front"]);
  });

  test("both orders and both lengths occur with the real random source", () => {
    const seen = new Set<string>();
    for (let i = 0; i < 400; i++) seen.add(generateChallenges(Math.random).join(","));
    expect(seen.size).toBe(4);
  });
});

describe("cosineSimilarity", () => {
  test("identical, orthogonal and opposite vectors", () => {
    expect(cosineSimilarity(Float32Array.of(1, 2, 3), Float32Array.of(1, 2, 3))).toBeCloseTo(1, 6);
    expect(cosineSimilarity(Float32Array.of(1, 0), Float32Array.of(0, 1))).toBeCloseTo(0, 6);
    expect(cosineSimilarity(Float32Array.of(1, 0), Float32Array.of(-1, 0))).toBeCloseTo(-1, 6);
  });

  test("does not require normalised input", () => {
    expect(cosineSimilarity(Float32Array.of(3, 4), Float32Array.of(6, 8))).toBeCloseTo(1, 6);
  });

  test("a zero vector matches nothing", () => {
    expect(cosineSimilarity(Float32Array.of(0, 0), Float32Array.of(1, 0))).toBe(0);
  });

  test("different lengths are a programming error", () => {
    expect(() => cosineSimilarity(Float32Array.of(1), Float32Array.of(1, 2))).toThrow();
  });
});

describe("pose", () => {
  test("eye distance is euclidean", () => {
    const lm = landmarks(100, 160, 130);
    expect(eyeDistance(lm)).toBeCloseTo(60, 6);
    const tilted: DetectedFace["landmarks"] = { ...lm, leftEye: { x: 130, y: 140 } };
    expect(eyeDistance(tilted)).toBeCloseTo(50, 6);
  });

  test("yaw is the nose offset from the eye midpoint over the eye distance", () => {
    expect(yawOf(landmarks(100, 200, 150))).toBeCloseTo(0, 6);
    expect(yawOf(landmarks(100, 200, 175))).toBeCloseTo(0.25, 6);
    expect(yawOf(landmarks(100, 200, 120))).toBeCloseTo(-0.3, 6);
  });

  test("mirroring the face flips the yaw sign", () => {
    const a = yawOf(landmarks(100, 200, 170));
    const mirrored = yawOf(landmarks(100, 200, 130));
    expect(mirrored).toBeCloseTo(-a, 6);
  });

  test("the minimum eye distance is 60 px", () => {
    expect(MIN_EYE_DISTANCE_PX).toBe(60);
  });

  test("front accepts |yaw| < 0.12 and refuses 0.12 exactly", () => {
    expect(checkPoses(["front"], [0.119])).toBeNull();
    expect(checkPoses(["front"], [-0.119])).toBeNull();
    expect(checkPoses(["front"], [0.12])).toBe("pose_mismatch");
    expect(checkPoses(["front"], [-0.12])).toBe("pose_mismatch");
  });

  test("a side pose needs |yaw| > 0.22, refused at 0.22 exactly", () => {
    expect(checkPoses(["front", "left", "right"], [0, 0.221, -0.221])).toBeNull();
    expect(checkPoses(["front", "left", "right"], [0, 0.22, -0.3])).toBe("pose_mismatch");
    expect(checkPoses(["front", "left", "right"], [0, 0.3, -0.22])).toBe("pose_mismatch");
  });

  test("left and right must have opposite signs, in either direction", () => {
    expect(checkPoses(["front", "left", "right"], [0, -0.4, 0.4])).toBeNull();
    expect(checkPoses(["front", "left", "right"], [0, 0.4, -0.4])).toBeNull();
    expect(checkPoses(["front", "left", "right"], [0, 0.4, 0.5])).toBe("pose_mismatch");
    expect(checkPoses(["front", "left", "right"], [0, -0.4, -0.5])).toBe("pose_mismatch");
  });

  test("a final front frame is checked like the first one", () => {
    expect(checkPoses(["front", "right", "left", "front"], [0, 0.4, -0.4, 0.05])).toBeNull();
    expect(checkPoses(["front", "right", "left", "front"], [0, 0.4, -0.4, 0.3])).toBe("pose_mismatch");
  });

  test("a yaw count that differs from the challenges is a programming error", () => {
    expect(() => checkPoses(["front", "left"], [0])).toThrow();
  });
});

describe("frame thumbnails and duplicate detection", () => {
  function flat(width: number, height: number, rgb: [number, number, number]) {
    const data = new Uint8Array(width * height * 3);
    for (let i = 0; i < width * height; i++) data.set(rgb, i * 3);
    return { width, height, data };
  }

  test("thumbnail is 32x32 grayscale", () => {
    const t = toGrayThumbnail(flat(200, 150, [255, 255, 255]));
    expect(THUMBNAIL_SIZE).toBe(32);
    expect(t).toHaveLength(32 * 32);
    expect(t.every((v) => v === 255)).toBe(true);
  });

  test("grayscale uses luma weights", () => {
    const red = toGrayThumbnail(flat(64, 64, [255, 0, 0]));
    const green = toGrayThumbnail(flat(64, 64, [0, 255, 0]));
    expect(red[0]).toBe(Math.round(0.299 * 255));
    expect(green[0]).toBe(Math.round(0.587 * 255));
  });

  test("images smaller than the thumbnail still produce 32x32", () => {
    const t = toGrayThumbnail(flat(10, 7, [10, 10, 10]));
    expect(t).toHaveLength(1024);
    expect(t.every((v) => v === 10)).toBe(true);
  });

  test("left half and right half are kept apart", () => {
    const width = 64;
    const height = 64;
    const data = new Uint8Array(width * height * 3);
    for (let y = 0; y < height; y++) for (let x = width / 2; x < width; x++) data.fill(255, (y * width + x) * 3, (y * width + x) * 3 + 3);
    const t = toGrayThumbnail({ width, height, data });
    expect(t[5 * 32 + 3]).toBe(0);
    expect(t[5 * 32 + 28]).toBe(255);
  });

  test("mean absolute difference", () => {
    const a = new Uint8Array(1024).fill(100);
    const b = new Uint8Array(1024).fill(103);
    expect(meanAbsoluteDifference(a, b)).toBe(3);
    expect(meanAbsoluteDifference(a, a)).toBe(0);
  });

  test("a difference of exactly 2/255 counts as a duplicate, above 2 it does not", () => {
    const a = new Uint8Array(1024).fill(100);
    const exactly2 = new Uint8Array(1024).fill(102);
    const above = new Uint8Array(1024).fill(102);
    above[0] = 103; // mean diff = (1023*2 + 3) / 1024 > 2
    expect(findDuplicateFrames([a, exactly2])).toBe(true);
    expect(findDuplicateFrames([a, above])).toBe(false);
  });

  test("any pair counts, not only neighbours", () => {
    const a = new Uint8Array(1024).fill(10);
    const b = new Uint8Array(1024).fill(90);
    const c = new Uint8Array(1024).fill(10);
    expect(findDuplicateFrames([a, b, c])).toBe(true);
  });

  test("a single frame has no duplicate", () => {
    expect(findDuplicateFrames([new Uint8Array(1024)])).toBe(false);
  });
});

describe("selectSubjectFace", () => {
  function faceOf(width: number, height: number, score = 0.9): DetectedFace {
    return {
      box: { x: 0, y: 0, width, height },
      score,
      landmarks: landmarks(10, 20, 15),
    };
  }

  test("no detection means no face", () => {
    expect(selectSubjectFace([])).toEqual({ status: "no_face" });
  });

  test("one detection is the subject", () => {
    const f = faceOf(100, 120);
    expect(selectSubjectFace([f])).toEqual({ status: "single_face", face: f });
  });

  test("a second face of comparable size is refused", () => {
    expect(selectSubjectFace([faceOf(100, 120), faceOf(90, 100)]).status).toBe("multiple_faces");
  });

  test("a tiny spurious detection next to the real face is ignored", () => {
    const main = faceOf(150, 164);
    const speck = faceOf(49, 62, 0.83); // 12 % of the area, seen on a real portrait (a hand)
    const result = selectSubjectFace([speck, main]);
    expect(result).toEqual({ status: "single_face", face: main });
  });

  test("the limit is 25 % of the largest area: at the limit counts as a second face", () => {
    const main = faceOf(100, 100);
    expect(selectSubjectFace([main, faceOf(50, 50)]).status).toBe("multiple_faces"); // exactly 25 %
    expect(selectSubjectFace([main, faceOf(49, 50)]).status).toBe("single_face"); // 24.5 %
  });

  test("the subject is the largest face whatever the input order", () => {
    const big = faceOf(200, 200);
    const small = faceOf(40, 40);
    expect(selectSubjectFace([small, big])).toEqual({ status: "single_face", face: big });
  });
});
