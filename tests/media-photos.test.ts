import { beforeAll, describe, expect, test } from "bun:test";
import sharp from "sharp";
import {
  BASE_URL, EXIF_MARKER, absolute, auth, craftSignedUrl, db, grantPlus, json, jpegWithGps,
  makeUser, uploadOk, uploadPhoto, type PhotoRow, type TestUser,
} from "./media-helpers";

// Integration tests of CONTRAT.md §2.1 (profile photos). Needs a running server.

describe("photo upload", () => {
  let user: TestUser;
  beforeAll(async () => { user = await makeUser("upload"); });

  test("re-encodes: no EXIF/GPS survives, orientation applied, client name and MIME ignored", async () => {
    const input = await jpegWithGps(300, 100, 6);
    const res = await uploadPhoto(user.token, input, { filename: "../../evil.php", mime: "text/html" });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { success: boolean; photo: PhotoRow };
    expect(body.success).toBe(true);
    expect(body.photo.url).toMatch(/\/media\/photos\/\d+\?exp=\d+&sig=[A-Za-z0-9_-]+$/);
    expect(body.photo.url).not.toContain("evil");

    const served = await fetch(absolute(body.photo.url));
    expect(served.status).toBe(200);
    expect(served.headers.get("content-type")).toBe("image/jpeg");
    expect(served.headers.get("cache-control")).toMatch(/^private, max-age=(3[6-9]\d\d|[4-6]\d{3}|7[01]\d\d|7200), immutable$/);
    const etag = served.headers.get("etag");
    expect(etag).toMatch(/^"[0-9a-f]{32}"$/);
    const revalidated = await fetch(absolute(body.photo.url), { headers: { "If-None-Match": etag ?? "" } });
    expect(revalidated.status).toBe(304);
    expect(served.headers.get("x-content-type-options")).toBe("nosniff");
    const bytes = Buffer.from(await served.arrayBuffer());
    expect([...bytes.subarray(0, 3)]).toEqual([0xff, 0xd8, 0xff]);
    expect(bytes.includes(Buffer.from("Exif\0\0", "binary"))).toBe(false);
    expect(bytes.includes(Buffer.from(EXIF_MARKER))).toBe(false);
    const meta = await sharp(bytes).metadata();
    expect(meta.exif).toBeUndefined();
    expect([meta.width, meta.height]).toEqual([100, 300]); // orientation 6 swaps the sides
  });

  test("the stored file name is a random UUID, never the client's", async () => {
    const photo = await uploadOk(user.token, await jpegWithGps(50, 50, 1));
    const [row] = await db<{ url: string }[]>`SELECT url FROM profile_photos WHERE id = ${photo.id}`;
    expect(row?.url).toMatch(/^photos\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$/);
  });

  test("refuses what cannot be decoded, and stores nothing", async () => {
    const before = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM profile_photos WHERE user_id = ${user.id}`;
    for (const bytes of [
      Buffer.from("<?php system($_GET['c']); ?>"),
      Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'),
      Buffer.alloc(0),
    ]) {
      const res = await uploadPhoto(user.token, bytes, { filename: "x.jpg", mime: "image/jpeg" });
      expect(res.status).toBe(400);
    }
    const after = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM profile_photos WHERE user_id = ${user.id}`;
    expect(after[0]?.n).toBe(before[0]?.n);
  });

  test("no file in the form is a 400", async () => {
    const res = await fetch(`${BASE_URL}/api/profile/photos`, { method: "POST", headers: auth(user.token), body: new FormData() });
    expect(res.status).toBe(400);
  });

  test("an arbitrary URL in a JSON body is refused", async () => {
    for (const body of [
      { url: "https://evil.example/tracker.jpg" },
      { url: "http://169.254.169.254/latest/meta-data" },
      { url: "https://lh3.googleusercontent.com/a/x", is_primary: true },
      { import_oauth_picture: true, url: "https://evil.example/x.jpg" },
      { import_oauth_picture: false },
      {},
    ]) {
      const res = await fetch(`${BASE_URL}/api/profile/photos`, { method: "POST", headers: json(user.token), body: JSON.stringify(body) });
      expect(res.status).toBe(400);
    }
  });

  test("import_oauth_picture refuses when the account has no picture or a non-Google one", async () => {
    const other = await makeUser("oauth");
    const attempt = () => fetch(`${BASE_URL}/api/profile/photos`, { method: "POST", headers: json(other.token), body: JSON.stringify({ import_oauth_picture: true }) });

    let res = await attempt();
    expect(res.status).toBe(400);
    expect(((await res.json()) as { reason: string }).reason).toBe("no_picture");

    await db`UPDATE users SET picture = 'https://i.pravatar.cc/400?img=3' WHERE id = ${other.id}`;
    res = await attempt();
    expect(res.status).toBe(400);
    expect(((await res.json()) as { reason: string }).reason).toBe("host_not_allowed");

    await db`UPDATE users SET picture = 'http://169.254.169.254/latest/meta-data' WHERE id = ${other.id}`;
    expect((await attempt()).status).toBe(400);
  });

  test("the photo list returns signed URLs and hides old external rows", async () => {
    const lister = await makeUser("list");
    const mine = await uploadOk(lister.token, await jpegWithGps(40, 40, 1));
    await db`INSERT INTO profile_photos (user_id, url, position) VALUES (${lister.id}, 'https://i.pravatar.cc/400?img=9', 5)`;

    const res = await fetch(`${BASE_URL}/api/profile/photos`, { headers: auth(lister.token) });
    const body = (await res.json()) as { photos: PhotoRow[] };
    expect(body.photos.map((p) => p.id)).toEqual([mine.id]);
    expect(body.photos.every((p) => /\/media\/photos\/\d+\?exp=/.test(p.url))).toBe(true);
  });

  test("deleting a photo erases the file: its signed URL stops working", async () => {
    const deleter = await makeUser("delete");
    const photo = await uploadOk(deleter.token, await jpegWithGps(40, 40, 1));
    expect((await fetch(absolute(photo.url))).status).toBe(200);
    const del = await fetch(`${BASE_URL}/api/profile/photos/${photo.id}`, { method: "DELETE", headers: auth(deleter.token) });
    expect(del.status).toBe(200);
    expect((await fetch(absolute(photo.url))).status).toBe(404);
  });
});

describe("signed photo route", () => {
  let user: TestUser;
  let photo: PhotoRow;
  beforeAll(async () => {
    user = await makeUser("sign");
    photo = await uploadOk(user.token, await jpegWithGps(60, 60, 1));
  });

  test("a URL signed by the contract formula is served", async () => {
    const exp = Math.floor(Date.now() / 1000) + 600;
    expect((await fetch(craftSignedUrl(photo.id, exp))).status).toBe(200);
  });

  test("an expired URL is a 404 even though its signature is correct", async () => {
    const exp = Math.floor(Date.now() / 1000) - 5;
    expect((await fetch(craftSignedUrl(photo.id, exp))).status).toBe(404);
  });

  test("tampering with id, exp or sig is a 404", async () => {
    const exp = Math.floor(Date.now() / 1000) + 600;
    const url = new URL(craftSignedUrl(photo.id, exp));
    const forgeSig = new URL(url);
    forgeSig.searchParams.set("sig", "A".repeat(43));
    const forgeExp = new URL(url);
    forgeExp.searchParams.set("exp", String(exp + 3600));
    const otherId = new URL(url);
    otherId.pathname = `/media/photos/${photo.id + 1}`;
    const noSig = new URL(url);
    noSig.searchParams.delete("sig");
    for (const bad of [forgeSig, forgeExp, otherId, noSig]) {
      expect((await fetch(bad)).status).toBe(404);
    }
    expect((await fetch(`${BASE_URL}/media/photos/abc?exp=1&sig=x`)).status).toBe(404);
  });

  test("the old unauthenticated /uploads route is gone", async () => {
    const res = await fetch(`${BASE_URL}/uploads/profiles/${user.id}/anything.jpg`);
    expect(res.status).toBe(403);
  });
});

describe("responses carry signed photo URLs", () => {
  let alice: TestUser;
  let bob: TestUser;
  let alicePhoto: PhotoRow;
  beforeAll(async () => {
    alice = await makeUser("alice");
    bob = await makeUser("bob");
    alicePhoto = await uploadOk(alice.token, await jpegWithGps(80, 80, 1), true);
    await uploadOk(bob.token, await jpegWithGps(80, 80, 1), true);
    await db`UPDATE profiles SET is_complete = true WHERE user_id IN (${alice.id}, ${bob.id})`;
  });

  const signed = /\/media\/photos\/\d+\?exp=\d+&sig=[A-Za-z0-9_-]{43}/;

  test("GET /api/profile/:userId", async () => {
    await db`INSERT INTO profile_photos (user_id, url, position) VALUES (${alice.id}, 'https://i.pravatar.cc/400?img=1', 9)`;
    const res = await fetch(`${BASE_URL}/api/profile/${alice.id}`, { headers: auth(bob.token) });
    const { profile } = (await res.json()) as { profile: { photos: string[]; picture: string | null } };
    expect(profile.photos).toHaveLength(1);
    expect(profile.photos[0]).toMatch(signed);
    expect(profile.picture).toMatch(signed);
    expect(JSON.stringify(profile)).not.toContain("pravatar");
  });

  test("a seeded external avatar is not exposed as picture", async () => {
    await db`UPDATE users SET picture = 'https://i.pravatar.cc/400?img=2' WHERE id = ${bob.id}`;
    const res = await fetch(`${BASE_URL}/api/profile/${bob.id}`, { headers: auth(alice.token) });
    expect(JSON.stringify(await res.json())).not.toContain("pravatar");
  });

  test("a Google avatar is kept as the fallback picture", async () => {
    const guest = await makeUser("guest");
    await db`UPDATE profiles SET is_complete = true WHERE user_id = ${guest.id}`;
    await db`UPDATE users SET picture = 'https://lh3.googleusercontent.com/a/AAA=s96-c' WHERE id = ${guest.id}`;
    const res = await fetch(`${BASE_URL}/api/profile/${guest.id}`, { headers: auth(alice.token) });
    const { profile } = (await res.json()) as { profile: { picture: string | null; photos: string[] } };
    expect(profile.picture).toBe("https://lh3.googleusercontent.com/a/AAA=s96-c");
  });

  test("likes received, matches and conversations", async () => {
    const swipe = (token: string, target: number) =>
      fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: json(token), body: JSON.stringify({ target_user_id: target, action: "like" }) });
    await swipe(alice.token, bob.id);

    // Received likes carry the sharp photo for a mazl+ member only (docs/web/adr/W11); the others get its blurred variant.
    const receivedLikes = () => fetch(`${BASE_URL}/api/likes/received`, { headers: auth(bob.token) }).then((r) => r.json()) as Promise<{ likes: Array<{ user_id?: number; picture?: string | null }> }>;
    const free = JSON.stringify((await receivedLikes()).likes);
    expect(free).not.toMatch(/\/media\/photos\/\d+\?/);
    expect(free).toMatch(/\/media\/photos\/\d+\/blur\?/);
    await grantPlus(bob.id);
    expect((await receivedLikes()).likes.find((l) => l.user_id === alice.id)?.picture).toMatch(signed);

    await swipe(bob.token, alice.id);
    const matches = await fetch(`${BASE_URL}/api/matches`, { headers: auth(bob.token) });
    const matchesBody = (await matches.json()) as { matches: Array<{ profile: { user_id: number; picture: string | null } }> };
    expect(matchesBody.matches.find((m) => m.profile.user_id === alice.id)?.profile.picture).toMatch(signed);

    const convs = await fetch(`${BASE_URL}/api/conversations`, { headers: auth(bob.token) });
    const convBody = (await convs.json()) as { conversations: Array<{ otherUser: { user_id: number; picture: string | null } }> };
    expect(convBody.conversations.find((c) => c.otherUser.user_id === alice.id)?.otherUser.picture).toMatch(signed);
  });

  test("discover and daily picks", async () => {
    const carol = await makeUser("carol");
    await uploadOk(carol.token, await jpegWithGps(80, 80, 1), true);
    await db`UPDATE profiles SET is_complete = true WHERE user_id = ${carol.id}`;
    const viewer = await makeUser("viewer");
    for (const path of ["/api/discover?limit=100", "/api/daily-picks"]) {
      const res = await fetch(`${BASE_URL}${path}`, { headers: auth(viewer.token) });
      const body = (await res.json()) as { profiles?: Array<{ user_id: number; photos: string[]; picture: string | null }>; picks?: Array<{ user_id: number; photos: string[]; picture: string | null }> };
      const list = body.profiles ?? body.picks ?? [];
      const text = JSON.stringify(list);
      expect(text).not.toContain("pravatar");
      expect(text).not.toMatch(/"(latitude|longitude)"/);
      for (const entry of list.filter((e) => [alice.id, bob.id, carol.id].includes(e.user_id))) {
        expect(entry.photos.every((p) => signed.test(p))).toBe(true);
        expect(entry.picture).toMatch(signed);
      }
    }
  });

  test("a stored photo id of another user cannot be fetched with a signature for a different id", async () => {
    const exp = Math.floor(Date.now() / 1000) + 600;
    const wrong = craftSignedUrl(alicePhoto.id, exp).replace(`/photos/${alicePhoto.id}`, `/photos/${alicePhoto.id + 100000}`);
    expect((await fetch(wrong)).status).toBe(404);
  });
});

describe("verification badge (contract 3, Badge)", () => {
  let owner: TestUser;
  let viewer: TestUser;
  let photo: PhotoRow;
  beforeAll(async () => {
    owner = await makeUser("badge");
    viewer = await makeUser("badgeviewer");
    photo = await uploadOk(owner.token, await jpegWithGps(60, 60, 1), true);
    await db`UPDATE profiles SET is_complete = true WHERE user_id = ${owner.id}`;
  });

  async function badge() {
    const res = await fetch(`${BASE_URL}/api/profile/${owner.id}`, { headers: auth(viewer.token) });
    const { profile } = (await res.json()) as { profile: { is_verified: boolean; photo_verified: boolean; identity_verified: boolean } };
    return profile;
  }

  test("nobody is verified by default, even if the legacy column says so", async () => {
    await db`UPDATE profiles SET is_verified = true WHERE user_id = ${owner.id}`;
    expect(await badge()).toMatchObject({ is_verified: false, photo_verified: false, identity_verified: false });
  });

  test("photo_verified needs the timestamp AND a matching primary photo", async () => {
    await db`UPDATE profiles SET photo_verified_at = NOW() WHERE user_id = ${owner.id}`;
    expect(await badge()).toMatchObject({ is_verified: false, photo_verified: false });

    await db`UPDATE profile_photos SET face_match = false WHERE id = ${photo.id}`;
    expect(await badge()).toMatchObject({ is_verified: false, photo_verified: false });

    await db`UPDATE profile_photos SET face_match = true WHERE id = ${photo.id}`;
    expect(await badge()).toMatchObject({ is_verified: true, photo_verified: true, identity_verified: false });

    await db`UPDATE profiles SET photo_verified_at = NULL WHERE user_id = ${owner.id}`;
    expect(await badge()).toMatchObject({ is_verified: false, photo_verified: false });
  });

  test("identity_verified alone is enough for is_verified", async () => {
    await db`UPDATE profiles SET identity_verified_at = NOW() WHERE user_id = ${owner.id}`;
    expect(await badge()).toMatchObject({ is_verified: true, photo_verified: false, identity_verified: true });
  });
});
