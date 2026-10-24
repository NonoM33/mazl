// Synchronous SHA-256 (FIPS 180-4) of an ASCII string. crypto.subtle is
// asynchronous, one promise per hash, far too slow for a proof of work that
// tries some 260,000 nonces.

const K = new Uint32Array([
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
]);
const W = new Uint32Array(64);

const rotr = (x: number, n: number) => (x >>> n) | (x << (32 - n));

function compress(state: Uint32Array, block: Uint8Array, offset: number): void {
  for (let i = 0; i < 16; i++) {
    const j = offset + i * 4;
    W[i] = ((block[j] ?? 0) << 24) | ((block[j + 1] ?? 0) << 16) | ((block[j + 2] ?? 0) << 8) | (block[j + 3] ?? 0);
  }
  for (let i = 16; i < 64; i++) {
    const w15 = W[i - 15] ?? 0;
    const w2 = W[i - 2] ?? 0;
    const s0 = rotr(w15, 7) ^ rotr(w15, 18) ^ (w15 >>> 3);
    const s1 = rotr(w2, 17) ^ rotr(w2, 19) ^ (w2 >>> 10);
    W[i] = ((W[i - 16] ?? 0) + s0 + (W[i - 7] ?? 0) + s1) | 0;
  }
  let a = state[0] ?? 0, b = state[1] ?? 0, c = state[2] ?? 0, d = state[3] ?? 0;
  let e = state[4] ?? 0, f = state[5] ?? 0, g = state[6] ?? 0, h = state[7] ?? 0;
  for (let i = 0; i < 64; i++) {
    const t1 = (h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + (K[i] ?? 0) + (W[i] ?? 0)) | 0;
    const t2 = ((rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c))) | 0;
    h = g; g = f; f = e; e = (d + t1) | 0; d = c; c = b; b = a; a = (t1 + t2) | 0;
  }
  const words = [a, b, c, d, e, f, g, h];
  for (let i = 0; i < 8; i++) state[i] = ((state[i] ?? 0) + (words[i] ?? 0)) | 0;
}

export function sha256Ascii(text: string): Uint8Array {
  const length = text.length;
  const padded = new Uint8Array((((length + 8) >> 6) + 1) << 6);
  for (let i = 0; i < length; i++) padded[i] = text.charCodeAt(i) & 0xff;
  padded[length] = 0x80;
  const bits = length * 8;
  const end = padded.length;
  padded[end - 4] = (bits >>> 24) & 0xff;
  padded[end - 3] = (bits >>> 16) & 0xff;
  padded[end - 2] = (bits >>> 8) & 0xff;
  padded[end - 1] = bits & 0xff;
  const state = new Uint32Array([0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]);
  for (let offset = 0; offset < end; offset += 64) compress(state, padded, offset);
  const out = new Uint8Array(32);
  for (let i = 0; i < 8; i++) {
    const word = state[i] ?? 0;
    out[i * 4] = word >>> 24; out[i * 4 + 1] = (word >>> 16) & 0xff; out[i * 4 + 2] = (word >>> 8) & 0xff; out[i * 4 + 3] = word & 0xff;
  }
  return out;
}
