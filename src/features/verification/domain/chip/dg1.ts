import { latin1 } from "./asn1";
import { ChipParseError } from "./errors";
import { parseMrz } from "./mrz";
import { children, expectTag, parseTlv, value } from "./tlv";
import type { ChipIdentity } from "../types";

const TAG_DG1 = 0x61;
const TAG_MRZ = 0x5f1f;

// EF.DG1 = 0x61 { 0x5F1F MRZ } (ICAO 9303 Part 10, 4.7.1). Names are parsed
// by nobody: only the fields of ChipIdentity ever leave this function.
export function parseDg1(bytes: Uint8Array, now: Date): ChipIdentity {
  const root = expectTag(parseTlv(bytes), TAG_DG1, "DG1");
  const kids = children(root);
  if (kids.length !== 1) throw new ChipParseError("dg1: unexpected content");
  const mrz = expectTag(kids[0], TAG_MRZ, "MRZ");
  return parseMrz(latin1(value(mrz)), now);
}
