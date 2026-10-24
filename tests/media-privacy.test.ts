import { beforeAll, describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, json, jpegWithGps, makeUser, uploadOk, type TestUser } from "./media-helpers";

// No response about ANOTHER member may carry identity or precise-location
// fields: email, legal name, exact birthdate, provider id, coordinates.
// (age and display_name are fine.) Only the caller's own profile may show
// email and name.

const FORBIDDEN_KEYS = new Set(["email", "name", "birthdate", "provider", "provider_id", "latitude", "longitude", "password"]);

function forbiddenKeysIn(value: unknown, path = "$"): string[] {
  if (Array.isArray(value)) return value.flatMap((v, i) => forbiddenKeysIn(v, `${path}[${i}]`));
  if (value === null || typeof value !== "object") return [];
  return Object.entries(value as Record<string, unknown>).flatMap(([key, v]) => [
    ...(FORBIDDEN_KEYS.has(key) ? [`${path}.${key}`] : []),
    ...forbiddenKeysIn(v, `${path}.${key}`),
  ]);
}

const signed = /\/media\/photos\/\d+\?exp=\d+&sig=[A-Za-z0-9_-]{43}/;

describe("no identity or location fields about other members", () => {
  let alice: TestUser;
  let bob: TestUser;
  let carol: TestUser;
  let dave: TestUser;

  beforeAll(async () => {
    [alice, bob, carol, dave] = await Promise.all([makeUser("pa"), makeUser("pb"), makeUser("pc"), makeUser("pd")]);
    for (const [user, name] of [[alice, "Alice"], [bob, "Bob"], [carol, "Carol"], [dave, "Dave"]] as const) {
      await fetch(`${BASE_URL}/api/profile`, {
        method: "PUT",
        headers: json(user.token),
        body: JSON.stringify({ displayName: name, birthdate: "1994-03-12", gender: "female", lookingFor: "female", latitude: 48.85, longitude: 2.35, location: "Paris" }),
      });
      await uploadOk(user.token, await jpegWithGps(60, 60, 1), true);
    }
    await db`UPDATE profiles SET is_complete = true WHERE user_id IN (${alice.id}, ${bob.id}, ${carol.id}, ${dave.id})`;
    await db`UPDATE users SET picture = 'https://lh3.googleusercontent.com/a/ZZZ' WHERE id = ${dave.id}`;
    const swipe = (t: string, target: number) =>
      fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: json(t), body: JSON.stringify({ target_user_id: target, action: "like" }) });
    await swipe(alice.token, bob.id); // match alice <-> bob
    await swipe(bob.token, alice.id);
    await swipe(carol.token, bob.id); // carol's like is received by bob
    await fetch(`${BASE_URL}/api/users/${dave.id}/block`, { method: "POST", headers: auth(bob.token) });
  });

  test("GET /api/profile/:userId of another member", async () => {
    const res = await fetch(`${BASE_URL}/api/profile/${alice.id}`, { headers: auth(bob.token) });
    const body = (await res.json()) as { profile: Record<string, unknown> };
    expect(forbiddenKeysIn(body)).toEqual([]);
    expect(body.profile.display_name).toBe("Alice");
    expect(typeof body.profile.age).toBe("number");
  });

  test("the caller's own profile still carries email and name", async () => {
    const res = await fetch(`${BASE_URL}/api/profile/${alice.id}`, { headers: auth(alice.token) });
    const { profile } = (await res.json()) as { profile: { email?: string; name?: string } };
    expect(profile.email).toContain("@");
    expect(profile.name).toBe("Media pa");
  });

  const lists: Array<[string, string]> = [
    ["discover", "/api/discover?limit=100"],
    ["daily picks", "/api/daily-picks"],
    ["likes received", "/api/likes/received"],
    ["matches", "/api/matches"],
    ["conversations", "/api/conversations"],
    ["blocked users", "/api/users/blocked"],
  ];
  for (const [label, path] of lists) {
    test(`${label} exposes none of them`, async () => {
      const viewer = label === "discover" || label === "daily picks" ? carol : bob;
      const res = await fetch(`${BASE_URL}${path}`, { headers: auth(viewer.token) });
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(JSON.stringify(body).length).toBeGreaterThan(40);
      expect(forbiddenKeysIn(body)).toEqual([]);
    });
  }

  test("blocked users list still shows who was blocked, with a Google avatar fallback", async () => {
    const res = await fetch(`${BASE_URL}/api/users/blocked`, { headers: auth(bob.token) });
    const { blocked } = (await res.json()) as { blocked: Array<{ user_id: number; picture: string | null }> };
    expect(blocked.find((b) => b.user_id === dave.id)?.picture).toMatch(signed);
  });
});

describe("couple screens show the partner's signed photo", () => {
  test("partner_picture and request pictures: primary photo first, Google avatar as fallback", async () => {
    const [x, y, z] = await Promise.all([makeUser("cx"), makeUser("cy"), makeUser("cz")]);
    await uploadOk(x.token, await jpegWithGps(60, 60, 1), true);
    await db`UPDATE users SET picture = 'https://lh3.googleusercontent.com/a/YYY' WHERE id = ${y.id}`;
    await db`UPDATE users SET picture = 'https://i.pravatar.cc/400?img=4' WHERE id = ${z.id}`;

    // A couple request needs a mutual match (contract §0.2): x matches y and z first.
    const like = (from: TestUser, to: TestUser) =>
      fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: json(from.token), body: JSON.stringify({ target_user_id: to.id, action: "like" }) });
    for (const other of [y, z]) {
      await like(x, other);
      await like(other, x);
    }

    // x asks y and z: y sees x's signed photo, x sees y's Google avatar, z has nothing displayable.
    const ask = (from: TestUser, to: TestUser) =>
      fetch(`${BASE_URL}/api/couple/request`, { method: "POST", headers: json(from.token), body: JSON.stringify({ target_user_id: to.id }) });
    const sent = (await (await ask(x, y)).json()) as { request: { id: number } };
    await ask(x, z);

    const forY = (await (await fetch(`${BASE_URL}/api/couple/requests`, { headers: auth(y.token) })).json()) as {
      received: Array<{ requester_picture: string | null }>;
    };
    expect(forY.received[0]?.requester_picture).toMatch(signed);

    const forX = (await (await fetch(`${BASE_URL}/api/couple/requests`, { headers: auth(x.token) })).json()) as {
      sent: Array<{ target_id: number; target_picture: string | null }>;
    };
    expect(forX.sent.find((r) => r.target_id === y.id)?.target_picture).toBe("https://lh3.googleusercontent.com/a/YYY");
    expect(forX.sent.find((r) => r.target_id === z.id)?.target_picture).toBeNull();

    await fetch(`${BASE_URL}/api/couple/request/${sent.request.id}`, { method: "PUT", headers: json(y.token), body: JSON.stringify({ action: "accept" }) });
    const couple = (await (await fetch(`${BASE_URL}/api/couple`, { headers: auth(y.token) })).json()) as {
      couple: { partner_picture: string | null };
    };
    expect(couple.couple.partner_picture).toMatch(signed);
    const forPartnerX = (await (await fetch(`${BASE_URL}/api/couple`, { headers: auth(x.token) })).json()) as {
      couple: { partner_picture: string | null };
    };
    expect(forPartnerX.couple.partner_picture).toBe("https://lh3.googleusercontent.com/a/YYY");
  });
});

describe("websocket match event", () => {
  test("match:new carries the other member's signed photo and no private field", async () => {
    const [a, b] = await Promise.all([makeUser("wa"), makeUser("wb")]);
    await uploadOk(a.token, await jpegWithGps(60, 60, 1), true);
    await db`UPDATE users SET picture = 'https://i.pravatar.cc/400?img=8' WHERE id IN (${a.id}, ${b.id})`;
    const wsUrl = (process.env.TEST_WS_URL ?? BASE_URL.replace(/^http/, "ws") + "/ws") + `?token=${b.token}`;
    const ws = new WebSocket(wsUrl);
    await new Promise<void>((res, rej) => { ws.onopen = () => res(); ws.onerror = () => rej(new Error("ws error")); });
    const event = new Promise<Record<string, unknown> | null>((resolve) => {
      const timer = setTimeout(() => resolve(null), 4000);
      ws.onmessage = (e) => {
        const m = JSON.parse(String(e.data)) as { type?: string; payload?: Record<string, unknown> };
        if (m.type === "match:new") { clearTimeout(timer); resolve(m.payload ?? null); }
      };
    });
    const swipe = (t: string, target: number) =>
      fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: json(t), body: JSON.stringify({ target_user_id: target, action: "like" }) });
    await swipe(a.token, b.id);
    await swipe(b.token, a.id);
    const payload = await event;
    ws.close();
    expect(payload).not.toBeNull();
    expect(payload?.userId).toBe(a.id);
    expect(String(payload?.userPicture)).toMatch(signed);
    expect(forbiddenKeysIn(payload)).toEqual([]);
  });
});
