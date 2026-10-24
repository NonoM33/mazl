// Minimal DER walker: lists the extension OIDs of an X.509 certificate.
// node:crypto exposes no extension accessor, and a byte search for the OID
// could match unrelated data, so the structure is walked properly:
//   Certificate ::= SEQUENCE { tbsCertificate SEQUENCE { ... [3] EXPLICIT SEQUENCE OF Extension }, ... }
//   Extension   ::= SEQUENCE { extnID OBJECT IDENTIFIER, critical BOOLEAN DEFAULT FALSE, extnValue OCTET STRING }

interface DerElement {
  readonly tag: number;
  readonly content: Uint8Array;
  readonly end: number;
}

const TAG_SEQUENCE = 0x30;
const TAG_OID = 0x06;
const TAG_EXTENSIONS = 0xa3;

function readElement(bytes: Uint8Array, offset: number): DerElement | undefined {
  const tag = bytes[offset];
  const first = bytes[offset + 1];
  if (tag === undefined || first === undefined) return undefined;
  let length = first;
  let start = offset + 2;
  if (first & 0x80) {
    const count = first & 0x7f;
    if (count === 0 || count > 4) return undefined;
    length = 0;
    for (let i = 0; i < count; i++) {
      const byte = bytes[start + i];
      if (byte === undefined) return undefined;
      length = length * 256 + byte;
    }
    start += count;
  }
  const end = start + length;
  if (end > bytes.length) return undefined;
  return { tag, content: bytes.subarray(start, end), end };
}

function children(bytes: Uint8Array): DerElement[] {
  const result: DerElement[] = [];
  for (let offset = 0; offset < bytes.length; ) {
    const element = readElement(bytes, offset);
    if (element === undefined) break;
    result.push(element);
    offset = element.end;
  }
  return result;
}

function decodeOid(content: Uint8Array): string {
  const arcs: number[] = [];
  let value = 0;
  for (const byte of content) {
    value = value * 128 + (byte & 0x7f);
    if (!(byte & 0x80)) {
      arcs.push(value);
      value = 0;
    }
  }
  const [head, ...rest] = arcs;
  if (head === undefined) return "";
  const first = Math.min(Math.floor(head / 40), 2);
  return [first, head - first * 40, ...rest].join(".");
}

export function extensionOids(certificateDer: Uint8Array): ReadonlySet<string> {
  const certificate = readElement(certificateDer, 0);
  if (certificate === undefined || certificate.tag !== TAG_SEQUENCE) return new Set();
  const tbs = children(certificate.content)[0];
  if (tbs === undefined || tbs.tag !== TAG_SEQUENCE) return new Set();
  const wrapper = children(tbs.content).find((element) => element.tag === TAG_EXTENSIONS);
  const list = wrapper === undefined ? undefined : children(wrapper.content)[0];
  if (list === undefined) return new Set();
  const oids = children(list.content).flatMap((extension) => {
    const id = children(extension.content)[0];
    return id !== undefined && id.tag === TAG_OID ? [decodeOid(id.content)] : [];
  });
  return new Set(oids);
}
