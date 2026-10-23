// The format is decided by the file's own first bytes, never by the
// client-declared MIME type or extension.

export type AcceptedMime = "image/jpeg" | "image/png" | "application/pdf";

const PNG_SIGNATURE = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
const JPEG_SIGNATURE = [0xff, 0xd8, 0xff];
const PDF_SIGNATURE = [0x25, 0x50, 0x44, 0x46, 0x2d]; // "%PDF-"

function startsWith(bytes: Uint8Array, signature: readonly number[]): boolean {
  return bytes.length >= signature.length && signature.every((value, index) => bytes[index] === value);
}

export function detectFileKind(bytes: Uint8Array): AcceptedMime | null {
  if (startsWith(bytes, JPEG_SIGNATURE)) return "image/jpeg";
  if (startsWith(bytes, PNG_SIGNATURE)) return "image/png";
  if (startsWith(bytes, PDF_SIGNATURE)) return "application/pdf";
  return null;
}
