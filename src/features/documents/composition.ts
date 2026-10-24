import { createPurger } from "./application/purge-documents";
import { createReadDocument } from "./application/read-document";
import { createReviewDocuments } from "./application/review-documents";
import { createUploadDocument } from "./application/upload-document";
import { createVerificationFlow } from "./application/verification-flow";
import type { DocumentFileStore, DocumentRepository } from "./application/ports";
import type { ObjectStore } from "../../shared/storage/object-store";
import { ObjectDocumentFileStore } from "./infra/object-document-file-store";
import { PostgresDocumentRepository } from "./infra/postgres-document-repository";
import { PostgresWaitlist } from "./infra/postgres-waitlist";

export function createMigrationDeps(objects: ObjectStore): { repo: DocumentRepository; store: DocumentFileStore } {
  return { repo: new PostgresDocumentRepository(), store: new ObjectDocumentFileStore(objects) };
}

export function createDocumentsModule(objects: ObjectStore) {
  const { repo, store } = createMigrationDeps(objects);
  const purger = createPurger({ repo, store });
  return {
    repo,
    purger,
    uploadDocument: createUploadDocument({ repo, store }),
    readDocument: createReadDocument({ repo, store }),
    review: createReviewDocuments({ repo, purger }),
    verificationFlow: createVerificationFlow({ repo, waitlist: new PostgresWaitlist() }),
  };
}

export type DocumentsModule = ReturnType<typeof createDocumentsModule>;
