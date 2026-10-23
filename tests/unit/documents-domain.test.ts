import { describe, expect, test } from "bun:test";
import { detectFileKind } from "../../src/features/documents/domain/file-kind";
import { findMissingRequired } from "../../src/features/documents/domain/required-documents";
import type { DocumentRecord } from "../../src/features/documents/domain/types";

const bytes = (...values: number[]) => new Uint8Array(values);
const ascii = (text: string) => new TextEncoder().encode(text);

describe("detectFileKind (magic bytes, not client MIME)", () => {
  test("recognises JPEG, PNG and PDF", () => {
    expect(detectFileKind(bytes(0xff, 0xd8, 0xff, 0xe1, 0x00))).toBe("image/jpeg");
    expect(detectFileKind(bytes(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0))).toBe("image/png");
    expect(detectFileKind(ascii("%PDF-1.7\n"))).toBe("application/pdf");
  });

  test("refuses HTML, scripts, GIF, executables and empty input", () => {
    expect(detectFileKind(ascii("<html><script>alert(1)</script>"))).toBeNull();
    expect(detectFileKind(ascii("GIF89a"))).toBeNull();
    expect(detectFileKind(bytes(0x4d, 0x5a, 0x90, 0x00))).toBeNull(); // MZ
    expect(detectFileKind(new Uint8Array())).toBeNull();
  });

  test("a truncated PNG signature is not a PNG", () => {
    expect(detectFileKind(bytes(0x89, 0x50, 0x4e, 0x47))).toBeNull();
  });

  test("a PDF header that does not start the file is refused", () => {
    expect(detectFileKind(ascii("junk%PDF-1.4"))).toBeNull();
  });
});

function doc(partial: Partial<DocumentRecord>): DocumentRecord {
  return {
    id: 1, waitlistId: 1, type: "selfie_id", filename: "x", mimeType: null, status: "pending",
    encrypted: true, purgedAt: null, createdAt: new Date(), ...partial,
  };
}

describe("findMissingRequired", () => {
  const all = {
    selfie_id: doc({ type: "selfie_id" }),
    id_card_front: doc({ type: "id_card_front" }),
    id_card_back: doc({ type: "id_card_back" }),
  };

  test("nothing missing when the three documents are present", () => {
    expect(findMissingRequired(all)).toEqual([]);
  });

  test("absent and rejected documents are missing", () => {
    expect(findMissingRequired({ ...all, id_card_back: undefined as never })).toEqual(["id_card_back"]);
    expect(findMissingRequired({ ...all, selfie_id: doc({ status: "rejected" }) })).toEqual(["selfie_id"]);
  });

  test("an approved document that was purged still counts", () => {
    const purged = doc({ status: "approved", filename: null, purgedAt: new Date() });
    expect(findMissingRequired({ ...all, selfie_id: purged })).toEqual([]);
  });

  test("an undecided document purged after 30 days must be sent again", () => {
    const stale = doc({ status: "pending", filename: null, purgedAt: new Date() });
    expect(findMissingRequired({ ...all, id_card_front: stale })).toEqual(["id_card_front"]);
  });

  test("community_doc is never required", () => {
    expect(findMissingRequired(all)).not.toContain("community_doc");
  });
});
