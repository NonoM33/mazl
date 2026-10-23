import { decodeAlgorithmIdentifier, decodeOctetString, decodeUnsignedInteger, TAG } from "./asn1";
import { ChipParseError } from "./errors";
import { HASH_OIDS, type HashName } from "./oids";
import { children, expectTag, parseTlv, type Tlv } from "./tlv";

// LDSSecurityObject (ICAO 9303 Part 10, 4.6.2 / Part 12):
//   SEQUENCE { version INTEGER, hashAlgorithm AlgorithmIdentifier,
//              dataGroupHashValues SEQUENCE OF SEQUENCE { INTEGER, OCTET STRING },
//              ldsVersionInfo OPTIONAL }

export interface LdsSecurityObject {
  readonly hashAlgorithm: HashName;
  readonly dataGroupHashes: ReadonlyMap<number, Uint8Array>;
}

export function parseLdsSecurityObject(content: Uint8Array): LdsSecurityObject {
  const root = expectTag(parseTlv(content), TAG.sequence, "LDSSecurityObject");
  const [version, hashAlg, hashes] = children(root);
  const v = decodeUnsignedInteger(expectTag(version, TAG.integer, "version"));
  if (v > 1n) throw new ChipParseError("lds: unknown version");
  const alg = decodeAlgorithmIdentifier(expectTag(hashAlg, TAG.sequence, "hashAlgorithm"));
  const hashAlgorithm = HASH_OIDS[alg.oid];
  if (hashAlgorithm === undefined) throw new ChipParseError("lds: unsupported hash algorithm");
  const dataGroupHashes = new Map<number, Uint8Array>();
  for (const entry of children(expectTag(hashes, TAG.sequence, "dataGroupHashValues"))) {
    const pair = readPair(entry);
    if (dataGroupHashes.has(pair.number)) throw new ChipParseError("lds: duplicate data group");
    dataGroupHashes.set(pair.number, pair.hash);
  }
  if (dataGroupHashes.size === 0) throw new ChipParseError("lds: no data group hashes");
  return { hashAlgorithm, dataGroupHashes };
}

function readPair(entry: Tlv): { number: number; hash: Uint8Array } {
  expectTag(entry, TAG.sequence, "DataGroupHash");
  const [num, hash, extra] = children(entry);
  if (extra !== undefined) throw new ChipParseError("lds: bad DataGroupHash");
  const number = Number(decodeUnsignedInteger(expectTag(num, TAG.integer, "dataGroupNumber")));
  if (number < 1 || number > 16) throw new ChipParseError("lds: data group number out of range");
  return { number, hash: decodeOctetString(expectTag(hash, TAG.octetString, "dataGroupHashValue")) };
}
