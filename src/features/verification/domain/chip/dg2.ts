import { ChipParseError } from "./errors";
import { children, expectTag, parseTlv, value, type Tlv } from "./tlv";

// EF.DG2 (ICAO 9303 Part 10, 4.7.2): 0x75 { 0x7F61 { 0x02 count,
// 0x7F60 { 0xA1 header, 0x5F2E | 0x7F2E biometric data block } ... } }.
// The data block is an ISO/IEC 19794-5 face record.

const TAG_DG2 = 0x75;
const TAG_BIOMETRIC_GROUP = 0x7f61;
const TAG_BIOMETRIC_INSTANCE = 0x7f60;
const TAG_BDB = new Set([0x5f2e, 0x7f2e]);

export type FaceImageFormat = "jpeg" | "jp2";
export interface FaceImage {
  readonly bytes: Uint8Array;
  readonly format: FaceImageFormat;
}

const JP2_SIGNATURE_BOX = [0x00, 0x00, 0x00, 0x0c, 0x6a, 0x50, 0x20, 0x20, 0x0d, 0x0a, 0x87, 0x0a];

function startsWith(bytes: Uint8Array, at: number, magic: readonly number[]): boolean {
  return magic.every((b, i) => bytes[at + i] === b);
}

export function detectImageFormat(bytes: Uint8Array, at = 0): FaceImageFormat | undefined {
  if (startsWith(bytes, at, [0xff, 0xd8, 0xff])) return "jpeg";
  if (startsWith(bytes, at, JP2_SIGNATURE_BOX) || startsWith(bytes, at, [0xff, 0x4f, 0xff, 0x51])) return "jp2";
  return undefined;
}

const FAC_HEADER = [0x46, 0x41, 0x43, 0x00]; // "FAC\0"
const RECORD_HEADER = 14; // format id 4, version 4, length 4, face count 2
const FACIAL_INFO = 20; // fixed part of the facial information block
const FEATURE_POINT = 8;
const IMAGE_INFO = 12;

// Locates the image inside the 19794-5 record: structurally first, then by
// scanning for an image magic. DG2 integrity is guaranteed by the SOD hash.
function extractImage(bdb: Uint8Array): FaceImage {
  if (!startsWith(bdb, 0, FAC_HEADER)) throw new ChipParseError("dg2: not a face record");
  if (bdb.length > RECORD_HEADER + FACIAL_INFO) {
    const featurePoints = ((bdb[RECORD_HEADER + 4] as number) << 8) | (bdb[RECORD_HEADER + 5] as number);
    const at = RECORD_HEADER + FACIAL_INFO + featurePoints * FEATURE_POINT + IMAGE_INFO;
    const format = at < bdb.length ? detectImageFormat(bdb, at) : undefined;
    if (format !== undefined) return { bytes: bdb.slice(at), format };
  }
  for (let at = RECORD_HEADER; at + 4 <= bdb.length; at++) {
    const format = detectImageFormat(bdb, at);
    if (format !== undefined) return { bytes: bdb.slice(at), format };
  }
  throw new ChipParseError("dg2: no image in face record");
}

function biometricDataBlock(instance: Tlv): Tlv | undefined {
  return children(instance).find((c) => TAG_BDB.has(c.tag));
}

export function parseDg2(bytes: Uint8Array): FaceImage {
  const root = expectTag(parseTlv(bytes), TAG_DG2, "DG2");
  const group = expectTag(children(root)[0], TAG_BIOMETRIC_GROUP, "biometric information group");
  const instance = children(group).find((c) => c.tag === TAG_BIOMETRIC_INSTANCE);
  if (instance === undefined) throw new ChipParseError("dg2: no biometric instance");
  const bdb = biometricDataBlock(instance);
  if (bdb === undefined) throw new ChipParseError("dg2: no biometric data block");
  return extractImage(value(bdb));
}
