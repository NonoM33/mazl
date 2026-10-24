import { beforeAll, describe, expect, test } from "bun:test";
import { sign } from "node:crypto";
import { InvalidTransactionError } from "../../src/features/subscriptions/domain/errors";
import { AppleJwsVerifier } from "../../src/features/subscriptions/infra/apple-jws-verifier";
import { createTestPki, signedByPki, signJws, withTamperedPayload, type TestPki } from "./support/apple-test-pki";

// Apple signs StoreKit 2 transactions as compact JWS (RFC 7515), alg ES256,
// header x5c = [leaf, intermediate, root] in standard base64 DER. The chains
// below are throwaway test CAs built with the Apple extension OIDs
// (leaf 1.2.840.113635.100.6.11.1, intermediate 1.2.840.113635.100.6.2.1).

const NOW = new Date();
const PAYLOAD = { productId: "com.mazl.app.plus.1m", originalTransactionId: "1000000000001" };

let pki: TestPki;
let otherPki: TestPki;
let noLeafOid: TestPki;
let noIntermediateOid: TestPki;

beforeAll(async () => {
  [pki, otherPki, noLeafOid, noIntermediateOid] = await Promise.all([
    createTestPki(),
    createTestPki(),
    createTestPki({ leafOid: false }),
    createTestPki({ intermediateOid: false }),
  ]);
});

function verifier(trustedRoot = pki.rootDer, now: Date = NOW): AppleJwsVerifier {
  return new AppleJwsVerifier(trustedRoot, () => now);
}

function reasonOf(action: () => unknown): string {
  try {
    action();
  } catch (error) {
    if (error instanceof InvalidTransactionError) return error.reason;
    throw error;
  }
  return "accepted";
}

describe("AppleJwsVerifier", () => {
  test("accepts a JWS signed by a leaf chained to the trusted root and returns the payload", () => {
    expect(verifier().verify(signedByPki(pki, PAYLOAD))).toEqual(PAYLOAD);
  });

  test("rejects a tampered payload (signature no longer matches)", () => {
    const tampered = withTamperedPayload(signedByPki(pki, PAYLOAD), { ...PAYLOAD, productId: "com.mazl.app.plus.12m" });
    expect(reasonOf(() => verifier().verify(tampered))).toBe("invalid_signature");
  });

  test("rejects a self-made chain whose root is not the trusted one", () => {
    expect(reasonOf(() => verifier(otherPki.rootDer).verify(signedByPki(pki, PAYLOAD)))).toBe("untrusted_root");
  });

  test("rejects a leaf that was not issued by the intermediate", () => {
    const spliced = signJws(
      { header: { alg: "ES256", x5c: [otherPki.x5c[0], pki.x5c[1], pki.x5c[2]] }, payload: PAYLOAD },
      otherPki.leafKey,
    );
    expect(reasonOf(() => verifier().verify(spliced))).toBe("invalid_certificate_chain");
  });

  test("rejects an intermediate that was not issued by the trusted root", () => {
    // Everything is internally consistent except that the trusted root never signed this intermediate.
    const foreignIntermediate = signJws(
      { header: { alg: "ES256", x5c: [otherPki.x5c[0], otherPki.x5c[1], pki.x5c[2]] }, payload: PAYLOAD },
      otherPki.leafKey,
    );
    expect(reasonOf(() => verifier().verify(foreignIntermediate))).toBe("invalid_certificate_chain");
  });

  test("rejects a JWS signed with a key other than the leaf key", () => {
    const forged = signJws({ header: { alg: "ES256", x5c: pki.x5c }, payload: PAYLOAD }, otherPki.leafKey);
    expect(reasonOf(() => verifier().verify(forged))).toBe("invalid_signature");
  });

  test("rejects a DER-encoded signature (JWS requires raw r||s)", () => {
    const [header, payload] = signedByPki(pki, PAYLOAD).split(".");
    const der = sign("sha256", Buffer.from(`${header}.${payload}`), pki.leafKey);
    expect(reasonOf(() => verifier().verify(`${header}.${payload}.${der.toString("base64url")}`))).toBe("invalid_signature");
  });

  test("rejects alg other than ES256", () => {
    for (const alg of ["none", "HS256", "RS256", "ES384"]) {
      const jws = signedByPki(pki, PAYLOAD, { alg });
      expect(reasonOf(() => verifier().verify(jws))).toBe("unsupported_algorithm");
    }
  });

  test("rejects a missing or short x5c", () => {
    const noChain = signJws({ header: { alg: "ES256" }, payload: PAYLOAD }, pki.leafKey);
    const short = signJws({ header: { alg: "ES256", x5c: pki.x5c.slice(0, 2) }, payload: PAYLOAD }, pki.leafKey);
    expect(reasonOf(() => verifier().verify(noChain))).toBe("invalid_certificate_chain");
    expect(reasonOf(() => verifier().verify(short))).toBe("invalid_certificate_chain");
  });

  test("rejects an x5c entry that is not a certificate", () => {
    const junk = signJws({ header: { alg: "ES256", x5c: ["AAAA", pki.x5c[1], pki.x5c[2]] }, payload: PAYLOAD }, pki.leafKey);
    expect(reasonOf(() => verifier().verify(junk))).toBe("invalid_certificate_chain");
  });

  test("requires the Apple extension OID on the leaf", () => {
    expect(reasonOf(() => verifier(noLeafOid.rootDer).verify(signedByPki(noLeafOid, PAYLOAD)))).toBe("invalid_certificate_chain");
  });

  test("requires the Apple extension OID on the intermediate", () => {
    expect(reasonOf(() => verifier(noIntermediateOid.rootDer).verify(signedByPki(noIntermediateOid, PAYLOAD)))).toBe("invalid_certificate_chain");
  });

  test("rejects certificates that are expired at verification time", () => {
    const farFuture = new Date("2100-01-01T00:00:00Z");
    expect(reasonOf(() => verifier(pki.rootDer, farFuture).verify(signedByPki(pki, PAYLOAD)))).toBe("invalid_certificate_chain");
  });

  test("rejects certificates that are not yet valid at verification time", () => {
    const past = new Date("2000-01-01T00:00:00Z");
    expect(reasonOf(() => verifier(pki.rootDer, past).verify(signedByPki(pki, PAYLOAD)))).toBe("invalid_certificate_chain");
  });

  test("rejects malformed compact serialisations", () => {
    for (const jws of ["", "a.b", "a.b.c.d", "!!.!!.!!"]) {
      expect(reasonOf(() => verifier().verify(jws))).toBe("malformed_jws");
    }
  });

  test("rejects a payload that is not a JSON object", () => {
    const header = Buffer.from(JSON.stringify({ alg: "ES256", x5c: pki.x5c })).toString("base64url");
    const signingInput = `${header}.${Buffer.from("[1,2]").toString("base64url")}`;
    const signature = sign("sha256", Buffer.from(signingInput), { key: pki.leafKey, dsaEncoding: "ieee-p1363" });
    expect(reasonOf(() => verifier().verify(`${signingInput}.${signature.toString("base64url")}`))).toBe("malformed_jws");
  });
});
