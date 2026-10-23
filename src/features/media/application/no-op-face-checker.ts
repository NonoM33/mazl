import type { PhotoFaceChecker } from "../../verification/application/ports";

// Default until the selfie-verification feature plugs its own checker in.
export const noopPhotoFaceChecker: PhotoFaceChecker = {
  async checkStoredPhoto(): Promise<void> {},
};
