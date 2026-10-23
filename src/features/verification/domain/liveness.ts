import { findDuplicateFrames } from "./frames";
import { checkPoses, MIN_EYE_DISTANCE_PX } from "./pose";
import { cosineSimilarity } from "./similarity";
import type { Challenge, Embedding, FaceRejection } from "./types";

// What the application layer measured on one uploaded frame. The decision
// below is pure: it never decodes, detects or embeds anything itself.
export type FrameObservation =
  | { readonly status: "invalid_image" }
  | { readonly status: "no_face" }
  | { readonly status: "multiple_faces" }
  | {
      readonly status: "single_face";
      readonly eyeDistance: number;
      readonly yaw: number;
      readonly thumbnail: Uint8Array;
      readonly embedding: Embedding;
    };

export type LivenessVerdict =
  | { readonly ok: true; readonly frontEmbedding: Embedding }
  | { readonly ok: false; readonly reason: FaceRejection };

// Steps 2 to 6 of the contract, in order: frame count, one usable face per
// frame, poses, no duplicated frame, same person throughout. Every embedding
// is compared with the first frame: a different person at any step differs
// from it, so pairwise checks would add nothing.
export function assessLiveness(
  challenges: readonly Challenge[],
  frames: readonly FrameObservation[],
  consistencyThreshold: number,
): LivenessVerdict {
  if (frames.length !== challenges.length) return reject("wrong_frame_count");

  const faces: Extract<FrameObservation, { status: "single_face" }>[] = [];
  for (const frame of frames) {
    if (frame.status !== "single_face") return reject(frame.status);
    if (frame.eyeDistance < MIN_EYE_DISTANCE_PX) return reject("face_too_small");
    faces.push(frame);
  }

  const poseProblem = checkPoses(challenges, faces.map((f) => f.yaw));
  if (poseProblem) return reject(poseProblem);

  if (findDuplicateFrames(faces.map((f) => f.thumbnail))) return reject("duplicate_frames");

  const anchor = faces[0];
  if (!anchor) return reject("wrong_frame_count");
  for (const face of faces.slice(1)) {
    if (cosineSimilarity(anchor.embedding, face.embedding) < consistencyThreshold) {
      return reject("inconsistent_identity");
    }
  }
  return { ok: true, frontEmbedding: anchor.embedding };
}

function reject(reason: FaceRejection): LivenessVerdict {
  return { ok: false, reason };
}
