// Base32, RFC 4648 section 6 (alphabet A-Z 2-7). Encoding has no padding, the
// form authenticator apps expect in an otpauth URI; decoding tolerates
// padding, spaces and lower case.

const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

export class Base32Error extends Error {
  constructor(character: string) {
    super(`not a base32 character: ${JSON.stringify(character)}`);
    this.name = "Base32Error";
  }
}

export function base32Encode(bytes: Uint8Array): string {
  let bits = 0;
  let buffer = 0;
  let out = "";
  for (const byte of bytes) {
    buffer = (buffer << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      out += ALPHABET[(buffer >>> (bits - 5)) & 31];
      bits -= 5;
    }
    buffer &= (1 << bits) - 1;
  }
  if (bits > 0) out += ALPHABET[(buffer << (5 - bits)) & 31];
  return out;
}

export function base32Decode(text: string): Uint8Array {
  const clean = text.replace(/[\s=]/g, "").toUpperCase();
  const out: number[] = [];
  let bits = 0;
  let buffer = 0;
  for (const character of clean) {
    const value = ALPHABET.indexOf(character);
    if (value < 0) throw new Base32Error(character);
    buffer = (buffer << 5) | value;
    bits += 5;
    if (bits >= 8) {
      out.push((buffer >>> (bits - 8)) & 255);
      bits -= 8;
    }
    buffer &= (1 << bits) - 1;
  }
  return Uint8Array.from(out);
}
