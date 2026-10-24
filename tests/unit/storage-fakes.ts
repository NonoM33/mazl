import type { S3ListPage, S3ListQuery, S3ObjectClient } from "../../src/shared/storage/s3-client";

// An in-memory S3 bucket that follows the S3 rules the adapter relies on, taken
// from the S3 ListObjectsV2 documentation and not from our adapter:
//  - `prefix` is a raw string prefix (no notion of directory),
//  - with a `delimiter`, keys below the first delimiter after the prefix are
//    rolled up and NOT returned in `objects`,
//  - results are in ascending key order and paged (`nextToken` while more),
//  - deleting a missing key succeeds.
export class FakeS3Client implements S3ObjectClient {
  readonly objects = new Map<string, { bytes: Uint8Array; modifiedAt: Date }>();
  readonly writes: string[] = [];
  readonly reads: string[] = [];
  readonly listQueries: S3ListQuery[] = [];
  failWith: Error | null = null;
  constructor(private readonly pageSize = 1000) {}

  private check(): void {
    if (this.failWith) throw this.failWith;
  }

  async read(key: string): Promise<Uint8Array | null> {
    this.check();
    this.reads.push(key);
    return this.objects.get(key)?.bytes ?? null;
  }

  async write(key: string, bytes: Uint8Array): Promise<void> {
    this.check();
    this.writes.push(key);
    this.objects.set(key, { bytes: new Uint8Array(bytes), modifiedAt: new Date("2026-03-01T10:00:00Z") });
  }

  async exists(key: string): Promise<boolean> {
    this.check();
    return this.objects.has(key);
  }

  async remove(key: string): Promise<void> {
    this.check();
    this.objects.delete(key);
  }

  async list(query: S3ListQuery): Promise<S3ListPage> {
    this.check();
    this.listQueries.push(query);
    const matching = [...this.objects.keys()]
      .filter((key) => key.startsWith(query.prefix))
      .filter((key) => query.delimiter === undefined || !key.slice(query.prefix.length).includes(query.delimiter))
      .sort();
    const start = query.continuationToken === undefined ? 0 : Number(query.continuationToken);
    const page = matching.slice(start, start + this.pageSize);
    const next = start + this.pageSize;
    return {
      objects: page.map((key) => ({ key, modifiedAt: this.objects.get(key)!.modifiedAt })),
      nextToken: next < matching.length ? String(next) : undefined,
    };
  }
}
