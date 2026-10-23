import { describe, expect, test } from "bun:test";
import { ChipParseError } from "../../src/features/verification/domain/chip/errors";
import { detectImageFormat, parseDg2 } from "../../src/features/verification/domain/chip/dg2";
import { encodeTlv } from "../../src/features/verification/domain/chip/tlv";
import { fixtureJpeg, loadFiles } from "./chip-fixtures";

const concat = (...parts: Uint8Array[]): Uint8Array => Uint8Array.of(...parts.flatMap((p) => [...p]));

// Builds a DG2 around an arbitrary image payload, per ISO/IEC 19794-5.
function dg2(image: Uint8Array, opts: { featurePoints?: number; bdbTag?: number } = {}): Uint8Array {
  const fp = opts.featurePoints ?? 0;
  const facial = new Uint8Array(20);
  facial[4] = fp >> 8;
  facial[5] = fp & 0xff;
  const record = concat(
    Uint8Array.of(0x46, 0x41, 0x43, 0x00, 0x30, 0x31, 0x30, 0x00, 0, 0, 0, 0, 0, 1),
    facial,
    new Uint8Array(fp * 8),
    new Uint8Array(12),
    image,
  );
  const instance = encodeTlv(0x7f60, concat(encodeTlv(0xa1, encodeTlv(0x81, Uint8Array.of(2))), encodeTlv(opts.bdbTag ?? 0x5f2e, record)));
  return encodeTlv(0x75, encodeTlv(0x7f61, concat(encodeTlv(0x02, Uint8Array.of(1)), instance)));
}

const JP2_BOX = Uint8Array.of(0, 0, 0, 0x0c, 0x6a, 0x50, 0x20, 0x20, 0x0d, 0x0a, 0x87, 0x0a, 1, 2, 3);
const J2K = Uint8Array.of(0xff, 0x4f, 0xff, 0x51, 9, 9, 9);

describe("DG2", () => {
  test("extracts the JPEG of an OpenSSL-independent fixture", () => {
    const face = parseDg2(loadFiles("rsa-pkcs1").dg2);
    expect(face.format).toBe("jpeg");
    expect(Buffer.from(face.bytes).equals(Buffer.from(fixtureJpeg("face-a")))).toBe(true);
  });

  test("JPEG 2000 JP2 box format and raw J2K codestream", () => {
    expect(parseDg2(dg2(JP2_BOX))).toEqual({ bytes: JP2_BOX, format: "jp2" });
    expect(parseDg2(dg2(J2K))).toEqual({ bytes: J2K, format: "jp2" });
  });

  test("feature points shift the image offset; 7F2E is accepted for the data block", () => {
    const jpeg = fixtureJpeg("face-b");
    expect(parseDg2(dg2(jpeg, { featurePoints: 3 })).bytes).toEqual(jpeg);
    expect(parseDg2(dg2(jpeg, { bdbTag: 0x7f2e })).format).toBe("jpeg");
  });

  test("format detection by magic bytes", () => {
    expect(detectImageFormat(Uint8Array.of(0xff, 0xd8, 0xff, 0xe0))).toBe("jpeg");
    expect(detectImageFormat(JP2_BOX)).toBe("jp2");
    expect(detectImageFormat(Uint8Array.of(0x89, 0x50, 0x4e, 0x47))).toBeUndefined();
  });

  test("rejects an unknown image payload, a missing record header and wrong structure", () => {
    expect(() => parseDg2(dg2(Uint8Array.of(0x89, 0x50, 0x4e, 0x47, 0, 0, 0, 0)))).toThrow(ChipParseError);
    const notFac = encodeTlv(0x75, encodeTlv(0x7f61, concat(encodeTlv(0x02, Uint8Array.of(1)), encodeTlv(0x7f60, encodeTlv(0x5f2e, new Uint8Array(40))))));
    expect(() => parseDg2(notFac)).toThrow(ChipParseError);
    expect(() => parseDg2(encodeTlv(0x75, new Uint8Array(0)))).toThrow(ChipParseError);
    expect(() => parseDg2(encodeTlv(0x76, new Uint8Array(0)))).toThrow(ChipParseError);
    expect(() => parseDg2(new Uint8Array(0))).toThrow(ChipParseError);
    expect(() => parseDg2(encodeTlv(0x75, encodeTlv(0x7f61, encodeTlv(0x02, Uint8Array.of(1)))))).toThrow(ChipParseError);
  });

  test("every truncation of a real DG2 is rejected without a stray exception type", () => {
    const real = loadFiles("rsa-pkcs1").dg2;
    for (let len = 0; len < real.length; len += 3) {
      try {
        parseDg2(real.slice(0, len));
        throw new Error("accepted a truncated DG2");
      } catch (e) {
        expect(e).toBeInstanceOf(ChipParseError);
      }
    }
  });
});
