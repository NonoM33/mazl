import type { Challenge, DetectedFace } from "./types";

type Landmarks = DetectedFace["landmarks"];

export const MIN_EYE_DISTANCE_PX = 60;
export const FRONT_YAW_LIMIT = 0.12;
export const SIDE_YAW_MINIMUM = 0.22;

export function eyeDistance(lm: Landmarks): number {
  return Math.hypot(lm.leftEye.x - lm.rightEye.x, lm.leftEye.y - lm.rightEye.y);
}

// Normalised horizontal offset of the nose from the middle of the eyes.
// Only its sign (relative to another frame) and magnitude matter: which side
// is "left" depends on whether the front camera mirrors the preview.
// Callers check the eye distance first; a degenerate face reads as frontal.
export function yawOf(lm: Landmarks): number {
  const distance = eyeDistance(lm);
  if (distance <= 0) return 0;
  const eyeMiddleX = (lm.rightEye.x + lm.leftEye.x) / 2;
  return (lm.nose.x - eyeMiddleX) / distance;
}

// Verifies each frame against its challenge, then that the left and right
// frames turned in opposite directions. Strict inequalities on purpose: a
// value exactly on a limit is refused.
export function checkPoses(challenges: readonly Challenge[], yaws: readonly number[]): "pose_mismatch" | null {
  if (challenges.length !== yaws.length) {
    throw new RangeError(`expected ${challenges.length} yaws, got ${yaws.length}`);
  }
  let leftYaw: number | null = null;
  let rightYaw: number | null = null;
  for (let i = 0; i < challenges.length; i++) {
    const yaw = yaws[i] ?? 0;
    const challenge = challenges[i];
    if (challenge === "front") {
      if (!(Math.abs(yaw) < FRONT_YAW_LIMIT)) return "pose_mismatch";
      continue;
    }
    if (!(Math.abs(yaw) > SIDE_YAW_MINIMUM)) return "pose_mismatch";
    if (challenge === "left") leftYaw = yaw;
    else rightYaw = yaw;
  }
  if (leftYaw !== null && rightYaw !== null && Math.sign(leftYaw) === Math.sign(rightYaw)) {
    return "pose_mismatch";
  }
  return null;
}
