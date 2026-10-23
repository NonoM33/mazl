import { DAILY_SESSION_LIMIT } from "../domain/thresholds";
import type { VerificationLevel } from "../domain/types";
import type { FaceSessionRepository, VerificationStateRepository } from "./ports";

export interface VerificationStatus {
  readonly photo: { readonly verified: boolean; readonly verifiedAt: Date | null; readonly attemptsToday: number };
  readonly identity: { readonly verified: boolean; readonly verifiedAt: Date | null; readonly attemptsToday: number };
  readonly level: VerificationLevel;
  readonly isVerified: boolean;
  readonly attemptsToday: number;
  readonly nextAttemptTime: Date | null;
}

export interface FaceStatusDeps {
  readonly sessions: FaceSessionRepository;
  readonly state: VerificationStateRepository;
}

export async function getVerificationStatus(deps: FaceStatusDeps, userId: number): Promise<VerificationStatus> {
  const [state, photoAttempts, identityAttempts] = await Promise.all([
    deps.state.read(userId),
    deps.sessions.countToday(userId, "photo"),
    deps.sessions.countToday(userId, "identity"),
  ]);
  // photo_verified = timestamp set AND the main photo still matches.
  const photoVerified = state.photoVerifiedAt !== null && state.primaryPhotoMatches;
  const identityVerified = state.identityVerifiedAt !== null;
  const level: VerificationLevel = identityVerified ? "identity" : photoVerified ? "photo" : "none";
  const isVerified = level !== "none";
  const exhausted = !isVerified && photoAttempts >= DAILY_SESSION_LIMIT;
  return {
    photo: { verified: photoVerified, verifiedAt: state.photoVerifiedAt, attemptsToday: photoAttempts },
    identity: { verified: identityVerified, verifiedAt: state.identityVerifiedAt, attemptsToday: identityAttempts },
    level,
    isVerified,
    attemptsToday: photoAttempts,
    nextAttemptTime: exhausted ? await deps.sessions.nextMidnight() : null,
  };
}
