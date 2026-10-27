import { firstHttpUrl } from "../../chat/domain/url-extract";

// The word that goes with a Super Like (docs/premium/MONETISATION.md section 5):
// 140 characters, treated like a message (trimmed, no control characters, no
// link). No other content filter exists on the server: the same rules as a
// text message apply, and the word is reportable like one.

export const NOTE_MAX_CHARACTERS = 140;

export type NoteVerdict =
  | { readonly kind: "none" }
  | { readonly kind: "valid"; readonly note: string }
  | { readonly kind: "invalid" };

// eslint-disable-next-line no-control-regex -- the point is to refuse control characters
const CONTROL = /[\u0000-\u0009\u000b-\u001f\u007f-\u009f]/;
const BARE_LINK = /\bwww\.[^\s]+/i;

// undefined and null mean « no word ».
export function readNote(raw: unknown): NoteVerdict {
  if (raw === undefined || raw === null) return { kind: "none" };
  if (typeof raw !== "string") return { kind: "invalid" };
  const note = raw.replace(/\r\n?/g, "\n").trim();
  if (note.length === 0 || CONTROL.test(note)) return { kind: "invalid" };
  // Counted in characters, not in UTF-16 units: an emoji is one.
  if (Array.from(note).length > NOTE_MAX_CHARACTERS) return { kind: "invalid" };
  if (firstHttpUrl(note) !== null || BARE_LINK.test(note)) return { kind: "invalid" };
  return { kind: "valid", note };
}
