import { embeddingToBytes } from "../domain/embedding-codec";
import type { FaceThresholds } from "../domain/thresholds";
import type { FaceRejection } from "../domain/types";
import { verifyLiveFrames } from "./live-frames";
import { evaluatePhoto, type PhotoMatchingDeps } from "./photo-matching";
import type {
  FaceReferenceStore,
  FaceSessionRepository,
  ProfilePhotoStore,
  SecretVault,
  VerificationStateRepository,
} from "./ports";

export const FACE_REFERENCE_MODEL = "sface_2021dec";
export const faceReferenceContext = (userId: number): string => `face-reference:${userId}`;

export interface SubmitFaceDeps extends PhotoMatchingDeps {
  readonly sessions: FaceSessionRepository;
  readonly references: FaceReferenceStore;
  readonly photos: ProfilePhotoStore;
  readonly state: VerificationStateRepository;
  readonly vault: SecretVault;
  readonly thresholds: FaceThresholds;
}

export type SubmitFaceResult =
  | { readonly verified: true; readonly photoMatches: readonly { readonly photoId: number; readonly match: boolean }[] }
  | { readonly verified: false; readonly reason: FaceRejection };

// Purpose "photo": live frames, then comparison with the profile photos.
// The session is consumed first and whatever happens next, so a failed
// attempt cannot be retried on the same challenges.
export async function submitFaceVerification(
  deps: SubmitFaceDeps,
  input: { readonly userId: number; readonly sessionId: string; readonly frames: readonly Uint8Array[] },
): Promise<SubmitFaceResult> {
  const consumed = await deps.sessions.consume(input.sessionId, input.userId, "photo");
  if (!consumed.ok) return { verified: false, reason: consumed.reason };

  let outcome = "internal_error";
  try {
    const result = await run(deps, input.userId, consumed.session.challenges, input.frames);
    outcome = result.verified ? "verified" : result.reason;
    return result;
  } finally {
    await deps.sessions.recordOutcome(input.sessionId, outcome);
  }
}

async function run(
  deps: SubmitFaceDeps,
  userId: number,
  challenges: Parameters<typeof verifyLiveFrames>[1],
  frames: readonly Uint8Array[],
): Promise<SubmitFaceResult> {
  const live = await verifyLiveFrames(
    { decoder: deps.decoder, engine: deps.engine, consistencyThreshold: deps.thresholds.consistency },
    challenges,
    frames,
  );
  if (!live.ok) return { verified: false, reason: live.reason };

  const photos = await deps.photos.listForUser(userId);
  const evaluations: { photoId: number; hasFace: boolean; match: boolean }[] = [];
  for (const photo of photos) {
    const bytes = await deps.photos.readBytes(photo.storageKey);
    const evaluation = bytes
      ? await evaluatePhoto(deps, bytes, live.frontEmbedding, deps.thresholds.match)
      : { hasFace: false, match: false };
    evaluations.push({ photoId: photo.id, ...evaluation });
  }

  // The main photo is the first one listed. It must show a face, and it must be
  // the user's: other photos are recorded but do not decide.
  const main = evaluations[0];
  if (!main || !main.hasFace) return { verified: false, reason: "no_profile_photo" };
  if (!main.match) return { verified: false, reason: "profile_mismatch" };

  const sealed = deps.vault.seal(embeddingToBytes(live.frontEmbedding), faceReferenceContext(userId));
  await deps.references.save(userId, sealed, FACE_REFERENCE_MODEL);
  for (const e of evaluations) await deps.photos.recordFaceMatch(e.photoId, e.match);
  await deps.state.markPhotoVerified(userId);
  return { verified: true, photoMatches: evaluations.map((e) => ({ photoId: e.photoId, match: e.match })) };
}
