// Identity documents submitted through the web verification flow (/verify).

export const DOCUMENT_TYPES = ["selfie_id", "id_card_front", "id_card_back", "community_doc"] as const;
export type DocumentType = (typeof DOCUMENT_TYPES)[number];

export const REQUIRED_DOCUMENT_TYPES: readonly DocumentType[] = ["selfie_id", "id_card_front", "id_card_back"];

export const MAX_DOCUMENT_BYTES = 10 * 1024 * 1024;

// An undecided document is purged after this long (CONTRAT §2.4).
export const STALE_AFTER_DAYS = 30;

export type ReviewStatus = "pending" | "approved" | "rejected";
export type DecisionStatus = Exclude<ReviewStatus, "pending">;

export interface DocumentRecord {
  id: number;
  waitlistId: number;
  type: string;
  // NULL once the file has been purged.
  filename: string | null;
  mimeType: string | null;
  status: ReviewStatus;
  encrypted: boolean;
  purgedAt: Date | null;
  createdAt: Date;
}

export type DocumentErrorCode =
  | "invalid_type"
  | "empty_file"
  | "file_too_large"
  | "unsupported_format";

export class DocumentUploadError extends Error {
  constructor(readonly code: DocumentErrorCode) {
    super(`document upload rejected: ${code}`);
    this.name = "DocumentUploadError";
  }
}

export class PurgeFailedError extends Error {
  constructor(readonly failed: number) {
    super(`${failed} document file(s) could not be deleted`);
    this.name = "PurgeFailedError";
  }
}

export function isDocumentType(value: string): value is DocumentType {
  return (DOCUMENT_TYPES as readonly string[]).includes(value);
}
