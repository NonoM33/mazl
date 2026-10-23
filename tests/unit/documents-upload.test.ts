import { describe, expect, test } from "bun:test";
import { createUploadDocument } from "../../src/features/documents/application/upload-document";
import { MAX_DOCUMENT_BYTES, DocumentUploadError } from "../../src/features/documents/domain/types";
import { open, SealedDataError } from "../../src/shared/crypto/secret-box";
import { containsBytes, fakeJpeg, MemoryRepo, MemoryStore, SECRET_MARKER } from "./documents-fakes";

function setup() {
  const repo = new MemoryRepo();
  const store = new MemoryStore();
  return { repo, store, upload: createUploadDocument({ repo, store }) };
}

async function rejectionCode(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof DocumentUploadError) return error.code;
    throw error;
  }
  throw new Error("expected a DocumentUploadError");
}

describe("upload-document", () => {
  test("stores only ciphertext, bound to document:<id>", async () => {
    const { repo, store, upload } = setup();
    const result = await upload({ waitlistId: 7, type: "selfie_id", bytes: fakeJpeg() });

    const row = repo.rows.get(result.documentId)!;
    expect(row.encrypted).toBe(true);
    expect(row.filename).toBe(result.filename);
    expect(result.filename).toMatch(/^documents\/[0-9a-f-]{36}\.enc$/);
    expect(row.mimeType).toBe("image/jpeg");

    const onDisk = store.files.get(result.filename)!;
    expect(containsBytes(onDisk, SECRET_MARKER)).toBe(false);
    expect(Buffer.from(open(onDisk, `document:${result.documentId}`)).equals(Buffer.from(fakeJpeg()))).toBe(true);
    expect(() => open(onDisk, `document:${result.documentId + 1}`)).toThrow(SealedDataError);
  });

  test("the format comes from the bytes, whatever the client claims", async () => {
    const { upload, store } = setup();
    const html = new TextEncoder().encode("<html>not an image</html>");
    expect(await rejectionCode(upload({ waitlistId: 1, type: "selfie_id", bytes: html }))).toBe("unsupported_format");
    expect(store.files.size).toBe(0);
  });

  test("refuses unknown types, empty files and files over 10 MB", async () => {
    const { upload, repo } = setup();
    expect(await rejectionCode(upload({ waitlistId: 1, type: "passport_scan", bytes: fakeJpeg() }))).toBe("invalid_type");
    expect(await rejectionCode(upload({ waitlistId: 1, type: "selfie_id", bytes: new Uint8Array() }))).toBe("empty_file");

    const big = new Uint8Array(MAX_DOCUMENT_BYTES + 1);
    big.set([0xff, 0xd8, 0xff]);
    expect(await rejectionCode(upload({ waitlistId: 1, type: "selfie_id", bytes: big }))).toBe("file_too_large");
    expect(repo.rows.size).toBe(0);
  });

  test("accepts exactly 10 MB", async () => {
    const { upload } = setup();
    const edge = new Uint8Array(MAX_DOCUMENT_BYTES);
    edge.set([0xff, 0xd8, 0xff]);
    const result = await upload({ waitlistId: 1, type: "id_card_front", bytes: edge });
    expect(result.documentId).toBeGreaterThan(0);
  });

  test("accepts the four known types", async () => {
    const { upload } = setup();
    for (const type of ["selfie_id", "id_card_front", "id_card_back", "community_doc"]) {
      await upload({ waitlistId: 1, type, bytes: fakeJpeg() });
    }
  });

  test("a failed write leaves no database row behind", async () => {
    const { upload, repo, store } = setup();
    store.failWrites = true;
    await expect(upload({ waitlistId: 1, type: "selfie_id", bytes: fakeJpeg() })).rejects.toThrow("disk full");
    expect(repo.rows.size).toBe(0);
  });

  test("the original filename is never stored", async () => {
    const { upload, repo } = setup();
    const { documentId } = await upload({ waitlistId: 1, type: "selfie_id", bytes: fakeJpeg() });
    expect(JSON.stringify(repo.rows.get(documentId))).not.toContain("passeport");
  });
});
