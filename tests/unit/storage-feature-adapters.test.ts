import { describe, expect, test } from "bun:test";
import { createChatStorage } from "../../src/features/chat/infra/chat-storage";
import { ObjectDocumentFileStore } from "../../src/features/documents/infra/object-document-file-store";
import { createPhotoStorage } from "../../src/features/media/infra/photo-storage";
import { createStorePhotoReader } from "../../src/features/verification/infra/store-photo-reader";
import { createS3ObjectStore } from "../../src/shared/storage/s3-object-store";
import { FakeS3Client } from "./storage-fakes";

const bytes = (...values: number[]): Uint8Array => new Uint8Array(values);
const LEGACY_DOC = "12-selfie_id-0b9a1f3e-aaaa-4bbb-8ccc-1234567890ab.jpg";

function bucket(): { client: FakeS3Client; store: ReturnType<typeof createS3ObjectStore> } {
  const client = new FakeS3Client();
  return { client, store: createS3ObjectStore(client) };
}

describe("photo storage over a bucket", () => {
  test("save, read, remove; a missing photo reads as null and removing it is fine", async () => {
    const { client, store } = bucket();
    const photos = createPhotoStorage(store);
    await photos.save("profiles/7/abc.jpg", bytes(1, 2));
    expect([...client.objects.keys()]).toEqual(["profiles/7/abc.jpg"]);
    expect(await photos.read("profiles/7/abc.jpg")).toEqual(bytes(1, 2));
    await photos.remove("profiles/7/abc.jpg");
    expect(await photos.read("profiles/7/abc.jpg")).toBeNull();
    await photos.remove("profiles/7/abc.jpg");
  });

  test("a key can never leave the bucket's prefix", async () => {
    const { store } = bucket();
    await expect(createPhotoStorage(store).save("../x.jpg", bytes(1))).rejects.toThrow();
  });
});

describe("chat storage over a bucket", () => {
  test("lists chat files with their keys, like the disk listing the sweep relies on", async () => {
    const { store } = bucket();
    const chat = createChatStorage(store);
    await chat.save("chat/7/a.jpg", bytes(1));
    await chat.save("chat/preview-cache/p.jpg", bytes(1));
    await chat.save("profiles/7/x.jpg", bytes(1));
    expect((await chat.list("chat")).map((f) => f.key)).toEqual(["chat/7/a.jpg", "chat/preview-cache/p.jpg"]);
    await expect(chat.list("../outside")).rejects.toThrow();
  });
});

describe("document file store over a bucket", () => {
  test("write, read, remove (idempotent)", async () => {
    const { store } = bucket();
    const documents = new ObjectDocumentFileStore(store);
    await documents.write("documents/x.enc", bytes(7));
    expect(await documents.read("documents/x.enc")).toEqual(bytes(7));
    await documents.remove("documents/x.enc");
    expect(await documents.read("documents/x.enc")).toBeNull();
    await documents.remove("documents/x.enc");
  });

  test("names that escape the root are refused", async () => {
    const { store } = bucket();
    const documents = new ObjectDocumentFileStore(store);
    await expect(documents.read("../etc/passwd")).rejects.toThrow();
    await expect(documents.remove("documents/../../x")).rejects.toThrow();
  });

  test("listLegacyFiles lists only root-level plaintext document files", async () => {
    const { client, store } = bucket();
    const documents = new ObjectDocumentFileStore(store);
    await client.write(LEGACY_DOC, bytes(1));
    await client.write("notes.txt", bytes(1));
    await documents.write("documents/x.enc", bytes(1));
    await client.write(`documents/${LEGACY_DOC}`, bytes(1));
    expect(await documents.listLegacyFiles()).toEqual([LEGACY_DOC]);
  });
});

describe("profile photo reader for the verification feature", () => {
  test("reads a legacy /uploads/ url and a bare relative key from the store", async () => {
    const { store } = bucket();
    await store.put("profiles/1/a.jpg", bytes(3));
    const read = createStorePhotoReader(store);
    expect(await read("/uploads/profiles/1/a.jpg")).toEqual(bytes(3));
    expect(await read("profiles/1/a.jpg")).toEqual(bytes(3));
    expect(await read("/profiles/1/a.jpg")).toEqual(bytes(3));
  });

  test("a missing file, a URL, or a key that climbs out is not readable: null, never an error", async () => {
    const { client, store } = bucket();
    await store.put("secret.txt", bytes(1));
    const read = createStorePhotoReader(store);
    expect(await read("profiles/1/none.jpg")).toBeNull();
    expect(await read("https://lh3.googleusercontent.com/a.jpg")).toBeNull();
    expect(await read("/uploads/../secret.txt")).toBeNull();
    expect(await read("../secret.txt")).toBeNull();
    expect(client.reads).toEqual(["profiles/1/none.jpg"]);
  });

  test("a storage failure is an error, not a missing photo", async () => {
    const { client, store } = bucket();
    client.failWith = new Error("bucket unreachable");
    await expect(createStorePhotoReader(store)("profiles/1/a.jpg")).rejects.toThrow("bucket unreachable");
  });
});
