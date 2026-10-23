import {
  canonicalName,
  decodeAlgorithmIdentifier,
  decodeByteAlignedBitString,
  decodeOctetString,
  decodeOid,
  decodeTime,
  integerBytes,
  TAG,
  type AlgorithmIdentifier,
} from "./asn1";
import { TlvError } from "./errors";
import { OID } from "./oids";
import { children, expectTag, parseTlv, raw, type Tlv } from "./tlv";

// Minimal X.509 v3 reader (RFC 5280): just what chaining a DSC to a CSCA needs.

export interface SubjectPublicKeyInfo {
  readonly algorithm: AlgorithmIdentifier;
  readonly publicKey: Uint8Array; // BIT STRING content
  readonly der: Uint8Array; // whole SPKI, for node:crypto
}

export interface Certificate {
  readonly der: Uint8Array;
  readonly tbs: Uint8Array; // exact bytes covered by the signature
  readonly serial: Uint8Array;
  readonly issuer: string; // canonical form
  readonly subject: string; // canonical form
  readonly notBefore: Date;
  readonly notAfter: Date;
  readonly spki: SubjectPublicKeyInfo;
  readonly signatureAlgorithm: AlgorithmIdentifier;
  readonly signature: Uint8Array;
  readonly subjectKeyId: Uint8Array | undefined;
  readonly authorityKeyId: Uint8Array | undefined;
}

const TAG_VERSION = 0xa0;
const TAG_EXTENSIONS = 0xa3;
const TAG_AKI_KEY_ID = 0x80;

function parseSpki(tlv: Tlv): SubjectPublicKeyInfo {
  expectTag(tlv, TAG.sequence, "SubjectPublicKeyInfo");
  const [alg, key, extra] = children(tlv);
  if (extra !== undefined) throw new TlvError("SPKI too long");
  return {
    algorithm: decodeAlgorithmIdentifier(expectTag(alg, TAG.sequence, "SPKI algorithm")),
    publicKey: decodeByteAlignedBitString(expectTag(key, TAG.bitString, "SPKI key")),
    der: raw(tlv),
  };
}

function parseKeyIds(extensions: Tlv | undefined): { ski?: Uint8Array; aki?: Uint8Array } {
  const result: { ski?: Uint8Array; aki?: Uint8Array } = {};
  if (extensions === undefined) return result;
  const list = expectTag(children(extensions)[0], TAG.sequence, "Extensions");
  for (const ext of children(list)) {
    const parts = children(expectTag(ext, TAG.sequence, "Extension"));
    const oid = decodeOid(expectTag(parts[0], TAG.oid, "extnID"));
    const valueTlv = parts[parts.length - 1] as Tlv;
    if (oid !== OID.extSubjectKeyIdentifier && oid !== OID.extAuthorityKeyIdentifier) continue;
    const inner = parseTlv(decodeOctetString(expectTag(valueTlv, TAG.octetString, "extnValue")));
    if (oid === OID.extSubjectKeyIdentifier) {
      result.ski = decodeOctetString(inner);
    } else {
      const keyId = children(expectTag(inner, TAG.sequence, "AKI")).find((c) => c.tag === TAG_AKI_KEY_ID);
      if (keyId !== undefined) result.aki = raw(keyId).subarray(keyId.valueStart - keyId.start);
    }
  }
  return result;
}

export function parseCertificate(der: Uint8Array): Certificate {
  const cert = expectTag(parseTlv(der), TAG.sequence, "Certificate");
  const [tbsTlv, sigAlg, sigValue, extra] = children(cert);
  if (extra !== undefined) throw new TlvError("certificate too long");
  const tbs = expectTag(tbsTlv, TAG.sequence, "TBSCertificate");
  const fields = children(tbs);
  let i = 0;
  if (fields[i]?.tag === TAG_VERSION) i++;
  const serial = integerBytes(expectTag(fields[i++], TAG.integer, "serial"));
  const tbsSignatureAlgorithm = expectTag(fields[i++], TAG.sequence, "tbs signature");
  // RFC 5280 4.1.1.2: the outer algorithm must repeat the signed one, otherwise
  // it is unauthenticated input to the verifier.
  if (!sameBytes(raw(tbsSignatureAlgorithm), raw(expectTag(sigAlg, TAG.sequence, "signatureAlgorithm")))) {
    throw new TlvError("signature algorithm mismatch");
  }
  const issuer = canonicalName(expectTag(fields[i++], TAG.sequence, "issuer"));
  const validity = children(expectTag(fields[i++], TAG.sequence, "validity"));
  const subject = canonicalName(expectTag(fields[i++], TAG.sequence, "subject"));
  const spki = parseSpki(expectTag(fields[i++], TAG.sequence, "SPKI"));
  const extensions = fields.slice(i).find((f) => f.tag === TAG_EXTENSIONS);
  const ids = parseKeyIds(extensions);
  const [nb, na] = validity;
  if (nb === undefined || na === undefined) throw new TlvError("bad validity");
  return {
    der,
    tbs: raw(tbs),
    serial,
    issuer,
    subject,
    notBefore: decodeTime(nb),
    notAfter: decodeTime(na),
    spki,
    signatureAlgorithm: decodeAlgorithmIdentifier(expectTag(sigAlg, TAG.sequence, "signatureAlgorithm")),
    signature: decodeByteAlignedBitString(expectTag(sigValue, TAG.bitString, "signatureValue")),
    subjectKeyId: ids.ski,
    authorityKeyId: ids.aki,
  };
}

function sameBytes(a: Uint8Array, b: Uint8Array): boolean {
  return a.length === b.length && a.every((v, i) => v === b[i]);
}

export function pemToDerList(pem: string): Uint8Array[] {
  const out: Uint8Array[] = [];
  const re = /-----BEGIN CERTIFICATE-----([\s\S]*?)-----END CERTIFICATE-----/g;
  for (let m = re.exec(pem); m !== null; m = re.exec(pem)) {
    out.push(new Uint8Array(Buffer.from((m[1] as string).replace(/\s+/g, ""), "base64")));
  }
  return out;
}
