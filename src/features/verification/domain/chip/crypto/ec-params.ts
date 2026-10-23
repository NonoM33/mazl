import { decodeOctetString, decodeOid, decodeUnsignedInteger, TAG, bytesToBigInt } from "../asn1";
import { InvalidKeyError, UnsupportedAlgorithmError } from "../errors";
import { OID } from "../oids";
import { children, expectTag, type Tlv } from "../tlv";
import { curveByOid, makeCurve, namedCurves, sameCurve, type AffinePoint, type Curve } from "./ec-curves";
import { isOnCurve, scalarMul } from "./ec-math";
import { bitLength, isProbablePrime, isqrt, mod } from "./mod-arith";

// EcpkParameters (RFC 3279 2.3.5 / RFC 5480 2.1.1): a named curve OID or
// explicit ECParameters. Explicit parameters are what many ePassports carry,
// including for brainpool curves.

// Explicit parameters are untrusted input until proven coherent.
function validateExplicit(c: Curve): void {
  const bits = bitLength(c.p);
  if (bits < 160 || bits > 521) throw new InvalidKeyError("field size");
  if (!isProbablePrime(c.p) || c.p % 2n === 0n) throw new InvalidKeyError("p not prime");
  if (c.a >= c.p || c.b >= c.p) throw new InvalidKeyError("a or b out of range");
  if (mod(4n * c.a ** 3n + 27n * c.b ** 2n, c.p) === 0n) throw new InvalidKeyError("singular curve");
  if (c.n < 2n || !isProbablePrime(c.n) || c.n === c.p) throw new InvalidKeyError("bad order");
  if (c.h < 1n || c.h > 8n) throw new InvalidKeyError("bad cofactor");
  // Hasse bound: |p + 1 - n*h| <= 2*sqrt(p).
  const delta = c.p + 1n - c.n * c.h;
  if ((delta < 0n ? -delta : delta) > 2n * isqrt(c.p) + 2n) throw new InvalidKeyError("order violates Hasse bound");
  if (!isOnCurve(c, c.g)) throw new InvalidKeyError("generator not on curve");
  if (scalarMul(c, c.n, c.g) !== undefined) throw new InvalidKeyError("generator order mismatch");
}

function parseExplicit(params: Tlv): Curve {
  const [version, fieldId, curve, base, order, cofactor] = children(params);
  if (decodeUnsignedInteger(expectTag(version, TAG.integer, "ECParameters version")) !== 1n) throw new InvalidKeyError("version");
  const [fieldType, primeTlv] = children(expectTag(fieldId, TAG.sequence, "FieldID"));
  if (decodeOid(expectTag(fieldType, TAG.oid, "fieldType")) !== OID.primeField) throw new UnsupportedAlgorithmError("non-prime field");
  const p = decodeUnsignedInteger(expectTag(primeTlv, TAG.integer, "prime"));
  const [aTlv, bTlv] = children(expectTag(curve, TAG.sequence, "Curve"));
  const a = bytesToBigInt(decodeOctetString(expectTag(aTlv, TAG.octetString, "a")));
  const b = bytesToBigInt(decodeOctetString(expectTag(bTlv, TAG.octetString, "b")));
  const g = decodeOctetString(expectTag(base, TAG.octetString, "base"));
  const n = decodeUnsignedInteger(expectTag(order, TAG.integer, "order"));
  const h = cofactor === undefined ? 1n : decodeUnsignedInteger(expectTag(cofactor, TAG.integer, "cofactor"));
  const half = (g.length - 1) / 2;
  if (g[0] !== 0x04 || !Number.isInteger(half) || half !== Math.ceil(bitLength(p) / 8)) throw new InvalidKeyError("base point encoding");
  const point: AffinePoint = { x: bytesToBigInt(g.subarray(1, 1 + half)), y: bytesToBigInt(g.subarray(1 + half)) };
  const explicit = makeCurve("explicit", p, a, b, point, n, h);
  // Known parameter sets skip the (costly) proof of coherence.
  for (const known of namedCurves()) if (sameCurve(known, explicit)) return known;
  if (cofactor === undefined) throw new InvalidKeyError("cofactor missing on unknown curve");
  validateExplicit(explicit);
  return explicit;
}

export function parseEcParameters(params: Tlv | undefined): Curve {
  if (params === undefined) throw new InvalidKeyError("missing EC parameters");
  if (params.tag === TAG.oid) {
    const curve = curveByOid(decodeOid(params));
    if (curve === undefined) throw new UnsupportedAlgorithmError("named curve");
    return curve;
  }
  if (params.tag === TAG.sequence) return parseExplicit(params);
  throw new UnsupportedAlgorithmError("implicit curve parameters");
}
