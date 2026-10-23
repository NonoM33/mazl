import { describe, expect, test } from "bun:test";
import { decodeOid } from "../../src/features/verification/domain/chip/asn1";
import { TlvError } from "../../src/features/verification/domain/chip/errors";
import { children, parseTlv, readTlv, value } from "../../src/features/verification/domain/chip/tlv";

const hex = (s: string): Uint8Array => new Uint8Array(Buffer.from(s.replace(/\s/g, ""), "hex"));

describe("strict TLV reader", () => {
  test("short, one-byte and two-byte long-form lengths", () => {
    expect(parseTlv(hex("0402aabb")).end).toBe(4);
    const l1 = parseTlv(hex("0481" + "80" + "00".repeat(0x80)));
    expect(l1.end - l1.valueStart).toBe(0x80);
    const l2 = parseTlv(hex("0482" + "0100" + "00".repeat(0x100)));
    expect(l2.end - l2.valueStart).toBe(0x100);
  });

  test("multi-byte tags (DG tags 5F1F, 7F61)", () => {
    expect(parseTlv(hex("5f1f02aabb")).tag).toBe(0x5f1f);
    const t = parseTlv(hex("7f6102" + "0200"));
    expect(t.tag).toBe(0x7f61);
    expect(t.constructed).toBe(true);
  });

  test("rejects an indefinite length", () => {
    expect(() => parseTlv(hex("30800000"))).toThrow(TlvError);
  });

  test("rejects non-minimal length encodings", () => {
    expect(() => parseTlv(hex("04810100"))).toThrow(TlvError); // 0x81 used for 1 (< 0x80)
    expect(() => parseTlv(hex("0482" + "0001" + "00"))).toThrow(TlvError); // leading zero length byte
  });

  test("rejects over-long length fields and lengths beyond the buffer", () => {
    expect(() => parseTlv(hex("0485" + "0000000001" + "00"))).toThrow(TlvError);
    expect(() => parseTlv(hex("0484ffffffff00"))).toThrow(TlvError);
    expect(() => parseTlv(hex("040500"))).toThrow(TlvError); // truncated value
  });

  test("rejects truncation at every point", () => {
    const full = hex("7f6106" + "020101" + "5f1f00");
    for (let len = 0; len < full.length; len++) expect(() => parseTlv(full.slice(0, len))).toThrow(TlvError);
    expect(() => parseTlv(full)).not.toThrow();
  });

  test("rejects trailing garbage", () => {
    expect(() => parseTlv(hex("0400ff"))).toThrow(TlvError);
  });

  test("children must consume the value exactly", () => {
    expect(() => children(parseTlv(hex("3004 0400 05")))).toThrow(TlvError);
    expect(children(parseTlv(hex("3004 0400 0500"))).map((c) => c.tag)).toEqual([4, 5]);
  });

  test("readTlv honours its limit", () => {
    expect(() => readTlv(hex("0402aabb"), 0, 3)).toThrow(TlvError);
  });

  test("OID decoding (SHA-256, rsaEncryption, multi-byte arcs)", () => {
    expect(decodeOid(parseTlv(hex("0609608648016503040201")))).toBe("2.16.840.1.101.3.4.2.1");
    expect(decodeOid(parseTlv(hex("06092a864886f70d010101")))).toBe("1.2.840.113549.1.1.1");
    expect(decodeOid(parseTlv(hex("0603883703")))).toBe("2.999.3"); // X.690 8.19.5 example
    expect(() => decodeOid(parseTlv(hex("060180")))).toThrow(TlvError);
    expect(value(parseTlv(hex("0400"))).length).toBe(0);
  });
});
