import type { Challenge, ChipFiles, ChipVerification, DetectedFace, Embedding, FacePurpose } from "../domain/types";

// Ports of the verification feature. Use cases depend on these interfaces
// only; adapters live in ../infra. CONTRACT: docs/verification/CONTRAT.md.

// Decoded image in RGB, row-major, 3 bytes per pixel.
export interface RgbImage {
  readonly width: number;
  readonly height: number;
  readonly data: Uint8Array;
}

export interface ImageDecoder {
  // JPEG, PNG or HEIC from the phone camera. Applies EXIF orientation, drops
  // all metadata, caps the long side. Throws InvalidImageError.
  decode(bytes: Uint8Array): Promise<RgbImage>;
}

export interface Jp2Decoder {
  // JPEG 2000 (codestream or JP2 box format) as found in passport DG2.
  decode(bytes: Uint8Array): Promise<RgbImage>;
}

export interface FaceEngine {
  detect(image: RgbImage): Promise<readonly DetectedFace[]>;
  // Aligns the face on its 5 landmarks (112x112, ArcFace template) and
  // returns an L2-normalised embedding.
  embed(image: RgbImage, face: DetectedFace): Promise<Embedding>;
}

export interface ChipVerifier {
  // ICAO 9303 passive authentication: SOD signature by a DSC that chains to a
  // trusted CSCA, DG1/DG2 hashes equal to those signed in the SOD, then DG1
  // (MRZ) and DG2 (face image) parsing.
  verify(files: ChipFiles, now: Date): Promise<ChipVerification>;
}

// Called by the profile feature after a photo is stored, so that photos added
// after verification are compared with the user's face reference. The default
// implementation does nothing.
export interface PhotoFaceChecker {
  checkStoredPhoto(userId: number, photoId: number, imageBytes: Uint8Array): Promise<void>;
}

export class InvalidImageError extends Error {
  constructor(reason: string) {
    super(`invalid image: ${reason}`);
    this.name = "InvalidImageError";
  }
}

// ---------- Level 1 additions: sessions, references, photos ----------

export interface FaceSession {
  readonly id: string;
  readonly userId: number;
  readonly purpose: FacePurpose;
  readonly challenges: readonly Challenge[];
  readonly expiresAt: Date;
}

export type SessionCreation =
  | { readonly ok: true; readonly session: FaceSession }
  | { readonly ok: false; readonly nextAttemptTime: Date };

export type SessionConsumption =
  | { readonly ok: true; readonly session: FaceSession }
  | { readonly ok: false; readonly reason: "session_not_found" | "session_expired" | "session_used" };

// Time (expiry, "today") is the database's: one clock for every instance.
export interface FaceSessionRepository {
  // Atomic: counts the user's sessions of the day for this purpose and
  // inserts the new one only when below the limit.
  createWithinDailyQuota(input: {
    readonly userId: number;
    readonly purpose: FacePurpose;
    readonly challenges: readonly Challenge[];
    readonly ttlSeconds: number;
    readonly dailyLimit: number;
  }): Promise<SessionCreation>;
  // Single use: marks the session consumed even if the submission then fails.
  consume(sessionId: string, userId: number, purpose: FacePurpose): Promise<SessionConsumption>;
  recordOutcome(sessionId: string, outcome: string): Promise<void>;
  countToday(userId: number, purpose: FacePurpose): Promise<number>;
  nextMidnight(): Promise<Date>;
}

export interface FaceReferenceStore {
  save(userId: number, sealed: Uint8Array, model: string): Promise<void>;
  load(userId: number): Promise<Uint8Array | null>;
  remove(userId: number): Promise<void>;
}

// Authenticated encryption at rest (src/shared/crypto/secret-box.ts).
export interface SecretVault {
  seal(plaintext: Uint8Array, context: string): Uint8Array;
  open(sealed: Uint8Array, context: string): Uint8Array;
}

export interface StoredPhoto {
  readonly id: number;
  readonly storageKey: string;
  readonly isPrimary: boolean;
}

export interface ProfilePhotoStore {
  // Primary photo first, then by position.
  listForUser(userId: number): Promise<readonly StoredPhoto[]>;
  // Null when the file is missing or is not a local file.
  readBytes(storageKey: string): Promise<Uint8Array | null>;
  recordFaceMatch(photoId: number, match: boolean): Promise<void>;
  clearFaceMatches(userId: number): Promise<void>;
}

export interface PhotoBadgeState {
  readonly photoVerifiedAt: Date | null;
  readonly identityVerifiedAt: Date | null;
  readonly primaryPhotoMatches: boolean;
}

export interface VerificationStateRepository {
  markPhotoVerified(userId: number): Promise<void>;
  clearPhotoVerified(userId: number): Promise<void>;
  // Re-derives profiles.is_verified / verification_level after a face_match change.
  refreshBadge(userId: number): Promise<void>;
  read(userId: number): Promise<PhotoBadgeState>;
}

// Whether the daily limit of attempts is lifted for a member (administrators
// testing the check, until a set date).
export interface QuotaWaiver {
  waived(userId: number): Promise<boolean>;
}
