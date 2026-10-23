import type { DetectedFace } from "./types";

// A second detection only counts as "another person in the frame" when it is
// a real face: at least this fraction of the largest face's area. Smaller
// detections are spurious (measured on a real portrait: a hand scored 0.83
// at 12 % of the area) or people far behind the subject.
export const SECOND_FACE_MIN_AREA_RATIO = 0.25;

export type SubjectSelection =
  | { readonly status: "no_face" }
  | { readonly status: "multiple_faces" }
  | { readonly status: "single_face"; readonly face: DetectedFace };

const area = (f: DetectedFace): number => f.box.width * f.box.height;

export function selectSubjectFace(faces: readonly DetectedFace[]): SubjectSelection {
  const largest = faces.reduce<DetectedFace | null>((best, f) => (best === null || area(f) > area(best) ? f : best), null);
  if (!largest) return { status: "no_face" };
  const threshold = area(largest) * SECOND_FACE_MIN_AREA_RATIO;
  const significant = faces.filter((f) => f !== largest && area(f) >= threshold);
  if (significant.length > 0) return { status: "multiple_faces" };
  return { status: "single_face", face: largest };
}
