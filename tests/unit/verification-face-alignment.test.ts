import { describe, expect, test } from "bun:test";
import {
  ARCFACE_TEMPLATE,
  estimateSimilarityTransform,
  applyTransform,
  type Point2,
} from "../../src/features/verification/infra/similarity-transform";
import { warpAffineBilinear, resizeBilinear } from "../../src/features/verification/infra/image-ops";

// Template published in OpenCV's face_recognize.cpp and in the ArcFace reference.
const EXPECTED_TEMPLATE: Point2[] = [
  [38.2946, 51.6963],
  [73.5318, 51.5014],
  [56.0252, 71.7366],
  [41.5493, 92.3655],
  [70.7299, 92.2041],
];

function transformPoints(points: readonly Point2[], a: number, b: number, tx: number, ty: number): Point2[] {
  // x' = a x - b y + tx ; y' = b x + a y + ty  (rotation + uniform scale + translation)
  return points.map(([x, y]) => [a * x - b * y + tx, b * x + a * y + ty]);
}

describe("estimateSimilarityTransform", () => {
  test("the template is the standard 112x112 ArcFace one", () => {
    expect(ARCFACE_TEMPLATE).toEqual(EXPECTED_TEMPLATE);
  });

  test("recovers a known rotation + scale + translation applied to the template", () => {
    const angle = (17 * Math.PI) / 180;
    const scale = 2.6;
    const a = scale * Math.cos(angle);
    const b = scale * Math.sin(angle);
    const src = transformPoints(EXPECTED_TEMPLATE, a, b, 210, 95);
    const m = estimateSimilarityTransform(src, EXPECTED_TEMPLATE);
    for (let i = 0; i < 5; i++) {
      const [x, y] = applyTransform(m, src[i]!);
      expect(x).toBeCloseTo(EXPECTED_TEMPLATE[i]![0], 3);
      expect(y).toBeCloseTo(EXPECTED_TEMPLATE[i]![1], 3);
    }
  });

  test("identity when the points already are the template", () => {
    const m = estimateSimilarityTransform(EXPECTED_TEMPLATE, EXPECTED_TEMPLATE);
    expect(m.a).toBeCloseTo(1, 6);
    expect(m.b).toBeCloseTo(0, 6);
    expect(m.tx).toBeCloseTo(0, 4);
    expect(m.ty).toBeCloseTo(0, 4);
  });

  test("is a least-squares fit: noisy landmarks stay within the noise", () => {
    const noise: Point2[] = [[1.5, -1], [-1, 1.2], [0.5, 0.5], [-1.2, -0.8], [1, 1]];
    const src = transformPoints(EXPECTED_TEMPLATE, 2, 0.3, 40, 60).map(([x, y], i) => [x + noise[i]![0], y + noise[i]![1]] as Point2);
    const m = estimateSimilarityTransform(src, EXPECTED_TEMPLATE);
    for (let i = 0; i < 5; i++) {
      const [x, y] = applyTransform(m, src[i]!);
      expect(Math.hypot(x - EXPECTED_TEMPLATE[i]![0], y - EXPECTED_TEMPLATE[i]![1])).toBeLessThan(2);
    }
    // The transform is a pure similarity: it never mirrors the face.
    expect(m.a * m.a + m.b * m.b).toBeGreaterThan(0);
  });

  test("rejects degenerate landmarks (all points equal)", () => {
    const same: Point2[] = Array.from({ length: 5 }, () => [10, 10] as Point2);
    expect(() => estimateSimilarityTransform(same, EXPECTED_TEMPLATE)).toThrow();
  });
});

function gradientImage(width: number, height: number) {
  // R = x, G = y, B = 7 so that each channel is traceable.
  const data = new Uint8Array(width * height * 3);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 3;
      data[i] = x;
      data[i + 1] = y;
      data[i + 2] = 7;
    }
  }
  return { width, height, data };
}

describe("warpAffineBilinear", () => {
  test("a pure translation moves pixels (dst = src + t)", () => {
    const src = gradientImage(64, 64);
    const out = warpAffineBilinear(src, { a: 1, b: 0, tx: 10, ty: 5 }, 32, 32);
    expect(out.width).toBe(32);
    const i = (20 * 32 + 25) * 3; // dst (25, 20) <- src (15, 15)
    expect(out.data[i]).toBe(15);
    expect(out.data[i + 1]).toBe(15);
    expect(out.data[i + 2]).toBe(7);
  });

  test("pixels that map outside the source are black (constant border)", () => {
    const src = gradientImage(16, 16);
    const out = warpAffineBilinear(src, { a: 1, b: 0, tx: 10, ty: 0 }, 16, 16);
    expect(Array.from(out.data.slice(0, 3))).toEqual([0, 0, 0]); // dst (0,0) <- src (-10, 0)
  });

  test("a 2x scale interpolates bilinearly between source pixels", () => {
    const src = gradientImage(16, 16);
    const out = warpAffineBilinear(src, { a: 2, b: 0, tx: 0, ty: 0 }, 16, 16);
    const i = (4 * 16 + 5) * 3; // dst (5, 4) <- src (2.5, 2)
    expect(out.data[i]).toBe(3); // 2.5 rounds to 3 (round half up)
    expect(out.data[i + 1]).toBe(2);
  });

  test("a rotation by 90 degrees maps the x axis onto the y axis", () => {
    const src = gradientImage(32, 32);
    // x' = -y + 31, y' = x : dst(x', y') = src(x, y) with x = y', y = 31 - x'
    const out = warpAffineBilinear(src, { a: 0, b: 1, tx: 31, ty: 0 }, 32, 32);
    const i = (10 * 32 + 8) * 3; // dst (8, 10) <- src (10, 23)
    expect(out.data[i]).toBe(10);
    expect(out.data[i + 1]).toBe(23);
  });
});

describe("resizeBilinear", () => {
  test("keeps the corners and the size contract", () => {
    const src = gradientImage(100, 50);
    const out = resizeBilinear(src, 50, 25);
    expect(out.width).toBe(50);
    expect(out.height).toBe(25);
    expect(out.data).toHaveLength(50 * 25 * 3);
    expect(out.data[2]).toBe(7);
  });
});
