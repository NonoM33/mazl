import { describe, expect, test } from "bun:test";
import { createPostgresLocationBackfill } from "../src/features/media/infra/postgres-location-backfill";
import { fuzzStoredLocations } from "../src/features/media/application/location-backfill";
import { BASE_URL, db, json, makeUser } from "./media-helpers";

// Positions stored before the socle were exact. At boot they are fuzzed once,
// flagged with profiles.location_fuzzed, and never touched again.

function distanceKm(a: [number, number], b: [number, number]): number {
  const rad = (d: number): number => (d * Math.PI) / 180;
  const h = Math.sin(rad(b[0] - a[0]) / 2) ** 2 + Math.cos(rad(a[0])) * Math.cos(rad(b[0])) * Math.sin(rad(b[1] - a[1]) / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.sqrt(h));
}

async function row(userId: number) {
  const [r] = await db<{ latitude: string | null; longitude: string | null; location_fuzzed: boolean }[]>`
    SELECT latitude, longitude, location_fuzzed FROM profiles WHERE user_id = ${userId}`;
  return { position: [Number(r?.latitude), Number(r?.longitude)] as [number, number], fuzzed: r?.location_fuzzed };
}

const backfill = () => fuzzStoredLocations(createPostgresLocationBackfill(db));
const EXACT: [number, number] = [43.2965, 5.3698];

describe("location_fuzzed and the boot backfill", () => {
  test("a write through the API flags the profile as fuzzed", async () => {
    const user = await makeUser("flag");
    expect((await row(user.id)).fuzzed).toBe(false);
    await fetch(`${BASE_URL}/api/profile`, { method: "PUT", headers: json(user.token), body: JSON.stringify({ displayName: "F", latitude: EXACT[0], longitude: EXACT[1] }) });
    const after = await row(user.id);
    expect(after.fuzzed).toBe(true);
    expect(after.position).not.toEqual(EXACT);
  });

  test("an update without coordinates does not flag a legacy exact position", async () => {
    const user = await makeUser("legacyflag");
    await db`UPDATE profiles SET latitude = ${EXACT[0]}, longitude = ${EXACT[1]} WHERE user_id = ${user.id}`;
    await fetch(`${BASE_URL}/api/profile`, { method: "PUT", headers: json(user.token), body: JSON.stringify({ bio: "no coords" }) });
    expect(await row(user.id)).toEqual({ position: EXACT, fuzzed: false });
  });

  test("an exact legacy point is fuzzed once; a second boot does not move it", async () => {
    const user = await makeUser("legacy");
    await db`UPDATE profiles SET latitude = ${EXACT[0]}, longitude = ${EXACT[1]} WHERE user_id = ${user.id}`;

    await backfill();
    const first = await row(user.id);
    expect(first.fuzzed).toBe(true);
    expect(first.position).not.toEqual(EXACT);
    expect(distanceKm(EXACT, first.position)).toBeLessThanOrEqual(1.8);

    await backfill();
    expect(await row(user.id)).toEqual(first);
  });

  test("a point fuzzed by the API is not moved by the boot task", async () => {
    const user = await makeUser("apifuzzed");
    await fetch(`${BASE_URL}/api/profile`, { method: "PUT", headers: json(user.token), body: JSON.stringify({ displayName: "A", latitude: EXACT[0], longitude: EXACT[1] }) });
    const stored = await row(user.id);
    await backfill();
    expect(await row(user.id)).toEqual(stored);
  });

  test("profiles without coordinates stay untouched", async () => {
    const user = await makeUser("nocoords");
    await backfill();
    const r = await row(user.id);
    expect(Number.isNaN(r.position[0]) || r.position[0] === 0).toBe(true);
    expect(r.fuzzed).toBe(false);
  });
});
