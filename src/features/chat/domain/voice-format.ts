// A voice note is accepted by its BYTES, never by a file name or a declared
// MIME type (CONTRAT.md §0.2): an ISO base media file whose first box is `ftyp`
// with an M4A/MP4 brand, that carries `moov` and `mdat`, and an AAC (`mp4a`)
// sample entry.

export type VoiceCheck = { readonly ok: true } | { readonly ok: false; readonly reason: VoiceRejection };
export type VoiceRejection = "not_mp4" | "bad_brand" | "incomplete" | "not_aac";

const MAJOR_BRANDS = new Set(["M4A ", "M4B ", "mp42", "isom", "iso2"]);
const MAX_FTYP_BYTES = 256;
const MAX_TOP_LEVEL_BOXES = 64;

interface Box {
  readonly type: string;
  readonly start: number;
  readonly end: number;
}

function fourcc(bytes: Uint8Array, at: number): string {
  return String.fromCharCode(bytes[at] ?? 0, bytes[at + 1] ?? 0, bytes[at + 2] ?? 0, bytes[at + 3] ?? 0);
}

function uint32(bytes: Uint8Array, at: number): number {
  return ((bytes[at] ?? 0) * 0x1000000) + ((bytes[at + 1] ?? 0) << 16) + ((bytes[at + 2] ?? 0) << 8) + (bytes[at + 3] ?? 0);
}

// Top-level boxes, or null when the structure is malformed. 64-bit sizes
// (size == 1) and "to the end" boxes (size == 0) are the only special cases.
function topLevelBoxes(bytes: Uint8Array): Box[] | null {
  const boxes: Box[] = [];
  let at = 0;
  while (at < bytes.length) {
    if (boxes.length >= MAX_TOP_LEVEL_BOXES || at + 8 > bytes.length) return null;
    const size = uint32(bytes, at);
    let end: number;
    if (size === 0) end = bytes.length;
    else if (size === 1) return null; // a voice note never needs a 64-bit box
    else end = at + size;
    if (size !== 0 && size < 8) return null;
    if (end > bytes.length) return null;
    boxes.push({ type: fourcc(bytes, at + 4), start: at, end });
    at = end;
  }
  return boxes;
}

function containsFourcc(bytes: Uint8Array, box: Box, wanted: string): boolean {
  const needle = Buffer.from(wanted, "latin1");
  return Buffer.from(bytes.buffer, bytes.byteOffset + box.start, box.end - box.start).includes(needle);
}

function brandsAccepted(bytes: Uint8Array, ftyp: Box): boolean {
  const size = ftyp.end - ftyp.start;
  if (size < 16 || size > MAX_FTYP_BYTES) return false;
  if (MAJOR_BRANDS.has(fourcc(bytes, ftyp.start + 8))) return true;
  for (let at = ftyp.start + 16; at + 4 <= ftyp.end; at += 4) {
    if (fourcc(bytes, at) === "M4A ") return true;
  }
  return false;
}

export function validateVoiceBytes(bytes: Uint8Array): VoiceCheck {
  if (bytes.length < 24 || fourcc(bytes, 4) !== "ftyp") return { ok: false, reason: "not_mp4" };
  const boxes = topLevelBoxes(bytes);
  const first = boxes?.[0];
  if (boxes === null || first === undefined || first.type !== "ftyp") return { ok: false, reason: "not_mp4" };
  if (!brandsAccepted(bytes, first)) return { ok: false, reason: "bad_brand" };
  const moov = boxes.find((box) => box.type === "moov");
  if (moov === undefined || !boxes.some((box) => box.type === "mdat")) return { ok: false, reason: "incomplete" };
  if (!containsFourcc(bytes, moov, "mp4a")) return { ok: false, reason: "not_aac" };
  return { ok: true };
}
