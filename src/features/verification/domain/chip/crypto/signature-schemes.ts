import { decodeUnsignedInteger, decodeAlgorithmIdentifier, TAG, type AlgorithmIdentifier } from "../asn1";
import { ChipParseError, UnsupportedAlgorithmError } from "../errors";
import { HASH_OIDS, OID, type HashName } from "../oids";
import { children, expectTag, type Tlv } from "../tlv";
import type { SignatureFormat } from "./ecdsa";

// Maps the AlgorithmIdentifier of a signature (certificate or SignerInfo) to
// a concrete scheme. CMS may say plain "rsaEncryption" / "id-ecPublicKey"
// and carry the hash in digestAlgorithm; `digestHint` covers that.

export type SignatureScheme =
  | { readonly kind: "rsa-pkcs1"; readonly hash: HashName }
  | { readonly kind: "rsa-pss"; readonly hash: HashName; readonly saltLength: number }
  | { readonly kind: "ecdsa"; readonly hash: HashName; readonly format: SignatureFormat };

const RSA_PKCS1: Readonly<Record<string, HashName>> = {
  "1.2.840.113549.1.1.5": "sha1",
  "1.2.840.113549.1.1.14": "sha224",
  "1.2.840.113549.1.1.11": "sha256",
  "1.2.840.113549.1.1.12": "sha384",
  "1.2.840.113549.1.1.13": "sha512",
};

const ECDSA_X962: Readonly<Record<string, HashName>> = {
  "1.2.840.10045.4.1": "sha1",
  "1.2.840.10045.4.3.1": "sha224",
  "1.2.840.10045.4.3.2": "sha256",
  "1.2.840.10045.4.3.3": "sha384",
  "1.2.840.10045.4.3.4": "sha512",
};

// BSI TR-03111 ecdsa-plain-*: signature is r || s.
const ECDSA_PLAIN: Readonly<Record<string, HashName>> = {
  "0.4.0.127.0.7.1.1.4.1.1": "sha1",
  "0.4.0.127.0.7.1.1.4.1.2": "sha224",
  "0.4.0.127.0.7.1.1.4.1.3": "sha256",
  "0.4.0.127.0.7.1.1.4.1.4": "sha384",
  "0.4.0.127.0.7.1.1.4.1.5": "sha512",
};

const DEFAULT_PSS_SALT = 20; // RFC 8017 A.2.3 defaults: SHA-1, MGF1-SHA-1, 20

function hashFromAlgorithm(alg: AlgorithmIdentifier): HashName {
  const hash = HASH_OIDS[alg.oid];
  if (hash === undefined) throw new UnsupportedAlgorithmError("hash");
  return hash;
}

// RSASSA-PSS-params (RFC 8017 A.2.3). Node's verify() ties the MGF1 hash to
// the message hash, so a different MGF1 hash is refused.
function parsePss(params: Tlv | undefined): SignatureScheme {
  let hash: HashName = "sha1";
  let mgfHash: HashName = "sha1";
  let saltLength = DEFAULT_PSS_SALT;
  if (params !== undefined) {
    for (const field of children(expectTag(params, TAG.sequence, "RSASSA-PSS-params"))) {
      const [inner] = children(field);
      if (inner === undefined) throw new ChipParseError("pss: empty field");
      switch (field.tag) {
        case 0xa0:
          hash = hashFromAlgorithm(decodeAlgorithmIdentifier(inner));
          break;
        case 0xa1: {
          const mgf = decodeAlgorithmIdentifier(inner);
          if (mgf.oid !== OID.mgf1 || mgf.parameters === undefined) throw new UnsupportedAlgorithmError("mask generation function");
          mgfHash = hashFromAlgorithm(decodeAlgorithmIdentifier(mgf.parameters));
          break;
        }
        case 0xa2:
          saltLength = Number(decodeUnsignedInteger(inner));
          break;
        case 0xa3:
          if (decodeUnsignedInteger(inner) !== 1n) throw new UnsupportedAlgorithmError("PSS trailer field");
          break;
        default:
          throw new ChipParseError("pss: unknown field");
      }
    }
  }
  if (mgfHash !== hash) throw new UnsupportedAlgorithmError("PSS with differing MGF1 hash");
  return { kind: "rsa-pss", hash, saltLength };
}

export function resolveSignatureScheme(alg: AlgorithmIdentifier, digestHint?: AlgorithmIdentifier): SignatureScheme {
  const rsaHash = RSA_PKCS1[alg.oid];
  if (rsaHash !== undefined) return { kind: "rsa-pkcs1", hash: rsaHash };
  const ecHash = ECDSA_X962[alg.oid];
  if (ecHash !== undefined) return { kind: "ecdsa", hash: ecHash, format: "auto" };
  const plainHash = ECDSA_PLAIN[alg.oid];
  if (plainHash !== undefined) return { kind: "ecdsa", hash: plainHash, format: "plain" };
  if (alg.oid === OID.rsaPss) return parsePss(alg.parameters);
  if (alg.oid === OID.rsaEncryption && digestHint) return { kind: "rsa-pkcs1", hash: hashFromAlgorithm(digestHint) };
  if (alg.oid === OID.ecPublicKey && digestHint) return { kind: "ecdsa", hash: hashFromAlgorithm(digestHint), format: "auto" };
  throw new UnsupportedAlgorithmError(`signature ${alg.oid}`);
}

