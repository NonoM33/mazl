// Typed business errors of the media feature. The presentation layer maps each
// one to an HTTP status; none carries image bytes or user data.

export type PhotoRejection =
  | "undecodable"
  | "unsupported_format"
  | "too_large"
  | "empty";

export class PhotoRejectedError extends Error {
  readonly reason: PhotoRejection;
  constructor(reason: PhotoRejection) {
    super(`photo rejected: ${reason}`);
    this.name = "PhotoRejectedError";
    this.reason = reason;
  }
}

export type ImportRejection =
  | "no_picture"
  | "host_not_allowed"
  | "fetch_failed"
  | "too_large";

export class PictureImportError extends Error {
  readonly reason: ImportRejection;
  constructor(reason: ImportRejection) {
    super(`picture import refused: ${reason}`);
    this.name = "PictureImportError";
    this.reason = reason;
  }
}
