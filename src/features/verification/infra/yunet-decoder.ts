import type { DetectedFace } from "../domain/types";

// Decoding of YuNet's raw outputs, a faithful port of
// opencv/modules/objdetect/src/face_detect.cpp (FaceDetectorYNImpl::postProcess).
// The network has three heads (strides 8, 16, 32); each grid cell predicts a
// class score, an objectness score, a box and five landmarks.

const STRIDES = [8, 16, 32] as const;
type Stride = (typeof STRIDES)[number];

export type YunetOutputs = {
  readonly [K in `${"cls" | "obj"}_${Stride}`]: Float32Array;
} & {
  readonly [K in `${"bbox" | "kps"}_${Stride}`]: Float32Array;
};

const clamp01 = (v: number): number => Math.min(1, Math.max(0, v));

export function decodeYunet(
  outputs: YunetOutputs,
  inputSize: { readonly width: number; readonly height: number },
  scoreThreshold: number,
  nmsThreshold: number,
  topK: number,
): DetectedFace[] {
  const candidates: DetectedFace[] = [];
  for (const stride of STRIDES) {
    const cols = Math.floor(inputSize.width / stride);
    const rows = Math.floor(inputSize.height / stride);
    const cls = outputs[`cls_${stride}`];
    const obj = outputs[`obj_${stride}`];
    const bbox = outputs[`bbox_${stride}`];
    const kps = outputs[`kps_${stride}`];
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        const idx = r * cols + c;
        const score = Math.sqrt(clamp01(cls[idx] ?? 0) * clamp01(obj[idx] ?? 0));
        if (score < scoreThreshold) continue;
        candidates.push(decodeCell(bbox, kps, idx, r, c, stride, score));
      }
    }
  }
  return nonMaximumSuppression(candidates, nmsThreshold, topK);
}

function decodeCell(
  bbox: Float32Array,
  kps: Float32Array,
  idx: number,
  r: number,
  c: number,
  stride: number,
  score: number,
): DetectedFace {
  const cx = (c + (bbox[idx * 4] ?? 0)) * stride;
  const cy = (r + (bbox[idx * 4 + 1] ?? 0)) * stride;
  const w = Math.exp(bbox[idx * 4 + 2] ?? 0) * stride;
  const h = Math.exp(bbox[idx * 4 + 3] ?? 0) * stride;
  const point = (n: number) => ({
    x: ((kps[idx * 10 + 2 * n] ?? 0) + c) * stride,
    y: ((kps[idx * 10 + 2 * n + 1] ?? 0) + r) * stride,
  });
  return {
    box: { x: cx - w / 2, y: cy - h / 2, width: w, height: h },
    score,
    landmarks: { rightEye: point(0), leftEye: point(1), nose: point(2), rightMouth: point(3), leftMouth: point(4) },
  };
}

// Greedy NMS as in cv::dnn::NMSBoxes (eta = 1): best score first, a box is
// kept when its IoU with every kept box is <= the threshold. Boxes are
// truncated to integers first, like OpenCV's Rect2i.
function nonMaximumSuppression(faces: DetectedFace[], nmsThreshold: number, topK: number): DetectedFace[] {
  if (faces.length <= 1) return faces.slice(0, Math.max(topK, 0));
  const order = faces.map((_, i) => i).sort((a, b) => (faces[b]?.score ?? 0) - (faces[a]?.score ?? 0));
  const considered = order.slice(0, Math.max(topK, 0));
  const kept: DetectedFace[] = [];
  for (const i of considered) {
    const face = faces[i];
    if (!face) continue;
    if (kept.every((k) => intersectionOverUnion(face, k) <= nmsThreshold)) kept.push(face);
  }
  return kept;
}

function intersectionOverUnion(a: DetectedFace, b: DetectedFace): number {
  const ax = Math.trunc(a.box.x);
  const ay = Math.trunc(a.box.y);
  const aw = Math.trunc(a.box.width);
  const ah = Math.trunc(a.box.height);
  const bx = Math.trunc(b.box.x);
  const by = Math.trunc(b.box.y);
  const bw = Math.trunc(b.box.width);
  const bh = Math.trunc(b.box.height);
  const iw = Math.min(ax + aw, bx + bw) - Math.max(ax, bx);
  const ih = Math.min(ay + ah, by + bh) - Math.max(ay, by);
  if (iw <= 0 || ih <= 0) return 0;
  const inter = iw * ih;
  const union = aw * ah + bw * bh - inter;
  return union <= 0 ? 0 : inter / union;
}
