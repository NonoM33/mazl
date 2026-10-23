import { TlvError } from "./errors";

// Strict BER/DER TLV reader (ISO/IEC 8825-1). Definite lengths only, minimal
// length encodings only, no trailing garbage. The same reader serves the ICAO
// LDS files (ISO 7816-4 BER-TLV) and the CMS / X.509 ASN.1.

export interface Tlv {
  // Full tag bytes as one integer, e.g. 0x30, 0x77, 0x5f1f, 0x7f61.
  readonly tag: number;
  readonly constructed: boolean;
  // Offsets into `buffer`.
  readonly start: number; // first byte of the tag
  readonly valueStart: number;
  readonly end: number; // one past the last value byte
  readonly buffer: Uint8Array;
  // Accept non-minimal length encodings (set only by trust-store tooling that
  // reads third-party files; chip data is always parsed strictly).
  readonly lenient: boolean;
}

const MAX_TAG_BYTES = 3;
const MAX_LENGTH_BYTES = 4;

export function readTlv(buffer: Uint8Array, offset: number, limit: number = buffer.length, lenient = false): Tlv {
  let pos = offset;
  if (pos >= limit) throw new TlvError("truncated: no tag");
  const first = buffer[pos++] as number;
  let tag = first;
  if ((first & 0x1f) === 0x1f) {
    // High-tag-number form: following bytes carry 7 bits, high bit = continue.
    let count = 1;
    for (;;) {
      if (pos >= limit) throw new TlvError("truncated: tag");
      const next = buffer[pos++] as number;
      if (count === 1 && next === 0x80) throw new TlvError("non-minimal tag");
      tag = tag * 256 + next;
      count++;
      if (count > MAX_TAG_BYTES) throw new TlvError("tag too long");
      if ((next & 0x80) === 0) break;
    }
  }
  if (pos >= limit) throw new TlvError("truncated: no length");
  const lengthByte = buffer[pos++] as number;
  let length: number;
  if (lengthByte < 0x80) {
    length = lengthByte;
  } else if (lengthByte === 0x80) {
    throw new TlvError("indefinite length not allowed");
  } else {
    const count = lengthByte & 0x7f;
    if (count > MAX_LENGTH_BYTES) throw new TlvError("length too long");
    if (pos + count > limit) throw new TlvError("truncated: length");
    length = 0;
    for (let i = 0; i < count; i++) length = length * 256 + (buffer[pos + i] as number);
    // DER: the long form is used only when needed, without leading zeros.
    if (!lenient && ((buffer[pos] as number) === 0 || length < 0x80)) throw new TlvError("non-minimal length");
    pos += count;
  }
  if (pos + length > limit) throw new TlvError("truncated: value");
  return { tag, constructed: (first & 0x20) !== 0, start: offset, valueStart: pos, end: pos + length, buffer, lenient };
}

// Exactly one TLV filling the whole input.
export function parseTlv(buffer: Uint8Array, lenient = false): Tlv {
  const tlv = readTlv(buffer, 0, buffer.length, lenient);
  if (tlv.end !== buffer.length) throw new TlvError("trailing data");
  return tlv;
}

// Children of a constructed TLV; the value must be fully consumed.
export function children(tlv: Tlv): Tlv[] {
  if (!tlv.constructed) throw new TlvError("not constructed");
  const result: Tlv[] = [];
  let pos = tlv.valueStart;
  while (pos < tlv.end) {
    const child = readTlv(tlv.buffer, pos, tlv.end, tlv.lenient);
    result.push(child);
    pos = child.end;
  }
  return result;
}

export function value(tlv: Tlv): Uint8Array {
  return tlv.buffer.subarray(tlv.valueStart, tlv.end);
}

// Header + value, as it appeared on the wire (what signatures cover).
export function raw(tlv: Tlv): Uint8Array {
  return tlv.buffer.subarray(tlv.start, tlv.end);
}

export function expectTag(tlv: Tlv | undefined, tag: number, what: string): Tlv {
  if (tlv === undefined) throw new TlvError(`missing ${what}`);
  if (tlv.tag !== tag) throw new TlvError(`unexpected tag for ${what}`);
  return tlv;
}

// Encodes a definite length (used to re-tag signed attributes and in tests).
export function encodeTlv(tag: number, content: Uint8Array): Uint8Array {
  const tagBytes: number[] = [];
  let t = tag;
  do {
    tagBytes.unshift(t & 0xff);
    t = Math.floor(t / 256);
  } while (t > 0);
  const len = content.length;
  const lenBytes = len < 0x80 ? [len] : len < 0x100 ? [0x81, len] : len < 0x10000 ? [0x82, len >> 8, len & 0xff] : [0x83, len >> 16, (len >> 8) & 0xff, len & 0xff];
  const out = new Uint8Array(tagBytes.length + lenBytes.length + len);
  out.set(tagBytes, 0);
  out.set(lenBytes, tagBytes.length);
  out.set(content, tagBytes.length + lenBytes.length);
  return out;
}
