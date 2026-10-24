// One-shot, idempotent copy of the uploads directory into the S3 bucket.
//
//   bun scripts/migrate-uploads-to-s3.ts [--dry-run]
//
// Needs UPLOADS_DIR (the directory to copy, default "uploads") and the S3_*
// variables of the server (S3_ENDPOINT, S3_BUCKET, S3_ACCESS_KEY_ID,
// S3_SECRET_ACCESS_KEY, optional S3_REGION and S3_FORCE_PATH_STYLE).
//
// Every file is uploaded under the same key as its path relative to UPLOADS_DIR,
// unless the bucket already has that key (so it can run again, and while the
// server is up: the server reads missing objects from the old directory in the
// meantime). Local files are never deleted or changed. Prints counts, plus the
// keys that failed; exits 1 when some failed, 2 on a usage or configuration error.
import { copyMissingObjects } from "../src/shared/storage/copy-missing-objects";
import { createBucketObjectStore } from "../src/shared/storage/create-object-store";
import { createDiskObjectStore } from "../src/shared/storage/disk-object-store";
import { readStorageConfig, StorageConfigError } from "../src/shared/storage/storage-config";

const args = process.argv.slice(2);
const unknown = args.filter((arg) => arg !== "--dry-run");
if (unknown.length > 0) {
  console.error(`unknown option(s): ${unknown.join(" ")}`);
  console.error("usage: bun scripts/migrate-uploads-to-s3.ts [--dry-run]");
  process.exit(2);
}
const dryRun = args.includes("--dry-run");

let config;
try {
  config = readStorageConfig(process.env);
} catch (error: unknown) {
  console.error(error instanceof StorageConfigError ? error.message : "cannot read the storage configuration");
  process.exit(2);
}
if (config.kind !== "s3") {
  console.error("S3 is not configured: set S3_ENDPOINT, S3_BUCKET, S3_ACCESS_KEY_ID and S3_SECRET_ACCESS_KEY.");
  process.exit(2);
}

const report = await copyMissingObjects({
  source: createDiskObjectStore(config.uploadsDir),
  target: createBucketObjectStore(config.s3),
  dryRun,
});

console.log(`${dryRun ? "DRY RUN - nothing was uploaded. " : ""}uploads to bucket "${config.s3.bucket}":`);
console.log(`  files scanned: ${report.scanned}`);
console.log(`  ${dryRun ? "would upload" : "uploaded"}: ${report.uploaded} (${report.bytesUploaded} bytes)`);
console.log(`  already in the bucket: ${report.alreadyPresent}`);
console.log(`  temporary .partial files skipped: ${report.skippedPartial}`);
console.log(`  failed: ${report.failed.length}`);
for (const key of report.failed) console.log(`    ${key}`);
process.exit(report.failed.length > 0 ? 1 : 0);
