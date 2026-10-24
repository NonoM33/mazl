import { S3Client } from "bun";
import type { S3Config } from "./storage-config";
import type { S3ListPage, S3ListQuery, S3ObjectClient } from "./s3-client";

function errorCode(error: unknown): string | undefined {
  if (typeof error !== "object" || error === null || !("code" in error)) return undefined;
  return typeof error.code === "string" ? error.code : undefined;
}

// Bun reports a missing object as an S3Error whose code is the S3 error code.
function isNoSuchKey(error: unknown): boolean {
  const code = errorCode(error);
  return code === "NoSuchKey" || code === "NotFound";
}

// Bun's native S3 client (no extra dependency) behind the small port the object
// store uses. ACL stays at the bucket default (private).
export function createBunS3Client(config: S3Config): S3ObjectClient {
  const client = new S3Client({
    endpoint: config.endpoint,
    bucket: config.bucket,
    accessKeyId: config.accessKeyId,
    secretAccessKey: config.secretAccessKey,
    region: config.region,
    virtualHostedStyle: !config.forcePathStyle,
  });

  return {
    async read(key) {
      try {
        return await client.file(key).bytes();
      } catch (error: unknown) {
        if (isNoSuchKey(error)) return null;
        throw error;
      }
    },

    async write(key, bytes) {
      await client.write(key, bytes);
    },

    exists: (key) => client.exists(key),

    async remove(key) {
      await client.delete(key);
    },

    async list(query: S3ListQuery): Promise<S3ListPage> {
      const response = await client.list({
        prefix: query.prefix,
        delimiter: query.delimiter,
        continuationToken: query.continuationToken,
      });
      return {
        objects: (response.contents ?? []).map((entry) => ({
          key: entry.key,
          modifiedAt: entry.lastModified === undefined ? new Date(0) : new Date(entry.lastModified),
        })),
        nextToken: response.isTruncated ? response.nextContinuationToken : undefined,
      };
    },
  };
}
