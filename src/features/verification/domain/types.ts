// Shared vocabulary of the verification feature (levels 1 and 2).
// CONTRACT: docs/verification/CONTRAT.md. Changing a name here changes the API.

// ---------- Level 1: live selfie ----------

// A pose the user is asked to hold in one frame. "left"/"right" are only
// checked relative to each other (opposite yaw signs), never against an
// absolute direction: front cameras mirror differently across devices.
export type Challenge = "front" | "left" | "right";

export type FacePurpose = "photo" | "identity";

export interface Point {
  readonly x: number;
  readonly y: number;
}

// One detected face, in pixel coordinates of the decoded image.
// Landmarks follow YuNet's order.
export interface DetectedFace {
  readonly box: { readonly x: number; readonly y: number; readonly width: number; readonly height: number };
  readonly score: number;
  readonly landmarks: {
    readonly rightEye: Point;
    readonly leftEye: Point;
    readonly nose: Point;
    readonly rightMouth: Point;
    readonly leftMouth: Point;
  };
}

// L2-normalised face embedding (SFace: 128 floats).
export type Embedding = Float32Array;

// Machine-readable refusal reasons. The mobile app translates them; the
// server never returns free text that could leak scores or internals.
export type FaceRejection =
  | "session_not_found"
  | "session_expired"
  | "session_used"
  | "wrong_frame_count"
  | "invalid_image"
  | "no_face"
  | "multiple_faces"
  | "face_too_small"
  | "pose_mismatch"
  | "duplicate_frames"
  | "inconsistent_identity"
  | "no_profile_photo"
  | "profile_mismatch"
  | "daily_limit_reached";

export type IdentityRejection =
  | FaceRejection
  | "chip_data_invalid"
  | "chip_signature_invalid"
  | "csca_unknown"
  | "document_expired"
  | "underage"
  | "document_already_used"
  | "document_banned"
  | "document_face_mismatch";

// ---------- Level 2: chip of the passport / ID card (ICAO 9303) ----------

// Raw elementary files read from the chip, exactly as returned by the card.
export interface ChipFiles {
  readonly dg1: Uint8Array;
  readonly dg2: Uint8Array;
  readonly sod: Uint8Array;
}

// What we keep from DG1 after passive authentication. Names are deliberately
// absent: we never store them.
export interface ChipIdentity {
  readonly documentType: string; // "P", "I", "ID"...
  readonly issuingState: string; // ICAO 3-letter code, e.g. "FRA"
  readonly documentNumber: string; // used only to compute the fingerprint, never stored
  readonly birthDate: string; // ISO yyyy-mm-dd
  readonly expiryDate: string; // ISO yyyy-mm-dd
  readonly sex: "M" | "F" | "X";
}

export type ChipVerification =
  | { readonly ok: true; readonly identity: ChipIdentity; readonly faceImage: Uint8Array; readonly faceImageFormat: "jpeg" | "jp2" }
  | { readonly ok: false; readonly reason: "chip_data_invalid" | "chip_signature_invalid" | "csca_unknown" };

// ---------- Status returned to the app ----------

export type VerificationLevel = "none" | "photo" | "identity";
