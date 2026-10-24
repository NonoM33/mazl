import { X509Certificate, verify, type KeyObject } from "node:crypto";
import type { JwsVerifier } from "../application/ports";
import { InvalidTransactionError } from "../domain/errors";
import { extensionOids } from "./der-extensions";

// Apple's marker extensions on the signing chain (App Store Server API docs):
// "Mac App Store Receipt Signing" on the leaf, "WWDR intermediate" on the
// intermediate.
const LEAF_OID = "1.2.840.113635.100.6.11.1";
const INTERMEDIATE_OID = "1.2.840.113635.100.6.2.1";
const ES256_SIGNATURE_BYTES = 64;

interface Header {
  readonly alg?: unknown;
  readonly x5c?: unknown;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function decodeJson(segment: string): Record<string, unknown> {
  try {
    const value: unknown = JSON.parse(Buffer.from(segment, "base64url").toString("utf8"));
    if (isRecord(value)) return value;
  } catch {
    // falls through to the malformed error below
  }
  throw new InvalidTransactionError("malformed_jws");
}

function parseChain(header: Header): [X509Certificate, X509Certificate, X509Certificate] {
  const entries = header.x5c;
  if (!Array.isArray(entries) || entries.length !== 3 || !entries.every((entry) => typeof entry === "string")) {
    throw new InvalidTransactionError("invalid_certificate_chain");
  }
  try {
    const [leaf, intermediate, root] = entries.map((entry: string) => new X509Certificate(Buffer.from(entry, "base64")));
    if (leaf === undefined || intermediate === undefined || root === undefined) throw new Error("short chain");
    return [leaf, intermediate, root];
  } catch {
    throw new InvalidTransactionError("invalid_certificate_chain");
  }
}

function isValidAt(certificate: X509Certificate, now: Date): boolean {
  return new Date(certificate.validFrom) <= now && now <= new Date(certificate.validTo);
}

function isP256(key: KeyObject): boolean {
  return key.asymmetricKeyType === "ec" && key.asymmetricKeyDetails?.namedCurve === "prime256v1";
}

// Verifies an App Store signed payload (compact JWS, ES256, x5c chain) against
// an injected trust anchor: production wires Apple Root CA - G3, tests wire a
// throwaway CA.
export class AppleJwsVerifier implements JwsVerifier {
  constructor(
    private readonly trustedRootDer: Uint8Array,
    private readonly clock: () => Date = () => new Date(),
  ) {}

  verify(jws: string): Record<string, unknown> {
    const parts = jws.split(".");
    const [encodedHeader, encodedPayload, encodedSignature] = parts;
    if (parts.length !== 3 || !encodedHeader || !encodedPayload || !encodedSignature) {
      throw new InvalidTransactionError("malformed_jws");
    }
    const header = decodeJson(encodedHeader);
    if (header.alg !== "ES256") throw new InvalidTransactionError("unsupported_algorithm");

    const leaf = this.verifiedLeaf(header);
    this.verifySignature(`${encodedHeader}.${encodedPayload}`, encodedSignature, leaf.publicKey);
    return decodeJson(encodedPayload);
  }

  private verifiedLeaf(header: Header): X509Certificate {
    const [leaf, intermediate, root] = parseChain(header);
    if (!Buffer.from(root.raw).equals(Buffer.from(this.trustedRootDer))) throw new InvalidTransactionError("untrusted_root");

    const now = this.clock();
    const chainIsValid =
      [leaf, intermediate, root].every((certificate) => isValidAt(certificate, now)) &&
      extensionOids(leaf.raw).has(LEAF_OID) &&
      extensionOids(intermediate.raw).has(INTERMEDIATE_OID) &&
      leaf.verify(intermediate.publicKey) &&
      intermediate.verify(root.publicKey) &&
      isP256(leaf.publicKey);
    if (!chainIsValid) throw new InvalidTransactionError("invalid_certificate_chain");
    return leaf;
  }

  private verifySignature(signingInput: string, encodedSignature: string, key: KeyObject): void {
    const signature = Buffer.from(encodedSignature, "base64url");
    // JWS ES256 signatures are the raw r||s pair, not DER.
    const valid =
      signature.length === ES256_SIGNATURE_BYTES &&
      verify("sha256", Buffer.from(signingInput), { key, dsaEncoding: "ieee-p1363" }, signature);
    if (!valid) throw new InvalidTransactionError("invalid_signature");
  }
}
