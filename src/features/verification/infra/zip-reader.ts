import { inflateRawSync } from "node:zlib";

// Minimal ZIP reader (stored and deflate entries) for the BSI download. No
// ZIP64, no encryption: anything else is refused rather than guessed at.

export interface ZipEntry {
  readonly name: string;
  readonly data: Uint8Array;
}

const EOCD_SIGNATURE = 0x06054b50;
const CENTRAL_SIGNATURE = 0x02014b50;
const LOCAL_SIGNATURE = 0x04034b50;
const MAX_ENTRY_BYTES = 64 * 1024 * 1024;

export function readZip(bytes: Uint8Array): ZipEntry[] {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  let eocd = -1;
  for (let i = bytes.length - 22; i >= Math.max(0, bytes.length - 22 - 0xffff); i--) {
    if (view.getUint32(i, true) === EOCD_SIGNATURE) {
      eocd = i;
      break;
    }
  }
  if (eocd < 0) throw new Error("zip: end of central directory not found");
  const count = view.getUint16(eocd + 10, true);
  let pos = view.getUint32(eocd + 16, true);
  const entries: ZipEntry[] = [];
  for (let n = 0; n < count; n++) {
    if (view.getUint32(pos, true) !== CENTRAL_SIGNATURE) throw new Error("zip: bad central directory");
    const method = view.getUint16(pos + 10, true);
    const compressedSize = view.getUint32(pos + 20, true);
    const nameLength = view.getUint16(pos + 28, true);
    const extraLength = view.getUint16(pos + 30, true);
    const commentLength = view.getUint16(pos + 32, true);
    const localOffset = view.getUint32(pos + 42, true);
    const name = new TextDecoder().decode(bytes.subarray(pos + 46, pos + 46 + nameLength));
    pos += 46 + nameLength + extraLength + commentLength;
    if (view.getUint32(localOffset, true) !== LOCAL_SIGNATURE) throw new Error("zip: bad local header");
    const dataStart = localOffset + 30 + view.getUint16(localOffset + 26, true) + view.getUint16(localOffset + 28, true);
    const stored = bytes.subarray(dataStart, dataStart + compressedSize);
    if (method === 0) entries.push({ name, data: stored });
    else if (method === 8) entries.push({ name, data: new Uint8Array(inflateRawSync(stored, { maxOutputLength: MAX_ENTRY_BYTES })) });
    else throw new Error(`zip: unsupported compression method ${method}`);
  }
  return entries;
}
