// Pagination parameters of the admin list routes.
// limit: integer in 1..100 (default 50). offset: integer in 0..2^31-1 (default 0).
// Garbage never reaches SQL: a non-integer falls back to the default, an
// out-of-range integer is clamped. A `LIMIT NaN` used to make Postgres throw (500).

const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 100;
const MAX_OFFSET = 2_147_483_647;

export interface Pagination {
  limit: number;
  offset: number;
}

function readInteger(raw: string | undefined): number | null {
  if (raw === undefined || !/^-?\d+$/.test(raw.trim())) return null;
  return Number(raw.trim());
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

// A record id from the URL path: a positive integer that fits a Postgres integer,
// otherwise null (the route answers 404 instead of letting `NaN` reach SQL).
export function parseRecordId(raw: string | undefined): number | null {
  if (raw === undefined || !/^\d+$/.test(raw)) return null;
  const id = Number(raw);
  return id >= 1 && id <= MAX_OFFSET ? id : null;
}

export function parsePagination(rawLimit: string | undefined, rawOffset: string | undefined): Pagination {
  const limit = readInteger(rawLimit);
  const offset = readInteger(rawOffset);
  return {
    limit: limit === null ? DEFAULT_LIMIT : clamp(limit, 1, MAX_LIMIT),
    offset: offset === null ? 0 : clamp(offset, 0, MAX_OFFSET),
  };
}
