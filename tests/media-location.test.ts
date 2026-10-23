import { beforeAll, describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, json, makeUser, type TestUser } from "./media-helpers";

// Integration tests of CONTRAT.md §2.2 (location privacy). Needs a running server.

function distanceKm(a: [number, number], b: [number, number]): number {
  const rad = (d: number): number => (d * Math.PI) / 180;
  const dLat = rad(b[0] - a[0]);
  const dLon = rad(b[1] - a[1]);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a[0])) * Math.cos(rad(b[0])) * Math.sin(dLon / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.sqrt(h));
}

interface ProfileBody { success: boolean; profile: { latitude: string | null; longitude: string | null; distance_max: number; bio: string | null } }

async function putProfile(user: TestUser, body: Record<string, unknown>): Promise<ProfileBody> {
  const res = await fetch(`${BASE_URL}/api/profile`, { method: "PUT", headers: json(user.token), body: JSON.stringify(body) });
  expect(res.status).toBe(200);
  return (await res.json()) as ProfileBody;
}

async function storedPosition(user: TestUser): Promise<[number, number]> {
  const [row] = await db<{ latitude: string; longitude: string }[]>`SELECT latitude, longitude FROM profiles WHERE user_id = ${user.id}`;
  return [Number(row?.latitude), Number(row?.longitude)];
}

const EXACT: [number, number] = [48.85837, 2.29448];

describe("location is fuzzed before storage", () => {
  let user: TestUser;
  beforeAll(async () => { user = await makeUser("loc"); });

  test("the exact coordinates are never stored, the stored ones stay within ~1.7 km", async () => {
    await putProfile(user, { displayName: "Loc", latitude: EXACT[0], longitude: EXACT[1] });
    const stored = await storedPosition(user);
    expect(stored).not.toEqual(EXACT);
    const km = distanceKm(EXACT, stored);
    expect(km).toBeGreaterThan(0);
    expect(km).toBeLessThanOrEqual(1.8); // 0.71 km grid snap + 1 km offset
  });

  test("the offset is fixed per user: saving the same spot again stores the same point", async () => {
    const first = await storedPosition(user);
    await putProfile(user, { latitude: EXACT[0], longitude: EXACT[1] });
    expect(await storedPosition(user)).toEqual(first);
  });

  test("two users at the same spot do not get the same stored point", async () => {
    const other = await makeUser("loc2");
    await putProfile(other, { displayName: "Loc2", latitude: EXACT[0], longitude: EXACT[1] });
    expect(await storedPosition(other)).not.toEqual(await storedPosition(user));
  });

  test("a profile update without coordinates leaves the stored position alone", async () => {
    const before = await storedPosition(user);
    const body = await putProfile(user, { bio: "no coordinates here" });
    expect(body.profile.bio).toBe("no coordinates here");
    expect(await storedPosition(user)).toEqual(before);
  });

  test("a lone latitude is ignored", async () => {
    const before = await storedPosition(user);
    await putProfile(user, { latitude: 10 });
    expect(await storedPosition(user)).toEqual(before);
  });

  test("out-of-range coordinates are rejected", async () => {
    const res = await fetch(`${BASE_URL}/api/profile`, { method: "PUT", headers: json(user.token), body: JSON.stringify({ latitude: 123, longitude: 2 }) });
    expect(res.status).toBe(400);
  });
});

describe("distance_max floor", () => {
  test("values under 5 km are raised to 5, larger ones are kept", async () => {
    const user = await makeUser("dist");
    expect((await putProfile(user, { displayName: "D", distanceMax: 1 })).profile.distance_max).toBe(5);
    expect((await putProfile(user, { distanceMax: 4 })).profile.distance_max).toBe(5);
    expect((await putProfile(user, { distanceMax: 50 })).profile.distance_max).toBe(50);
    expect((await putProfile(user, { distanceMax: 5 })).profile.distance_max).toBe(5);
  });
});

describe("10 location changes per 24 hours", () => {
  test("the 11th change is ignored, the rest of the profile is still saved", async () => {
    const user = await makeUser("quota");
    const spots: Array<[number, number]> = [];
    for (let i = 0; i < 12; i++) spots.push([10 + i * 2, 20 + i * 3]); // far apart: each one is a real move

    const stored: Array<[number, number]> = [];
    for (let i = 0; i < 10; i++) {
      await putProfile(user, { displayName: "Q", latitude: spots[i]![0], longitude: spots[i]![1] });
      stored.push(await storedPosition(user));
    }
    expect(new Set(stored.map((s) => s.join(","))).size).toBe(10);

    const eleventh = await putProfile(user, { latitude: spots[10]![0], longitude: spots[10]![1], bio: "still saved" });
    expect(eleventh.profile.bio).toBe("still saved");
    expect(await storedPosition(user)).toEqual(stored[9]!);

    await putProfile(user, { latitude: spots[11]![0], longitude: spots[11]![1] });
    expect(await storedPosition(user)).toEqual(stored[9]!);
  });

  test("the quota is per user, and re-saving the same place does not use it up", async () => {
    const user = await makeUser("quota2");
    for (let i = 0; i < 25; i++) await putProfile(user, { latitude: 45.5, longitude: 5.5 });
    const [row] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM location_updates WHERE user_id = ${user.id}`;
    expect(Number(row?.n)).toBe(1);

    const fresh = await makeUser("quota3");
    await putProfile(fresh, { latitude: 1, longitude: 1 });
    const [freshRow] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM location_updates WHERE user_id = ${fresh.id}`;
    expect(Number(freshRow?.n)).toBe(1);
  });

  test("changes older than 24 hours no longer count", async () => {
    const user = await makeUser("quota4");
    for (let i = 0; i < 10; i++) await putProfile(user, { latitude: 10 + i, longitude: 30 + i });
    const before = await storedPosition(user);
    await putProfile(user, { latitude: 60, longitude: 60 });
    expect(await storedPosition(user)).toEqual(before); // blocked

    await db`UPDATE location_updates SET created_at = NOW() - INTERVAL '25 hours' WHERE user_id = ${user.id}`;
    await putProfile(user, { latitude: 60, longitude: 60 });
    expect(await storedPosition(user)).not.toEqual(before);
  });
});

describe("no response leaks another member's coordinates", () => {
  test("profile, discover and daily picks never contain latitude/longitude of others", async () => {
    const target = await makeUser("leak");
    await putProfile(target, { displayName: "Leak", latitude: EXACT[0], longitude: EXACT[1] });
    await db`UPDATE profiles SET is_complete = true WHERE user_id = ${target.id}`;
    const viewer = await makeUser("leakviewer");

    const profile = await fetch(`${BASE_URL}/api/profile/${target.id}`, { headers: auth(viewer.token) });
    const profileText = await profile.text();
    expect(profileText).not.toMatch(/latitude|longitude/i);
    for (const path of ["/api/discover?limit=100", "/api/daily-picks"]) {
      const text = await (await fetch(`${BASE_URL}${path}`, { headers: auth(viewer.token) })).text();
      expect(text).not.toMatch(/latitude|longitude/i);
    }
  });
});
