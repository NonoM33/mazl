import type { FaceReferenceStore, ProfilePhotoStore, VerificationStateRepository } from "./ports";

export interface DeleteFaceReferenceDeps {
  readonly references: FaceReferenceStore;
  readonly photos: ProfilePhotoStore;
  readonly state: VerificationStateRepository;
}

// Withdrawal of consent: the face reference goes, and the badge with it.
export async function deleteFaceReference(deps: DeleteFaceReferenceDeps, userId: number): Promise<void> {
  await deps.references.remove(userId);
  await deps.photos.clearFaceMatches(userId);
  await deps.state.clearPhotoVerified(userId);
}
