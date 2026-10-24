import { ageOn, documentFingerprintMessage, isExpired } from "../domain/chip/identity-helpers";
import { selectSubjectFace } from "../domain/face-selection";
import { cosineSimilarity } from "../domain/similarity";
import type { FaceThresholds } from "../domain/thresholds";
import type { ChipFiles, ChipIdentity, Embedding, IdentityRejection } from "../domain/types";
import type { DocumentFingerprinter, IdentityRepository } from "./identity-ports";
import { verifyLiveFrames } from "./live-frames";
import {
  InvalidImageError,
  type ChipVerifier,
  type FaceEngine,
  type FaceSessionRepository,
  type ImageDecoder,
  type Jp2Decoder,
  type RgbImage,
  type VerificationStateRepository,
} from "./ports";

export const ADULT_AGE = 18;

export interface SubmitIdentityDeps {
  readonly decoder: ImageDecoder;
  readonly jp2: Jp2Decoder;
  readonly engine: FaceEngine;
  readonly chip: ChipVerifier;
  readonly sessions: FaceSessionRepository;
  readonly identities: IdentityRepository;
  readonly state: VerificationStateRepository;
  readonly fingerprint: DocumentFingerprinter;
  readonly thresholds: FaceThresholds;
  readonly now: () => Date;
}

export interface SubmitIdentityInput {
  readonly userId: number;
  readonly sessionId: string;
  readonly frames: readonly Uint8Array[];
  readonly chip: ChipFiles;
}

export type SubmitIdentityResult =
  | { readonly verified: true }
  | { readonly verified: false; readonly reason: IdentityRejection };

const refuse = (reason: IdentityRejection): SubmitIdentityResult => ({ verified: false, reason });

// Purpose "identity". Order matters: the face on the chip is compared with the
// live selfie BEFORE the document registry is consulted, so that someone
// holding copied chip data cannot learn whether that document is used here.
// Nothing read from the chip is stored except IdentityRecord.
export async function submitIdentityVerification(
  deps: SubmitIdentityDeps,
  input: SubmitIdentityInput,
): Promise<SubmitIdentityResult> {
  const consumed = await deps.sessions.consume(input.sessionId, input.userId, "identity");
  if (!consumed.ok) return refuse(consumed.reason);

  let outcome = "internal_error";
  try {
    const result = await run(deps, input, consumed.session.challenges);
    outcome = result.verified ? "verified" : result.reason;
    return result;
  } finally {
    await deps.sessions.recordOutcome(input.sessionId, outcome);
  }
}

async function run(
  deps: SubmitIdentityDeps,
  input: SubmitIdentityInput,
  challenges: Parameters<typeof verifyLiveFrames>[1],
): Promise<SubmitIdentityResult> {
  const live = await verifyLiveFrames(
    { decoder: deps.decoder, engine: deps.engine, consistencyThreshold: deps.thresholds.consistency },
    challenges,
    input.frames,
  );
  if (!live.ok) return refuse(live.reason);

  const now = deps.now();
  const chip = await deps.chip.verify(input.chip, now);
  if (!chip.ok) return refuse(chip.reason);
  if (isExpired(chip.identity, now)) return refuse("document_expired");
  if (ageOn(chip.identity, now) < ADULT_AGE) return refuse("underage");

  const documentFace = await embedDocumentFace(deps, chip.faceImage, chip.faceImageFormat);
  if (documentFace === null || cosineSimilarity(live.frontEmbedding, documentFace) < deps.thresholds.match) {
    return refuse("document_face_mismatch");
  }

  return register(deps, input.userId, chip.identity);
}

async function register(deps: SubmitIdentityDeps, userId: number, identity: ChipIdentity): Promise<SubmitIdentityResult> {
  const fingerprint = deps.fingerprint(documentFingerprintMessage(identity));
  if (await deps.identities.isBanned(fingerprint)) return refuse("document_banned");
  const owner = await deps.identities.ownerOf(fingerprint);
  if (owner !== null && owner !== userId) return refuse("document_already_used");

  const saved = await deps.identities.save({
    userId,
    method: "nfc_passive_auth",
    issuingState: identity.issuingState,
    documentType: identity.documentType,
    fingerprint,
    documentExpiry: identity.expiryDate,
    birthDate: identity.birthDate,
  });
  if (saved === "fingerprint_taken") return refuse("document_already_used");
  await deps.state.refreshBadge(userId);
  return { verified: true };
}

// The chip photo is a passport portrait: exactly one face expected. An
// undecodable image or no single face is treated as a mismatch, never trusted.
async function embedDocumentFace(
  deps: SubmitIdentityDeps,
  bytes: Uint8Array,
  format: "jpeg" | "jp2",
): Promise<Embedding | null> {
  let image: RgbImage;
  try {
    image = format === "jp2" ? await deps.jp2.decode(bytes) : await deps.decoder.decode(bytes);
  } catch (error: unknown) {
    if (error instanceof InvalidImageError) return null;
    throw error;
  }
  const selection = selectSubjectFace(await deps.engine.detect(image));
  if (selection.status !== "single_face") return null;
  return deps.engine.embed(image, selection.face);
}
