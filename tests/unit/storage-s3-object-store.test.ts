import { describe, expect, test } from "bun:test";
import { createS3ObjectStore } from "../../src/shared/storage/s3-object-store";
import { describeObjectStoreContract } from "./storage-contract";
import { FakeS3Client } from "./storage-fakes";

describeObjectStoreContract("S3 adapter over the in-memory bucket", () => createS3ObjectStore(new FakeS3Client()));
describeObjectStoreContract("S3 adapter, pages of 2 keys", () => createS3ObjectStore(new FakeS3Client(2)));

describe("S3 adapter", () => {
  test("object keys are the same relative paths as under UPLOADS_DIR, so a plain copy migrates them", async () => {
    const client = new FakeS3Client();
    const store = createS3ObjectStore(client);
    await store.put("profiles/7/a.jpg", new Uint8Array([1]));
    await store.put("/chat//7/b.jpg", new Uint8Array([1]));
    expect(client.writes).toEqual(["profiles/7/a.jpg", "chat/7/b.jpg"]);
  });

  test("a key that climbs out is refused before any request is sent", async () => {
    const client = new FakeS3Client();
    const store = createS3ObjectStore(client);
    await expect(store.put("../x", new Uint8Array([1]))).rejects.toThrow();
    await expect(store.get("a/../../x")).rejects.toThrow();
    await expect(store.list("..")).rejects.toThrow();
    expect(client.writes).toEqual([]);
    expect(client.reads).toEqual([]);
    expect(client.listQueries).toEqual([]);
  });

  test("a directory listing asks S3 for 'dir/' so that chat does not match chatter", async () => {
    const client = new FakeS3Client();
    const store = createS3ObjectStore(client);
    await store.list("chat");
    expect(client.listQueries[0]?.prefix).toBe("chat/");
    await store.list("");
    expect(client.listQueries[1]?.prefix).toBe("");
  });

  test("a recursive listing follows every page", async () => {
    const client = new FakeS3Client(2);
    const store = createS3ObjectStore(client);
    for (let i = 0; i < 7; i++) await store.put(`chat/1/${i}.jpg`, new Uint8Array([i]));
    expect(await store.list("chat")).toHaveLength(7);
    expect(client.listQueries.length).toBe(4);
  });

  test("a non-recursive listing groups below the first slash and keeps the top-level files", async () => {
    const client = new FakeS3Client();
    const store = createS3ObjectStore(client);
    await store.put("12-selfie.jpg", new Uint8Array([1]));
    await store.put("documents/x.enc", new Uint8Array([1]));
    expect((await store.list("", { recursive: false })).map((o) => o.key)).toEqual(["12-selfie.jpg"]);
    expect(client.listQueries[0]?.delimiter).toBe("/");
  });

  test("console-made 'folder' placeholder objects (keys ending with a slash) are not files", async () => {
    const client = new FakeS3Client();
    const store = createS3ObjectStore(client);
    await client.write("chat/", new Uint8Array());
    await store.put("chat/1/a.jpg", new Uint8Array([1]));
    expect((await store.list("chat")).map((o) => o.key)).toEqual(["chat/1/a.jpg"]);
  });

  test("an S3 failure is an error, never a missing file", async () => {
    const client = new FakeS3Client();
    const store = createS3ObjectStore(client);
    client.failWith = new Error("SignatureDoesNotMatch");
    await expect(store.get("a/b")).rejects.toThrow("SignatureDoesNotMatch");
    await expect(store.exists("a/b")).rejects.toThrow("SignatureDoesNotMatch");
    await expect(store.put("a/b", new Uint8Array([1]))).rejects.toThrow("SignatureDoesNotMatch");
    await expect(store.delete("a/b")).rejects.toThrow("SignatureDoesNotMatch");
    await expect(store.list("a")).rejects.toThrow("SignatureDoesNotMatch");
  });
});
