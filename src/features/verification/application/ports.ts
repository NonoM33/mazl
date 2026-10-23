import type { ChipFiles, ChipVerification, DetectedFace, Embedding } from "../domain/types";

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
