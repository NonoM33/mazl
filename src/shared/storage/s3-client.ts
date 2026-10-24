// The few S3 operations the object store needs. The production implementation
// wraps Bun's native S3 client (bun-s3-client.ts); tests use an in-memory one.
// Keys here are final bucket keys: validation and normalisation happen above.

export interface S3ListQuery {
  // A raw string prefix, as S3 itself reads it.
  readonly prefix: string;
  // When set, keys with that character after the prefix are rolled up and not
  // returned in `objects`.
  readonly delimiter?: string;
  readonly continuationToken?: string;
}

export interface S3ListedObject {
  readonly key: string;
  readonly modifiedAt: Date;
}

export interface S3ListPage {
  readonly objects: readonly S3ListedObject[];
  // Present while more pages remain.
  readonly nextToken?: string;
}

export interface S3ObjectClient {
  // null only when the object does not exist; every other failure rejects.
  read(key: string): Promise<Uint8Array | null>;
  write(key: string, bytes: Uint8Array): Promise<void>;
  exists(key: string): Promise<boolean>;
  // Removing a missing object succeeds.
  remove(key: string): Promise<void>;
  list(query: S3ListQuery): Promise<S3ListPage>;
}
