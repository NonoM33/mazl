import { embeddingFromBytes } from "../domain/embedding-codec";
import { faceReferenceContext } from "./submit-face";
import { evaluatePhoto, type PhotoMatchingDeps } from "./photo-matching";
import type { FaceReferenceStore, PhotoFaceChecker, ProfilePhotoStore, SecretVault, VerificationStateRepository } from "./ports";

export interface PhotoFaceCheckerDeps extends PhotoMatchingDeps {
  readonly references: FaceReferenceStore;
  readonly photos: ProfilePhotoStore;
  readonly state: VerificationStateRepository;
  readonly vault: SecretVault;
  readonly matchThreshold: number;
}

// Checks a photo added after verification against the user's stored face
// reference. Users who never verified have no reference: nothing to do.
export class PhotoFaceCheckerService implements PhotoFaceChecker {
  constructor(private readonly deps: PhotoFaceCheckerDeps) {}

  async checkStoredPhoto(userId: number, photoId: number, imageBytes: Uint8Array): Promise<void> {
    const sealed = await this.deps.references.load(userId);
    if (!sealed) return;
    const reference = embeddingFromBytes(this.deps.vault.open(sealed, faceReferenceContext(userId)));
    const { match } = await evaluatePhoto(this.deps, imageBytes, reference, this.deps.matchThreshold);
    await this.deps.photos.recordFaceMatch(photoId, match);
    await this.deps.state.refreshBadge(userId);
  }
}
