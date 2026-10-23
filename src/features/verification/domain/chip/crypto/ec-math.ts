import { InvalidKeyError } from "../errors";
import type { AffinePoint, Curve } from "./ec-curves";
import { mod, modInv, modSqrt } from "./mod-arith";

// Short-Weierstrass group law over a prime field, Jacobian coordinates
// (x = X/Z^2, y = Y/Z^3). The point at infinity has Z = 0.

interface Jacobian {
  readonly X: bigint;
  readonly Y: bigint;
  readonly Z: bigint;
}

const INFINITY: Jacobian = { X: 1n, Y: 1n, Z: 0n };

function toJacobian(pt: AffinePoint): Jacobian {
  return { X: pt.x, Y: pt.y, Z: 1n };
}

function double(c: Curve, pt: Jacobian): Jacobian {
  const { p } = c;
  if (pt.Z === 0n || pt.Y === 0n) return INFINITY;
  const yy = (pt.Y * pt.Y) % p;
  const s = (4n * pt.X * yy) % p;
  const zz = (pt.Z * pt.Z) % p;
  const m = (3n * pt.X * pt.X + c.a * zz * zz) % p;
  const x3 = mod(m * m - 2n * s, p);
  const y3 = mod(m * (s - x3) - 8n * yy * yy, p);
  return { X: x3, Y: y3, Z: (2n * pt.Y * pt.Z) % p };
}

function add(c: Curve, p1: Jacobian, p2: Jacobian): Jacobian {
  const { p } = c;
  if (p1.Z === 0n) return p2;
  if (p2.Z === 0n) return p1;
  const z1z1 = (p1.Z * p1.Z) % p;
  const z2z2 = (p2.Z * p2.Z) % p;
  const u1 = (p1.X * z2z2) % p;
  const u2 = (p2.X * z1z1) % p;
  const s1 = (p1.Y * p2.Z * z2z2) % p;
  const s2 = (p2.Y * p1.Z * z1z1) % p;
  if (u1 === u2) return s1 === s2 ? double(c, p1) : INFINITY;
  const h = mod(u2 - u1, p);
  const r = mod(s2 - s1, p);
  const hh = (h * h) % p;
  const hhh = (hh * h) % p;
  const v = (u1 * hh) % p;
  const x3 = mod(r * r - hhh - 2n * v, p);
  const y3 = mod(r * (v - x3) - s1 * hhh, p);
  return { X: x3, Y: y3, Z: (h * p1.Z * p2.Z) % p };
}

function toAffine(c: Curve, pt: Jacobian): AffinePoint | undefined {
  if (pt.Z === 0n) return undefined;
  const zInv = modInv(pt.Z, c.p);
  const zInv2 = (zInv * zInv) % c.p;
  return { x: (pt.X * zInv2) % c.p, y: (pt.Y * zInv2 * zInv) % c.p };
}

// k * pt; undefined is the point at infinity.
export function scalarMul(c: Curve, k: bigint, pt: AffinePoint): AffinePoint | undefined {
  return toAffine(c, scalarMulJacobian(c, k, pt));
}

function scalarMulJacobian(c: Curve, k: bigint, pt: AffinePoint): Jacobian {
  let acc = INFINITY;
  const base = toJacobian(pt);
  for (let i = k.toString(2).length - 1; i >= 0; i--) {
    acc = double(c, acc);
    if ((k >> BigInt(i)) & 1n) acc = add(c, acc, base);
  }
  return acc;
}

// u1*G + u2*Q; undefined is the point at infinity.
export function doubleScalarMul(c: Curve, u1: bigint, u2: bigint, q: AffinePoint): AffinePoint | undefined {
  return toAffine(c, add(c, scalarMulJacobian(c, u1, c.g), scalarMulJacobian(c, u2, q)));
}

export function isOnCurve(c: Curve, pt: AffinePoint): boolean {
  if (pt.x < 0n || pt.x >= c.p || pt.y < 0n || pt.y >= c.p) return false;
  const lhs = (pt.y * pt.y) % c.p;
  const rhs = mod(pt.x * pt.x * pt.x + c.a * pt.x + c.b, c.p);
  return lhs === rhs;
}

function fromBytes(bytes: Uint8Array): bigint {
  let n = 0n;
  for (const b of bytes) n = (n << 8n) | BigInt(b);
  return n;
}

// SEC 1 2.3.4 point decoding: uncompressed (04), compressed (02/03) and
// hybrid (06/07). Rejects anything not on the curve or not in the subgroup.
export function decodePoint(c: Curve, bytes: Uint8Array): AffinePoint {
  const len = c.fieldBytes;
  const form = bytes[0];
  let pt: AffinePoint;
  if ((form === 0x04 || form === 0x06 || form === 0x07) && bytes.length === 1 + 2 * len) {
    pt = { x: fromBytes(bytes.subarray(1, 1 + len)), y: fromBytes(bytes.subarray(1 + len)) };
    if ((form === 0x06 || form === 0x07) && Number(pt.y & 1n) !== form - 6) throw new InvalidKeyError("hybrid point parity");
  } else if ((form === 0x02 || form === 0x03) && bytes.length === 1 + len) {
    const x = fromBytes(bytes.subarray(1));
    if (x >= c.p) throw new InvalidKeyError("x out of range");
    const y = modSqrt(mod(x * x * x + c.a * x + c.b, c.p), c.p);
    if (y === undefined) throw new InvalidKeyError("x not on curve");
    pt = { x, y: Number(y & 1n) === form - 2 ? y : c.p - y };
  } else {
    throw new InvalidKeyError("bad point encoding");
  }
  assertValidPoint(c, pt);
  return pt;
}

export function assertValidPoint(c: Curve, pt: AffinePoint): void {
  if (!isOnCurve(c, pt)) throw new InvalidKeyError("point not on curve");
  // Subgroup check; needed only when the cofactor is not 1.
  if (c.h !== 1n && scalarMul(c, c.n, pt) !== undefined) throw new InvalidKeyError("point not in subgroup");
}
