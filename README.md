# mazl

To install dependencies:

```bash
bun install
```

To run:

```bash
bun run index.ts
```

This project was created using `bun init` in bun v1.3.1. [Bun](https://bun.com) is a fast all-in-one JavaScript runtime.

## File storage (photos, chat files, identity documents)

By default files go to the disk, under `UPLOADS_DIR` (default `uploads`). Set all of
the following to store them in an S3-compatible bucket (MinIO in production) instead:

| variable | meaning |
|---|---|
| `S3_ENDPOINT` | e.g. `https://s3.example.com` |
| `S3_BUCKET` | bucket name (must exist) |
| `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` | credentials |
| `S3_REGION` | default `us-east-1` |
| `S3_FORCE_PATH_STYLE` | default `true` (`http://host/bucket/key`, what MinIO expects) |

A partial S3 configuration stops the server at boot; it never falls back to disk by
itself. Objects are private and keep the key of their old path under `UPLOADS_DIR`.
While files remain on the old disk, a file missing from the bucket is read from
`UPLOADS_DIR` (and deletes hit both). Copy them with
`bun scripts/migrate-uploads-to-s3.ts [--dry-run]` (idempotent, never deletes local files).

Tests: `cd tests/unit && bun test ./storage-*.test.ts`; the one against a real server runs
when `S3_TEST_ENDPOINT` is set (with `S3_TEST_BUCKET`, `S3_TEST_ACCESS_KEY_ID`,
`S3_TEST_SECRET_ACCESS_KEY`).
