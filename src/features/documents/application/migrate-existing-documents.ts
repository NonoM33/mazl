import { seal } from "../../../shared/crypto/secret-box";
import { documentContext, newEncryptedFileName } from "./document-context";
import type { DocumentFileStore, DocumentRepository } from "./ports";

export interface MigrationReport {
  encrypted: number;
  purgedDecided: number;
  missingFile: number;
  failed: number;
  orphans: number;
  orphansDeleted: number;
}

export interface MigrationOptions {
  repo: DocumentRepository;
  store: DocumentFileStore;
  dryRun: boolean;
  deleteOrphans?: boolean;
}

// One-shot, idempotent: plaintext files of undecided documents are sealed and
// their originals deleted; plaintext files of documents that were already
// decided are purged (no point encrypting what must not exist any more).
// Only counts are reported, never names or addresses.
export async function migrateExistingDocuments(options: MigrationOptions): Promise<MigrationReport> {
  const { repo, store, dryRun } = options;
  const report: MigrationReport = {
    encrypted: 0, purgedDecided: 0, missingFile: 0, failed: 0, orphans: 0, orphansDeleted: 0,
  };

  for (const doc of await repo.findPlaintext()) {
    const originalName = doc.filename;
    if (originalName === null) continue;
    try {
      if (doc.status !== "pending") {
        if (!dryRun) {
          await store.remove(originalName);
          await repo.markPurged([doc.id]);
        }
        report.purgedDecided += 1;
        continue;
      }

      const plain = await store.read(originalName);
      if (!plain) {
        report.missingFile += 1;
        continue;
      }
      if (!dryRun) {
        const sealedName = newEncryptedFileName();
        await store.write(sealedName, seal(plain, documentContext(doc.id)));
        try {
          await repo.replaceWithEncrypted(doc.id, sealedName);
        } catch (error) {
          await store.remove(sealedName).catch(() => undefined);
          throw error;
        }
        await store.remove(originalName);
      }
      report.encrypted += 1;
    } catch {
      report.failed += 1;
    }
  }

  await handleOrphans(options, report);
  return report;
}

// Plaintext files in the uploads root that no row points to (left behind by
// deleted waitlist entries). Deleted only when explicitly asked to.
async function handleOrphans(options: MigrationOptions, report: MigrationReport): Promise<void> {
  const referenced = await options.repo.referencedFileNames();
  for (const name of await options.store.listLegacyFiles()) {
    if (referenced.has(name)) continue;
    report.orphans += 1;
    if (options.deleteOrphans && !options.dryRun) {
      await options.store.remove(name);
      report.orphansDeleted += 1;
    }
  }
}
