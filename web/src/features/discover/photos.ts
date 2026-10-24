import type { ProfileCard } from "../../shared/api/types";

export function cardPhotos(profile: ProfileCard): readonly string[] {
  if (profile.photos.length > 0) return profile.photos;
  return profile.picture ? [profile.picture] : [];
}

// Next or previous photo; `wrap` loops (Space key), otherwise it stops at the ends.
export function stepPhoto(index: number, count: number, delta: 1 | -1, wrap: boolean): number {
  if (count <= 1) return 0;
  const next = index + delta;
  if (wrap) return (next + count) % count;
  return Math.min(count - 1, Math.max(0, next));
}
