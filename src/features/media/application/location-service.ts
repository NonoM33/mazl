import { hmacBase64Url } from "../../../shared/crypto/signer";
import { fuzzCoordinates, type Coordinates } from "../domain/geo-fuzz";
import type { LocationUpdateLog } from "./ports";

export const MAX_LOCATION_CHANGES = 10;
export const LOCATION_WINDOW_MS = 24 * 60 * 60 * 1000;
const SAME_POSITION_EPSILON = 1e-6;

export interface LocationService {
  // The position to store for this write, or null to leave the stored one
  // untouched (no coordinates supplied, or the daily quota is used up).
  resolve(userId: number, latitude: number | undefined, longitude: number | undefined): Promise<Coordinates | null>;
}

function seedFor(userId: number): Uint8Array {
  return new Uint8Array(Buffer.from(hmacBase64Url("MEDIA_SIGNING_KEY", `geo:${userId}`), "base64url"));
}

function samePosition(a: Coordinates, b: Coordinates): boolean {
  return (
    Math.abs(a.latitude - b.latitude) < SAME_POSITION_EPSILON &&
    Math.abs(a.longitude - b.longitude) < SAME_POSITION_EPSILON
  );
}

export function createLocationService(log: LocationUpdateLog): LocationService {
  return {
    async resolve(userId, latitude, longitude) {
      if (latitude === undefined || longitude === undefined) return null;
      const fuzzed = fuzzCoordinates({ latitude, longitude }, seedFor(userId));
      const current = await log.currentPosition(userId);
      // The app re-sends the whole profile on every save: only a real move counts.
      if (current !== null && samePosition(current, fuzzed)) return fuzzed;
      const allowed = await log.tryRecord(userId, MAX_LOCATION_CHANGES, LOCATION_WINDOW_MS);
      return allowed ? fuzzed : null;
    },
  };
}
