import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { createHmac } from "node:crypto";
import { resetKeyCacheForTests } from "../../src/shared/crypto/keys";
import { fuzzCoordinates } from "../../src/features/media/domain/geo-fuzz";
import { fuzzStoredLocations } from "../../src/features/media/application/location-backfill";
import type { LocationBackfillRepository } from "../../src/features/media/application/ports";

// Boot task: every stored position that was never fuzzed (location_fuzzed =
// false) is replaced once by fuzz(exact, HMAC(key, "geo:<userId>")) and flagged.

const KEY = Buffer.alloc(32, 5);
type Row = { userId: number; latitude: number; longitude: number; fuzzed: boolean };

function fakeRepository(rows: Row[], pageSize?: { seen: number[] }): LocationBackfillRepository {
  return {
    async listUnfuzzed(limit) {
      const page = rows.filter((r) => !r.fuzzed).slice(0, limit);
      pageSize?.seen.push(page.length);
      return page.map(({ userId, latitude, longitude }) => ({ userId, latitude, longitude }));
    },
    async markFuzzed(userId, coords) {
      const row = rows.find((r) => r.userId === userId);
      if (!row || row.fuzzed) return false;
      row.latitude = coords.latitude;
      row.longitude = coords.longitude;
      row.fuzzed = true;
      return true;
    },
  };
}

describe("fuzzing of positions stored before the socle", () => {
  const previous = process.env.MEDIA_SIGNING_KEY;
  beforeAll(() => {
    process.env.MEDIA_SIGNING_KEY = KEY.toString("base64");
    resetKeyCacheForTests();
  });
  afterAll(() => {
    if (previous === undefined) delete process.env.MEDIA_SIGNING_KEY;
    else process.env.MEDIA_SIGNING_KEY = previous;
    resetKeyCacheForTests();
  });

  test("each exact position is replaced by its per-user fuzzed point and flagged", async () => {
    const rows: Row[] = [
      { userId: 1, latitude: 48.85837, longitude: 2.29448, fuzzed: false },
      { userId: 2, latitude: 40.6892, longitude: -74.0445, fuzzed: false },
    ];
    const count = await fuzzStoredLocations(fakeRepository(rows));
    expect(count).toBe(2);
    for (const [index, exact] of [[0, { latitude: 48.85837, longitude: 2.29448 }], [1, { latitude: 40.6892, longitude: -74.0445 }]] as const) {
      const userId = index + 1;
      const seed = new Uint8Array(createHmac("sha256", KEY).update(`geo:${userId}`).digest());
      expect(rows[index]).toEqual({ userId, ...fuzzCoordinates(exact, seed), fuzzed: true });
    }
  });

  test("running again moves nothing (a second boot)", async () => {
    const rows: Row[] = [{ userId: 7, latitude: 48.1, longitude: 11.5, fuzzed: false }];
    const repo = fakeRepository(rows);
    await fuzzStoredLocations(repo);
    const afterFirstBoot = { ...rows[0]! };
    expect(await fuzzStoredLocations(repo)).toBe(0);
    expect(rows[0]).toEqual(afterFirstBoot);
  });

  test("an already fuzzed point is left alone", async () => {
    const rows: Row[] = [{ userId: 3, latitude: 10.5, longitude: 20.5, fuzzed: true }];
    expect(await fuzzStoredLocations(fakeRepository(rows))).toBe(0);
    expect(rows[0]).toMatchObject({ latitude: 10.5, longitude: 20.5 });
  });

  test("works through many rows page after page", async () => {
    const rows: Row[] = Array.from({ length: 1234 }, (_, i) => ({ userId: i + 1, latitude: 30 + (i % 50) * 0.1, longitude: 5 + (i % 70) * 0.1, fuzzed: false }));
    const seen = { seen: [] as number[] };
    expect(await fuzzStoredLocations(fakeRepository(rows, seen))).toBe(1234);
    expect(rows.every((r) => r.fuzzed)).toBe(true);
    expect(seen.seen.length).toBeGreaterThan(1);
  });

  test("stops instead of looping when the repository makes no progress", async () => {
    const stuck: LocationBackfillRepository = {
      async listUnfuzzed() { return [{ userId: 1, latitude: 1, longitude: 1 }]; },
      async markFuzzed() { return false; },
    };
    expect(await fuzzStoredLocations(stuck)).toBe(0);
  });
});
