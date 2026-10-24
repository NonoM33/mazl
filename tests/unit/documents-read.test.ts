import { describe, expect, test } from "bun:test";
import { createReadDocument } from "../../src/features/documents/application/read-document";
import { createUploadDocument } from "../../src/features/documents/application/upload-document";
import { seal } from "../../src/shared/crypto/secret-box";
import { fakeJpeg, MemoryRepo, MemoryStore } from "./documents-fakes";

describe("read-document (admin viewing)", () => {
  test("decrypts a sealed document on the fly", async () => {
    const repo = new MemoryRepo();
    const store = new MemoryStore();
    const { documentId } = await createUploadDocument({ repo, store })({ waitlistId: 1, type: "selfie_id", bytes: fakeJpeg() });

    const result = await createReadDocument({ repo, store })(documentId);
    expect(result.kind).toBe("ok");
    if (result.kind === "ok") {
      expect(Buffer.from(result.bytes).equals(Buffer.from(fakeJpeg()))).toBe(true);
      expect(result.mimeType).toBe("image/jpeg");
    }
  });

  test("legacy plaintext files stay readable until migrated", async () => {
    const repo = new MemoryRepo();
    const store = new MemoryStore();
    const row = repo.seed({ filename: "1-selfie_id-abc.jpg", encrypted: false, mimeType: "image/jpeg" });
    await store.write("1-selfie_id-abc.jpg", fakeJpeg());

    const result = await createReadDocument({ repo, store })(row.id);
    expect(result.kind).toBe("ok");
  });

  test("unknown, purged and missing documents are told apart", async () => {
    const repo = new MemoryRepo();
    const store = new MemoryStore();
    const read = createReadDocument({ repo, store });
    expect((await read(999)).kind).toBe("not_found");

    const purged = repo.seed({ filename: null, purgedAt: new Date(), status: "approved" });
    expect((await read(purged.id)).kind).toBe("purged");

    const lost = repo.seed({ filename: "documents/gone.enc", encrypted: true });
    expect((await read(lost.id)).kind).toBe("file_missing");
  });

  test("a sealed file moved under another row cannot be opened", async () => {
    const repo = new MemoryRepo();
    const store = new MemoryStore();
    const a = repo.seed({ filename: "documents/a.enc", encrypted: true });
    const b = repo.seed({ filename: "documents/b.enc", encrypted: true });
    await store.write("documents/a.enc", seal(fakeJpeg(), `document:${a.id}`));
    await store.write("documents/b.enc", seal(fakeJpeg(), `document:${a.id}`)); // copied under b

    const read = createReadDocument({ repo, store });
    expect((await read(a.id)).kind).toBe("ok");
    await expect(read(b.id)).rejects.toThrow();
  });
});
