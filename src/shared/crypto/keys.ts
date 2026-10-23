import { createHash } from "node:crypto";

// Server-side keys for data protection. Each key is 32 random bytes, base64.
// Generate one with:  bun -e 'console.log(crypto.getRandomValues(new Uint8Array(32)).toBase64())'
//
// In production a missing or malformed key stops the boot: falling back to a
// constant would silently encrypt identity documents with a key that is
// published in the repository. Outside production a per-name development key
// is derived so that local runs and tests work without configuration.

export type KeyName = "DATA_ENCRYPTION_KEY" | "MEDIA_SIGNING_KEY" | "DOC_FINGERPRINT_KEY";

const KEY_BYTES = 32;
const cache = new Map<KeyName, Buffer>();

export class MissingKeyError extends Error {
  constructor(name: KeyName, reason: string) {
    super(`${name}: ${reason}`);
    this.name = "MissingKeyError";
  }
}

function isProduction(): boolean {
  return process.env.NODE_ENV === "production";
}

function developmentKey(name: KeyName): Buffer {
  return createHash("sha256").update(`mazl-development-only:${name}`).digest();
}

function decode(name: KeyName, raw: string): Buffer {
  const key = Buffer.from(raw, "base64");
  if (key.length !== KEY_BYTES) {
    throw new MissingKeyError(name, `expected ${KEY_BYTES} bytes of base64, got ${key.length}`);
  }
  return key;
}

export function getKey(name: KeyName): Buffer {
  const cached = cache.get(name);
  if (cached) return cached;

  const raw = process.env[name];
  let key: Buffer;
  if (raw && raw.length > 0) {
    key = decode(name, raw);
  } else if (isProduction()) {
    throw new MissingKeyError(name, "must be set in production");
  } else {
    key = developmentKey(name);
  }
  cache.set(name, key);
  return key;
}

// Called once at boot so that a production deployment without keys fails
// immediately instead of on the first identity document.
export function assertKeysConfigured(): void {
  for (const name of ["DATA_ENCRYPTION_KEY", "MEDIA_SIGNING_KEY", "DOC_FINGERPRINT_KEY"] as const) {
    getKey(name);
  }
}

// Test hook: environment changes are otherwise hidden by the cache.
export function resetKeyCacheForTests(): void {
  cache.clear();
}
