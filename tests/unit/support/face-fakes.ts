import {
  InvalidImageError,
  type FaceEngine,
  type FaceReferenceStore,
  type FaceSession,
  type FaceSessionRepository,
  type ImageDecoder,
  type PhotoBadgeState,
  type ProfilePhotoStore,
  type RgbImage,
  type SecretVault,
  type SessionConsumption,
  type SessionCreation,
  type StoredPhoto,
  type VerificationStateRepository,
} from "../../../src/features/verification/application/ports";
import type { Challenge, DetectedFace, Embedding, FacePurpose } from "../../../src/features/verification/domain/types";

// Test images are one byte: its value is the grey level of a 32x32 image and
// the key of the scene the fake engine "sees" in it. 0xFF is not an image.
export const NOT_AN_IMAGE = 0xff;
export const imageOf = (level: number): Uint8Array => Uint8Array.of(level);

export class FakeImageDecoder implements ImageDecoder {
  async decode(bytes: Uint8Array): Promise<RgbImage> {
    const level = bytes[0];
    if (level === undefined || level === NOT_AN_IMAGE) throw new InvalidImageError("fake garbage");
    return { width: 32, height: 32, data: new Uint8Array(32 * 32 * 3).fill(level) };
  }
}

export interface SceneFace {
  readonly face: DetectedFace;
  readonly embedding: Embedding;
}

export function sceneFace(embedding: Embedding, yaw = 0, eyeDistance = 90, size = 200): SceneFace {
  const rightEyeX = 100;
  const middle = rightEyeX + eyeDistance / 2;
  return {
    embedding,
    face: {
      box: { x: 50, y: 50, width: size, height: size },
      score: 0.95,
      landmarks: {
        rightEye: { x: rightEyeX, y: 100 },
        leftEye: { x: rightEyeX + eyeDistance, y: 100 },
        nose: { x: middle + yaw * eyeDistance, y: 140 },
        rightMouth: { x: rightEyeX + 10, y: 180 },
        leftMouth: { x: rightEyeX + eyeDistance - 10, y: 180 },
      },
    },
  };
}

export class FakeFaceEngine implements FaceEngine {
  detectCalls = 0;
  embedCalls = 0;
  failWith: Error | null = null;
  constructor(private readonly scenes: ReadonlyMap<number, readonly SceneFace[]>) {}

  async detect(image: RgbImage): Promise<readonly DetectedFace[]> {
    this.detectCalls++;
    if (this.failWith) throw this.failWith;
    return (this.scenes.get(image.data[0] ?? -1) ?? []).map((s) => s.face);
  }

  async embed(image: RgbImage, face: DetectedFace): Promise<Embedding> {
    this.embedCalls++;
    const found = (this.scenes.get(image.data[0] ?? -1) ?? []).find((s) => s.face === face);
    if (!found) throw new Error("fake engine: unknown face");
    return found.embedding;
  }
}

// Unit vectors: persons A and B are orthogonal; A2 is A seen from another angle.
export const PERSON_A: Embedding = Float32Array.of(1, 0, 0);
export const PERSON_A_TURNED: Embedding = Float32Array.of(0.8, 0.6, 0);
export const PERSON_B: Embedding = Float32Array.of(0, 0, 1);

interface StoredSession extends FaceSession {
  consumed: boolean;
  outcome: string | null;
  createdOnDay: number;
}

export class FakeSessionRepository implements FaceSessionRepository {
  readonly sessions = new Map<string, StoredSession>();
  day = 1;
  private expired = new Set<string>();
  private counter = 0;

  async createWithinDailyQuota(input: {
    userId: number;
    purpose: FacePurpose;
    challenges: readonly Challenge[];
    ttlSeconds: number;
    dailyLimit: number;
  }): Promise<SessionCreation> {
    if ((await this.countToday(input.userId, input.purpose)) >= input.dailyLimit) {
      return { ok: false, nextAttemptTime: await this.nextMidnight() };
    }
    const session: StoredSession = {
      id: `00000000-0000-4000-8000-${String(++this.counter).padStart(12, "0")}`,
      userId: input.userId,
      purpose: input.purpose,
      challenges: input.challenges,
      expiresAt: new Date(Date.now() + input.ttlSeconds * 1000),
      consumed: false,
      outcome: null,
      createdOnDay: this.day,
    };
    this.sessions.set(session.id, session);
    return { ok: true, session };
  }

  expire(sessionId: string): void {
    this.expired.add(sessionId);
  }

  async consume(sessionId: string, userId: number, purpose: FacePurpose): Promise<SessionConsumption> {
    const s = this.sessions.get(sessionId);
    if (!s || s.userId !== userId || s.purpose !== purpose) return { ok: false, reason: "session_not_found" };
    if (s.consumed) return { ok: false, reason: "session_used" };
    if (this.expired.has(sessionId)) return { ok: false, reason: "session_expired" };
    s.consumed = true;
    return { ok: true, session: s };
  }

  async recordOutcome(sessionId: string, outcome: string): Promise<void> {
    const s = this.sessions.get(sessionId);
    if (s) s.outcome = outcome;
  }

  async countToday(userId: number, purpose: FacePurpose): Promise<number> {
    return [...this.sessions.values()].filter((s) => s.userId === userId && s.purpose === purpose && s.createdOnDay === this.day).length;
  }

  async nextMidnight(): Promise<Date> {
    return new Date("2030-01-02T00:00:00.000Z");
  }
}

export class FakeReferenceStore implements FaceReferenceStore {
  readonly rows = new Map<number, { sealed: Uint8Array; model: string }>();
  async save(userId: number, sealed: Uint8Array, model: string): Promise<void> {
    this.rows.set(userId, { sealed, model });
  }
  async load(userId: number): Promise<Uint8Array | null> {
    return this.rows.get(userId)?.sealed ?? null;
  }
  async remove(userId: number): Promise<void> {
    this.rows.delete(userId);
  }
}

// Not real crypto: reversible, context-bound, and visibly different from the
// plaintext, which is all the use cases need to be tested against.
export class FakeVault implements SecretVault {
  readonly sealedWith: string[] = [];
  seal(plaintext: Uint8Array, context: string): Uint8Array {
    this.sealedWith.push(context);
    return Uint8Array.from([...new TextEncoder().encode(context + "|"), ...plaintext.map((b) => b ^ 0x5a)]);
  }
  open(sealed: Uint8Array, context: string): Uint8Array {
    const prefix = new TextEncoder().encode(context + "|");
    const head = sealed.slice(0, prefix.length);
    if (head.some((b, i) => b !== prefix[i])) throw new Error("fake vault: wrong context");
    return sealed.slice(prefix.length).map((b) => b ^ 0x5a);
  }
}

export class FakePhotoStore implements ProfilePhotoStore {
  readonly photos = new Map<number, StoredPhoto[]>();
  readonly files = new Map<string, Uint8Array>();
  readonly faceMatch = new Map<number, boolean | null>();

  add(userId: number, id: number, level: number, isPrimary = false): void {
    const list = this.photos.get(userId) ?? [];
    list.push({ id, storageKey: `photo-${id}`, isPrimary });
    this.photos.set(userId, list);
    this.files.set(`photo-${id}`, imageOf(level));
    this.faceMatch.set(id, null);
  }

  async listForUser(userId: number): Promise<readonly StoredPhoto[]> {
    return [...(this.photos.get(userId) ?? [])].sort((a, b) => Number(b.isPrimary) - Number(a.isPrimary));
  }
  async readBytes(storageKey: string): Promise<Uint8Array | null> {
    return this.files.get(storageKey) ?? null;
  }
  async recordFaceMatch(photoId: number, match: boolean): Promise<void> {
    this.faceMatch.set(photoId, match);
  }
  async clearFaceMatches(userId: number): Promise<void> {
    for (const p of this.photos.get(userId) ?? []) this.faceMatch.set(p.id, null);
  }
}

export class FakeStateRepository implements VerificationStateRepository {
  readonly verifiedAt = new Map<number, Date | null>();
  readonly identityAt = new Map<number, Date | null>();
  primaryMatches = new Map<number, boolean>();
  refreshed: number[] = [];

  async markPhotoVerified(userId: number): Promise<void> {
    this.verifiedAt.set(userId, new Date("2030-01-01T10:00:00.000Z"));
  }
  async clearPhotoVerified(userId: number): Promise<void> {
    this.verifiedAt.set(userId, null);
  }
  async refreshBadge(userId: number): Promise<void> {
    this.refreshed.push(userId);
  }
  async read(userId: number): Promise<PhotoBadgeState> {
    return {
      photoVerifiedAt: this.verifiedAt.get(userId) ?? null,
      identityVerifiedAt: this.identityAt.get(userId) ?? null,
      primaryPhotoMatches: this.primaryMatches.get(userId) ?? false,
    };
  }
}
