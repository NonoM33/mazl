import { createHash, createPublicKey, generateKeyPairSync, sign } from "node:crypto";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, test } from "bun:test";
import { bigIntToBytes } from "../../src/features/verification/domain/chip/asn1";
import { InvalidKeyError, UnsupportedAlgorithmError } from "../../src/features/verification/domain/chip/errors";
import { candidateSignatures, parseDerSignature, verifyEcdsa } from "../../src/features/verification/domain/chip/crypto/ecdsa";
import { curveByOid, namedCurves, type Curve } from "../../src/features/verification/domain/chip/crypto/ec-curves";
import { decodePoint, isOnCurve, scalarMul } from "../../src/features/verification/domain/chip/crypto/ec-math";
import { parseEcParameters } from "../../src/features/verification/domain/chip/crypto/ec-params";
import { isProbablePrime, modSqrt } from "../../src/features/verification/domain/chip/crypto/mod-arith";
import { encodeTlv, parseTlv } from "../../src/features/verification/domain/chip/tlv";

const hex = (s: string): Uint8Array => new Uint8Array(Buffer.from(s, "hex"));

describe("named curve parameter tables", () => {
  const curves = namedCurves();
  test("nine curves are available", () => {
    expect(curves.map((c) => c.name).sort()).toEqual(
      ["brainpoolP224r1", "brainpoolP256r1", "brainpoolP320r1", "brainpoolP384r1", "brainpoolP512r1", "secp224r1", "secp256r1", "secp384r1", "secp521r1"].sort(),
    );
  });
  for (const c of curves) {
    test(`${c.name}: p and n prime, G on curve, n*G = infinity, (n+1)*G = G`, () => {
      expect(isProbablePrime(c.p)).toBe(true);
      expect(isProbablePrime(c.n)).toBe(true);
      expect(isOnCurve(c, c.g)).toBe(true);
      expect(scalarMul(c, c.n, c.g)).toBeUndefined();
      expect(scalarMul(c, c.n + 1n, c.g)).toEqual(c.g);
      expect(scalarMul(c, c.n - 1n, c.g)).toEqual({ x: c.g.x, y: c.p - c.g.y });
    });
  }
  test("brainpoolP256r1 matches RFC 5639 section 3.4 (p, order and generator x)", () => {
    const c = curveByOid("1.3.36.3.3.2.8.1.1.7") as Curve;
    expect(c.p.toString(16)).toBe("a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5377");
    expect(c.n.toString(16)).toBe("a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e82974856a7");
    expect(c.g.x.toString(16)).toBe("8bd2aeb9cb7e57cb2c4b482ffc81b7afb9de27e1e3bd23c23a4453bd9ace3262");
  });
});

describe("modular square root (point decompression)", () => {
  test("p = 1 mod 4 (secp224r1) uses Tonelli-Shanks", () => {
    const c = curveByOid("1.3.132.0.33") as Curve;
    expect(c.p % 4n).toBe(1n);
    const root = modSqrt(c.g.y * c.g.y, c.p);
    expect(root === c.g.y || root === c.p - c.g.y).toBe(true);
  });
  test("a non-residue has no root", () => {
    expect(modSqrt(3n, 7n)).toBeUndefined(); // squares mod 7: 1, 2, 4
  });
});

function pointBytes(c: Curve, form: "uncompressed" | "compressed"): Uint8Array {
  const x = bigIntToBytes(c.g.x, c.fieldBytes);
  if (form === "compressed") return Uint8Array.of(0x02 + Number(c.g.y & 1n), ...x);
  return Uint8Array.of(0x04, ...x, ...bigIntToBytes(c.g.y, c.fieldBytes));
}

describe("point decoding rejects invalid points", () => {
  const c = curveByOid("1.3.36.3.3.2.8.1.1.7") as Curve;
  test("uncompressed and compressed generator decode to G", () => {
    expect(decodePoint(c, pointBytes(c, "uncompressed"))).toEqual(c.g);
    expect(decodePoint(c, pointBytes(c, "compressed"))).toEqual(c.g);
  });
  test("compressed decoding works on every named curve", () => {
    for (const curve of namedCurves()) expect(decodePoint(curve, pointBytes(curve, "compressed"))).toEqual(curve.g);
  });
  test("a point off the curve", () => {
    const bad = pointBytes(c, "uncompressed").slice();
    bad[bad.length - 1] = (bad[bad.length - 1] as number) ^ 1;
    expect(() => decodePoint(c, bad)).toThrow(InvalidKeyError);
  });
  test("coordinates >= p", () => {
    const bad = Uint8Array.of(0x04, ...bigIntToBytes(c.p, c.fieldBytes), ...bigIntToBytes(c.g.y, c.fieldBytes));
    expect(() => decodePoint(c, bad)).toThrow(InvalidKeyError);
  });
  test("point at infinity, wrong length, unknown prefix", () => {
    expect(() => decodePoint(c, Uint8Array.of(0x00))).toThrow(InvalidKeyError);
    expect(() => decodePoint(c, pointBytes(c, "uncompressed").slice(0, 40))).toThrow(InvalidKeyError);
    expect(() => decodePoint(c, Uint8Array.of(0x05, ...pointBytes(c, "uncompressed").slice(1)))).toThrow(InvalidKeyError);
    expect(() => decodePoint(c, new Uint8Array(0))).toThrow(InvalidKeyError);
  });
  test("compressed x with no square root", () => {
    for (let x = 1n; x < 50n; x++) {
      const enc = Uint8Array.of(0x02, ...bigIntToBytes(x, c.fieldBytes));
      try {
        decodePoint(c, enc);
      } catch (e) {
        expect(e).toBeInstanceOf(InvalidKeyError);
        return;
      }
    }
    throw new Error("expected at least one non-residue x");
  });
});

interface WycheproofFile {
  file: string;
  format: "der" | "p1363";
  groups: Array<{ key: string; curve: string; sha: string; tests: Array<{ id: number; comment: string; msg: string; sig: string; result: "valid" | "invalid" }> }>;
}

describe("Wycheproof ECDSA vectors (own BigInt implementation)", () => {
  const data = JSON.parse(readFileSync(join(import.meta.dir, "..", "fixtures", "chip", "wycheproof-ecdsa-subset.json"), "utf8")) as { files: WycheproofFile[] };
  for (const file of data.files) {
    test(file.file, () => {
      let valid = 0;
      let invalid = 0;
      for (const group of file.groups) {
        const curve = namedCurves().find((c) => c.name === group.curve) as Curve;
        const point = decodePoint(curve, hex(group.key));
        const algo = group.sha.replace("-", "").toLowerCase();
        for (const t of group.tests) {
          const digest = new Uint8Array(createHash(algo).update(hex(t.msg)).digest());
          const sigs = candidateSignatures(hex(t.sig), file.format === "der" ? "der" : "plain", curve.orderBytes);
          const ok = sigs.some((s) => verifyEcdsa(curve, point, digest, s));
          expect({ id: t.id, comment: t.comment, ok }).toEqual({ id: t.id, comment: t.comment, ok: t.result === "valid" });
          if (t.result === "valid") valid++;
          else invalid++;
        }
      }
      expect(valid).toBeGreaterThan(5);
      expect(invalid).toBeGreaterThan(20);
    });
  }
});

describe("cross-check against node:crypto (BoringSSL) on the NIST curves", () => {
  for (const [name, oid, hash] of [["prime256v1", "1.2.840.10045.3.1.7", "sha256"], ["secp384r1", "1.3.132.0.34", "sha384"], ["secp521r1", "1.3.132.0.35", "sha512"]] as const) {
    test(`${name}: signatures made by BoringSSL verify, altered ones do not`, () => {
      const curve = curveByOid(oid) as Curve;
      for (let i = 0; i < 3; i++) {
        const { publicKey, privateKey } = generateKeyPairSync("ec", { namedCurve: name });
        const spki = publicKey.export({ format: "der", type: "spki" });
        const point = decodePoint(curve, new Uint8Array(spki.subarray(spki.length - (1 + 2 * curve.fieldBytes))));
        const message = Buffer.from(`message ${i}`);
        const der = new Uint8Array(sign(hash, message, privateKey));
        const digest = new Uint8Array(createHash(hash).update(message).digest());
        const parsed = parseDerSignature(der);
        expect(parsed).toBeDefined();
        expect(verifyEcdsa(curve, point, digest, parsed as never)).toBe(true);
        const other = new Uint8Array(createHash(hash).update("other").digest());
        expect(verifyEcdsa(curve, point, other, parsed as never)).toBe(false);
        expect(verifyEcdsa(curve, point, digest, { r: (parsed as { r: bigint }).r, s: 0n })).toBe(false);
        expect(verifyEcdsa(curve, point, digest, { r: curve.n, s: (parsed as { s: bigint }).s })).toBe(false);
        expect(createPublicKey({ key: spki, format: "der", type: "spki" }).asymmetricKeyType).toBe("ec");
      }
    });
  }
});

describe("signature encodings", () => {
  test("DER with non-minimal INTEGER padding is rejected", () => {
    const ok = hex("3006020101020102");
    expect(parseDerSignature(ok)).toEqual({ r: 1n, s: 2n });
    expect(parseDerSignature(hex("300702020001020102"))).toBeUndefined();
    expect(parseDerSignature(hex("3006020101020102ff"))).toBeUndefined();
    expect(parseDerSignature(hex("3006020101020100"))).toBeDefined(); // s = 0 parses, verification rejects it
    expect(parseDerSignature(hex("3006020101020182"))).toBeUndefined(); // negative
  });
});

// Explicit domain parameters: secp256k1 is not in our table (RFC / SEC 2 constants).
function explicitParams(over: { b?: bigint; n?: bigint; p?: bigint; gy?: bigint } = {}): Uint8Array {
  const p = over.p ?? 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2fn;
  const n = over.n ?? 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141n;
  const gx = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798n;
  const gy = over.gy ?? 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8n;
  const int = (v: bigint): Uint8Array => {
    let b = bigIntToBytes(v, Math.ceil(v.toString(16).length / 2));
    if ((b[0] as number) & 0x80) b = Uint8Array.of(0, ...b);
    return encodeTlv(0x02, b);
  };
  const cat = (...parts: Uint8Array[]): Uint8Array => Uint8Array.of(...parts.flatMap((x) => [...x]));
  const oid = (h: string): Uint8Array => encodeTlv(0x06, hex(h));
  const field = encodeTlv(0x30, cat(oid("2a8648ce3d0101"), int(p)));
  const curve = encodeTlv(0x30, cat(encodeTlv(0x04, Uint8Array.of(0)), encodeTlv(0x04, Uint8Array.of(7 + (over.b ? Number(over.b - 7n) : 0)))));
  const base = encodeTlv(0x04, Uint8Array.of(0x04, ...bigIntToBytes(gx, 32), ...bigIntToBytes(gy, 32)));
  return encodeTlv(0x30, cat(int(1n), field, curve, base, int(n), int(1n)));
}

describe("explicit EC domain parameters", () => {
  test("a coherent unknown curve (secp256k1) is accepted", () => {
    const curve = parseEcParameters(parseTlv(explicitParams()));
    expect(curve.name).toBe("explicit");
    expect(curve.b).toBe(7n);
    expect(scalarMul(curve, curve.n, curve.g)).toBeUndefined();
  });
  test("a known curve is recognised and mapped to the table entry", () => {
    const named = curveByOid("1.3.132.0.34") as Curve;
    expect(named.name).toBe("secp384r1");
  });
  test("tampered generator, order, field or curve constant are rejected", () => {
    expect(() => parseEcParameters(parseTlv(explicitParams({ gy: 5n })))).toThrow(InvalidKeyError);
    expect(() => parseEcParameters(parseTlv(explicitParams({ n: 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364143n })))).toThrow(InvalidKeyError);
    expect(() => parseEcParameters(parseTlv(explicitParams({ p: 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2dn })))).toThrow(InvalidKeyError);
    expect(() => parseEcParameters(parseTlv(explicitParams({ b: 8n })))).toThrow(InvalidKeyError);
  });
  test("unknown named curve and missing parameters", () => {
    expect(() => parseEcParameters(parseTlv(hex("06032b8104")))).toThrow(UnsupportedAlgorithmError);
    expect(() => parseEcParameters(undefined)).toThrow(InvalidKeyError);
    expect(() => parseEcParameters(parseTlv(hex("0500")))).toThrow(UnsupportedAlgorithmError);
  });
});
