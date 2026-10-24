import { normalizeKey, normalizePrefix, type ObjectStore, type StoredObject } from "./object-store";
import type { S3ObjectClient } from "./s3-client";

// Objects in a bucket, under the same keys as the files under UPLOADS_DIR.
// Objects are private: nothing here hands out a public or presigned URL, the API
// serves every file through its own routes.
export function createS3ObjectStore(client: S3ObjectClient): ObjectStore {
  return {
    // async: an invalid key rejects the promise instead of throwing synchronously.
    async put(key, bytes) {
      await client.write(normalizeKey(key), bytes);
    },
    async get(key) {
      return client.read(normalizeKey(key));
    },
    async exists(key) {
      return client.exists(normalizeKey(key));
    },
    async delete(key) {
      await client.remove(normalizeKey(key));
    },

    async list(prefix, options) {
      // A directory, not a string prefix: "chat" must not match "chatter/...".
      const directory = normalizePrefix(prefix);
      const prefixKey = directory === "" ? "" : `${directory}/`;
      const delimiter = options?.recursive === false ? "/" : undefined;
      const found: StoredObject[] = [];
      let continuationToken: string | undefined;
      do {
        const page = await client.list({ prefix: prefixKey, delimiter, continuationToken });
        for (const object of page.objects) {
          // Consoles create "folder" placeholders: keys ending with a slash.
          if (!object.key.endsWith("/")) found.push({ key: object.key, modifiedAt: object.modifiedAt });
        }
        continuationToken = page.nextToken;
      } while (continuationToken !== undefined);
      return found.sort((a, b) => (a.key < b.key ? -1 : a.key > b.key ? 1 : 0));
    },
  };
}
