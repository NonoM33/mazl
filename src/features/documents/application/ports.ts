import type { DecisionStatus, DocumentRecord, DocumentType } from "../domain/types";

export interface NewDocument {
  waitlistId: number;
  type: DocumentType;
  fileName: string;
  mimeType: string;
}

export interface PurgeTarget {
  id: number;
  filename: string | null;
}

export type PurgeScope = { ids: readonly number[] } | { waitlistId: number } | "all";

export interface DocumentRepository {
  // Rows are created encrypted: the plaintext path no longer exists.
  insert(doc: NewDocument): Promise<number>;
  delete(id: number): Promise<void>;
  findById(id: number): Promise<DocumentRecord | null>;
  latestByType(waitlistId: number): Promise<Record<string, DocumentRecord>>;
  typesByIds(waitlistId: number, ids: readonly number[]): Promise<string[]>;
  // Documents of the waitlist entry whose file has not been purged.
  countActive(waitlistId: number): Promise<number>;

  decide(params: {
    ids: readonly number[];
    waitlistId?: number;
    status: DecisionStatus;
    notes: string | null;
  }): Promise<void>;
  approveAllNotRejected(waitlistId: number): Promise<void>;
  rejectAll(waitlistId: number, notes: string | null): Promise<void>;

  findDecidedUnpurged(scope: PurgeScope): Promise<PurgeTarget[]>;
  findStaleUndecided(maxAgeDays: number): Promise<PurgeTarget[]>;
  // Sets filename = NULL, original_name = NULL, purged_at = NOW().
  markPurged(ids: readonly number[]): Promise<void>;

  findPlaintext(): Promise<DocumentRecord[]>;
  replaceWithEncrypted(id: number, fileName: string): Promise<void>;
  referencedFileNames(): Promise<Set<string>>;
}

// Plain byte storage. Sealing is the application layer's job, so this port can
// only ever see ciphertext for new documents.
export interface DocumentFileStore {
  write(fileName: string, bytes: Uint8Array): Promise<void>;
  // null when the file does not exist.
  read(fileName: string): Promise<Uint8Array | null>;
  // Idempotent: a file that is already gone is not an error.
  remove(fileName: string): Promise<void>;
  // Legacy plaintext files sitting directly in the uploads root.
  listLegacyFiles(): Promise<string[]>;
}

export interface WaitlistEntry {
  id: number;
  email: string;
  verificationStatus: string;
}

export interface WaitlistPort {
  findByVerificationToken(token: string): Promise<WaitlistEntry | null>;
  setOs(waitlistId: number, os: "ios" | "android"): Promise<void>;
  markSubmitted(waitlistId: number): Promise<void>;
}
