import { sha256Ascii } from "./sha256";

// Finds `nonce` so that SHA-256(`${challenge}:${nonce}`) starts with
// `difficulty` zero bits (src/features/web-session/domain/pow.ts). Works in
// slices so the page stays responsive while the QR code is being prepared.

export function zeroBits(digest: Uint8Array): number {
  let bits = 0;
  for (const byte of digest) {
    if (byte === 0) { bits += 8; continue; }
    return bits + Math.clz32(byte) - 24;
  }
  return bits;
}

export function solveSlice(challenge: string, difficulty: number, from: number, count: number): string | null {
  for (let n = from; n < from + count; n++) {
    const nonce = n.toString(36);
    if (zeroBits(sha256Ascii(`${challenge}:${nonce}`)) >= difficulty) return nonce;
  }
  return null;
}

export async function solve(challenge: string, difficulty: number, signal?: AbortSignal): Promise<string> {
  const slice = 4096;
  for (let from = 0; ; from += slice) {
    if (signal?.aborted) throw new DOMException("aborted", "AbortError");
    const found = solveSlice(challenge, difficulty, from, slice);
    if (found !== null) return found;
    await new Promise((resolve) => setTimeout(resolve, 0));
  }
}
