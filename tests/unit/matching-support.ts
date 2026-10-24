import type { MatchProfile, ViewerContext } from "../../src/features/matching/domain/profile";

export const NOW = "2026-06-15T12:00:00.000Z";

export const baseProfile: MatchProfile = {
  userId: 1,
  gender: "male",
  lookingFor: "female",
  age: 30,
  ageMin: 25,
  ageMax: 35,
  distanceMaxKm: 50,
  location: { latitude: 48.8566, longitude: 2.3522 },
  denomination: "Massorti",
  kashrut: "Strict",
  shabbat: "Partiellement",
  intention: "Serious",
  photoCount: 4,
  hasBio: true,
  promptCount: 3,
  verification: "identity",
  lastActiveAt: NOW,
  createdAt: "2025-01-01T00:00:00.000Z",
  boostedUntil: null,
  likesReceived7d: 0,
  openReports90d: 0,
};

export function profile(overrides: Partial<MatchProfile> = {}): MatchProfile {
  return { ...baseProfile, ...overrides };
}

export function context(excluded: readonly number[] = [], now: string = NOW): ViewerContext {
  return { now, excluded: new Set(excluded) };
}

// Independent reference haversine, written from the formula (R = 6371 km).
export function referenceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const rad = Math.PI / 180;
  const dLat = (lat2 - lat1) * rad;
  const dLon = (lon2 - lon1) * rad;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * Math.sin(dLon / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.min(1, Math.sqrt(h)));
}
