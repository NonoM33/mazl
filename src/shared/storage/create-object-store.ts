import { createBunS3Client } from "./bun-s3-client";
import { createDiskObjectStore } from "./disk-object-store";
import { withLegacyFallback } from "./fallback-object-store";
import type { ObjectStore } from "./object-store";
import { createS3ObjectStore } from "./s3-object-store";
import type { S3Config, StorageConfig } from "./storage-config";

// The bucket alone, without the old-disk fallback: what the copy script checks
// "already there" against.
export function createBucketObjectStore(config: S3Config): ObjectStore {
  return createS3ObjectStore(createBunS3Client(config));
}

// The store the whole app uses. With S3, files that are not in the bucket yet
// are still read from the old uploads directory (see withLegacyFallback).
export function createObjectStore(config: StorageConfig): ObjectStore {
  const disk = createDiskObjectStore(config.uploadsDir);
  if (config.kind === "disk") return disk;
  return withLegacyFallback(createBucketObjectStore(config.s3), disk);
}
