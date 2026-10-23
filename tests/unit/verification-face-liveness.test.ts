import { describe, expect, test } from "bun:test";
import {
  assessLiveness,
  type FrameObservation,
} from "../../src/features/verification/domain/liveness";
import type { Challenge } from "../../src/features/verification/domain/types";

const CONSISTENCY = 0.5;

// Unit vectors with a chosen cosine to the reference [1, 0].
function embeddingWithCosine(cosine: number): Float32Array {
  return Float32Array.of(cosine, Math.sqrt(1 - cosine * cosine));
}

function thumb(level: number): Uint8Array {
  return new Uint8Array(1024).fill(level);
}

function face(over: Partial<Extract<FrameObservation, { status: "single_face" }>> = {}): FrameObservation {
  return {
    status: "single_face",
    eyeDistance: 90,
    yaw: 0,
    thumbnail: thumb(50),
    embedding: Float32Array.of(1, 0),
    ...over,
  };
}

const CHALLENGES: Challenge[] = ["front", "left", "right"];

function goodFrames(): FrameObservation[] {
  return [
    face({ yaw: 0.02, thumbnail: thumb(40) }),
    face({ yaw: 0.35, thumbnail: thumb(90) }),
    face({ yaw: -0.35, thumbnail: thumb(140) }),
  ];
}

describe("assessLiveness", () => {
  test("a clean submission passes and returns the first front embedding", () => {
    const frames = goodFrames();
    const verdict = assessLiveness(CHALLENGES, frames, CONSISTENCY);
    expect(verdict.ok).toBe(true);
    if (verdict.ok) expect(verdict.frontEmbedding).toBe((frames[0] as { embedding: Float32Array }).embedding);
  });

  test("frame count must match the challenges", () => {
    expect(assessLiveness(CHALLENGES, goodFrames().slice(0, 2), CONSISTENCY)).toEqual({
      ok: false,
      reason: "wrong_frame_count",
    });
  });

  test("an undecodable, empty or crowded frame is reported by its status", () => {
    for (const status of ["invalid_image", "no_face", "multiple_faces"] as const) {
      const frames = goodFrames();
      frames[1] = { status };
      expect(assessLiveness(CHALLENGES, frames, CONSISTENCY)).toEqual({ ok: false, reason: status });
    }
  });

  test("eyes closer than 60 px are too small, exactly 60 is accepted", () => {
    const small = goodFrames();
    small[2] = face({ yaw: -0.35, eyeDistance: 59.9, thumbnail: thumb(140) });
    expect(assessLiveness(CHALLENGES, small, CONSISTENCY)).toEqual({ ok: false, reason: "face_too_small" });

    const exact = goodFrames();
    exact[2] = face({ yaw: -0.35, eyeDistance: 60, thumbnail: thumb(140) });
    expect(assessLiveness(CHALLENGES, exact, CONSISTENCY).ok).toBe(true);
  });

  test("face checks come before pose checks", () => {
    const frames = goodFrames();
    frames[0] = face({ yaw: 0.9 }); // wrong pose
    frames[2] = { status: "no_face" };
    expect(assessLiveness(CHALLENGES, frames, CONSISTENCY)).toEqual({ ok: false, reason: "no_face" });
  });

  test("a wrong pose is refused", () => {
    const frames = goodFrames();
    frames[0] = face({ yaw: 0.3, thumbnail: thumb(40) });
    expect(assessLiveness(CHALLENGES, frames, CONSISTENCY)).toEqual({ ok: false, reason: "pose_mismatch" });
  });

  test("left and right turned the same way are refused", () => {
    const frames = goodFrames();
    frames[2] = face({ yaw: 0.35, thumbnail: thumb(140) });
    expect(assessLiveness(CHALLENGES, frames, CONSISTENCY)).toEqual({ ok: false, reason: "pose_mismatch" });
  });

  test("identical frames are refused even when the poses are right", () => {
    const frames = goodFrames();
    frames[1] = face({ yaw: 0.35, thumbnail: thumb(40) }); // same pixels as frame 0
    expect(assessLiveness(CHALLENGES, frames, CONSISTENCY)).toEqual({ ok: false, reason: "duplicate_frames" });
  });

  test("another person in any frame is refused", () => {
    const frames = goodFrames();
    frames[2] = face({ yaw: -0.35, thumbnail: thumb(140), embedding: embeddingWithCosine(0.2) });
    expect(assessLiveness(CHALLENGES, frames, CONSISTENCY)).toEqual({ ok: false, reason: "inconsistent_identity" });
  });

  test("consistency is inclusive at the threshold and exclusive just below", () => {
    const at = goodFrames();
    at[1] = face({ yaw: 0.35, thumbnail: thumb(90), embedding: embeddingWithCosine(0.5) });
    expect(assessLiveness(CHALLENGES, at, 0.5 - 1e-6).ok).toBe(true);

    const below = goodFrames();
    below[1] = face({ yaw: 0.35, thumbnail: thumb(90), embedding: embeddingWithCosine(0.49) });
    expect(assessLiveness(CHALLENGES, below, 0.5).ok).toBe(false);
  });

  test("a four step session with a final front frame passes", () => {
    const challenges: Challenge[] = ["front", "right", "left", "front"];
    const frames = [
      face({ yaw: 0.0, thumbnail: thumb(40) }),
      face({ yaw: -0.3, thumbnail: thumb(80) }),
      face({ yaw: 0.3, thumbnail: thumb(120) }),
      face({ yaw: 0.05, thumbnail: thumb(160) }),
    ];
    expect(assessLiveness(challenges, frames, CONSISTENCY).ok).toBe(true);
    frames[3] = face({ yaw: 0.05, thumbnail: thumb(40) }); // final front equals the first
    expect(assessLiveness(challenges, frames, CONSISTENCY)).toEqual({ ok: false, reason: "duplicate_frames" });
  });
});
