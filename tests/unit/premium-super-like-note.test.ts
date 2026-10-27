import { describe, expect, test } from "bun:test";
import { NOTE_MAX_CHARACTERS, readNote } from "../../src/features/matching/domain/super-like-note";

// docs/premium/MONETISATION.md section 5: 140 characters, treated like a message.

describe("the word of a Super Like", () => {
  test("no word is fine", () => {
    expect(readNote(undefined)).toEqual({ kind: "none" });
    expect(readNote(null)).toEqual({ kind: "none" });
  });

  test("is trimmed and kept", () => {
    expect(readNote("  Votre sourire à la soirée de Hanoucca  ")).toEqual({ kind: "valid", note: "Votre sourire à la soirée de Hanoucca" });
  });

  test("140 characters pass, 141 do not", () => {
    expect(readNote("a".repeat(NOTE_MAX_CHARACTERS)).kind).toBe("valid");
    expect(readNote("a".repeat(NOTE_MAX_CHARACTERS + 1)).kind).toBe("invalid");
  });

  test("characters are counted, not UTF-16 units: 140 emoji pass", () => {
    expect(readNote("😀".repeat(140)).kind).toBe("valid");
    expect(readNote("😀".repeat(141)).kind).toBe("invalid");
  });

  test("empty, blank, not a string, control characters and links are refused", () => {
    for (const raw of ["", "   \n ", 42, {}, ["a"], "bonjour\u0000", "bonjour\u001b[31m", "voir https://example.com/x", "http://example.com", "www.example.com/profil"]) {
      expect([raw, readNote(raw).kind]).toEqual([raw, "invalid"]);
    }
  });

  test("a line break is allowed", () => {
    expect(readNote("Bonjour\nà vous").kind).toBe("valid");
  });
});
