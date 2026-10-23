import { open } from "../../../shared/crypto/secret-box";
import { documentContext } from "./document-context";
import type { DocumentFileStore, DocumentRepository } from "./ports";

export type ReadDocumentResult =
  | { kind: "ok"; bytes: Uint8Array; mimeType: string | null }
  | { kind: "not_found" }
  | { kind: "purged" }
  | { kind: "file_missing" };

// Decrypts on the fly; plaintext legacy files (encrypted = false) are served
// as they are until the migration script has dealt with them.
export function createReadDocument(deps: { repo: DocumentRepository; store: DocumentFileStore }) {
  return async function readDocument(documentId: number): Promise<ReadDocumentResult> {
    const doc = await deps.repo.findById(documentId);
    if (!doc) return { kind: "not_found" };
    if (doc.purgedAt !== null || doc.filename === null) return { kind: "purged" };

    const stored = await deps.store.read(doc.filename);
    if (!stored) return { kind: "file_missing" };

    const bytes = doc.encrypted ? open(stored, documentContext(doc.id)) : stored;
    return { kind: "ok", bytes, mimeType: doc.mimeType };
  };
}
