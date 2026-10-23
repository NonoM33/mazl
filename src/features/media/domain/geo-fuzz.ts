// Location fuzzing, CONTRAT.md §2.2: snap to a ~1 km grid, then add a fixed
// per-user offset of at most 1 km. The offset comes from a per-user secret
// seed (HMAC) supplied by the caller, so this module stays pure.

export interface Coordinates {
  readonly latitude: number;
  readonly longitude: number;
}

export const GRID_KM = 1;
export const MAX_OFFSET_KM = 1;
export const MIN_DISTANCE_MAX_KM = 5;

const KM_PER_DEGREE = 111.195;
const MIN_COS_LATITUDE = 0.01;

function toRadians(degrees: number): number {
  return (degrees * Math.PI) / 180;
}

function lonDegreesPerKm(latitude: number): number {
  const cos = Math.max(Math.cos(toRadians(latitude)), MIN_COS_LATITUDE);
  return 1 / (KM_PER_DEGREE * cos);
}

function snapToGrid(point: Coordinates): Coordinates {
  const latStep = GRID_KM / KM_PER_DEGREE;
  const latitude = Math.round(point.latitude / latStep) * latStep;
  const lonStep = GRID_KM * lonDegreesPerKm(latitude);
  return { latitude, longitude: Math.round(point.longitude / lonStep) * lonStep };
}

function readUnit(seed: Uint8Array, offset: number): number {
  const view = new DataView(seed.buffer, seed.byteOffset, seed.byteLength);
  return view.getUint32(offset, false) / 2 ** 32;
}

// Uniform point in a disc of radius MAX_OFFSET_KM.
function offsetKm(seed: Uint8Array): { northKm: number; eastKm: number } {
  const angle = 2 * Math.PI * readUnit(seed, 0);
  const radius = MAX_OFFSET_KM * Math.sqrt(readUnit(seed, 4));
  return { northKm: radius * Math.cos(angle), eastKm: radius * Math.sin(angle) };
}

function wrapLongitude(longitude: number): number {
  if (longitude > 180) return longitude - 360;
  if (longitude < -180) return longitude + 360;
  return longitude;
}

function round6(value: number): number {
  return Math.round(value * 1e6) / 1e6;
}

export function fuzzCoordinates(exact: Coordinates, seed: Uint8Array): Coordinates {
  const snapped = snapToGrid(exact);
  const { northKm, eastKm } = offsetKm(seed);
  const latitude = Math.max(-90, Math.min(90, snapped.latitude + northKm / KM_PER_DEGREE));
  const longitude = wrapLongitude(snapped.longitude + eastKm * lonDegreesPerKm(latitude));
  return { latitude: round6(latitude), longitude: round6(longitude) };
}

export function clampDistanceMax(requestedKm: number): number {
  return Math.max(MIN_DISTANCE_MAX_KM, requestedKm);
}
