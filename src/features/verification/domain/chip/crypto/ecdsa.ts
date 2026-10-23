import { decodeUnsignedInteger, TAG } from "../asn1";
import { TlvError } from "../errors";
import { children, parseTlv, value } from "../tlv";
import type { AffinePoint, Curve } from "./ec-curves";
import { doubleScalarMul } from "./ec-math";
import { mod, modInv } from "./mod-arith";

// ECDSA verification (ANSI X9.62 / FIPS 186-4 6.4), any prime curve.

export interface EcdsaSignature {
  readonly r: bigint;
  readonly s: bigint;
}

function fromBytes(bytes: Uint8Array): bigint {
  let n = 0n;
  for (const b of bytes) n = (n << 8n) | BigInt(b);
  return n;
}

// SEQUENCE { INTEGER r, INTEGER s } with minimal INTEGER encodings. Returns
// undefined if the bytes are not exactly that.
export function parseDerSignature(bytes: Uint8Array): EcdsaSignature | undefined {
  try {
    const seq = parseTlv(bytes);
    if (seq.tag !== TAG.sequence) return undefined;
    const [r, s, extra] = children(seq);
    if (r === undefined || s === undefined || extra !== undefined) return undefined;
    for (const k of [r, s]) {
      const v = value(k);
      if (v.length > 1 && v[0] === 0 && ((v[1] as number) & 0x80) === 0) return undefined; // padding
    }
    return { r: decodeUnsignedInteger(r), s: decodeUnsignedInteger(s) };
  } catch (e) {
    if (e instanceof TlvError) return undefined;
    throw e;
  }
}

// IEEE P1363 / BSI TR-03111 plain format: r || s, each orderBytes long.
export function parsePlainSignature(bytes: Uint8Array, orderBytes: number): EcdsaSignature | undefined {
  if (bytes.length !== 2 * orderBytes) return undefined;
  return { r: fromBytes(bytes.subarray(0, orderBytes)), s: fromBytes(bytes.subarray(orderBytes)) };
}

export type SignatureFormat = "der" | "plain" | "auto";

export function candidateSignatures(bytes: Uint8Array, format: SignatureFormat, orderBytes: number): EcdsaSignature[] {
  const out: EcdsaSignature[] = [];
  if (format !== "plain") {
    const der = parseDerSignature(bytes);
    if (der) out.push(der);
  }
  if (format !== "der") {
    const plain = parsePlainSignature(bytes, orderBytes);
    if (plain) out.push(plain);
  }
  return out;
}

// Leftmost orderBits bits of the digest (FIPS 186-4 6.4, step 2).
function digestToInteger(c: Curve, digest: Uint8Array): bigint {
  const e = fromBytes(digest);
  const excess = digest.length * 8 - c.orderBits;
  return excess > 0 ? e >> BigInt(excess) : e;
}

export function verifyEcdsa(c: Curve, publicKey: AffinePoint, digest: Uint8Array, sig: EcdsaSignature): boolean {
  const { r, s } = sig;
  if (r < 1n || r >= c.n || s < 1n || s >= c.n) return false;
  const w = modInv(s, c.n);
  const e = digestToInteger(c, digest);
  const u1 = mod(e * w, c.n);
  const u2 = mod(r * w, c.n);
  const pt = doubleScalarMul(c, u1, u2, publicKey);
  if (pt === undefined) return false;
  return mod(pt.x, c.n) === r;
}
