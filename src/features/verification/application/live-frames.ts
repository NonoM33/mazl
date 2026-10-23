import { toGrayThumbnail } from "../domain/frames";
import { selectSubjectFace } from "../domain/face-selection";
import { assessLiveness, type FrameObservation, type LivenessVerdict } from "../domain/liveness";
import { eyeDistance, MIN_EYE_DISTANCE_PX, yawOf } from "../domain/pose";
import type { Challenge } from "../domain/types";
import { InvalidImageError, type FaceEngine, type ImageDecoder } from "./ports";

export interface LiveFramesDeps {
  readonly decoder: ImageDecoder;
  readonly engine: FaceEngine;
  readonly consistencyThreshold: number;
}

// Steps 2 to 6 of the contract (frame count, one face per frame, poses,
// distinct frames, same person). Shared by level 1 ("photo") and level 2
// ("identity"); on success the verdict carries the first front embedding.
// Frames are processed one at a time and never written anywhere.
export async function verifyLiveFrames(
  deps: LiveFramesDeps,
  challenges: readonly Challenge[],
  frames: readonly Uint8Array[],
): Promise<LivenessVerdict> {
  if (frames.length !== challenges.length) return { ok: false, reason: "wrong_frame_count" };
  const observations: FrameObservation[] = [];
  for (const bytes of frames) observations.push(await observe(deps, bytes));
  return assessLiveness(challenges, observations, deps.consistencyThreshold);
}

async function observe(deps: LiveFramesDeps, bytes: Uint8Array): Promise<FrameObservation> {
  let image;
  try {
    image = await deps.decoder.decode(bytes);
  } catch (error: unknown) {
    if (error instanceof InvalidImageError) return { status: "invalid_image" };
    throw error;
  }
  const selection = selectSubjectFace(await deps.engine.detect(image));
  if (selection.status !== "single_face") return { status: selection.status };

  const distance = eyeDistance(selection.face.landmarks);
  // A face this small is refused by the eye-distance rule before the
  // embedding is read, so computing it would be wasted work.
  const embedding =
    distance < MIN_EYE_DISTANCE_PX ? new Float32Array(0) : await deps.engine.embed(image, selection.face);
  return {
    status: "single_face",
    eyeDistance: distance,
    yaw: yawOf(selection.face.landmarks),
    thumbnail: toGrayThumbnail(image),
    embedding,
  };
}
