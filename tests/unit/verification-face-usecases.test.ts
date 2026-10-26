import { beforeEach, describe, expect, test } from "bun:test";
import { startFaceSession } from "../../src/features/verification/application/start-session";
import { submitFaceVerification, type SubmitFaceDeps } from "../../src/features/verification/application/submit-face";
import { verifyLiveFrames } from "../../src/features/verification/application/live-frames";
import { PhotoFaceCheckerService } from "../../src/features/verification/application/photo-face-checker";
import { deleteFaceReference } from "../../src/features/verification/application/face-reference";
import { getVerificationStatus } from "../../src/features/verification/application/face-status";
import { embeddingFromBytes, embeddingToBytes } from "../../src/features/verification/domain/embedding-codec";
import { cosineSimilarity } from "../../src/features/verification/domain/similarity";
import type { Challenge } from "../../src/features/verification/domain/types";
import {
  FakeFaceEngine,
  FakeImageDecoder,
  FakePhotoStore,
  FakeReferenceStore,
  FakeSessionRepository,
  FakeStateRepository,
  FakeVault,
  NOT_AN_IMAGE,
  PERSON_A,
  PERSON_A_TURNED,
  PERSON_B,
  imageOf,
  sceneFace,
  type SceneFace,
} from "./support/face-fakes";

const USER = 7;
const OTHER_USER = 8;
const THRESHOLDS = { match: 0.363, consistency: 0.5 };

// Grey levels that name a scene in the fake engine.
const FRONT = 40;
const TURNED_A = 90;
const TURNED_B = 140;
const FINAL_FRONT = 190;
const PROFILE_PHOTO_A = 200;
const PROFILE_PHOTO_B = 210;
const LANDSCAPE = 220;
const CROWD = 230;

function scenes(): Map<number, readonly SceneFace[]> {
  return new Map<number, readonly SceneFace[]>([
    [FRONT, [sceneFace(PERSON_A, 0.02)]],
    [TURNED_A, [sceneFace(PERSON_A_TURNED, 0.35)]],
    [TURNED_B, [sceneFace(PERSON_A_TURNED, -0.35)]],
    [FINAL_FRONT, [sceneFace(PERSON_A, -0.03)]],
    [PROFILE_PHOTO_A, [sceneFace(PERSON_A, 0.05)]],
    [PROFILE_PHOTO_B, [sceneFace(PERSON_B, 0.05)]],
    [LANDSCAPE, []],
    [CROWD, [sceneFace(PERSON_B, 0, 90, 200), sceneFace(PERSON_A, 0, 90, 100)]],
    [60, [sceneFace(PERSON_A, 0.02), sceneFace(PERSON_B, 0.02)]], // two faces of similar size
    [70, [sceneFace(PERSON_B, 0.02)]], // another person
    [80, [sceneFace(PERSON_A, 0.02, 40)]], // eyes only 40 px apart
    [100, [sceneFace(PERSON_A, 0.4)]], // front asked, head turned
  ]);
}

let engine: FakeFaceEngine;
let sessions: FakeSessionRepository;
let references: FakeReferenceStore;
let photos: FakePhotoStore;
let state: FakeStateRepository;
let vault: FakeVault;
let deps: SubmitFaceDeps;

beforeEach(() => {
  engine = new FakeFaceEngine(scenes());
  sessions = new FakeSessionRepository();
  references = new FakeReferenceStore();
  photos = new FakePhotoStore();
  state = new FakeStateRepository();
  vault = new FakeVault();
  deps = { decoder: new FakeImageDecoder(), engine, sessions, references, photos, state, vault, thresholds: THRESHOLDS };
});

// Opens a session and returns it with frames laid out for its challenges.
async function openSession(userId = USER, purpose: "photo" | "identity" = "photo") {
  const started = await startFaceSession({ sessions, random: Math.random }, userId, purpose);
  if (!started.ok) throw new Error("session refused");
  return started;
}

function goodFrames(challenges: readonly Challenge[]): Uint8Array[] {
  const sides = challenges.filter((c) => c !== "front");
  const levels: number[] = [FRONT];
  // Whichever side is asked first, the two turned frames have opposite yaws.
  for (const _ of sides) levels.push(levels.length === 1 ? TURNED_A : TURNED_B);
  if (challenges.length === 4) levels.push(FINAL_FRONT);
  return levels.map(imageOf);
}

describe("startFaceSession", () => {
  test("returns front first, then both sides, expiring in about 2 minutes", async () => {
    const s = await openSession();
    expect(s.challenges[0]).toBe("front");
    const sides = s.challenges.filter((c) => c !== "front").sort();
    expect(sides).toEqual(["left", "right"]);
    expect([3, 4]).toContain(s.challenges.length);
    const ttl = s.expiresAt.getTime() - Date.now();
    expect(ttl).toBeGreaterThan(110_000);
    expect(ttl).toBeLessThanOrEqual(120_000);
  });

  test("the fourth session of the day is refused with the time of the next attempt", async () => {
    for (let i = 0; i < 3; i++) await openSession();
    const fourth = await startFaceSession({ sessions, random: Math.random }, USER, "photo");
    expect(fourth.ok).toBe(false);
    if (!fourth.ok) {
      expect(fourth.reason).toBe("daily_limit_reached");
      expect(fourth.nextAttemptTime).toBeInstanceOf(Date);
    }
  });

  test("a waived member is not held to the daily limit, the others still are", async () => {
    for (let i = 0; i < 3; i++) await openSession(USER, "photo");
    const waiver = { waived: async (userId: number) => userId === USER };
    expect((await startFaceSession({ sessions, random: Math.random, waiver }, USER, "photo")).ok).toBe(true);
    for (let i = 0; i < 3; i++) await openSession(OTHER_USER, "photo");
    expect((await startFaceSession({ sessions, random: Math.random, waiver }, OTHER_USER, "photo")).ok).toBe(false);
    const status = await getVerificationStatus({ sessions, state, waiver }, USER);
    expect(status.nextAttemptTime).toBeNull();
  });

  test("quotas are per purpose and per user", async () => {
    for (let i = 0; i < 3; i++) await openSession(USER, "photo");
    expect((await startFaceSession({ sessions, random: Math.random }, USER, "identity")).ok).toBe(true);
    expect((await startFaceSession({ sessions, random: Math.random }, OTHER_USER, "photo")).ok).toBe(true);
  });

  test("a new day resets the quota", async () => {
    for (let i = 0; i < 3; i++) await openSession();
    sessions.day = 2;
    expect((await startFaceSession({ sessions, random: Math.random }, USER, "photo")).ok).toBe(true);
  });
});

describe("submitFaceVerification: session rules", () => {
  test("an unknown session id", async () => {
    const r = await submitFaceVerification(deps, { userId: USER, sessionId: "nope", frames: [] });
    expect(r).toEqual({ verified: false, reason: "session_not_found" });
  });

  test("someone else's session looks like an unknown one", async () => {
    const s = await openSession(OTHER_USER);
    const r = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: goodFrames(s.challenges) });
    expect(r).toEqual({ verified: false, reason: "session_not_found" });
  });

  test("an identity session cannot be spent on the photo flow, and stays usable", async () => {
    const s = await openSession(USER, "identity");
    const r = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: [] });
    expect(r).toEqual({ verified: false, reason: "session_not_found" });
    expect(sessions.sessions.get(s.sessionId)?.consumed).toBe(false);
  });

  test("an expired session", async () => {
    const s = await openSession();
    sessions.expire(s.sessionId);
    const r = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: goodFrames(s.challenges) });
    expect(r).toEqual({ verified: false, reason: "session_expired" });
  });

  test("a session is single use, even after a failure", async () => {
    const s = await openSession();
    const first = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: [] });
    expect(first).toEqual({ verified: false, reason: "wrong_frame_count" });
    const second = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: goodFrames(s.challenges) });
    expect(second).toEqual({ verified: false, reason: "session_used" });
  });
});

describe("submitFaceVerification: frames", () => {
  beforeEach(() => {
    photos.add(USER, 1, PROFILE_PHOTO_A, true);
  });

  async function submitWith(mutate: (frames: Uint8Array[]) => void) {
    const s = await openSession();
    const frames = goodFrames(s.challenges);
    mutate(frames);
    const result = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames });
    return { result, s };
  }

  test("one frame too many", async () => {
    const { result } = await submitWith((f) => f.push(imageOf(FRONT)));
    expect(result).toEqual({ verified: false, reason: "wrong_frame_count" });
  });

  test("an undecodable frame", async () => {
    const { result } = await submitWith((f) => (f[1] = imageOf(NOT_AN_IMAGE)));
    expect(result).toEqual({ verified: false, reason: "invalid_image" });
  });

  test("a frame without a face", async () => {
    const { result } = await submitWith((f) => (f[2] = imageOf(LANDSCAPE)));
    expect(result).toEqual({ verified: false, reason: "no_face" });
  });

  test("two similar faces in one frame", async () => {
    const { result } = await submitWith((f) => (f[1] = imageOf(60)));
    expect(result).toEqual({ verified: false, reason: "multiple_faces" });
  });

  test("a face too small", async () => {
    const { result } = await submitWith((f) => (f[0] = imageOf(80)));
    expect(result).toEqual({ verified: false, reason: "face_too_small" });
  });

  test("a head not facing the camera on the front step", async () => {
    const { result } = await submitWith((f) => (f[0] = imageOf(100)));
    expect(result).toEqual({ verified: false, reason: "pose_mismatch" });
  });

  test("the same image sent for every step", async () => {
    const { result } = await submitWith((f) => f.fill(imageOf(FRONT)));
    expect(result.verified).toBe(false);
    if (!result.verified) expect(["pose_mismatch", "duplicate_frames"]).toContain(result.reason);
  });

  test("another person in the last frame", async () => {
    const s = await openSession();
    const frames = goodFrames(s.challenges);
    frames[2] = imageOf(70);
    // person B, yaw 0.02: wrong pose comes first, so use a pose-valid B by swapping the scene
    engine = new FakeFaceEngine(new Map([...scenes(), [70, [sceneFace(PERSON_B, -0.35)]]]));
    deps = { ...deps, engine };
    const r = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames });
    expect(r).toEqual({ verified: false, reason: "inconsistent_identity" });
  });

  test("a refusal leaves no trace: no reference, no badge, no photo flags", async () => {
    await submitWith((f) => (f[2] = imageOf(LANDSCAPE)));
    expect(references.rows.size).toBe(0);
    expect(state.verifiedAt.get(USER) ?? null).toBeNull();
    expect(photos.faceMatch.get(1)).toBeNull();
  });

  test("the refusal reason is recorded as the session outcome", async () => {
    const { s } = await submitWith((f) => (f[2] = imageOf(LANDSCAPE)));
    expect(sessions.sessions.get(s.sessionId)?.outcome).toBe("no_face");
  });
});

describe("submitFaceVerification: profile photos", () => {
  test("no photo at all", async () => {
    const s = await openSession();
    const r = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: goodFrames(s.challenges) });
    expect(r).toEqual({ verified: false, reason: "no_profile_photo" });
  });

  test("a main photo without a face, even when another photo shows the user", async () => {
    photos.add(USER, 1, LANDSCAPE, true);
    photos.add(USER, 2, PROFILE_PHOTO_A);
    const s = await openSession();
    const r = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: goodFrames(s.challenges) });
    expect(r).toEqual({ verified: false, reason: "no_profile_photo" });
  });

  test("a main photo missing from storage counts as no face", async () => {
    photos.add(USER, 1, PROFILE_PHOTO_A, true);
    photos.files.delete("photo-1");
    const s = await openSession();
    const r = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: goodFrames(s.challenges) });
    expect(r).toEqual({ verified: false, reason: "no_profile_photo" });
  });

  test("a main photo of someone else", async () => {
    photos.add(USER, 1, PROFILE_PHOTO_B, true);
    photos.add(USER, 2, PROFILE_PHOTO_A);
    const s = await openSession();
    const r = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: goodFrames(s.challenges) });
    expect(r).toEqual({ verified: false, reason: "profile_mismatch" });
    expect(state.verifiedAt.get(USER) ?? null).toBeNull();
    expect(references.rows.size).toBe(0);
    expect(photos.faceMatch.get(2)).toBeNull();
  });

  test("success: badge, sealed reference and one result per photo", async () => {
    photos.add(USER, 1, PROFILE_PHOTO_A, true);
    photos.add(USER, 2, PROFILE_PHOTO_B);
    photos.add(USER, 3, LANDSCAPE);
    const s = await openSession();
    const r = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: goodFrames(s.challenges) });
    expect(r).toEqual({
      verified: true,
      photoMatches: [
        { photoId: 1, match: true },
        { photoId: 2, match: false },
        { photoId: 3, match: false },
      ],
    });
    expect(state.verifiedAt.get(USER)).toBeInstanceOf(Date);
    expect([photos.faceMatch.get(1), photos.faceMatch.get(2), photos.faceMatch.get(3)]).toEqual([true, false, false]);
    expect(sessions.sessions.get(s.sessionId)?.outcome).toBe("verified");

    // The stored reference is the sealed first front embedding, bound to the user.
    expect(vault.sealedWith).toEqual([`face-reference:${USER}`]);
    const row = references.rows.get(USER);
    expect(row?.model).toBe("sface_2021dec");
    const plain = embeddingToBytes(PERSON_A);
    expect(Buffer.from(row!.sealed).includes(Buffer.from(plain))).toBe(false);
    const opened = embeddingFromBytes(vault.open(row!.sealed, `face-reference:${USER}`));
    expect(cosineSimilarity(opened, PERSON_A)).toBeCloseTo(1, 6);
  });

  test("a group photo that contains the user matches", async () => {
    photos.add(USER, 1, CROWD, true);
    const s = await openSession();
    const r = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: goodFrames(s.challenges) });
    expect(r.verified).toBe(true);
  });

  test("a second verification replaces the reference", async () => {
    photos.add(USER, 1, PROFILE_PHOTO_A, true);
    for (let i = 0; i < 2; i++) {
      const s = await openSession();
      const r = await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: goodFrames(s.challenges) });
      expect(r.verified).toBe(true);
    }
    expect(references.rows.size).toBe(1);
  });

  test("an engine failure is not swallowed and leaves an internal_error outcome", async () => {
    photos.add(USER, 1, PROFILE_PHOTO_A, true);
    const s = await openSession();
    engine.failWith = new Error("model missing");
    await expect(
      submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: goodFrames(s.challenges) }),
    ).rejects.toThrow("model missing");
    expect(sessions.sessions.get(s.sessionId)?.outcome).toBe("internal_error");
  });
});

describe("verifyLiveFrames (shared with level 2)", () => {
  const live = () => ({ decoder: new FakeImageDecoder(), engine, consistencyThreshold: 0.5 });

  test("returns the embedding of the first front frame", async () => {
    const challenges: Challenge[] = ["front", "left", "right"];
    const verdict = await verifyLiveFrames(live(), challenges, goodFrames(challenges));
    expect(verdict.ok).toBe(true);
    if (verdict.ok) expect(cosineSimilarity(verdict.frontEmbedding, PERSON_A)).toBeCloseTo(1, 6);
  });

  test("refuses a wrong frame count before decoding anything", async () => {
    const verdict = await verifyLiveFrames(live(), ["front", "left", "right"], [imageOf(FRONT)]);
    expect(verdict).toEqual({ ok: false, reason: "wrong_frame_count" });
    expect(engine.detectCalls).toBe(0);
  });

  test("skips the embedding of a face refused for its size", async () => {
    const verdict = await verifyLiveFrames(live(), ["front"], [imageOf(80)]);
    expect(verdict).toEqual({ ok: false, reason: "face_too_small" });
    expect(engine.embedCalls).toBe(0);
  });
});

describe("PhotoFaceCheckerService", () => {
  function checker(): PhotoFaceCheckerService {
    return new PhotoFaceCheckerService({
      decoder: new FakeImageDecoder(),
      engine,
      references,
      photos,
      state,
      vault,
      matchThreshold: THRESHOLDS.match,
    });
  }

  async function verifiedUser(): Promise<void> {
    photos.add(USER, 1, PROFILE_PHOTO_A, true);
    const s = await openSession();
    await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: goodFrames(s.challenges) });
  }

  test("a user without reference is left alone", async () => {
    photos.add(USER, 5, PROFILE_PHOTO_A);
    await checker().checkStoredPhoto(USER, 5, imageOf(PROFILE_PHOTO_A));
    expect(photos.faceMatch.get(5)).toBeNull();
    expect(state.refreshed).toEqual([]);
  });

  test("a new photo of the user matches", async () => {
    await verifiedUser();
    photos.add(USER, 5, PROFILE_PHOTO_A);
    await checker().checkStoredPhoto(USER, 5, imageOf(PROFILE_PHOTO_A));
    expect(photos.faceMatch.get(5)).toBe(true);
    expect(state.refreshed).toContain(USER);
  });

  test("a new photo of someone else does not", async () => {
    await verifiedUser();
    photos.add(USER, 5, PROFILE_PHOTO_B);
    await checker().checkStoredPhoto(USER, 5, imageOf(PROFILE_PHOTO_B));
    expect(photos.faceMatch.get(5)).toBe(false);
  });

  test("a photo without a face does not match", async () => {
    await verifiedUser();
    photos.add(USER, 5, LANDSCAPE);
    await checker().checkStoredPhoto(USER, 5, imageOf(LANDSCAPE));
    expect(photos.faceMatch.get(5)).toBe(false);
  });

  test("an undecodable upload does not match and does not throw", async () => {
    await verifiedUser();
    photos.add(USER, 5, LANDSCAPE);
    await checker().checkStoredPhoto(USER, 5, imageOf(NOT_AN_IMAGE));
    expect(photos.faceMatch.get(5)).toBe(false);
  });

  test("another user's reference cannot be opened for this user (context binding)", async () => {
    await verifiedUser();
    const stolen = references.rows.get(USER)!;
    references.rows.set(OTHER_USER, stolen);
    photos.add(OTHER_USER, 9, PROFILE_PHOTO_A);
    await expect(checker().checkStoredPhoto(OTHER_USER, 9, imageOf(PROFILE_PHOTO_A))).rejects.toThrow();
  });
});

describe("deleteFaceReference", () => {
  test("removes the reference, the photo flags and the badge", async () => {
    photos.add(USER, 1, PROFILE_PHOTO_A, true);
    const s = await openSession();
    await submitFaceVerification(deps, { userId: USER, sessionId: s.sessionId, frames: goodFrames(s.challenges) });
    expect(references.rows.has(USER)).toBe(true);

    await deleteFaceReference({ references, photos, state }, USER);
    expect(references.rows.has(USER)).toBe(false);
    expect(photos.faceMatch.get(1)).toBeNull();
    expect(state.verifiedAt.get(USER)).toBeNull();
  });

  test("is harmless when nothing was stored", async () => {
    await deleteFaceReference({ references, photos, state }, USER);
    expect(references.rows.size).toBe(0);
  });
});

describe("getVerificationStatus", () => {
  test("a new member has no level and no attempt", async () => {
    const s = await getVerificationStatus({ sessions, state }, USER);
    expect(s.level).toBe("none");
    expect(s.isVerified).toBe(false);
    expect(s.photo).toEqual({ verified: false, verifiedAt: null, attemptsToday: 0 });
    expect(s.nextAttemptTime).toBeNull();
  });

  test("after a verification: level photo, one attempt", async () => {
    photos.add(USER, 1, PROFILE_PHOTO_A, true);
    const o = await openSession();
    await submitFaceVerification(deps, { userId: USER, sessionId: o.sessionId, frames: goodFrames(o.challenges) });
    state.primaryMatches.set(USER, true);
    const s = await getVerificationStatus({ sessions, state }, USER);
    expect(s.level).toBe("photo");
    expect(s.isVerified).toBe(true);
    expect(s.photo.verified).toBe(true);
    expect(s.photo.attemptsToday).toBe(1);
    expect(s.attemptsToday).toBe(1);
  });

  test("a timestamp without a matching main photo is not a badge", async () => {
    await state.markPhotoVerified(USER);
    state.primaryMatches.set(USER, false);
    const s = await getVerificationStatus({ sessions, state }, USER);
    expect(s.photo.verified).toBe(false);
    expect(s.level).toBe("none");
  });

  test("identity beats photo", async () => {
    await state.markPhotoVerified(USER);
    state.primaryMatches.set(USER, true);
    state.identityAt.set(USER, new Date("2030-01-01T00:00:00.000Z"));
    const s = await getVerificationStatus({ sessions, state }, USER);
    expect(s.level).toBe("identity");
    expect(s.identity.verified).toBe(true);
  });

  test("when the three attempts are used the next attempt time is given", async () => {
    for (let i = 0; i < 3; i++) await openSession();
    const s = await getVerificationStatus({ sessions, state }, USER);
    expect(s.attemptsToday).toBe(3);
    expect(s.nextAttemptTime).toBeInstanceOf(Date);
  });

  test("attempts are counted per purpose", async () => {
    await openSession(USER, "identity");
    const s = await getVerificationStatus({ sessions, state }, USER);
    expect(s.identity.attemptsToday).toBe(1);
    expect(s.photo.attemptsToday).toBe(0);
  });
});

describe("embedding codec", () => {
  test("round trips exactly and is little-endian float32", () => {
    const e = Float32Array.of(0.25, -1.5, 3);
    const bytes = embeddingToBytes(e);
    expect(bytes).toHaveLength(12);
    expect(Array.from(bytes.slice(0, 4))).toEqual([0x00, 0x00, 0x80, 0x3e]); // 0.25f little endian
    expect(Array.from(embeddingFromBytes(bytes))).toEqual([0.25, -1.5, 3]);
  });

  test("bytes that are not whole floats are refused", () => {
    expect(() => embeddingFromBytes(new Uint8Array(5))).toThrow();
    expect(() => embeddingFromBytes(new Uint8Array(0))).toThrow();
  });

  test("works on a view into a larger buffer", () => {
    const e = Float32Array.of(1, 2);
    const padded = new Uint8Array(20);
    padded.set(embeddingToBytes(e), 4);
    expect(Array.from(embeddingFromBytes(padded.subarray(4, 12)))).toEqual([1, 2]);
  });
});
