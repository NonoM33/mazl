import { beforeAll, describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import sharp from "sharp";
import { OnnxFaceEngine } from "../../src/features/verification/infra/onnx-face-engine";
import { SharpImageDecoder } from "../../src/features/verification/infra/sharp-image-decoder";
import { cosineSimilarity } from "../../src/features/verification/domain/similarity";
import { yawOf } from "../../src/features/verification/domain/pose";
import type { RgbImage } from "../../src/features/verification/application/ports";
import type { DetectedFace } from "../../src/features/verification/domain/types";

// Real models, real public-domain portraits (see tests/fixtures/faces/SOURCES.md).
// Expected values come from the published SFace cosine threshold (0.363,
// OpenCV Zoo), not from this implementation's own output.
const SFACE_COSINE_THRESHOLD = 0.363;
const DIR = join(import.meta.dir, "..", "fixtures", "faces");
const engine = new OnnxFaceEngine(join(import.meta.dir, "..", "..", "models"));
const decoder = new SharpImageDecoder();

const read = (name: string): Uint8Array => new Uint8Array(readFileSync(join(DIR, name)));

interface Subject {
  readonly image: RgbImage;
  readonly faces: readonly DetectedFace[];
}
const subjects: Record<string, Subject> = {};

async function load(name: string): Promise<Subject> {
  const image = await decoder.decode(read(name));
  return { image, faces: await engine.detect(image) };
}

async function flipped(name: string): Promise<Subject> {
  const bytes = await sharp(read(name)).flop().jpeg({ quality: 90 }).toBuffer();
  const image = await decoder.decode(new Uint8Array(bytes));
  return { image, faces: await engine.detect(image) };
}

const FILES = [
  "ride-portrait-1984.jpg",
  "ride-flight-deck-1983.jpg",
  "ride-profile-sts7-1983.jpg",
  "glenn-senate-portrait.jpg",
] as const;

beforeAll(async () => {
  for (const f of FILES) subjects[f] = await load(f);
});

function only(name: string): DetectedFace {
  const faces = subjects[name]?.faces ?? [];
  expect(faces).toHaveLength(1);
  return faces[0] as DetectedFace;
}

async function embed(name: string): Promise<Float32Array> {
  const s = subjects[name] as Subject;
  return engine.embed(s.image, only(name));
}

describe("YuNet detection on real portraits", () => {
  for (const f of FILES) {
    test(`${f}: exactly one face, confident, with plausible landmarks`, () => {
      const face = only(f);
      const lm = face.landmarks;
      expect(face.score).toBeGreaterThan(0.7);
      const eyeY = (lm.rightEye.y + lm.leftEye.y) / 2;
      const mouthY = (lm.rightMouth.y + lm.leftMouth.y) / 2;
      expect(eyeY).toBeLessThan(lm.nose.y);
      expect(lm.nose.y).toBeLessThan(mouthY);
      // The five landmarks fall inside the detected box (with a small margin).
      const { x, y, width, height } = face.box;
      for (const p of Object.values(lm)) {
        expect(p.x).toBeGreaterThan(x - 0.05 * width);
        expect(p.x).toBeLessThan(x + 1.05 * width);
        expect(p.y).toBeGreaterThan(y - 0.05 * height);
        expect(p.y).toBeLessThan(y + 1.05 * height);
      }
    });
  }

  test("a frontal portrait has its eyes level and its nose between them", () => {
    const lm = only("ride-portrait-1984.jpg").landmarks;
    const eyeDistance = Math.hypot(lm.leftEye.x - lm.rightEye.x, lm.leftEye.y - lm.rightEye.y);
    expect(Math.abs(lm.leftEye.y - lm.rightEye.y)).toBeLessThan(0.15 * eyeDistance);
    expect(lm.nose.x).toBeGreaterThan(lm.rightEye.x);
    expect(lm.nose.x).toBeLessThan(lm.leftEye.x);
    expect(Math.abs(yawOf(lm))).toBeLessThan(0.2);
  });

  test("the box is placed on the face: the eyes sit in its upper half", () => {
    const face = only("glenn-senate-portrait.jpg");
    const eyeY = (face.landmarks.rightEye.y + face.landmarks.leftEye.y) / 2;
    expect(eyeY).toBeGreaterThan(face.box.y);
    expect(eyeY).toBeLessThan(face.box.y + face.box.height / 2);
  });

  test("a blank image has no face", async () => {
    const blank: RgbImage = { width: 480, height: 360, data: new Uint8Array(480 * 360 * 3).fill(128) };
    expect(await engine.detect(blank)).toHaveLength(0);
  });

  test("detection is scale-independent: the same portrait at half size is still found", async () => {
    const half = await sharp(read("glenn-senate-portrait.jpg")).resize({ width: 480 }).jpeg().toBuffer();
    const img = await decoder.decode(new Uint8Array(half));
    expect(await engine.detect(img)).toHaveLength(1);
  });
});

describe("SFace embeddings on real portraits", () => {
  test("an embedding is 128 floats, L2-normalised", async () => {
    const e = await embed("ride-portrait-1984.jpg");
    expect(e).toHaveLength(128);
    expect(Math.hypot(...e)).toBeCloseTo(1, 4);
  });

  test("the same person in two different photos is at or above the published threshold", async () => {
    const a = await embed("ride-portrait-1984.jpg");
    const b = await embed("ride-flight-deck-1983.jpg");
    expect(cosineSimilarity(a, b)).toBeGreaterThanOrEqual(SFACE_COSINE_THRESHOLD);
  });

  test("two different people are below the published threshold", async () => {
    const ride = await embed("ride-portrait-1984.jpg");
    const rideOther = await embed("ride-flight-deck-1983.jpg");
    const glenn = await embed("glenn-senate-portrait.jpg");
    expect(cosineSimilarity(ride, glenn)).toBeLessThan(SFACE_COSINE_THRESHOLD);
    expect(cosineSimilarity(rideOther, glenn)).toBeLessThan(SFACE_COSINE_THRESHOLD);
  });

  test("the same photo embeds to the same vector", async () => {
    const a = await embed("glenn-senate-portrait.jpg");
    const b = await embed("glenn-senate-portrait.jpg");
    expect(cosineSimilarity(a, b)).toBeGreaterThan(0.9999);
  });

  test("a mirrored photo of the same person still matches the original", async () => {
    const original = await embed("ride-portrait-1984.jpg");
    const mirror = await flipped("ride-portrait-1984.jpg");
    expect(mirror.faces).toHaveLength(1);
    const e = await engine.embed(mirror.image, mirror.faces[0] as DetectedFace);
    expect(cosineSimilarity(original, e)).toBeGreaterThanOrEqual(SFACE_COSINE_THRESHOLD);
  });
});

describe("yaw on real portraits", () => {
  test("a head turned away has a large yaw, and mirroring flips its sign", async () => {
    const yaw = yawOf(only("ride-profile-sts7-1983.jpg").landmarks);
    const mirror = await flipped("ride-profile-sts7-1983.jpg");
    expect(mirror.faces).toHaveLength(1);
    const mirrorYaw = yawOf((mirror.faces[0] as DetectedFace).landmarks);
    expect(Math.abs(yaw)).toBeGreaterThan(0.22);
    expect(Math.abs(mirrorYaw)).toBeGreaterThan(0.22);
    expect(Math.sign(mirrorYaw)).toBe(-Math.sign(yaw));
  });
});
