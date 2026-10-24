// Where uploaded files live, chosen by environment:
//   nothing S3_* set  -> disk under UPLOADS_DIR (local dev, tests)
//   endpoint, bucket and both keys set -> an S3-compatible bucket (MinIO in prod)
//   anything in between -> the server refuses to start. It never falls back to
//   disk by itself: a production box with a typo in a variable name would
//   otherwise write members' documents to a volume nobody backs up.

export interface S3Config {
  readonly endpoint: string;
  readonly bucket: string;
  readonly accessKeyId: string;
  readonly secretAccessKey: string;
  readonly region: string;
  // MinIO and most self-hosted servers want http://host/bucket/key, not
  // http://bucket.host/key.
  readonly forcePathStyle: boolean;
}

export type StorageConfig =
  | { readonly kind: "disk"; readonly uploadsDir: string }
  // `uploadsDir` is the legacy directory that is still read as a fallback.
  | { readonly kind: "s3"; readonly uploadsDir: string; readonly s3: S3Config };

export class StorageConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "StorageConfigError";
  }
}

const REQUIRED = ["S3_ENDPOINT", "S3_BUCKET", "S3_ACCESS_KEY_ID", "S3_SECRET_ACCESS_KEY"] as const;
const OPTIONAL = ["S3_REGION", "S3_FORCE_PATH_STYLE"] as const;

type Env = Readonly<Record<string, string | undefined>>;

function valueOf(env: Env, name: string): string | undefined {
  const value = env[name]?.trim();
  return value === undefined || value === "" ? undefined : value;
}

function parseBoolean(name: string, raw: string | undefined, fallback: boolean): boolean {
  if (raw === undefined) return fallback;
  const lowered = raw.toLowerCase();
  if (lowered === "true" || lowered === "1") return true;
  if (lowered === "false" || lowered === "0") return false;
  throw new StorageConfigError(`${name} must be true or false`);
}

function parseEndpoint(raw: string): string {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new StorageConfigError("S3_ENDPOINT must be a URL such as https://s3.example.com");
  }
  if (url.protocol !== "https:" && url.protocol !== "http:") {
    throw new StorageConfigError("S3_ENDPOINT must be an http(s) URL");
  }
  return raw;
}

export function readStorageConfig(env: Env): StorageConfig {
  const uploadsDir = valueOf(env, "UPLOADS_DIR") ?? "uploads";
  const touched = [...REQUIRED, ...OPTIONAL].some((name) => valueOf(env, name) !== undefined);
  if (!touched) return { kind: "disk", uploadsDir };

  const missing = REQUIRED.filter((name) => valueOf(env, name) === undefined);
  if (missing.length > 0) {
    throw new StorageConfigError(
      `Incomplete S3 configuration, missing: ${missing.join(", ")}. ` +
        "Set all of S3_ENDPOINT, S3_BUCKET, S3_ACCESS_KEY_ID and S3_SECRET_ACCESS_KEY to store files in a bucket, " +
        "or none of the S3_* variables to keep them on disk.",
    );
  }
  return {
    kind: "s3",
    uploadsDir,
    s3: {
      endpoint: parseEndpoint(valueOf(env, "S3_ENDPOINT")!),
      bucket: valueOf(env, "S3_BUCKET")!,
      accessKeyId: valueOf(env, "S3_ACCESS_KEY_ID")!,
      secretAccessKey: valueOf(env, "S3_SECRET_ACCESS_KEY")!,
      region: valueOf(env, "S3_REGION") ?? "us-east-1",
      forcePathStyle: parseBoolean("S3_FORCE_PATH_STYLE", valueOf(env, "S3_FORCE_PATH_STYLE"), true),
    },
  };
}
