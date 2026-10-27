import { describe, expect, test } from "bun:test";
import sharp from "sharp";
import { BASE_URL, auth, db, grantPlus, jpegWithGps, json, makeUser, readyToDiscover, uploadOk, type TestUser } from "./media-helpers";
import { makeMatch, send } from "./chat-helpers";

// Integration of docs/premium/MONETISATION.md against a running server:
// the blurred likes, the passport, the discreet mode, the receipts, the word of
// a Super Like, the priority likes, the rewind, the programmed Boost.
// Needs TEST_API_URL and TEST_DATABASE_URL (run: bun scripts/test-integration.ts).

const swipe = (member: TestUser, target: number, action: "like" | "pass" | "super_like", extra: Record<string, unknown> = {}) =>
  fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: json(member.token), body: JSON.stringify({ target_user_id: target, action, ...extra }) });

const get = (member: TestUser, path: string) => fetch(`${BASE_URL}${path}`, { headers: auth(member.token) });
const put = (member: TestUser, path: string, body: unknown) => fetch(`${BASE_URL}${path}`, { method: "PUT", headers: json(member.token), body: JSON.stringify(body) });

interface Envelope<T> { success: boolean; data?: T; error?: string }
async function data(res: Response): Promise<Record<string, unknown>>;
async function data<T>(res: Response): Promise<T>;
async function data(res: Response): Promise<unknown> {
  const body = (await res.json()) as Envelope<unknown>;
  if (!body.success || body.data === undefined) throw new Error(`unexpected ${res.status}: ${JSON.stringify(body)}`);
  return body.data;
}

async function discoverIds(member: TestUser): Promise<number[]> {
  const res = await get(member, "/api/discover?limit=50");
  expect(res.status).toBe(200);
  const body = (await res.json()) as { profiles: Array<{ user_id: number }> };
  return body.profiles.map((profile) => profile.user_id);
}

async function discoverProfiles(member: TestUser): Promise<Array<Record<string, unknown> & { user_id: number }>> {
  const res = await get(member, "/api/discover?limit=50");
  return ((await res.json()) as { profiles: Array<Record<string, unknown> & { user_id: number }> }).profiles;
}

// A member ready to be proposed to male viewers who look for women.
const woman = async (label: string) => readyToDiscover(await makeUser(label), { gender: "female", lookingFor: "male" });
const man = async (label: string) => readyToDiscover(await makeUser(label), { gender: "male", lookingFor: "female" });

describe("section 1: blurred likes", () => {
  interface Received { count: number; is_premium: boolean; likes: Array<Record<string, unknown>> }
  const received = async (member: TestUser): Promise<{ text: string; body: Received }> => {
    const res = await get(member, "/api/likes/received");
    expect(res.status).toBe(200);
    const text = await res.text();
    return { text, body: JSON.parse(text) as Received };
  };

  test("a free member gets a 48 px blurred variant, never the sharp photo, an id or a picture", async () => {
    const liker = await makeUser("blur-liker");
    const liked = await makeUser("blur-liked");
    const photo = await uploadOk(liker.token, await jpegWithGps(900, 1200, 1), true);
    expect((await swipe(liker, liked.id, "like")).status).toBe(200);

    const { text, body } = await received(liked);
    expect(body.is_premium).toBe(false);
    expect(body.count).toBe(1);
    const [teaser] = body.likes;
    expect(Object.keys(teaser ?? {}).sort()).toEqual(["blurredPhotoUrl", "display_name", "is_super_like", "is_verified", "liked_at"]);

    // Security: nothing in the answer opens the photo or the profile.
    expect(text).not.toContain("user_id");
    expect(text).not.toContain('"picture"');
    expect(text).not.toContain('"age"');
    expect(text).not.toMatch(new RegExp(`/media/photos/${photo.id}\\?`));
    expect(text).toMatch(new RegExp(`/media/photos/${photo.id}/blur\\?exp=\\d+&sig=[\\w-]+`));

    const blurred = await fetch(String(teaser?.blurredPhotoUrl));
    expect([blurred.status, blurred.headers.get("content-type")]).toEqual([200, "image/jpeg"]);
    const bytes = new Uint8Array(await blurred.arrayBuffer());
    expect(bytes.byteLength).toBeLessThan(4000);
    const meta = await sharp(bytes).metadata();
    expect([meta.format, meta.width, meta.height]).toEqual(["jpeg", 48, 64]);
    expect(meta.exif).toBeUndefined();
  });

  test("the signature of the blurred variant opens nothing else", async () => {
    const liker = await makeUser("blur-sig-liker");
    const liked = await makeUser("blur-sig-liked");
    const photo = await uploadOk(liker.token, await jpegWithGps(300, 400, 1), true);
    await swipe(liker, liked.id, "like");
    const url = new URL(String(((await received(liked)).body.likes[0] ?? {}).blurredPhotoUrl));
    const query = url.search;

    // The same query on the sharp photo, on another photo, tampered, or missing.
    expect((await fetch(`${BASE_URL}/media/photos/${photo.id}${query}`)).status).toBe(404);
    expect((await fetch(`${BASE_URL}/media/photos/${photo.id + 1}/blur${query}`)).status).toBe(404);
    expect((await fetch(`${BASE_URL}/media/photos/${photo.id}/blur${query.slice(0, -2)}xx`)).status).toBe(404);
    expect((await fetch(`${BASE_URL}/media/photos/${photo.id}/blur`)).status).toBe(404);
    expect((await fetch(`${BASE_URL}/media/photos/${photo.id}/blur?exp=1&sig=abc`)).status).toBe(404);
    expect((await fetch(url.toString())).status).toBe(200);
  });

  test("a photo the member deletes is no longer served, blurred or not", async () => {
    const liker = await makeUser("blur-del-liker");
    const liked = await makeUser("blur-del-liked");
    const photo = await uploadOk(liker.token, await jpegWithGps(300, 400, 1), true);
    await swipe(liker, liked.id, "like");
    const url = String(((await received(liked)).body.likes[0] ?? {}).blurredPhotoUrl);
    expect((await fetch(url)).status).toBe(200);
    expect((await fetch(`${BASE_URL}/api/profile/photos/${photo.id}`, { method: "DELETE", headers: auth(liker.token) })).status).toBe(200);
    expect((await fetch(url)).status).toBe(404);
  });

  test("a liker with no photo of ours gives null: the app draws a gradient", async () => {
    const liker = await makeUser("blur-none-liker");
    const liked = await makeUser("blur-none-liked");
    await swipe(liker, liked.id, "like");
    expect(((await received(liked)).body.likes[0] ?? {}).blurredPhotoUrl).toBeNull();
  });

  test("with mazl+ the whole profile comes, without the blurred field, and a Super Like word is shown only then", async () => {
    const liker = await makeUser("blur-plus-liker");
    const liked = await makeUser("blur-plus-liked");
    await swipe(liker, liked.id, "super_like", { note: "Votre sourire au Shabbat" });

    const free = await received(liked);
    expect(free.text).not.toContain("Votre sourire");
    expect(free.body.likes[0]?.is_super_like).toBe(true);

    await grantPlus(liked.id);
    const plus = await received(liked);
    expect(plus.body.is_premium).toBe(true);
    expect(plus.body.likes[0]).toMatchObject({ user_id: liker.id, is_super_like: true, note: "Votre sourire au Shabbat" });
  });

  test("the count is the real number of likes", async () => {
    const liked = await makeUser("blur-count-liked");
    for (let i = 0; i < 3; i += 1) await swipe(await makeUser(`blur-count-${i}`), liked.id, "like");
    const { body } = await received(liked);
    expect([body.count, body.likes.length]).toEqual([3, 3]);
  });

  test("the blur route needs no session but a valid signature, like the photo", async () => {
    expect((await fetch(`${BASE_URL}/media/photos/abc/blur?exp=1&sig=x`)).status).toBe(404);
  });
});

describe("sections 2 and 3: passport and discreet mode", () => {
  const TEL_AVIV = { city: "Tel-Aviv", latitude: 32.0853, longitude: 34.7818 };

  test("every route needs a member", async () => {
    for (const [method, path] of [["GET", "/api/premium/settings"], ["PUT", "/api/discover/passport"], ["PUT", "/api/profile/incognito"], ["PUT", "/api/profile/read-receipts"], ["POST", "/api/swipes/undo"], ["GET", "/api/boost/best-time"], ["POST", "/api/boost/schedule"], ["DELETE", "/api/boost/schedule"]] as const) {
      const res = await fetch(`${BASE_URL}${path}`, { method, headers: { "Content-Type": "application/json" }, body: method === "GET" || method === "DELETE" ? null : "{}" });
      expect([method, path, res.status]).toEqual([method, path, 401]);
    }
  });

  test("402 mazl_plus_required without a subscription, for both", async () => {
    const free = await makeUser("pp-free");
    const passport = await put(free, "/api/discover/passport", TEL_AVIV);
    expect([passport.status, await passport.json()]).toEqual([402, { success: false, error: "mazl_plus_required" }]);
    const incognito = await put(free, "/api/profile/incognito", { enabled: true });
    expect([incognito.status, await incognito.json()]).toEqual([402, { success: false, error: "mazl_plus_required" }]);
    expect(await data(await get(free, "/api/premium/settings"))).toEqual({ is_plus: false, passport: null, incognito: false, send_read_receipts: true });
  });

  test("a passport moves the search, not the member: Tel-Aviv is found from Paris only with it", async () => {
    const viewer = await man("pp-viewer");
    const local = await woman("pp-paris");
    const faraway = await woman("pp-telaviv");
    await db`UPDATE profiles SET latitude = 48.8566, longitude = 2.3522, distance_max = 50 WHERE user_id = ${viewer.id}`;
    await db`UPDATE profiles SET latitude = 48.86, longitude = 2.35 WHERE user_id = ${local.id}`;
    await db`UPDATE profiles SET latitude = 32.0853, longitude = 34.7818 WHERE user_id = ${faraway.id}`;
    await grantPlus(viewer.id);

    const before = await discoverIds(viewer);
    expect(before).toContain(local.id);
    expect(before).not.toContain(faraway.id);

    expect((await put(viewer, "/api/discover/passport", TEL_AVIV)).status).toBe(200);
    expect(await data(await get(viewer, "/api/premium/settings"))).toMatchObject({ is_plus: true, passport: TEL_AVIV });
    const during = await discoverIds(viewer);
    expect(during).toContain(faraway.id);
    expect(during).not.toContain(local.id);
    // The member's own profile did not move.
    const [row] = await db<{ latitude: string }[]>`SELECT latitude FROM profiles WHERE user_id = ${viewer.id}`;
    expect(Number(row?.latitude)).toBeCloseTo(48.8566, 3);

    expect((await put(viewer, "/api/discover/passport", null)).status).toBe(200);
    expect(await discoverIds(viewer)).toContain(local.id);
  });

  test("the passport only counts while mazl+ is active", async () => {
    const viewer = await man("pp-lapse");
    const faraway = await woman("pp-lapse-telaviv");
    await db`UPDATE profiles SET latitude = 48.8566, longitude = 2.3522, distance_max = 50 WHERE user_id = ${viewer.id}`;
    await db`UPDATE profiles SET latitude = 32.0853, longitude = 34.7818 WHERE user_id = ${faraway.id}`;
    await grantPlus(viewer.id);
    await put(viewer, "/api/discover/passport", TEL_AVIV);
    expect(await discoverIds(viewer)).toContain(faraway.id);

    await db`UPDATE subscriptions SET expires_at = (NOW() AT TIME ZONE 'UTC') - INTERVAL '1 hour' WHERE user_id = ${viewer.id}`;
    expect(await discoverIds(viewer)).not.toContain(faraway.id);
    expect(await data(await get(viewer, "/api/premium/settings"))).toMatchObject({ is_plus: false, passport: null });
    // Coming home is allowed without mazl+.
    expect((await put(viewer, "/api/discover/passport", null)).status).toBe(200);
  });

  test("others read « De passage à X » on a member travelling with mazl+, not once it has ended", async () => {
    const traveller = await woman("pp-traveller");
    const viewer = await man("pp-watcher");
    await grantPlus(traveller.id);
    await put(traveller, "/api/discover/passport", TEL_AVIV);
    const travelling = (await discoverProfiles(viewer)).find((profile) => profile.user_id === traveller.id);
    expect(travelling?.traveling_city).toBe("Tel-Aviv");
    const stay = (await discoverProfiles(viewer)).filter((profile) => profile.user_id !== traveller.id);
    for (const profile of stay) expect(profile.traveling_city).toBeNull();

    await db`UPDATE subscriptions SET expires_at = (NOW() AT TIME ZONE 'UTC') - INTERVAL '1 hour' WHERE user_id = ${traveller.id}`;
    expect((await discoverProfiles(viewer)).find((profile) => profile.user_id === traveller.id)?.traveling_city).toBeNull();
  });

  test("the discreet mode hides a member from everybody they have not liked", async () => {
    const hidden = await woman("inc-hidden");
    const stranger = await man("inc-stranger");
    const liked = await man("inc-liked");
    await grantPlus(hidden.id);
    expect(await discoverIds(stranger)).toContain(hidden.id);

    expect(await data(await put(hidden, "/api/profile/incognito", { enabled: true }))).toEqual({ incognito: true });
    expect(await discoverIds(stranger)).not.toContain(hidden.id);
    expect(await discoverIds(liked)).not.toContain(hidden.id);

    // Once the member likes somebody, that somebody sees them.
    expect((await swipe(hidden, liked.id, "like")).status).toBe(200);
    expect(await discoverIds(liked)).toContain(hidden.id);
    expect(await discoverIds(stranger)).not.toContain(hidden.id);

    expect(await data(await put(hidden, "/api/profile/incognito", { enabled: false }))).toEqual({ incognito: false });
    expect(await discoverIds(stranger)).toContain(hidden.id);
  });

  test("the discreet mode of a lapsed subscription hides nobody", async () => {
    const hidden = await woman("inc-lapsed");
    const stranger = await man("inc-lapsed-viewer");
    await grantPlus(hidden.id);
    await put(hidden, "/api/profile/incognito", { enabled: true });
    expect(await discoverIds(stranger)).not.toContain(hidden.id);
    await db`UPDATE subscriptions SET expires_at = (NOW() AT TIME ZONE 'UTC') - INTERVAL '1 hour' WHERE user_id = ${hidden.id}`;
    expect(await discoverIds(stranger)).toContain(hidden.id);
  });

  test("validation: 400 invalid_body, never the text of a schema", async () => {
    const member = await makeUser("pp-validation");
    await grantPlus(member.id);
    for (const body of [{}, { city: "Paris" }, { city: "", latitude: 1, longitude: 1 }, { city: "Paris", latitude: 200, longitude: 0 }, "Paris"]) {
      const res = await put(member, "/api/discover/passport", body);
      expect([res.status, await res.json()]).toEqual([400, { success: false, error: "invalid_body" }]);
    }
    const res = await put(member, "/api/profile/incognito", { enabled: "yes" });
    expect([res.status, await res.json()]).toEqual([400, { success: false, error: "invalid_body" }]);
  });
});

describe("section 4: read receipts", () => {
  async function readAt(reader: TestUser, author: TestUser, conversationId: number): Promise<{ read_at: string | null; is_read: boolean } | undefined> {
    const res = await get(author, `/api/conversations/${conversationId}/messages`);
    const body = (await res.json()) as { messages: Array<{ sender_id: number; read_at: string | null; is_read: boolean }> };
    return body.messages.find((message) => message.sender_id === author.id) ?? undefined;
  }
  const markRead = (reader: TestUser, conversationId: number) =>
    fetch(`${BASE_URL}/api/conversations/${conversationId}/read`, { method: "PUT", headers: json(reader.token), body: "{}" });

  test("a free author never sees « read »; with mazl+ they do; the reader's switch ends it", async () => {
    const { a, b, conversationId } = await makeMatch("rr");
    expect((await send(a.token, conversationId, { content: "Shabbat shalom" })).status).toBe(200);
    expect((await markRead(b, conversationId)).status).toBe(200);

    expect(await readAt(b, a, conversationId)).toMatchObject({ read_at: null, is_read: false });

    await grantPlus(a.id);
    const seen = await readAt(b, a, conversationId);
    expect(seen?.is_read).toBe(true);
    expect(seen?.read_at).toMatch(/^\d{4}-\d{2}-\d{2}T/);

    expect(await data(await put(b, "/api/profile/read-receipts", { enabled: false }))).toEqual({ send_read_receipts: false });
    expect(await readAt(b, a, conversationId)).toMatchObject({ read_at: null, is_read: false });

    await put(b, "/api/profile/read-receipts", { enabled: true });
    expect((await readAt(b, a, conversationId))?.is_read).toBe(true);
  });

  test("the reader's own list is untouched and the switch needs no subscription", async () => {
    const { a, b, conversationId } = await makeMatch("rr2");
    await send(a.token, conversationId, { content: "Bonjour" });
    await markRead(b, conversationId);
    expect((await put(b, "/api/profile/read-receipts", { enabled: false })).status).toBe(200);
    expect(await data(await get(b, "/api/premium/settings"))).toMatchObject({ is_plus: false, send_read_receipts: false });
    const own = await get(b, `/api/conversations/${conversationId}/messages`);
    expect(own.status).toBe(200);
  });
});

describe("section 5 and 6: the word of a Super Like, priority likes", () => {
  test("the recipient finds the Super Like and its word on the card in Discover", async () => {
    const sender = await woman("sl-sender");
    const recipient = await man("sl-recipient");
    expect((await swipe(sender, recipient.id, "super_like", { note: "  Votre sourire à la soirée  " })).status).toBe(200);
    const card = (await discoverProfiles(recipient)).find((profile) => profile.user_id === sender.id);
    expect(card).toMatchObject({ super_liked_you: true, super_like_note: "Votre sourire à la soirée" });
    const other = await man("sl-other");
    expect((await discoverProfiles(other)).find((profile) => profile.user_id === sender.id)).toMatchObject({ super_liked_you: false, super_like_note: null });
  });

  test("a Super Like without a word shows a mark and no word", async () => {
    const sender = await woman("sl-bare");
    const recipient = await man("sl-bare-recipient");
    await swipe(sender, recipient.id, "super_like");
    expect((await discoverProfiles(recipient)).find((profile) => profile.user_id === sender.id)).toMatchObject({ super_liked_you: true, super_like_note: null });
  });

  test("a word the server refuses debits nothing and records nothing", async () => {
    const sender = await woman("sl-refused");
    const recipient = await man("sl-refused-recipient");
    for (const note of ["", "a".repeat(141), "https://example.com/moi", 7]) {
      const res = await swipe(sender, recipient.id, "super_like", { note });
      expect([res.status, ((await res.json()) as { error: string }).error]).toEqual([400, "invalid_note"]);
    }
    const wrongAction = await swipe(sender, recipient.id, "like", { note: "Bonjour" });
    expect([wrongAction.status, ((await wrongAction.json()) as { error: string }).error]).toEqual([400, "note_requires_super_like"]);
    const [row] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM swipes WHERE user_id = ${sender.id}`;
    expect(Number(row?.n)).toBe(0);
    // Her Super Like of the day is intact.
    expect((await swipe(sender, recipient.id, "super_like", { note: "x".repeat(140) })).status).toBe(200);
  });

  test("the word is stored apart from the other swipes and dropped when the swipe changes", async () => {
    const sender = await woman("sl-drop");
    const recipient = await man("sl-drop-recipient");
    await swipe(sender, recipient.id, "super_like", { note: "Bonjour" });
    await swipe(sender, recipient.id, "super_like");
    const [kept] = await db<{ note: string | null }[]>`SELECT note FROM swipes WHERE user_id = ${sender.id}`;
    expect(kept?.note).toBe("Bonjour");
    await swipe(sender, recipient.id, "pass");
    const [dropped] = await db<{ note: string | null; action: string }[]>`SELECT note, action FROM swipes WHERE user_id = ${sender.id}`;
    expect([dropped?.action, dropped?.note]).toEqual(["pass", null]);
  });

  test("the like of a mazl+ member comes first in Discover; the rest keeps its order", async () => {
    const viewer = await man("prio-viewer");
    const plusLiker = await woman("prio-plus");
    const freeLiker = await woman("prio-free");
    await grantPlus(plusLiker.id);
    const before = (await discoverIds(viewer)).filter((id) => id !== plusLiker.id);

    await swipe(plusLiker, viewer.id, "like");
    await swipe(freeLiker, viewer.id, "like");
    const after = await discoverIds(viewer);
    expect(after[0]).toBe(plusLiker.id);
    expect(after.filter((id) => id !== plusLiker.id && id !== freeLiker.id)).toEqual(before.filter((id) => id !== freeLiker.id).slice(0, after.length - 2));
  });

  test("the priority goes when the subscription ends", async () => {
    const viewer = await man("prio-lapse-viewer");
    const liker = await woman("prio-lapse");
    await grantPlus(liker.id);
    await swipe(liker, viewer.id, "like");
    expect((await discoverIds(viewer))[0]).toBe(liker.id);
    await db`UPDATE subscriptions SET expires_at = (NOW() AT TIME ZONE 'UTC') - INTERVAL '1 hour' WHERE user_id = ${liker.id}`;
    const after = await discoverIds(viewer);
    expect(after).toContain(liker.id);
  });
});

describe("section 7: the rewind", () => {
  const undo = (member: TestUser) => fetch(`${BASE_URL}/api/swipes/undo`, { method: "POST", headers: auth(member.token) });

  test("nothing to take back: 404 nothing_to_undo, and it costs nothing", async () => {
    const member = await makeUser("undo-none");
    const res = await undo(member);
    expect([res.status, await res.json()]).toEqual([404, { success: false, error: "nothing_to_undo" }]);
    const target = await makeUser("undo-none-target");
    await swipe(member, target.id, "pass");
    expect((await undo(member)).status).toBe(200);
  });

  test("a free member gets one a day: the second is 402 undo_limit_reached and the card stays passed", async () => {
    const member = await makeUser("undo-free");
    const [first, second] = [await makeUser("undo-free-1"), await makeUser("undo-free-2")];
    await swipe(member, first.id, "pass");
    const ok = await undo(member);
    expect([ok.status, await ok.json()]).toEqual([200, { success: true, data: { target_user_id: first.id, action: "pass", remaining_free_undos: 0 } }]);
    const [gone] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM swipes WHERE user_id = ${member.id}`;
    expect(Number(gone?.n)).toBe(0);

    await swipe(member, second.id, "pass");
    const refused = await undo(member);
    expect([refused.status, await refused.json()]).toEqual([402, { success: false, error: "undo_limit_reached" }]);
    const [still] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM swipes WHERE user_id = ${member.id}`;
    expect(Number(still?.n)).toBe(1);
  });

  test("mazl+ has no limit and sees remaining_free_undos null", async () => {
    const member = await makeUser("undo-plus");
    await grantPlus(member.id);
    for (let i = 0; i < 3; i += 1) {
      const target = await makeUser(`undo-plus-${i}`);
      await swipe(member, target.id, "pass");
      const res = await undo(member);
      expect([res.status, (await data<{ remaining_free_undos: number | null }>(res)).remaining_free_undos]).toEqual([200, null]);
    }
  });

  test("a like taken back does not give the day's like back, and can be sent again for free", async () => {
    const member = await makeUser("undo-like");
    const target = await makeUser("undo-like-target");
    await swipe(member, target.id, "like");
    const allowance = async () => ((await (await get(member, "/api/likes/allowance")).json()) as { allowance: { remaining: number } }).allowance.remaining;
    expect(await allowance()).toBe(9);
    expect((await undo(member)).status).toBe(200);
    expect(await allowance()).toBe(9);
    expect((await swipe(member, target.id, "like")).status).toBe(200);
    expect(await allowance()).toBe(9);
  });

  test("a Super Like or a match cannot be taken back: 409 undo_not_possible", async () => {
    const member = await makeUser("undo-409");
    const target = await makeUser("undo-409-target");
    await swipe(member, target.id, "super_like");
    const superLike = await undo(member);
    expect([superLike.status, await superLike.json()]).toEqual([409, { success: false, error: "undo_not_possible" }]);

    const a = await makeUser("undo-match-a");
    const b = await makeUser("undo-match-b");
    await swipe(a, b.id, "like");
    await swipe(b, a.id, "like");
    const match = await undo(b);
    expect([match.status, await match.json()]).toEqual([409, { success: false, error: "undo_not_possible" }]);
  });

  test("only a recent swipe can be taken back", async () => {
    const member = await makeUser("undo-old");
    const target = await makeUser("undo-old-target");
    await swipe(member, target.id, "pass");
    await db`UPDATE swipes SET created_at = NOW() - INTERVAL '11 minutes' WHERE user_id = ${member.id}`;
    expect((await undo(member)).status).toBe(404);
  });

  test("two simultaneous rewinds of a free member spend one undo, not two", async () => {
    const member = await makeUser("undo-race");
    for (let i = 0; i < 2; i += 1) await swipe(member, (await makeUser(`undo-race-${i}`)).id, "pass");
    const results = await Promise.all([undo(member), undo(member), undo(member)]);
    expect(results.map((res) => res.status).sort()).toEqual([200, 402, 402]);
  });
});

describe("section 8: Boost at the right moment", () => {
  const schedule = (member: TestUser, at: string) => fetch(`${BASE_URL}/api/boost/schedule`, { method: "POST", headers: json(member.token), body: JSON.stringify({ at }) });
  const inMinutes = (minutes: number) => new Date(Date.now() + minutes * 60_000).toISOString();

  test("best-time says nothing for a quiet or unknown city, with no city at all", async () => {
    const member = await makeUser("bt-quiet");
    expect(await data(await get(member, "/api/boost/best-time"))).toEqual({ city: null, best_time: null, scheduled_at: null });
    await db`INSERT INTO profiles (user_id, display_name, location) VALUES (${member.id}, 'Boost', 'Quietville, France') ON CONFLICT (user_id) DO UPDATE SET location = 'Quietville, France'`;
    expect(await data(await get(member, "/api/boost/best-time"))).toEqual({ city: "Quietville", best_time: null, scheduled_at: null });
  });

  test("opening Discover counts one session per hour in the member's city; the best hour appears once the city is lively enough", async () => {
    const city = `Livelyville${Date.now()}`;
    const viewer = await man("bt-viewer");
    await db`UPDATE profiles SET location = ${`${city}, France`} WHERE user_id = ${viewer.id}`;
    await get(viewer, "/api/discover");
    await get(viewer, "/api/discover");
    await new Promise((resolve) => setTimeout(resolve, 300));
    const key = city.toLowerCase();
    const rows = await db<{ sessions: number }[]>`SELECT sessions FROM city_activity WHERE city_key = ${key}`;
    expect(rows.reduce((sum, row) => sum + row.sessions, 0)).toBe(1);
    // Counts only, never who.
    const columns = await db<{ column_name: string }[]>`SELECT column_name FROM information_schema.columns WHERE table_name = 'city_activity'`;
    expect(columns.map((c) => c.column_name).sort()).toEqual(["city_key", "dow", "hour", "sessions"]);

    await db`INSERT INTO city_activity (city_key, dow, hour, sessions) VALUES (${key}, 6, 21, 90), (${key}, 2, 8, 10) ON CONFLICT (city_key, dow, hour) DO UPDATE SET sessions = EXCLUDED.sessions`;
    const best = await data<{ city: string; best_time: { starts_at: string; weekday: number; hour: number } | null }>(await get(viewer, "/api/boost/best-time"));
    expect(best.city).toBe(city);
    expect(best.best_time).toMatchObject({ weekday: 6, hour: 21 });
    const startsAt = new Date(best.best_time?.starts_at ?? "");
    expect([startsAt.getUTCDay(), startsAt.getUTCHours()]).toEqual([6, 21]);
    expect(startsAt.getTime()).toBeGreaterThan(Date.now());
  });

  test("a free member without a Boost cannot programme one: 402 boosts_exhausted", async () => {
    const member = await makeUser("bt-free");
    const res = await schedule(member, inMinutes(30));
    expect([res.status, await res.json()]).toEqual([402, { success: false, error: "boosts_exhausted" }]);
  });

  test("invalid times and bodies are 400, a second programming is 409, cancelling frees it", async () => {
    const member = await makeUser("bt-rules");
    await grantPlus(member.id);
    for (const at of [inMinutes(-10), inMinutes(1), inMinutes(60 * 24 * 8)]) {
      const res = await schedule(member, at);
      expect([res.status, ((await res.json()) as { error: string }).error]).toEqual([400, "invalid_time"]);
    }
    for (const body of [{}, { at: "tomorrow" }, { at: 12 }]) {
      const res = await fetch(`${BASE_URL}/api/boost/schedule`, { method: "POST", headers: json(member.token), body: JSON.stringify(body) });
      expect([res.status, ((await res.json()) as { error: string }).error]).toEqual([400, "invalid_body"]);
    }
    const when = inMinutes(60);
    const ok = await schedule(member, when);
    expect(ok.status).toBe(201);
    expect((await data<{ scheduled_at: string }>(ok)).scheduled_at).toBe(new Date(when).toISOString());
    expect((await data<{ scheduled_at: string }>(await get(member, "/api/boost/best-time"))).scheduled_at).toBe(new Date(when).toISOString());
    const twice = await schedule(member, inMinutes(90));
    expect([twice.status, ((await twice.json()) as { error: string }).error]).toEqual([409, "already_scheduled"]);
    const cancelled = await fetch(`${BASE_URL}/api/boost/schedule`, { method: "DELETE", headers: auth(member.token) });
    expect(await data(cancelled)).toEqual({ scheduled_at: null });
    expect((await schedule(member, inMinutes(90))).status).toBe(201);
  });

  test("a schedule belongs to its member: nobody else sees or cancels it", async () => {
    const owner = await makeUser("bt-owner");
    const other = await makeUser("bt-other");
    await grantPlus(owner.id);
    await grantPlus(other.id);
    await schedule(owner, inMinutes(60));
    expect((await data<{ scheduled_at: string | null }>(await get(other, "/api/boost/best-time"))).scheduled_at).toBeNull();
    await fetch(`${BASE_URL}/api/boost/schedule`, { method: "DELETE", headers: auth(other.token) });
    expect((await data<{ scheduled_at: string | null }>(await get(owner, "/api/boost/best-time"))).scheduled_at).not.toBeNull();
  });

  test("the minute task starts the Boost when the time comes: the credit is spent and the schedule is gone", async () => {
    const member = await makeUser("bt-run");
    await grantPlus(member.id);
    expect((await schedule(member, inMinutes(30))).status).toBe(201);
    await db`UPDATE boost_schedules SET run_at = NOW() - INTERVAL '5 seconds' WHERE user_id = ${member.id}`;
    let active = false;
    for (let attempt = 0; attempt < 90 && !active; attempt += 1) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      active = ((await (await get(member, "/api/boost/status")).json()) as { is_active: boolean }).is_active;
    }
    expect(active).toBe(true);
    const status = (await (await get(member, "/api/boost/status")).json()) as { credits: { boost: { available: number } } };
    expect(status.credits.boost.available).toBe(0);
    const rows = await db`SELECT 1 FROM boost_schedules WHERE user_id = ${member.id}`;
    expect(rows.length).toBe(0);
  });

  test("a member who spent their Boost meanwhile loses the schedule and is charged nothing", async () => {
    const member = await makeUser("bt-spent");
    await grantPlus(member.id);
    expect((await schedule(member, inMinutes(30))).status).toBe(201);
    expect((await fetch(`${BASE_URL}/api/boost/activate`, { method: "POST", headers: auth(member.token) })).status).toBe(201);
    await db`UPDATE boost_schedules SET run_at = NOW() - INTERVAL '5 seconds' WHERE user_id = ${member.id}`;
    for (let attempt = 0; attempt < 90; attempt += 1) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      const rows = await db`SELECT 1 FROM boost_schedules WHERE user_id = ${member.id}`;
      if (rows.length === 0) break;
    }
    expect((await db`SELECT 1 FROM boost_schedules WHERE user_id = ${member.id}`).length).toBe(0);
    const boosts = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM boosts WHERE user_id = ${member.id}`;
    expect(Number(boosts[0]?.n)).toBe(1);
  });
});
