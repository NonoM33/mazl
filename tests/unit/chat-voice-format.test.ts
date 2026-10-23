import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { validateVoiceBytes } from "../../src/features/chat/domain/voice-format";

// ISO base media file format (ISO/IEC 14496-12): a file is a run of boxes, each
// "size(4, big endian) type(4) payload". An AAC voice note is ftyp + moov + mdat,
// with an 'mp4a' sample entry inside moov.

const ascii = (text: string): Uint8Array => new TextEncoder().encode(text);

function box(type: string, ...payload: Uint8Array[]): Uint8Array {
  const body = Buffer.concat(payload);
  const out = Buffer.alloc(8 + body.length);
  out.writeUInt32BE(8 + body.length, 0);
  out.write(type, 4, "latin1");
  body.copy(out, 8);
  return out;
}
const ftyp = (major: string, ...compat: string[]): Uint8Array =>
  box("ftyp", ascii(major), new Uint8Array(4), ...compat.map(ascii));
const moovWithAac = (): Uint8Array => box("moov", box("trak", box("mdia", box("stsd", ascii("....mp4a....")))));
const moovWithoutAac = (): Uint8Array => box("moov", box("trak", box("mdia", box("stsd", ascii("....alac...."))))); 
const mdat = (): Uint8Array => box("mdat", new Uint8Array(64));
const file = (...boxes: Uint8Array[]): Uint8Array => new Uint8Array(Buffer.concat(boxes));

describe("accepted", () => {
  test("M4A brand", () => {
    expect(validateVoiceBytes(file(ftyp("M4A ", "M4A ", "mp42", "isom"), moovWithAac(), mdat()))).toEqual({ ok: true });
  });
  test("mp42 and isom major brands (what Android recorders write)", () => {
    expect(validateVoiceBytes(file(ftyp("mp42", "isom"), moovWithAac(), mdat())).ok).toBe(true);
    expect(validateVoiceBytes(file(ftyp("isom"), moovWithAac(), mdat())).ok).toBe(true);
  });
  test("mdat before moov (a recorder that does not move the index) is fine", () => {
    expect(validateVoiceBytes(file(ftyp("M4A "), mdat(), moovWithAac())).ok).toBe(true);
  });
  test("a real AAC recording made by Apple's encoder (afconvert)", () => {
    const bytes = new Uint8Array(readFileSync(join(import.meta.dir, "../fixtures/chat/voice.m4a")));
    expect(validateVoiceBytes(bytes)).toEqual({ ok: true });
  });
});

describe("refused", () => {
  const refused: Array<[string, Uint8Array]> = [
    ["empty", new Uint8Array()],
    ["too short", ascii("ftyp")],
    ["a JPEG", Uint8Array.from([0xff, 0xd8, 0xff, 0xe0, 0, 16, 0x4a, 0x46, 0x49, 0x46, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0])],
    ["a WAV", ascii("RIFF$\u0000\u0000\u0000WAVEfmt \u0010\u0000\u0000\u0000")],
    ["an MP3", Uint8Array.from([0x49, 0x44, 0x33, 3, 0, 0, 0, 0, 0, 0x21, 0xff, 0xfb, 0x90, 0, 0, 0, 0, 0, 0, 0])],
    ["plain text named .m4a", ascii("this is not audio at all, only a long enough string")],
    ["an HEIC image (ftyp, wrong brand)", file(ftyp("heic", "mif1"), box("meta", new Uint8Array(32)), mdat())],
    ["a QuickTime movie (ftyp qt)", file(ftyp("qt  ", "qt  "), moovWithAac(), mdat())],
    ["ftyp not first", file(mdat(), ftyp("M4A "), moovWithAac())],
    ["ftyp only, no moov", file(ftyp("M4A "), mdat())],
    ["no mdat", file(ftyp("M4A "), moovWithAac())],
    ["not AAC (alac sample entry)", file(ftyp("M4A "), moovWithoutAac(), mdat())],
    ["ftyp declared larger than the file", (() => {
      const b = Buffer.from(file(ftyp("M4A ")));
      b.writeUInt32BE(5000, 0);
      return new Uint8Array(b);
    })()],
    ["ftyp with a size smaller than its header", (() => {
      const b = Buffer.from(file(ftyp("M4A "), moovWithAac(), mdat()));
      b.writeUInt32BE(4, 0);
      return new Uint8Array(b);
    })()],
    ["a box that overruns the file", (() => {
      const b = Buffer.from(file(ftyp("M4A "), moovWithAac(), mdat()));
      b.writeUInt32BE(0x7fffffff, ftyp("M4A ").length); // the size field of moov
      return new Uint8Array(b);
    })()],
  ];
  for (const [label, bytes] of refused) {
    test(label, () => {
      const result = validateVoiceBytes(bytes);
      expect(result.ok).toBe(false);
    });
  }

  test("the extension and any declared MIME type play no part: only bytes are read", () => {
    // validateVoiceBytes has no name/MIME parameter by construction.
    expect(validateVoiceBytes.length).toBe(1);
  });
});
