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

## Push notifications (OneSignal)

| variable | meaning |
|---|---|
| `ONESIGNAL_REST_API_KEY` | REST API key. Absent: nothing is sent and no query is made for a push. |
| `ONESIGNAL_APP_ID` | OneSignal app (default: the production app). |
| `ONESIGNAL_API_BASE` | Stand-in server for tests only (refused when `NODE_ENV=production`). |

A member is addressed as `user_<id>`, the identifier the app gives `OneSignal.login`. Pushes: a new match (both
members), a message (only to a recipient with no open WebSocket, grouped by conversation), a couple request and
its acceptance. The contract (`data` fields, wording rules) is in `docs/launch/V1-CONTRAT.md` section 1; the code is
in `src/features/push/`. A blocked, banned, restricted or inactive member triggers nothing.

## Tests

| command | what it runs |
|---|---|
| `bun run test:unit` | `tests/unit`: no server, no database |
| `bun run typecheck` | `tsc` on the API, the console and the landing |
| `bun run test:integration` (`bun scripts/test-integration.ts`) | `tests/*.test.ts` against a real server |
| `bun scripts/test-integration.ts tests/chat-security.test.ts [...]` | the same, only those files |

The integration run is self-contained and leaves nothing behind. It needs Docker and nothing else:

- a throwaway Postgres 16 (docker, a free local port, removed at the end);
- the API server in `NODE_ENV=test` (that is what enables the sample members, the couple catalogue and
  the `/api/dev/*` routes the suites use), with every secret drawn at random;
- the fake Stripe of `tests/support/` (`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_API_BASE`, the
  `STRIPE_PRICE_*` and `FAKE_STRIPE_URL`), so the billing suites never reach api.stripe.com;
- no `RESEND_API_KEY` and no `ONESIGNAL_REST_API_KEY`: no e-mail and no push is ever sent.

Logs are written to `.integ/` (`server.log`, `stripe.log`, `integ.log`, ignored by git). Suites that must start
from an empty database or may destroy data (`seed-data-gate`, `purge-seed-data`) create a database of their own
inside the throwaway Postgres (`tests/support/scratch-database.ts`).

Sample data (20 fake members with provider `seed`, a fictitious couple catalogue) exists only when `NODE_ENV` is
`development` or `test`. Databases started by older releases are cleaned with
`DATABASE_URL=... bun scripts/purge-seed-data.ts` (dry-run by default, `--apply` to delete, in one transaction).
