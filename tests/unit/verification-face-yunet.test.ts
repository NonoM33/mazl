import { describe, expect, test } from "bun:test";
import { decodeYunet, type YunetOutputs } from "../../src/features/verification/infra/yunet-decoder";

const SIZE = 640;
const STRIDES = [8, 16, 32] as const;

// Raw network outputs for an empty scene (every score 0), shaped like the
// real model's: one row per anchor, strides 8/16/32.
function emptyOutputs(): { out: YunetOutputs; cells: Record<number, number> } {
  const out: Record<string, Float32Array> = {};
  const cells: Record<number, number> = {};
  for (const s of STRIDES) {
    const n = (SIZE / s) * (SIZE / s);
    cells[s] = n;
    out[`cls_${s}`] = new Float32Array(n);
    out[`obj_${s}`] = new Float32Array(n);
    out[`bbox_${s}`] = new Float32Array(n * 4);
    out[`kps_${s}`] = new Float32Array(n * 10);
  }
  return { out: out as YunetOutputs, cells };
}

function plant(
  out: YunetOutputs,
  stride: 8 | 16 | 32,
  row: number,
  col: number,
  p: { cls: number; obj: number; bbox: [number, number, number, number]; kps: number[] },
): void {
  const cols = SIZE / stride;
  const idx = row * cols + col;
  out[`cls_${stride}`][idx] = p.cls;
  out[`obj_${stride}`][idx] = p.obj;
  out[`bbox_${stride}`].set(p.bbox, idx * 4);
  out[`kps_${stride}`].set(p.kps, idx * 10);
}

const KPS = [-0.2, -0.1, 0.2, -0.1, 0.0, 0.1, -0.15, 0.3, 0.15, 0.3];

describe("decodeYunet", () => {
  test("an empty scene yields no face", () => {
    expect(decodeYunet(emptyOutputs().out, { width: SIZE, height: SIZE }, 0.6, 0.3, 5000)).toEqual([]);
  });

  test("decodes box, landmarks and score exactly as OpenCV's FaceDetectorYN", () => {
    const { out } = emptyOutputs();
    // stride 16, cell row 3 / col 5. score = sqrt(cls * obj) = sqrt(0.81 * 1) = 0.9
    plant(out, 16, 3, 5, { cls: 0.81, obj: 1, bbox: [0.5, -0.25, Math.log(4), Math.log(5)], kps: KPS });
    const faces = decodeYunet(out, { width: SIZE, height: SIZE }, 0.6, 0.3, 5000);
    expect(faces).toHaveLength(1);
    const f = faces[0]!;
    // centre = ((col + dx) * stride, (row + dy) * stride) = (88, 44); size = exp(.) * stride = (64, 80)
    expect(f.box.x).toBeCloseTo(88 - 32, 3);
    expect(f.box.y).toBeCloseTo(44 - 40, 3);
    expect(f.box.width).toBeCloseTo(64, 3);
    expect(f.box.height).toBeCloseTo(80, 3);
    expect(f.score).toBeCloseTo(0.9, 5);
    // landmark = (kps + cell) * stride
    const at = (i: number): [number, number] => [(KPS[2 * i]! + 5) * 16, (KPS[2 * i + 1]! + 3) * 16];
    expect(f.landmarks.rightEye.x).toBeCloseTo(at(0)[0], 3);
    expect(f.landmarks.rightEye.y).toBeCloseTo(at(0)[1], 3);
    expect(f.landmarks.leftEye.x).toBeCloseTo(at(1)[0], 3);
    expect(f.landmarks.leftEye.y).toBeCloseTo(at(1)[1], 3);
    expect(f.landmarks.nose.x).toBeCloseTo(at(2)[0], 3);
    expect(f.landmarks.rightMouth.y).toBeCloseTo(at(3)[1], 3);
    expect(f.landmarks.leftMouth.x).toBeCloseTo(at(4)[0], 3);
  });

  test("the same decode formula holds on the stride 8 and 32 grids", () => {
    const { out } = emptyOutputs();
    plant(out, 8, 10, 12, { cls: 1, obj: 1, bbox: [0, 0, Math.log(10), Math.log(10)], kps: KPS });
    plant(out, 32, 15, 2, { cls: 1, obj: 1, bbox: [0, 0, Math.log(2), Math.log(3)], kps: KPS });
    const faces = decodeYunet(out, { width: SIZE, height: SIZE }, 0.6, 0.3, 5000);
    expect(faces).toHaveLength(2);
    const small = faces.find((f) => Math.abs(f.box.width - 80) < 0.01)!;
    expect(small.box.x).toBeCloseTo(12 * 8 - 40, 3);
    expect(small.box.y).toBeCloseTo(10 * 8 - 40, 3);
    const big = faces.find((f) => Math.abs(f.box.width - 64) < 0.01)!;
    expect(big.box.width).toBeCloseTo(64, 3);
    expect(big.box.height).toBeCloseTo(96, 3);
  });

  test("scores are clamped to [0, 1] before the geometric mean", () => {
    const { out } = emptyOutputs();
    plant(out, 16, 3, 5, { cls: 7, obj: 0.64, bbox: [0, 0, 0, 0], kps: KPS });
    const faces = decodeYunet(out, { width: SIZE, height: SIZE }, 0.6, 0.3, 5000);
    expect(faces[0]!.score).toBeCloseTo(0.8, 5); // sqrt(1 * 0.64)
    plant(out, 16, 20, 20, { cls: -3, obj: 1, bbox: [0, 0, 0, 0], kps: KPS });
    expect(decodeYunet(out, { width: SIZE, height: SIZE }, 0.6, 0.3, 5000)).toHaveLength(1);
  });

  test("candidates under the score threshold are dropped, at the threshold they stay", () => {
    const { out } = emptyOutputs();
    plant(out, 16, 3, 5, { cls: 0.25, obj: 1, bbox: [0, 0, 0, 0], kps: KPS }); // score 0.5
    expect(decodeYunet(out, { width: SIZE, height: SIZE }, 0.6, 0.3, 5000)).toHaveLength(0);
    expect(decodeYunet(out, { width: SIZE, height: SIZE }, 0.5, 0.3, 5000)).toHaveLength(1);
  });

  test("overlapping detections of one face collapse to the best score", () => {
    const { out } = emptyOutputs();
    // Same 64x64 box seen from two neighbouring cells of the stride 16 grid, shifted by 1 px.
    plant(out, 16, 4, 4, { cls: 0.81, obj: 1, bbox: [0, 0, Math.log(4), Math.log(4)], kps: KPS });
    plant(out, 16, 4, 5, { cls: 0.64, obj: 1, bbox: [-1 / 16, 0, Math.log(4), Math.log(4)], kps: KPS });
    const faces = decodeYunet(out, { width: SIZE, height: SIZE }, 0.6, 0.3, 5000);
    expect(faces).toHaveLength(1);
    expect(faces[0]!.score).toBeCloseTo(0.9, 5);
  });

  test("two faces far apart both survive NMS, best score first", () => {
    const { out } = emptyOutputs();
    plant(out, 16, 4, 4, { cls: 0.64, obj: 1, bbox: [0, 0, Math.log(4), Math.log(4)], kps: KPS });
    plant(out, 16, 30, 30, { cls: 0.81, obj: 1, bbox: [0, 0, Math.log(4), Math.log(4)], kps: KPS });
    const faces = decodeYunet(out, { width: SIZE, height: SIZE }, 0.6, 0.3, 5000);
    expect(faces.map((f) => Number(f.score.toFixed(2)))).toEqual([0.9, 0.8]);
  });

  test("boxes under the NMS overlap limit are both kept, above it one is dropped", () => {
    const { out } = emptyOutputs();
    // Two 100x100 boxes (stride 32 not needed: use stride 8, w = exp(.) * 8 = 100).
    // Shift by 54 px horizontally: intersection 46*100, union 2*10000 - 4600 = 15400, IoU = 0.2987 < 0.3
    const lw = Math.log(12.5);
    plant(out, 8, 20, 20, { cls: 1, obj: 1, bbox: [0, 0, lw, lw], kps: KPS });
    plant(out, 8, 20, 26, { cls: 0.81, obj: 1, bbox: [6 / 8, 0, lw, lw], kps: KPS }); // +48 +6 = 54 px
    expect(decodeYunet(out, { width: SIZE, height: SIZE }, 0.6, 0.3, 5000)).toHaveLength(2);
    // Raising the overlap: shift by 40 px -> IoU = 6000 / 14000 = 0.43 > 0.3
    const { out: out2 } = emptyOutputs();
    plant(out2, 8, 20, 20, { cls: 1, obj: 1, bbox: [0, 0, lw, lw], kps: KPS });
    plant(out2, 8, 20, 25, { cls: 0.81, obj: 1, bbox: [0, 0, lw, lw], kps: KPS });
    expect(decodeYunet(out2, { width: SIZE, height: SIZE }, 0.6, 0.3, 5000)).toHaveLength(1);
  });

  test("topK caps the number of candidates examined", () => {
    const { out } = emptyOutputs();
    plant(out, 16, 4, 4, { cls: 0.64, obj: 1, bbox: [0, 0, Math.log(4), Math.log(4)], kps: KPS });
    plant(out, 16, 30, 30, { cls: 0.81, obj: 1, bbox: [0, 0, Math.log(4), Math.log(4)], kps: KPS });
    expect(decodeYunet(out, { width: SIZE, height: SIZE }, 0.6, 0.3, 1)).toHaveLength(1);
  });
});
