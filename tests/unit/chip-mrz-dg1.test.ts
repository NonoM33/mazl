import { describe, expect, test } from "bun:test";
import { ChipParseError } from "../../src/features/verification/domain/chip/errors";
import { parseDg1 } from "../../src/features/verification/domain/chip/dg1";
import { ageOn, documentFingerprintMessage, isExpired } from "../../src/features/verification/domain/chip/identity-helpers";
import { checkDigit, parseMrz } from "../../src/features/verification/domain/chip/mrz";
import { encodeTlv } from "../../src/features/verification/domain/chip/tlv";

const NOW = new Date("2026-10-23T12:00:00Z");

// ICAO Doc 9303 Part 4 (TD3) and Part 5 (TD1) specimen MRZs, check digits as published.
const TD3 = "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<" + "L898902C36UTO7408122F1204159ZE184226B<<<<<10";
const TD1 = "I<UTOD231458907<<<<<<<<<<<<<<<" + "7408122F1204159UTO<<<<<<<<<<<6" + "ERIKSSON<<ANNA<MARIA<<<<<<<<<<";

describe("check digits (ICAO 9303 Part 3, weights 7-3-1)", () => {
  test("published specimen values", () => {
    expect(checkDigit("L898902C3")).toBe(6);
    expect(checkDigit("740812")).toBe(2);
    expect(checkDigit("120415")).toBe(9);
    expect(checkDigit("ZE184226B<<<<<")).toBe(1);
    expect(checkDigit("D23145890")).toBe(7);
  });
});

describe("MRZ parsing", () => {
  test("TD3 specimen", () => {
    expect(parseMrz(TD3, NOW)).toEqual({
      documentType: "P",
      issuingState: "UTO",
      documentNumber: "L898902C3",
      birthDate: "1974-08-12",
      expiryDate: "2012-04-15",
      sex: "F",
    });
  });

  test("TD1 specimen", () => {
    expect(parseMrz(TD1, NOW)).toEqual({
      documentType: "I",
      issuingState: "UTO",
      documentNumber: "D23145890",
      birthDate: "1974-08-12",
      expiryDate: "2012-04-15",
      sex: "F",
    });
  });

  test("TD1 with a document number longer than 9 characters (check digit slot holds '<')", () => {
    // 12-char number "ABCDEFGHI123": the first 9 sit in line 1, the rest + its check digit in the optional field.
    const number = "ABCDEFGHI123";
    const cd = checkDigit(number);
    const l1 = ("I<UTO" + "ABCDEFGHI" + "<" + "123" + String(cd) + "<").padEnd(30, "<");
    const l2body = "7408122F1204159UTO" + "<".repeat(11);
    const composite = checkDigit(l1.slice(5, 30) + l2body.slice(0, 7) + l2body.slice(8, 15) + l2body.slice(18, 29));
    const mrz = l1 + l2body + String(composite) + "ERIKSSON<<ANNA<MARIA<<<<<<<<<<";
    expect(parseMrz(mrz, NOW).documentNumber).toBe(number);
  });

  test("TD2 layout", () => {
    const l1 = "I<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<";
    const num = "D23145890";
    const l2head = num + String(checkDigit(num)) + "UTO" + "7408122" + "F" + "1204159" + "<<<<<<<";
    const l2 = l2head + String(checkDigit(l2head.slice(0, 10) + l2head.slice(13, 20) + l2head.slice(21, 35)));
    expect(l1.length).toBe(36);
    expect(l2.length).toBe(36);
    expect(parseMrz(l1 + l2, NOW).documentNumber).toBe("D23145890");
  });

  test("a bad check digit anywhere is rejected", () => {
    const positions = [44 + 9, 44 + 19, 44 + 27, 44 + 42, 44 + 43];
    for (const at of positions) {
      const bad = TD3.slice(0, at) + String((Number(TD3[at]) + 1) % 10) + TD3.slice(at + 1);
      expect(() => parseMrz(bad, NOW)).toThrow(ChipParseError);
    }
    const td1Bad = TD1.slice(0, 14) + "8" + TD1.slice(15);
    expect(() => parseMrz(td1Bad, NOW)).toThrow(ChipParseError);
  });

  test("altering a covered field without fixing its digit is rejected", () => {
    const bad = TD3.slice(0, 44 + 3) + "9" + TD3.slice(44 + 4); // document number digit
    expect(() => parseMrz(bad, NOW)).toThrow(ChipParseError);
  });

  test("wrong length, illegal characters, impossible dates", () => {
    expect(() => parseMrz(TD3.slice(0, 87), NOW)).toThrow(ChipParseError);
    expect(() => parseMrz(TD3.toLowerCase(), NOW)).toThrow(ChipParseError);
    expect(() => parseMrz("", NOW)).toThrow(ChipParseError);
    const feb30 = "L898902C3" ;
    const l2 = feb30 + String(checkDigit(feb30)) + "UTO" + "740230" + String(checkDigit("740230")) + "F" + "120415" + "9" + "ZE184226B<<<<<" + "1";
    const withComposite = l2 + String(checkDigit(l2.slice(0, 10) + l2.slice(13, 20) + l2.slice(21, 43)));
    expect(() => parseMrz(TD3.slice(0, 44) + withComposite, NOW)).toThrow(ChipParseError);
  });

  test("century rule: future birth dates roll back, expiry is always 20xx", () => {
    const build = (birth: string, expiry: string): string => {
      const l2a = "L898902C3" + "6" + "UTO" + birth + String(checkDigit(birth)) + "F" + expiry + String(checkDigit(expiry)) + "ZE184226B<<<<<" + "1";
      return TD3.slice(0, 44) + l2a + String(checkDigit(l2a.slice(0, 10) + l2a.slice(13, 20) + l2a.slice(21, 43)));
    };
    expect(parseMrz(build("261023", "400101"), NOW).birthDate).toBe("2026-10-23"); // today: not in the future
    expect(parseMrz(build("261024", "400101"), NOW).birthDate).toBe("1926-10-24"); // tomorrow: 1926
    expect(parseMrz(build("050101", "400101"), NOW).birthDate).toBe("2005-01-01");
    expect(parseMrz(build("990101", "990101"), NOW).expiryDate).toBe("2099-01-01");
    expect(parseMrz(build("000101", "400101"), NOW).birthDate).toBe("2000-01-01");
  });
});

describe("DG1", () => {
  const dg1 = (mrz: string): Uint8Array => encodeTlv(0x61, encodeTlv(0x5f1f, new TextEncoder().encode(mrz)));

  test("parses a TD3 DG1", () => {
    expect(parseDg1(dg1(TD3), NOW).documentNumber).toBe("L898902C3");
  });

  test("rejects wrong tags, extra content and trailing bytes", () => {
    expect(() => parseDg1(encodeTlv(0x62, encodeTlv(0x5f1f, new TextEncoder().encode(TD3))), NOW)).toThrow(ChipParseError);
    expect(() => parseDg1(encodeTlv(0x61, encodeTlv(0x5f20, new TextEncoder().encode(TD3))), NOW)).toThrow(ChipParseError);
    expect(() => parseDg1(Uint8Array.of(...dg1(TD3), 0), NOW)).toThrow(ChipParseError);
    expect(() => parseDg1(new Uint8Array(0), NOW)).toThrow(ChipParseError);
  });
});

describe("identity helpers", () => {
  const identity = { issuingState: "FRA", documentNumber: "12AB34567", birthDate: "2000-03-15", expiryDate: "2030-06-01" };

  test("isExpired: valid through the whole expiry day", () => {
    expect(isExpired(identity, new Date("2030-06-01T23:59:59Z"))).toBe(false);
    expect(isExpired(identity, new Date("2030-06-02T00:00:00Z"))).toBe(true);
    expect(isExpired(identity, new Date("2020-01-01T00:00:00Z"))).toBe(false);
  });

  test("ageOn counts completed years", () => {
    expect(ageOn(identity, new Date("2018-03-14T00:00:00Z"))).toBe(17);
    expect(ageOn(identity, new Date("2018-03-15T00:00:00Z"))).toBe(18);
    expect(ageOn(identity, new Date("2026-10-23T00:00:00Z"))).toBe(26);
    expect(ageOn({ birthDate: "2000-02-29" }, new Date("2001-02-28T00:00:00Z"))).toBe(0);
    expect(ageOn({ birthDate: "2000-02-29" }, new Date("2001-03-01T00:00:00Z"))).toBe(1);
  });

  test("documentFingerprintMessage", () => {
    expect(documentFingerprintMessage(identity)).toBe("FRA|12AB34567|2000-03-15");
  });
});
