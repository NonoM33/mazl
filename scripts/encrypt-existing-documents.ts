// One-shot, idempotent migration of the identity documents uploaded before
// they were encrypted (CONTRAT §2.4).
//
//   bun scripts/encrypt-existing-documents.ts [--dry-run] [--delete-orphans]
//
// Needs DATABASE_URL, UPLOADS_DIR and DATA_ENCRYPTION_KEY (NODE_ENV=production
// refuses to run without the key). Prints counts only: no names, no emails.
import { sql } from "../src/db";
import { migrateExistingDocuments } from "../src/features/documents/application/migrate-existing-documents";
import { createMigrationDeps } from "../src/features/documents/composition";
import { ensureDocumentsSchema } from "../src/features/documents/infra/schema";
import { assertKeysConfigured } from "../src/shared/crypto/keys";

const args = new Set(process.argv.slice(2));
const unknown = [...args].filter((arg) => arg !== "--dry-run" && arg !== "--delete-orphans");
if (unknown.length > 0) {
  console.error(`unknown option(s): ${unknown.join(" ")}`);
  console.error("usage: bun scripts/encrypt-existing-documents.ts [--dry-run] [--delete-orphans]");
  process.exit(2);
}

const dryRun = args.has("--dry-run");
const uploadsDir = process.env.UPLOADS_DIR || "uploads";

assertKeysConfigured();
await ensureDocumentsSchema();

const report = await migrateExistingDocuments({
  ...createMigrationDeps(uploadsDir),
  dryRun,
  deleteOrphans: args.has("--delete-orphans"),
});
await sql.end();

console.log(`${dryRun ? "DRY RUN - nothing was changed. " : ""}documents migration:`);
console.log(`  encrypted: ${report.encrypted}`);
console.log(`  purged (already decided): ${report.purgedDecided}`);
console.log(`  row without file: ${report.missingFile}`);
console.log(`  failed: ${report.failed}`);
console.log(`  orphan files: ${report.orphans} (deleted: ${report.orphansDeleted})`);
process.exit(report.failed > 0 ? 1 : 0);
