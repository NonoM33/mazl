import { detectFileKind } from "../domain/file-kind";
import { DocumentUploadError, isDocumentType, MAX_DOCUMENT_BYTES, MAX_DOCUMENTS_PER_WAITLIST } from "../domain/types";
import { seal } from "../../../shared/crypto/secret-box";
import { documentContext, newEncryptedFileName } from "./document-context";
import type { DocumentFileStore, DocumentRepository } from "./ports";

export interface UploadInput {
  waitlistId: number;
  type: string;
  bytes: Uint8Array;
}

export interface UploadResult {
  documentId: number;
  filename: string;
}

export function createUploadDocument(deps: { repo: DocumentRepository; store: DocumentFileStore }) {
  return async function uploadDocument(input: UploadInput): Promise<UploadResult> {
    if (!isDocumentType(input.type)) throw new DocumentUploadError("invalid_type");
    if (input.bytes.length === 0) throw new DocumentUploadError("empty_file");
    if (input.bytes.length > MAX_DOCUMENT_BYTES) throw new DocumentUploadError("file_too_large");
    const mimeType = detectFileKind(input.bytes);
    if (!mimeType) throw new DocumentUploadError("unsupported_format");
    // Best effort under concurrency (a burst may overshoot by a few): the cap
    // is about keeping one link from filling the disk, not an exact quota.
    if ((await deps.repo.countActive(input.waitlistId)) >= MAX_DOCUMENTS_PER_WAITLIST) {
      throw new DocumentUploadError("too_many_files");
    }

    // The row comes first: its id is part of the encryption context.
    const fileName = newEncryptedFileName();
    const documentId = await deps.repo.insert({
      waitlistId: input.waitlistId,
      type: input.type,
      fileName,
      mimeType,
    });

    try {
      await deps.store.write(fileName, seal(input.bytes, documentContext(documentId)));
    } catch (error) {
      await deps.repo.delete(documentId);
      await deps.store.remove(fileName).catch(() => undefined);
      throw error;
    }
    return { documentId, filename: fileName };
  };
}
