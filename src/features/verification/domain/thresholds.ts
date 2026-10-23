// SFace cosine threshold published by OpenCV Zoo for "same person".
export const DEFAULT_FACE_MATCH_THRESHOLD = 0.363;
// Cosine floor between the frames of one live session (CONTRAT.md §1).
export const DEFAULT_FACE_CONSISTENCY_THRESHOLD = 0.5;

export const SESSION_TTL_SECONDS = 120;
export const DAILY_SESSION_LIMIT = 3;

export interface FaceThresholds {
  readonly match: number;
  readonly consistency: number;
}
