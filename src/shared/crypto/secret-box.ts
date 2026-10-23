import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto";
import { getKey } from "./keys";

// Authenticated encryption at rest (AES-256-GCM) for identity documents and
// face references. Layout of a sealed value:
//   [1 byte version = 0x01][12 bytes IV][ciphertext][16 bytes GCM tag]
// `context` is bound as additional authenticated data: a value sealed for one
// purpose (e.g. "face-reference:42") cannot be replayed as another.

const VERSION = 0x01;
const IV_BYTES = 12;
const TAG_BYTES = 16;
const HEADER_BYTES = 1 + IV_BYTES;

export class SealedDataError extends Error {
  constructor(reason: string) {
    super(`sealed data rejected: ${reason}`);
    this.name = "SealedDataError";
  }
}

export function seal(plaintext: Uint8Array, context: string): Buffer {
  const iv = randomBytes(IV_BYTES);
  const cipher = createCipheriv("aes-256-gcm", getKey("DATA_ENCRYPTION_KEY"), iv);
  cipher.setAAD(Buffer.from(context, "utf8"));
  const body = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  return Buffer.concat([Buffer.from([VERSION]), iv, body, cipher.getAuthTag()]);
}

export function open(sealed: Uint8Array, context: string): Buffer {
  const data = Buffer.from(sealed);
  if (data.length < HEADER_BYTES + TAG_BYTES) throw new SealedDataError("too short");
  if (data[0] !== VERSION) throw new SealedDataError(`unknown version ${data[0]}`);

  const iv = data.subarray(1, HEADER_BYTES);
  const tag = data.subarray(data.length - TAG_BYTES);
  const body = data.subarray(HEADER_BYTES, data.length - TAG_BYTES);
  const decipher = createDecipheriv("aes-256-gcm", getKey("DATA_ENCRYPTION_KEY"), iv);
  decipher.setAAD(Buffer.from(context, "utf8"));
  decipher.setAuthTag(tag);
  try {
    return Buffer.concat([decipher.update(body), decipher.final()]);
  } catch {
    throw new SealedDataError("authentication failed (wrong key, context or tampered data)");
  }
}
