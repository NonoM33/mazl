import { describe, expect, test, beforeAll, afterAll } from "bun:test";
import { createHmac } from "node:crypto";
import { resetKeyCacheForTests } from "../../src/shared/crypto/keys";
import { fuzzCoordinates } from "../../src/features/media/domain/geo-fuzz";
import { createLocationService } from "../../src/features/media/application/location-service";
import type { LocationUpdateLog } from "../../src/features/media/application/ports";

// CONTRAT.md §2.2: stored position = fuzz(exact) with the seed
// HMAC(MEDIA_SIGNING_KEY, "geo:<userId>"); at most 10 position changes per 24 h,
// extra ones ignored.

const KEY = Buffer.alloc(32, 3);

function fakeLog() {
  const calls: Array<{ userId: number; max: number; windowMs: number }> = [];
  let recorded = 0;
  let stored: { latitude: number; longitude: number } | null = null;
  const log: LocationUpdateLog = {
    async tryRecord(userId, max, windowMs) {
      calls.push({ userId, max, windowMs });
      if (recorded >= max) return false;
      recorded += 1;
      return true;
    },
    async currentPosition() { return stored; },
  };
  return { log, calls, setStored: (p: { latitude: number; longitude: number } | null) => { stored = p; } };
}

describe("location service", () => {
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

  test("stores the fuzzed position derived from HMAC(key, geo:<userId>), never the exact one", async () => {
    const f = fakeLog();
    const service = createLocationService(f.log);
    const exact = { latitude: 48.85837, longitude: 2.29448 };
    const seed = new Uint8Array(createHmac("sha256", KEY).update("geo:42").digest());

    const stored = await service.resolve(42, exact.latitude, exact.longitude);

    expect(stored).toEqual(fuzzCoordinates(exact, seed));
    expect(stored).not.toEqual(exact);
  });

  test("quota: 10 changes in 24 h are accepted, the 11th is ignored", async () => {
    const f = fakeLog();
    const service = createLocationService(f.log);
    for (let i = 0; i < 10; i++) {
      expect(await service.resolve(1, 40 + i * 0.1, 3)).not.toBeNull();
    }
    expect(await service.resolve(1, 45, 3)).toBeNull();
    expect(f.calls.every((c) => c.max === 10 && c.windowMs === 24 * 3600 * 1000)).toBe(true);
  });

  test("re-saving the same position does not consume the quota", async () => {
    const f = fakeLog();
    const service = createLocationService(f.log);
    const first = await service.resolve(1, 48.85, 2.35);
    expect(first).not.toBeNull();
    f.setStored(first);
    const callsBefore = f.calls.length;
    for (let i = 0; i < 20; i++) {
      expect(await service.resolve(1, 48.85, 2.35)).toEqual(first);
    }
    expect(f.calls.length).toBe(callsBefore);
  });

  test("a position needs both coordinates, otherwise it is ignored", async () => {
    const f = fakeLog();
    const service = createLocationService(f.log);
    expect(await service.resolve(1, 48.85, undefined)).toBeNull();
    expect(await service.resolve(1, undefined, 2.35)).toBeNull();
    expect(await service.resolve(1, undefined, undefined)).toBeNull();
    expect(f.calls).toHaveLength(0);
  });
});
