// 2D similarity transform (rotation + uniform scale + translation), as used
// by OpenCV's FaceRecognizerSF::alignCrop to put a face on the standard
// 112x112 ArcFace layout. OpenCV computes the Umeyama solution with an SVD;
// in 2D, with no reflection allowed, the same least-squares optimum has a
// closed form with complex numbers, which is what is implemented here.

export type Point2 = readonly [number, number];

// x' = a*x - b*y + tx ; y' = b*x + a*y + ty
export interface SimilarityTransform {
  readonly a: number;
  readonly b: number;
  readonly tx: number;
  readonly ty: number;
}

// Right eye, left eye, nose tip, right and left mouth corners, in the
// 112x112 aligned image (face_recognize.cpp, getSimilarityTransformMatrix).
export const ARCFACE_TEMPLATE: readonly Point2[] = [
  [38.2946, 51.6963],
  [73.5318, 51.5014],
  [56.0252, 71.7366],
  [41.5493, 92.3655],
  [70.7299, 92.2041],
];

export class DegenerateLandmarksError extends Error {
  constructor() {
    super("landmarks are coincident: no similarity transform exists");
    this.name = "DegenerateLandmarksError";
  }
}

export function estimateSimilarityTransform(src: readonly Point2[], dst: readonly Point2[]): SimilarityTransform {
  if (src.length !== dst.length || src.length === 0) throw new RangeError("point sets must match and be non-empty");
  const n = src.length;
  const meanSrc = mean(src);
  const meanDst = mean(dst);
  let dot = 0;
  let cross = 0;
  let variance = 0;
  for (let i = 0; i < n; i++) {
    const sx = (src[i]?.[0] ?? 0) - meanSrc[0];
    const sy = (src[i]?.[1] ?? 0) - meanSrc[1];
    const dx = (dst[i]?.[0] ?? 0) - meanDst[0];
    const dy = (dst[i]?.[1] ?? 0) - meanDst[1];
    dot += sx * dx + sy * dy;
    cross += sx * dy - sy * dx;
    variance += sx * sx + sy * sy;
  }
  if (variance < 1e-9) throw new DegenerateLandmarksError();
  const a = dot / variance;
  const b = cross / variance;
  return {
    a,
    b,
    tx: meanDst[0] - (a * meanSrc[0] - b * meanSrc[1]),
    ty: meanDst[1] - (b * meanSrc[0] + a * meanSrc[1]),
  };
}

export function applyTransform(m: SimilarityTransform, p: Point2): Point2 {
  return [m.a * p[0] - m.b * p[1] + m.tx, m.b * p[0] + m.a * p[1] + m.ty];
}

function mean(points: readonly Point2[]): Point2 {
  let x = 0;
  let y = 0;
  for (const p of points) {
    x += p[0];
    y += p[1];
  }
  return [x / points.length, y / points.length];
}
