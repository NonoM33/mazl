import { TlvError } from "./errors";
import { children, expectTag, value, type Tlv } from "./tlv";

// Decoders for the ASN.1 universal types we meet in CMS and X.509.

export const TAG = {
  boolean: 0x01,
  integer: 0x02,
  bitString: 0x03,
  octetString: 0x04,
  null: 0x05,
  oid: 0x06,
  utf8String: 0x0c,
  printableString: 0x13,
  t61String: 0x14,
  ia5String: 0x16,
  utcTime: 0x17,
  generalizedTime: 0x18,
  bmpString: 0x1e,
  sequence: 0x30,
  set: 0x31,
} as const;

export function latin1(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return s;
}

export function decodeOid(tlv: Tlv): string {
  expectTag(tlv, TAG.oid, "OID");
  const bytes = value(tlv);
  if (bytes.length === 0) throw new TlvError("empty OID");
  const parts: string[] = [];
  let acc = 0n;
  let first = true;
  for (let i = 0; i < bytes.length; i++) {
    const b = bytes[i] as number;
    if (acc === 0n && b === 0x80) throw new TlvError("non-minimal OID arc");
    acc = (acc << 7n) | BigInt(b & 0x7f);
    if ((b & 0x80) === 0) {
      if (first) {
        const top = acc < 40n ? 0n : acc < 80n ? 1n : 2n;
        parts.push(top.toString(), (acc - top * 40n).toString());
        first = false;
      } else {
        parts.push(acc.toString());
      }
      acc = 0n;
    } else if (i === bytes.length - 1) {
      throw new TlvError("truncated OID");
    }
  }
  return parts.join(".");
}

export function decodeUnsignedInteger(tlv: Tlv): bigint {
  expectTag(tlv, TAG.integer, "INTEGER");
  const bytes = value(tlv);
  if (bytes.length === 0) throw new TlvError("empty INTEGER");
  if ((bytes[0] as number) & 0x80) throw new TlvError("negative INTEGER");
  return bytesToBigInt(bytes);
}

// INTEGER content octets with the DER sign padding removed (serial numbers).
export function integerBytes(tlv: Tlv): Uint8Array {
  expectTag(tlv, TAG.integer, "INTEGER");
  const bytes = value(tlv);
  if (bytes.length === 0) throw new TlvError("empty INTEGER");
  let i = 0;
  while (i < bytes.length - 1 && bytes[i] === 0) i++;
  return bytes.subarray(i);
}

export function bytesToBigInt(bytes: Uint8Array): bigint {
  let n = 0n;
  for (const b of bytes) n = (n << 8n) | BigInt(b);
  return n;
}

export function bigIntToBytes(n: bigint, length: number): Uint8Array {
  const out = new Uint8Array(length);
  let v = n;
  for (let i = length - 1; i >= 0; i--) {
    out[i] = Number(v & 0xffn);
    v >>= 8n;
  }
  return out;
}

// BIT STRING whose bit count is a multiple of 8 (keys, signatures).
export function decodeByteAlignedBitString(tlv: Tlv): Uint8Array {
  expectTag(tlv, TAG.bitString, "BIT STRING");
  const bytes = value(tlv);
  if (bytes.length === 0 || bytes[0] !== 0) throw new TlvError("bit string not byte aligned");
  return bytes.subarray(1);
}

// OCTET STRING; constructed (BER chunked) forms are concatenated.
export function decodeOctetString(tlv: Tlv): Uint8Array {
  if (tlv.tag === TAG.octetString) return value(tlv);
  if (tlv.tag === (TAG.octetString | 0x20)) {
    const parts = children(tlv).map((c) => decodeOctetString(c));
    const out = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
    let pos = 0;
    for (const p of parts) {
      out.set(p, pos);
      pos += p.length;
    }
    return out;
  }
  throw new TlvError("expected OCTET STRING");
}

// UTCTime (YYMMDDHHMMSSZ, RFC 5280: 50..99 -> 19xx) or GeneralizedTime.
export function decodeTime(tlv: Tlv): Date {
  const text = latin1(value(tlv));
  let m: RegExpExecArray | null;
  let year: number;
  if (tlv.tag === TAG.utcTime) {
    m = /^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z$/.exec(text);
    if (!m) throw new TlvError("bad UTCTime");
    const yy = Number(m[1]);
    year = yy >= 50 ? 1900 + yy : 2000 + yy;
  } else if (tlv.tag === TAG.generalizedTime) {
    m = /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z$/.exec(text);
    if (!m) throw new TlvError("bad GeneralizedTime");
    year = Number(m[1]);
  } else {
    throw new TlvError("expected time");
  }
  const date = new Date(Date.UTC(year, Number(m[2]) - 1, Number(m[3]), Number(m[4]), Number(m[5]), Number(m[6])));
  if (Number.isNaN(date.getTime())) throw new TlvError("bad time value");
  return date;
}

export interface AlgorithmIdentifier {
  readonly oid: string;
  readonly parameters: Tlv | undefined;
}

export function decodeAlgorithmIdentifier(tlv: Tlv): AlgorithmIdentifier {
  expectTag(tlv, TAG.sequence, "AlgorithmIdentifier");
  const [oid, parameters, extra] = children(tlv);
  if (extra !== undefined) throw new TlvError("AlgorithmIdentifier too long");
  return { oid: decodeOid(expectTag(oid, TAG.oid, "algorithm OID")), parameters };
}

function decodeString(tlv: Tlv): string {
  const bytes = value(tlv);
  switch (tlv.tag) {
    case TAG.utf8String:
      try {
        return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
      } catch {
        throw new TlvError("invalid UTF-8 in Name");
      }
    case TAG.bmpString: {
      let s = "";
      for (let i = 0; i + 1 < bytes.length; i += 2) s += String.fromCharCode(((bytes[i] as number) << 8) | (bytes[i + 1] as number));
      return s;
    }
    default:
      return latin1(bytes);
  }
}

// Canonical form of an X.501 Name for comparison: attribute values are
// case-folded and whitespace-collapsed (RFC 5280 4.1.2.4 matching rules), so
// that PrintableString vs UTF8String encodings of the same name still match.
export function canonicalName(name: Tlv): string {
  expectTag(name, TAG.sequence, "Name");
  const rdns = children(name).map((rdn) => {
    expectTag(rdn, TAG.set, "RDN");
    return children(rdn)
      .map((atv) => {
        expectTag(atv, TAG.sequence, "AttributeTypeAndValue");
        const [oid, val] = children(atv);
        if (oid === undefined || val === undefined) throw new TlvError("bad AttributeTypeAndValue");
        const text = decodeString(val).normalize("NFC").trim().replace(/\s+/g, " ").toLowerCase();
        return `${decodeOid(oid)}=${text}`;
      })
      .sort()
      .join("+");
  });
  return rdns.join(",");
}

// The single countryName (2.5.4.6) of a Name, upper-cased; undefined if there
// is none or more than one (ambiguous).
export function countryOfName(name: Tlv): string | undefined {
  expectTag(name, TAG.sequence, "Name");
  const found: string[] = [];
  for (const rdn of children(name)) {
    for (const atv of children(expectTag(rdn, TAG.set, "RDN"))) {
      const [oid, val] = children(expectTag(atv, TAG.sequence, "AttributeTypeAndValue"));
      if (oid !== undefined && val !== undefined && decodeOid(oid) === "2.5.4.6") found.push(decodeString(val).trim().toUpperCase());
    }
  }
  return found.length === 1 ? found[0] : undefined;
}
