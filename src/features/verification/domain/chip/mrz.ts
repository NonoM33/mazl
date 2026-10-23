import { ChipParseError } from "./errors";
import type { ChipIdentity } from "../types";

// MRZ layouts and check digits, ICAO Doc 9303 Part 3 (check digits), Part 4
// (TD3, 2x44), Part 5 (TD1, 3x30) and Part 6 (TD2, 2x36).

const WEIGHTS = [7, 3, 1] as const;

function charValue(c: string): number {
  if (c >= "0" && c <= "9") return c.charCodeAt(0) - 48;
  if (c >= "A" && c <= "Z") return c.charCodeAt(0) - 55;
  if (c === "<") return 0;
  throw new ChipParseError("mrz: illegal character");
}

export function checkDigit(field: string): number {
  let sum = 0;
  for (let i = 0; i < field.length; i++) sum += charValue(field[i] as string) * (WEIGHTS[i % 3] as number);
  return sum % 10;
}

// A check digit may be '<' (counted as 0) only for an empty optional field.
function verifyDigit(field: string, digit: string, optional = false): void {
  if (digit === "<" && optional && /^<*$/.test(field)) return;
  if (!/^[0-9]$/.test(digit) || checkDigit(field) !== Number(digit)) throw new ChipParseError("mrz: check digit mismatch");
}

function strip(field: string): string {
  return field.replace(/<+$/g, "").replace(/</g, " ").trim();
}

function parseDate(yymmdd: string, kind: "birth" | "expiry", now: Date): string {
  if (!/^\d{6}$/.test(yymmdd)) throw new ChipParseError("mrz: bad date");
  const yy = Number(yymmdd.slice(0, 2));
  const mm = Number(yymmdd.slice(2, 4));
  const dd = Number(yymmdd.slice(4, 6));
  // Expiry dates are 20xx. A birth date in the future means the previous century.
  let year = 2000 + yy;
  if (kind === "birth" && !isOnOrBefore(year, mm, dd, now)) year -= 100;
  const probe = new Date(Date.UTC(year, mm - 1, dd));
  if (probe.getUTCFullYear() !== year || probe.getUTCMonth() !== mm - 1 || probe.getUTCDate() !== dd) {
    throw new ChipParseError("mrz: impossible date");
  }
  return `${String(year).padStart(4, "0")}-${String(mm).padStart(2, "0")}-${String(dd).padStart(2, "0")}`;
}

function isOnOrBefore(year: number, month: number, day: number, now: Date): boolean {
  const key = (y: number, m: number, d: number): number => y * 10000 + m * 100 + d;
  return key(year, month, day) <= key(now.getUTCFullYear(), now.getUTCMonth() + 1, now.getUTCDate());
}

function parseSex(c: string): ChipIdentity["sex"] {
  if (c === "M" || c === "F") return c;
  if (c === "<" || c === "X") return "X";
  throw new ChipParseError("mrz: bad sex");
}

function common(line1Head: string): { documentType: string; issuingState: string } {
  const documentType = line1Head.slice(0, 2).replace(/</g, "");
  const issuingState = line1Head.slice(2, 5).replace(/</g, "");
  if (documentType.length === 0 || issuingState.length === 0) throw new ChipParseError("mrz: missing type or state");
  return { documentType, issuingState };
}

function parseTd3(l1: string, l2: string, now: Date): ChipIdentity {
  verifyDigit(l2.slice(0, 9), l2[9] as string);
  verifyDigit(l2.slice(13, 19), l2[19] as string);
  verifyDigit(l2.slice(21, 27), l2[27] as string);
  verifyDigit(l2.slice(28, 42), l2[42] as string, true);
  verifyDigit(l2.slice(0, 10) + l2.slice(13, 20) + l2.slice(21, 43), l2[43] as string);
  return {
    ...common(l1),
    documentNumber: strip(l2.slice(0, 9)),
    birthDate: parseDate(l2.slice(13, 19), "birth", now),
    expiryDate: parseDate(l2.slice(21, 27), "expiry", now),
    sex: parseSex(l2[20] as string),
  };
}

function parseTd2(l1: string, l2: string, now: Date): ChipIdentity {
  verifyDigit(l2.slice(0, 9), l2[9] as string);
  verifyDigit(l2.slice(13, 19), l2[19] as string);
  verifyDigit(l2.slice(21, 27), l2[27] as string);
  verifyDigit(l2.slice(0, 10) + l2.slice(13, 20) + l2.slice(21, 35), l2[35] as string);
  return {
    ...common(l1),
    documentNumber: strip(l2.slice(0, 9)),
    birthDate: parseDate(l2.slice(13, 19), "birth", now),
    expiryDate: parseDate(l2.slice(21, 27), "expiry", now),
    sex: parseSex(l2[20] as string),
  };
}

// Document numbers longer than 9 characters spill into the optional field:
// the check-digit slot holds '<' and the number ends with its own check digit
// (9303 Part 5, 4.2.4).
function td1DocumentNumber(l1: string): string {
  if (l1[14] !== "<") {
    verifyDigit(l1.slice(5, 14), l1[14] as string);
    return strip(l1.slice(5, 14));
  }
  const optional = l1.slice(15, 30);
  const stop = optional.indexOf("<");
  const tail = stop === -1 ? optional : optional.slice(0, stop);
  if (tail.length < 2) throw new ChipParseError("mrz: bad long document number");
  const number = l1.slice(5, 14) + tail.slice(0, -1);
  verifyDigit(number, tail.slice(-1));
  return strip(number);
}

function parseTd1(l1: string, l2: string, now: Date): ChipIdentity {
  const documentNumber = td1DocumentNumber(l1);
  verifyDigit(l2.slice(0, 6), l2[6] as string);
  verifyDigit(l2.slice(8, 14), l2[14] as string);
  verifyDigit(l1.slice(5, 30) + l2.slice(0, 7) + l2.slice(8, 15) + l2.slice(18, 29), l2[29] as string);
  return {
    ...common(l1),
    documentNumber,
    birthDate: parseDate(l2.slice(0, 6), "birth", now),
    expiryDate: parseDate(l2.slice(8, 14), "expiry", now),
    sex: parseSex(l2[7] as string),
  };
}

export function parseMrz(mrz: string, now: Date): ChipIdentity {
  if (!/^[A-Z0-9<]+$/.test(mrz)) throw new ChipParseError("mrz: illegal characters");
  switch (mrz.length) {
    case 90:
      return parseTd1(mrz.slice(0, 30), mrz.slice(30, 60), now);
    case 72:
      return parseTd2(mrz.slice(0, 36), mrz.slice(36, 72), now);
    case 88:
      return parseTd3(mrz.slice(0, 44), mrz.slice(44, 88), now);
    default:
      throw new ChipParseError("mrz: unknown layout");
  }
}
