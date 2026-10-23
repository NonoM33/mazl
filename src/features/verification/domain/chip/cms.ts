import {
  canonicalName,
  decodeAlgorithmIdentifier,
  decodeOctetString,
  decodeOid,
  decodeUnsignedInteger,
  integerBytes,
  TAG,
  type AlgorithmIdentifier,
} from "./asn1";
import { ChipParseError } from "./errors";
import { OID } from "./oids";
import { children, encodeTlv, expectTag, parseTlv, raw, value, type Tlv } from "./tlv";
import { parseCertificate, type Certificate } from "./x509";

// EF.SOD (ICAO 9303 Part 10, 4.6) = 0x77 { CMS ContentInfo { SignedData } }.
// CMS per RFC 5652 sections 3 and 5.

const TAG_SOD = 0x77;
const TAG_EXPLICIT_0 = 0xa0;
const TAG_CERTIFICATES = 0xa0;
const TAG_CRLS = 0xa1;
const TAG_SID_SKI = 0x80;
const TAG_SIGNED_ATTRS = 0xa0;
const TAG_UNSIGNED_ATTRS = 0xa1;

export type SignerId =
  | { readonly kind: "issuerAndSerial"; readonly issuer: string; readonly serial: Uint8Array }
  | { readonly kind: "subjectKeyId"; readonly keyId: Uint8Array };

export interface SignerInfo {
  readonly sid: SignerId;
  readonly digestAlgorithm: AlgorithmIdentifier;
  readonly signatureAlgorithm: AlgorithmIdentifier;
  readonly signature: Uint8Array;
  // DER of the signed attributes re-tagged as SET (RFC 5652 5.4), if present.
  readonly signedAttrsDer: Uint8Array | undefined;
  readonly contentTypeAttr: string | undefined;
  readonly messageDigestAttr: Uint8Array | undefined;
}

export interface SignedData {
  readonly eContentType: string;
  readonly eContent: Uint8Array;
  readonly certificates: readonly Certificate[];
  readonly signerInfos: readonly SignerInfo[];
}

function parseSid(tlv: Tlv): SignerId {
  if (tlv.tag === TAG.sequence) {
    const [issuer, serial] = children(tlv);
    if (issuer === undefined || serial === undefined) throw new ChipParseError("cms: bad issuerAndSerialNumber");
    return { kind: "issuerAndSerial", issuer: canonicalName(issuer), serial: integerBytes(serial) };
  }
  if (tlv.tag === TAG_SID_SKI) return { kind: "subjectKeyId", keyId: value(tlv) };
  throw new ChipParseError("cms: unknown signer identifier");
}

function parseSignedAttrs(attrs: Tlv): { der: Uint8Array; contentType?: string; digest?: Uint8Array } {
  const result: { der: Uint8Array; contentType?: string; digest?: Uint8Array } = {
    der: encodeTlv(TAG.set, value(attrs)),
  };
  const seen = new Set<string>();
  for (const attr of children(attrs)) {
    const [typeTlv, valuesTlv, extra] = children(expectTag(attr, TAG.sequence, "Attribute"));
    if (extra !== undefined) throw new ChipParseError("cms: bad attribute");
    const oid = decodeOid(expectTag(typeTlv, TAG.oid, "attrType"));
    if (seen.has(oid)) throw new ChipParseError("cms: duplicate attribute");
    seen.add(oid);
    const vals = children(expectTag(valuesTlv, TAG.set, "attrValues"));
    if (oid === OID.attrContentType) {
      if (vals.length !== 1) throw new ChipParseError("cms: bad contentType attribute");
      result.contentType = decodeOid(vals[0] as Tlv);
    } else if (oid === OID.attrMessageDigest) {
      if (vals.length !== 1) throw new ChipParseError("cms: bad messageDigest attribute");
      result.digest = decodeOctetString(expectTag(vals[0], TAG.octetString, "messageDigest"));
    }
  }
  return result;
}

function parseSignerInfo(tlv: Tlv): SignerInfo {
  expectTag(tlv, TAG.sequence, "SignerInfo");
  const f = children(tlv);
  let i = 0;
  decodeUnsignedInteger(expectTag(f[i++], TAG.integer, "SignerInfo version"));
  const sid = parseSid(f[i++] as Tlv);
  const digestAlgorithm = decodeAlgorithmIdentifier(expectTag(f[i++], TAG.sequence, "digestAlgorithm"));
  let attrs: ReturnType<typeof parseSignedAttrs> | undefined;
  if (f[i]?.tag === TAG_SIGNED_ATTRS) attrs = parseSignedAttrs(f[i++] as Tlv);
  const signatureAlgorithm = decodeAlgorithmIdentifier(expectTag(f[i++], TAG.sequence, "signatureAlgorithm"));
  const signature = decodeOctetString(expectTag(f[i++], TAG.octetString, "signature"));
  if (f[i]?.tag === TAG_UNSIGNED_ATTRS) i++;
  if (i !== f.length) throw new ChipParseError("cms: unexpected SignerInfo content");
  return {
    sid,
    digestAlgorithm,
    signatureAlgorithm,
    signature,
    signedAttrsDer: attrs?.der,
    contentTypeAttr: attrs?.contentType,
    messageDigestAttr: attrs?.digest,
  };
}

function parseEncapContent(tlv: Tlv): { type: string; content: Uint8Array } {
  const [typeTlv, wrapper, extra] = children(expectTag(tlv, TAG.sequence, "EncapsulatedContentInfo"));
  if (extra !== undefined) throw new ChipParseError("cms: bad EncapsulatedContentInfo");
  const type = decodeOid(expectTag(typeTlv, TAG.oid, "eContentType"));
  const inner = children(expectTag(wrapper, TAG_EXPLICIT_0, "eContent"));
  if (inner.length !== 1) throw new ChipParseError("cms: bad eContent");
  return { type, content: decodeOctetString(inner[0] as Tlv) };
}

export function parseSod(sod: Uint8Array): SignedData {
  const wrapper = expectTag(parseTlv(sod), TAG_SOD, "EF.SOD");
  const [contentInfo, trailing] = children(wrapper);
  if (trailing !== undefined) throw new ChipParseError("sod: unexpected content");
  return parseContentInfo(expectTag(contentInfo, TAG.sequence, "ContentInfo"));
}

// A bare CMS ContentInfo (e.g. an ICAO master list file). `lenient` accepts
// BER length encodings produced by third-party tools.
export function parseCmsSignedData(der: Uint8Array, lenient = false): SignedData {
  return parseContentInfo(expectTag(parseTlv(der, lenient), TAG.sequence, "ContentInfo"));
}

function parseContentInfo(contentInfo: Tlv): SignedData {
  const [ctype, explicit] = children(contentInfo);
  if (decodeOid(expectTag(ctype, TAG.oid, "contentType")) !== OID.contentTypeSignedData) throw new ChipParseError("sod: not SignedData");
  const signedData = expectTag(children(expectTag(explicit, TAG_EXPLICIT_0, "content"))[0], TAG.sequence, "SignedData");
  const f = children(signedData);
  let i = 0;
  decodeUnsignedInteger(expectTag(f[i++], TAG.integer, "SignedData version"));
  expectTag(f[i++], TAG.set, "digestAlgorithms");
  const encap = parseEncapContent(f[i++] as Tlv);
  const certificates: Certificate[] = [];
  if (f[i]?.tag === TAG_CERTIFICATES) {
    for (const c of children(f[i++] as Tlv)) if (c.tag === TAG.sequence) certificates.push(parseCertificate(raw(c), c.lenient));
  }
  if (f[i]?.tag === TAG_CRLS) i++;
  const signerInfos = children(expectTag(f[i++], TAG.set, "signerInfos")).map(parseSignerInfo);
  if (i !== f.length) throw new ChipParseError("sod: unexpected SignedData content");
  return { eContentType: encap.type, eContent: encap.content, certificates, signerInfos };
}
