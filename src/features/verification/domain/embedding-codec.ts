import type { Embedding } from "./types";

// Fixed little-endian float32 layout, independent of the host: this is what
// gets sealed and stored, so it must stay readable forever.
export function embeddingToBytes(embedding: Embedding): Uint8Array {
  const out = new Uint8Array(embedding.length * 4);
  const view = new DataView(out.buffer);
  embedding.forEach((value, i) => view.setFloat32(i * 4, value, true));
  return out;
}

export class MalformedEmbeddingError extends Error {
  constructor(byteLength: number) {
    super(`embedding of ${byteLength} bytes is not a float32 array`);
    this.name = "MalformedEmbeddingError";
  }
}

export function embeddingFromBytes(bytes: Uint8Array): Embedding {
  if (bytes.length === 0 || bytes.length % 4 !== 0) throw new MalformedEmbeddingError(bytes.length);
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const out = new Float32Array(bytes.length / 4);
  for (let i = 0; i < out.length; i++) out[i] = view.getFloat32(i * 4, true);
  return out;
}
