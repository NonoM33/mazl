import { describe, expect, test } from "bun:test";
import { createPhotoService } from "../../src/features/media/application/photo-service";
import type { ImageProcessor, PhotoRepository, PhotoStorage } from "../../src/features/media/application/ports";

// serveBlurred: the row is read every time (a deleted photo stops at once),
// the decoding and blurring are done once per photo.

function harness(initialUrl: string | null) {
  let storedUrl = initialUrl;
  let blurred = 0;
  const files = new Map<string, Uint8Array>([["photos/0b6f6e3a-1c2d-4e5f-8a9b-0c1d2e3f4a5b.jpg", new Uint8Array([1, 2, 3])]]);
  const processor: ImageProcessor = {
    async toProfileJpeg() { return Buffer.from("sharp"); },
    async toBlurredJpeg() { blurred += 1; return Buffer.from("blur"); },
  };
  const storage: PhotoStorage = {
    async save(key, bytes) { files.set(key, bytes); },
    async read(key) { return files.get(key) ?? null; },
    async remove(key) { files.delete(key); },
  };
  const repository: PhotoRepository = {
    async addPhoto() { throw new Error("unused"); },
    async findKey() { return storedUrl; },
    async deletePhoto() { throw new Error("unused"); },
    async findUserPicture() { return null; },
    async listUserKeys() { return []; },
  };
  const service = createPhotoService({
    processor, storage, repository,
    fetcher: { async fetch() { throw new Error("unused"); } },
    faceChecker: { async checkStoredPhoto() {} },
  });
  return { service, blurredCount: () => blurred, forget: () => { storedUrl = null; }, files };
}

describe("serveBlurred", () => {
  test("gives the blurred bytes, and blurs a photo once for many requests", async () => {
    const h = harness("photos/0b6f6e3a-1c2d-4e5f-8a9b-0c1d2e3f4a5b.jpg");
    expect(Buffer.from((await h.service.serveBlurred(1)) ?? new Uint8Array()).toString()).toBe("blur");
    await h.service.serveBlurred(1);
    await h.service.serveBlurred(1);
    expect(h.blurredCount()).toBe(1);
  });

  test("nothing for an unknown photo, a demo photo or a missing file", async () => {
    expect(await harness(null).service.serveBlurred(1)).toBeNull();
    expect(await harness("/demo/photos/anna.jpg").service.serveBlurred(1)).toBeNull();
    const missing = harness("photos/9c9c9c9c-1c2d-4e5f-8a9b-0c1d2e3f4a5b.jpg");
    expect(await missing.service.serveBlurred(1)).toBeNull();
  });

  test("a photo deleted after it was cached is no longer served", async () => {
    const h = harness("photos/0b6f6e3a-1c2d-4e5f-8a9b-0c1d2e3f4a5b.jpg");
    expect(await h.service.serveBlurred(1)).not.toBeNull();
    h.forget();
    expect(await h.service.serveBlurred(1)).toBeNull();
  });
});
