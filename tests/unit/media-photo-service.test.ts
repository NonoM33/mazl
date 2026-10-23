import { describe, expect, spyOn, test } from "bun:test";
import { createPhotoService } from "../../src/features/media/application/photo-service";
import type {
  ImageProcessor,
  PhotoRepository,
  PhotoStorage,
  RemoteImageFetcher,
  StoredPhoto,
} from "../../src/features/media/application/ports";
import type { PhotoFaceChecker } from "../../src/features/verification/application/ports";
import { PhotoRejectedError, PictureImportError } from "../../src/features/media/domain/errors";

// Behaviour from CONTRAT.md §2.1: random UUID file name whatever the client
// says, nothing stored when the image is refused, the face checker is called
// once the photo is stored, OAuth import only from lh3.googleusercontent.com.

const PROCESSED = Buffer.from("processed-jpeg");
const KEY_PATTERN = /^photos\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$/;

function harness(options: { storedUrl?: string | null; picture?: string | null; processorFails?: boolean; checkerFails?: boolean; repoFails?: boolean } = {}) {
  const saved = new Map<string, Uint8Array>();
  const removed: string[] = [];
  const checked: Array<{ userId: number; photoId: number; bytes: Uint8Array }> = [];
  const fetched: Array<{ url: string; timeoutMs: number; maxBytes: number }> = [];
  const added: Array<{ userId: number; key: string; isPrimary: boolean }> = [];

  const processor: ImageProcessor = {
    async toProfileJpeg() {
      if (options.processorFails) throw new PhotoRejectedError("undecodable");
      return PROCESSED;
    },
  };
  const storage: PhotoStorage = {
    async save(key, bytes) { saved.set(key, bytes); },
    async read(key) { return saved.get(key) ?? null; },
    async remove(key) { removed.push(key); saved.delete(key); },
  };
  const repository: PhotoRepository = {
    async addPhoto(input) {
      if (options.repoFails) throw new Error("db down");
      added.push(input);
      const photo: StoredPhoto = { id: 77, url: input.key, is_primary: input.isPrimary, position: 0 };
      return photo;
    },
    async findKey() { return options.storedUrl === undefined ? null : options.storedUrl; },
    async findUserPicture() { return options.picture === undefined ? null : options.picture; },
    async deletePhoto() { return options.storedUrl === undefined ? null : options.storedUrl; },
  };
  const fetcher: RemoteImageFetcher = {
    async fetch(url, limits) {
      fetched.push({ url: url.toString(), ...limits });
      return new Uint8Array([1, 2, 3]);
    },
  };
  const faceChecker: PhotoFaceChecker = {
    async checkStoredPhoto(userId, photoId, bytes) {
      if (options.checkerFails) throw new Error("model crashed");
      checked.push({ userId, photoId, bytes });
    },
  };
  const service = createPhotoService({ processor, storage, repository, fetcher, faceChecker });
  return { service, saved, removed, checked, fetched, added };
}

describe("photo service: upload", () => {
  test("stores the re-encoded bytes under a random UUID key and checks the face afterwards", async () => {
    const h = harness();
    const photo = await h.service.upload(5, new Uint8Array([9, 9, 9]), true);

    expect(photo.id).toBe(77);
    expect(h.added).toHaveLength(1);
    expect(h.added[0]?.key).toMatch(KEY_PATTERN);
    expect(h.added[0]).toMatchObject({ userId: 5, isPrimary: true });
    const key = h.added[0]?.key ?? "";
    expect(h.saved.get(key)).toEqual(PROCESSED); // the processed bytes, not the upload
    expect(h.checked).toEqual([{ userId: 5, photoId: 77, bytes: PROCESSED }]);
  });

  test("two uploads never share a file name", async () => {
    const h = harness();
    await h.service.upload(5, new Uint8Array([1]), false);
    await h.service.upload(5, new Uint8Array([1]), false);
    expect(new Set(h.added.map((a) => a.key)).size).toBe(2);
  });

  test("an undecodable image stores nothing and skips the face check", async () => {
    const h = harness({ processorFails: true });
    await expect(h.service.upload(5, new Uint8Array([1]), false)).rejects.toBeInstanceOf(PhotoRejectedError);
    expect(h.saved.size).toBe(0);
    expect(h.added).toHaveLength(0);
    expect(h.checked).toHaveLength(0);
  });

  test("a face checker failure does not lose the upload", async () => {
    const h = harness({ checkerFails: true });
    const log = spyOn(console, "error").mockImplementation(() => {});
    const photo = await h.service.upload(5, new Uint8Array([1]), false);
    log.mockRestore();
    expect(photo.id).toBe(77);
    expect(h.saved.size).toBe(1);
  });

  test("when the database insert fails the file is removed again", async () => {
    const h = harness({ repoFails: true });
    await expect(h.service.upload(5, new Uint8Array([1]), false)).rejects.toThrow("db down");
    expect(h.saved.size).toBe(0);
    expect(h.removed).toHaveLength(1);
  });
});

describe("photo service: OAuth picture import", () => {
  test("downloads the Google avatar with a 5 s timeout and a 10 MB cap, then stores it like an upload", async () => {
    const h = harness({ picture: "https://lh3.googleusercontent.com/a/AAA=s96-c" });
    const photo = await h.service.importOauthPicture(5, false);
    expect(h.fetched).toEqual([{ url: "https://lh3.googleusercontent.com/a/AAA=s96-c", timeoutMs: 5000, maxBytes: 10 * 1024 * 1024 }]);
    expect(photo.id).toBe(77);
    expect(h.added[0]?.key).toMatch(KEY_PATTERN);
  });

  test("refuses any other host without fetching", async () => {
    const bad = [
      "https://i.pravatar.cc/400?img=3",
      "https://lh3.googleusercontent.com.evil.example/a",
      "https://evil.example/lh3.googleusercontent.com/a",
      "http://lh3.googleusercontent.com/a",
      "https://lh3.googleusercontent.com@evil.example/a",
      "http://169.254.169.254/latest/meta-data",
      "https://lh3.googleusercontent.com:8443/a",
    ];
    for (const picture of bad) {
      const h = harness({ picture });
      const error = await h.service.importOauthPicture(5, false).catch((e: unknown) => e);
      expect(error).toBeInstanceOf(PictureImportError);
      expect((error as PictureImportError).reason).toBe("host_not_allowed");
      expect(h.fetched).toHaveLength(0);
    }
  });

  test("no picture on the account is a distinct refusal", async () => {
    const h = harness({ picture: null });
    const error = await h.service.importOauthPicture(5, false).catch((e: unknown) => e);
    expect((error as PictureImportError).reason).toBe("no_picture");
  });
});

describe("photo service: serve and remove", () => {
  const KEY = "photos/3f0c1d1e-5c1a-4a53-9d0e-2a4f7a6b8c90.jpg";

  test("serves the stored bytes untouched for pipeline photos", async () => {
    const h = harness({ storedUrl: KEY });
    h.saved.set(KEY, new Uint8Array([4, 5, 6]));
    expect(await h.service.serve(1)).toEqual(new Uint8Array([4, 5, 6]));
  });

  test("legacy files are re-encoded on the way out", async () => {
    const h = harness({ storedUrl: "/uploads/profiles/3/old.jpg" });
    h.saved.set("profiles/3/old.jpg", new Uint8Array([4, 5, 6]));
    expect(await h.service.serve(1)).toEqual(PROCESSED);
  });

  test("unknown id, external rows, unsafe keys and missing files give null", async () => {
    expect(await harness().service.serve(1)).toBeNull();
    expect(await harness({ storedUrl: "https://i.pravatar.cc/400" }).service.serve(1)).toBeNull();
    expect(await harness({ storedUrl: "/uploads/profiles/3/../../etc/passwd" }).service.serve(1)).toBeNull();
    expect(await harness({ storedUrl: KEY }).service.serve(1)).toBeNull();
  });

  test("deleting a photo erases its file", async () => {
    const h = harness({ storedUrl: KEY });
    h.saved.set(KEY, new Uint8Array([1]));
    await h.service.remove(5, 1);
    expect(h.removed).toEqual([KEY]);
  });
});
