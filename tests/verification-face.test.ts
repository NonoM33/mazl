import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { copyFile, mkdir, readdir, readFile } from "node:fs/promises";
import { join } from "node:path";
import postgres from "postgres";
import sharp from "sharp";
import { PhotoFaceCheckerService } from "../src/features/verification/application/photo-face-checker";
import { PgFaceReferenceStore } from "../src/features/verification/infra/pg-face-reference-store";
import { PgProfilePhotoStore } from "../src/features/verification/infra/pg-profile-photo-store";
import { PgVerificationState } from "../src/features/verification/infra/pg-verification-state";
import { gcmSecretVault } from "../src/features/verification/infra/secret-vault";
import { sharedFaceEngine } from "../src/features/verification/infra/shared-face-engine";
import { SharpImageDecoder } from "../src/features/verification/infra/sharp-image-decoder";
import { TEST_PASSWORD } from "./test-password";

// Integration test of the level 1 selfie verification, against a running
// server and its Postgres.
//
//   DATABASE_URL=<db> UPLOADS_DIR=<dir> PORT=3323 ... bun src/index.ts
//   TEST_API_URL=http://localhost:3323 DATABASE_URL=<db> UPLOADS_DIR=<dir> bun test tests/verification-face.test.ts
//
// Every rule runs at its default value. The public-domain fixtures are decades
// apart and strongly turned (cosine 0.39 between portrait and profile), still
// above the 0.363 consistency floor.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";
const DATABASE_URL = process.env.DATABASE_URL ?? "";
const UPLOADS_DIR = process.env.UPLOADS_DIR ?? "";
const FIXTURES = join(import.meta.dir, "fixtures", "faces");

interface TestUser { id: number; token: string }
const sql = postgres(DATABASE_URL || "postgres://invalid", { max: 2 });
afterAll(async () => {
  await sql.end({ timeout: 2 });
});

async function makeUser(label: string): Promise<TestUser> {
  const email = `vface-${label}-${Date.now()}-${Math.floor(performance.now())}@mazl.app`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: TEST_PASSWORD, name: label }),
  });
  const data = (await res.json()) as { success: boolean; user?: { id: number }; token?: string };
  if (!data.success || !data.user || !data.token) throw new Error(`makeUser(${label}): ${JSON.stringify(data)}`);
  return { id: data.user.id, token: data.token };
}

const json = (t: string): Record<string, string> => ({ "Content-Type": "application/json", Authorization: `Bearer ${t}` });
const auth = (t: string): Record<string, string> => ({ Authorization: `Bearer ${t}` });

interface SessionBody { success: boolean; session_id: string; challenges: string[]; expires_at: string }

async function openSession(u: TestUser, purpose: "photo" | "identity" = "photo"): Promise<SessionBody> {
  const r = await fetch(`${BASE_URL}/api/verification/face/session`, {
    method: "POST",
    headers: json(u.token),
    body: JSON.stringify({ purpose }),
  });
  expect(r.status).toBe(200);
  return (await r.json()) as SessionBody;
}

async function submit(u: TestUser, sessionId: string | null, frames: Uint8Array[]): Promise<{ status: number; body: Record<string, unknown> }> {
  const form = new FormData();
  if (sessionId !== null) form.set("session_id", sessionId);
  frames.forEach((f, i) => form.set(`frame_${i}`, new Blob([f], { type: "image/jpeg" }), `frame_${i}.jpg`));
  const r = await fetch(`${BASE_URL}/api/verification/face/submit`, { method: "POST", headers: auth(u.token), body: form });
  return { status: r.status, body: (await r.json()) as Record<string, unknown> };
}

const blank = async (level: number): Promise<Uint8Array> =>
  new Uint8Array(await sharp({ create: { width: 640, height: 480, channels: 3, background: { r: level, g: level, b: level } } }).jpeg().toBuffer());

const fixture = async (name: string): Promise<Uint8Array> => new Uint8Array(await readFile(join(FIXTURES, name)));
const mirrored = async (name: string): Promise<Uint8Array> =>
  new Uint8Array(await sharp(await readFile(join(FIXTURES, name))).flop().jpeg({ quality: 90 }).toBuffer());

async function expireSession(id: string): Promise<void> {
  await sql`UPDATE face_verification_sessions SET expires_at = NOW() - INTERVAL '1 minute' WHERE id = ${id}`;
}

async function countFiles(dir: string): Promise<number> {
  let n = 0;
  for (const e of await readdir(dir, { withFileTypes: true, recursive: true })) if (e.isFile()) n++;
  return n;
}

describe("face session", () => {
  test("opens with front first, a valid expiry and one use", async () => {
    const u = await makeUser("session");
    const s = await openSession(u);
    expect(s.success).toBe(true);
    expect(s.session_id).toMatch(/^[0-9a-f-]{36}$/);
    expect(s.challenges[0]).toBe("front");
    expect(s.challenges).toContain("left");
    expect(s.challenges).toContain("right");
    expect([3, 4]).toContain(s.challenges.length);
    const ttl = new Date(s.expires_at).getTime() - Date.now();
    expect(ttl).toBeGreaterThan(100_000);
    expect(ttl).toBeLessThanOrEqual(121_000);
  });

  test("the fourth session of the day for a purpose is refused with 429", async () => {
    const u = await makeUser("quota");
    for (let i = 0; i < 3; i++) await openSession(u);
    const r = await fetch(`${BASE_URL}/api/verification/face/session`, {
      method: "POST",
      headers: json(u.token),
      body: JSON.stringify({ purpose: "photo" }),
    });
    expect(r.status).toBe(429);
    const body = (await r.json()) as { success: boolean; error: string; next_attempt_time: string };
    expect(body.success).toBe(false);
    expect(body.error).toBe("daily_limit_reached");
    expect(new Date(body.next_attempt_time).getTime()).toBeGreaterThan(Date.now());
    // The other purpose has its own allowance.
    expect((await openSession(u, "identity")).success).toBe(true);
  });

  test("rejects an unknown purpose and a missing token", async () => {
    const u = await makeUser("purpose");
    const bad = await fetch(`${BASE_URL}/api/verification/face/session`, {
      method: "POST",
      headers: json(u.token),
      body: JSON.stringify({ purpose: "passport" }),
    });
    expect(bad.status).toBe(400);
    const anon = await fetch(`${BASE_URL}/api/verification/face/session`, { method: "POST", body: "{}" });
    expect(anon.status).toBe(401);
  });
});

describe("face submit: session rules", () => {
  test("an unknown session", async () => {
    const u = await makeUser("unknown");
    const r = await submit(u, crypto.randomUUID(), [await blank(100)]);
    expect(r.status).toBe(200);
    expect(r.body).toEqual({ success: true, verified: false, reason: "session_not_found" });
  });

  test("a session id that is not even a UUID", async () => {
    const u = await makeUser("notuuid");
    const r = await submit(u, "'; DROP TABLE users; --", [await blank(100)]);
    expect(r.body).toEqual({ success: true, verified: false, reason: "session_not_found" });
  });

  test("another member's session", async () => {
    const owner = await makeUser("owner");
    const thief = await makeUser("thief");
    const s = await openSession(owner);
    const r = await submit(thief, s.session_id, [await blank(100)]);
    expect(r.body.reason).toBe("session_not_found");
  });

  test("an identity session cannot be spent on the photo endpoint", async () => {
    const u = await makeUser("purposemix");
    const s = await openSession(u, "identity");
    expect((await submit(u, s.session_id, [await blank(100)])).body.reason).toBe("session_not_found");
  });

  test("an expired session", async () => {
    const u = await makeUser("expired");
    const s = await openSession(u);
    await expireSession(s.session_id);
    const r = await submit(u, s.session_id, await Promise.all(s.challenges.map((_, i) => blank(40 + i * 40))));
    expect(r.body).toEqual({ success: true, verified: false, reason: "session_expired" });
  });

  test("a session is single use, even after a refusal", async () => {
    const u = await makeUser("reuse");
    const s = await openSession(u);
    const frames = await Promise.all(s.challenges.map((_, i) => blank(40 + i * 40)));
    expect((await submit(u, s.session_id, frames)).body.reason).toBe("no_face");
    expect((await submit(u, s.session_id, frames)).body.reason).toBe("session_used");
  });
});

describe("face submit: frames", () => {
  test("a wrong number of frames", async () => {
    const u = await makeUser("count");
    const s = await openSession(u);
    const r = await submit(u, s.session_id, [await blank(100)]);
    expect(r.body).toEqual({ success: true, verified: false, reason: "wrong_frame_count" });
  });

  test("frames with a gap in their numbering count as a wrong frame count", async () => {
    const u = await makeUser("gap");
    const s = await openSession(u);
    const form = new FormData();
    form.set("session_id", s.session_id);
    s.challenges.forEach((_, i) => form.set(`frame_${i === 1 ? 5 : i}`, new Blob([new Uint8Array([1, 2, 3])]), "f.jpg"));
    const r = await fetch(`${BASE_URL}/api/verification/face/submit`, { method: "POST", headers: auth(u.token), body: form });
    expect(((await r.json()) as { reason: string }).reason).toBe("wrong_frame_count");
  });

  test("blank images contain no face", async () => {
    const u = await makeUser("blank");
    const s = await openSession(u);
    const frames = await Promise.all(s.challenges.map((_, i) => blank(40 + i * 40)));
    const r = await submit(u, s.session_id, frames);
    expect(r.body).toEqual({ success: true, verified: false, reason: "no_face" });
  });

  test("bytes that are not an image", async () => {
    const u = await makeUser("garbage");
    const s = await openSession(u);
    const frames = s.challenges.map(() => new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7]));
    expect((await submit(u, s.session_id, frames)).body.reason).toBe("invalid_image");
  });

  test("a frame over 2 MB is refused with 413", async () => {
    const u = await makeUser("big");
    const s = await openSession(u);
    const frames = s.challenges.map(() => new Uint8Array(2 * 1024 * 1024 + 1));
    const r = await submit(u, s.session_id, frames);
    expect(r.status).toBe(413);
    expect(r.body.success).toBe(false);
  });

  test("a JSON body, or a missing session_id, is a 400", async () => {
    const u = await makeUser("shape");
    const json400 = await fetch(`${BASE_URL}/api/verification/face/submit`, { method: "POST", headers: json(u.token), body: "{}" });
    expect(json400.status).toBe(400);
    expect((await submit(u, null, [await blank(100)])).status).toBe(400);
  });

  test("a face that does not turn is refused for its pose", async () => {
    const u = await makeUser("pose");
    const s = await openSession(u);
    const front = await fixture("ride-portrait-1984.jpg");
    const r = await submit(u, s.session_id, s.challenges.map(() => front));
    expect(r.body).toEqual({ success: true, verified: false, reason: "pose_mismatch" });
  });
});

describe("face submit: a real verification", () => {
  let user: TestUser;
  let primaryPhotoId: number;
  let secondPhotoId: number;

  beforeAll(async () => {
    expect(DATABASE_URL).not.toBe("");
    expect(UPLOADS_DIR).not.toBe("");
    user = await makeUser("real");
    const dir = join(UPLOADS_DIR, "profiles", String(user.id));
    await mkdir(dir, { recursive: true });
    await copyFile(join(FIXTURES, "ride-portrait-1984.jpg"), join(dir, "main.jpg"));
    await copyFile(join(FIXTURES, "glenn-senate-portrait.jpg"), join(dir, "other.jpg"));
    const [main] = await sql<{ id: number }[]>`
      INSERT INTO profile_photos (user_id, url, position, is_primary)
      VALUES (${user.id}, ${`/uploads/profiles/${user.id}/main.jpg`}, 0, true) RETURNING id`;
    const [other] = await sql<{ id: number }[]>`
      INSERT INTO profile_photos (user_id, url, position, is_primary)
      VALUES (${user.id}, ${`/uploads/profiles/${user.id}/other.jpg`}, 1, false) RETURNING id`;
    primaryPhotoId = main!.id;
    secondPhotoId = other!.id;
  });

  async function liveFrames(challenges: string[]): Promise<Uint8Array[]> {
    const sides = [await fixture("ride-profile-sts7-1983.jpg"), await mirrored("ride-profile-sts7-1983.jpg")];
    const out: Uint8Array[] = [await fixture("ride-portrait-1984.jpg")];
    for (const c of challenges.slice(1)) out.push(c === "front" ? await fixture("ride-flight-deck-1983.jpg") : (sides.shift() as Uint8Array));
    return out;
  }

  test("status before: nothing verified", async () => {
    const r = await fetch(`${BASE_URL}/api/verification/status`, { headers: auth(user.token) });
    const s = (await r.json()) as Record<string, any>;
    expect(s.photo.verified).toBe(false);
    expect(s.level).toBe("none");
    expect(s.is_verified).toBe(false);
  });

  test("the live selfie matches the main photo: badge, photo flags and a sealed reference", async () => {
    const filesBefore = await countFiles(UPLOADS_DIR);
    const s = await openSession(user);
    const r = await submit(user, s.session_id, await liveFrames(s.challenges));
    expect(r.status).toBe(200);
    expect(r.body).toEqual({
      success: true,
      verified: true,
      photo_matches: [
        { photo_id: primaryPhotoId, match: true },
        { photo_id: secondPhotoId, match: false },
      ],
    });

    const [profile] = await sql<{ photo_verified_at: Date | null; is_verified: boolean; verification_level: string }[]>`
      SELECT photo_verified_at, is_verified, verification_level FROM profiles WHERE user_id = ${user.id}`;
    expect(profile?.photo_verified_at).not.toBeNull();
    expect(profile?.is_verified).toBe(true);
    expect(profile?.verification_level).toBe("photo");

    const photos = await sql<{ id: number; face_match: boolean | null; face_checked_at: Date | null }[]>`
      SELECT id, face_match, face_checked_at FROM profile_photos WHERE user_id = ${user.id} ORDER BY id`;
    expect(photos.map((p) => p.face_match)).toEqual([true, false]);
    expect(photos.every((p) => p.face_checked_at !== null)).toBe(true);

    const [ref] = await sql<{ embedding_sealed: Buffer; model: string }[]>`
      SELECT embedding_sealed, model FROM face_references WHERE user_id = ${user.id}`;
    expect(ref?.model).toBe("sface_2021dec");
    // 1 version byte + 12 IV + 128 float32 + 16 tag
    expect(ref?.embedding_sealed.length).toBe(1 + 12 + 512 + 16);

    const [session] = await sql<{ outcome: string; consumed_at: Date | null }[]>`
      SELECT outcome, consumed_at FROM face_verification_sessions WHERE id = ${s.session_id}`;
    expect(session?.outcome).toBe("verified");
    expect(session?.consumed_at).not.toBeNull();

    // No frame, thumbnail or embedding landed on disk.
    expect(await countFiles(UPLOADS_DIR)).toBe(filesBefore);
  });

  test("status after: level photo, one attempt", async () => {
    const r = await fetch(`${BASE_URL}/api/verification/status`, { headers: auth(user.token) });
    const s = (await r.json()) as Record<string, any>;
    expect(s.photo.verified).toBe(true);
    expect(typeof s.photo.verified_at).toBe("string");
    expect(s.photo.attempts_today).toBe(1);
    expect(s.identity.verified).toBe(false);
    expect(s.level).toBe("photo");
    expect(s.is_verified).toBe(true);
    expect(s.attempts_today).toBe(1);
    expect(s.next_attempt_time).toBeNull();
  });

  test("a photo added later is checked against the sealed reference", async () => {
    const decoder = new SharpImageDecoder();
    const checker = new PhotoFaceCheckerService({
      decoder,
      engine: sharedFaceEngine("models"),
      references: new PgFaceReferenceStore(sql),
      photos: new PgProfilePhotoStore(sql, async () => null),
      state: new PgVerificationState(sql),
      vault: gcmSecretVault,
      matchThreshold: 0.363,
    });
    const [same] = await sql<{ id: number }[]>`
      INSERT INTO profile_photos (user_id, url, position) VALUES (${user.id}, '/uploads/x/same.jpg', 2) RETURNING id`;
    const [stranger] = await sql<{ id: number }[]>`
      INSERT INTO profile_photos (user_id, url, position) VALUES (${user.id}, '/uploads/x/stranger.jpg', 3) RETURNING id`;
    await checker.checkStoredPhoto(user.id, same!.id, await fixture("ride-flight-deck-1983.jpg"));
    await checker.checkStoredPhoto(user.id, stranger!.id, await fixture("glenn-senate-portrait.jpg"));
    const rows = await sql<{ id: number; face_match: boolean | null }[]>`
      SELECT id, face_match FROM profile_photos WHERE id IN (${same!.id}, ${stranger!.id}) ORDER BY id`;
    expect(rows.map((r) => r.face_match)).toEqual([true, false]);
  });

  test("replacing the main photo with someone else drops the badge", async () => {
    const checker = new PgVerificationState(sql);
    await sql`UPDATE profile_photos SET face_match = false WHERE id = ${primaryPhotoId}`;
    await checker.refreshBadge(user.id);
    const [profile] = await sql<{ is_verified: boolean; verification_level: string }[]>`
      SELECT is_verified, verification_level FROM profiles WHERE user_id = ${user.id}`;
    expect(profile?.is_verified).toBe(false);
    expect(profile?.verification_level).toBe("none");
    const status = (await (await fetch(`${BASE_URL}/api/verification/status`, { headers: auth(user.token) })).json()) as Record<string, any>;
    expect(status.photo.verified).toBe(false);
    await sql`UPDATE profile_photos SET face_match = true WHERE id = ${primaryPhotoId}`;
    await checker.refreshBadge(user.id);
  });

  test("a main photo of someone else refuses the verification and keeps nothing", async () => {
    const stranger = await makeUser("mismatch");
    const dir = join(UPLOADS_DIR, "profiles", String(stranger.id));
    await mkdir(dir, { recursive: true });
    await copyFile(join(FIXTURES, "glenn-senate-portrait.jpg"), join(dir, "main.jpg"));
    await sql`INSERT INTO profile_photos (user_id, url, position, is_primary)
              VALUES (${stranger.id}, ${`/uploads/profiles/${stranger.id}/main.jpg`}, 0, true)`;
    const s = await openSession(stranger);
    const r = await submit(stranger, s.session_id, await liveFrames(s.challenges));
    expect(r.body).toEqual({ success: true, verified: false, reason: "profile_mismatch" });
    const refs = await sql`SELECT 1 FROM face_references WHERE user_id = ${stranger.id}`;
    expect(refs).toHaveLength(0);
    const [p] = await sql<{ photo_verified_at: Date | null }[]>`SELECT photo_verified_at FROM profiles WHERE user_id = ${stranger.id}`;
    expect(p?.photo_verified_at).toBeNull();
  });

  test("a member without any profile photo cannot be verified", async () => {
    const bare = await makeUser("nophoto");
    const s = await openSession(bare);
    const r = await submit(bare, s.session_id, await liveFrames(s.challenges));
    expect(r.body).toEqual({ success: true, verified: false, reason: "no_profile_photo" });
  });

  test("withdrawing consent deletes the reference and the badge", async () => {
    const del = await fetch(`${BASE_URL}/api/verification/face/reference`, { method: "DELETE", headers: auth(user.token) });
    expect(del.status).toBe(200);
    expect(await sql`SELECT 1 FROM face_references WHERE user_id = ${user.id}`).toHaveLength(0);
    const [p] = await sql<{ photo_verified_at: Date | null; is_verified: boolean }[]>`
      SELECT photo_verified_at, is_verified FROM profiles WHERE user_id = ${user.id}`;
    expect(p?.photo_verified_at).toBeNull();
    expect(p?.is_verified).toBe(false);
    const photos = await sql<{ face_match: boolean | null }[]>`SELECT face_match FROM profile_photos WHERE user_id = ${user.id}`;
    expect(photos.every((x) => x.face_match === null)).toBe(true);
    const status = (await (await fetch(`${BASE_URL}/api/verification/status`, { headers: auth(user.token) })).json()) as Record<string, any>;
    expect(status.level).toBe("none");
  });
});

describe("legacy endpoints", () => {
  test("submit no longer verifies anybody", async () => {
    const u = await makeUser("legacy");
    const start = await fetch(`${BASE_URL}/api/verification/start`, { method: "POST", headers: json(u.token) });
    expect(start.status).toBe(200);
    const { gesture_id } = (await start.json()) as { gesture_id?: string };
    expect(["hand_up", "smile", "thumbs_up"]).toContain(gesture_id ?? "");

    const r = await fetch(`${BASE_URL}/api/verification/submit`, {
      method: "POST",
      headers: json(u.token),
      body: JSON.stringify({ selfie: "data:image/png;base64,AAAA", gesture_id }),
    });
    expect(r.status).toBe(200);
    expect(await r.json()).toEqual({ success: true, verified: false, reason: "app_update_required" });

    const status = (await (await fetch(`${BASE_URL}/api/verification/status`, { headers: json(u.token) })).json()) as Record<string, unknown>;
    expect(status.is_verified).toBe(false);
    expect(status.level).toBe("none");
  });

  test("the status keeps the fields old app versions read", async () => {
    const u = await makeUser("legacystatus");
    const s = (await (await fetch(`${BASE_URL}/api/verification/status`, { headers: json(u.token) })).json()) as Record<string, any>;
    expect(s.success).toBe(true);
    expect(s.is_verified).toBe(false);
    expect(s.attempts_today).toBe(0);
    expect(s.next_attempt_time).toBeNull();
    expect(s.photo).toEqual({ verified: false, verified_at: null, attempts_today: 0 });
    expect(s.identity).toEqual({ verified: false, verified_at: null, attempts_today: 0 });
  });
});
