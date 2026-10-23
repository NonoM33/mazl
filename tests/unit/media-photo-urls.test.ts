import { describe, expect, test, beforeAll, afterAll } from "bun:test";
import { resetKeyCacheForTests } from "../../src/shared/crypto/keys";
import {
  publicPhotoUrl,
  publicPicture,
  publicAvatarUrl,
} from "../../src/features/media/application/photo-urls";

// CONTRAT.md §2.1: responses carry signed URLs; stored URLs starting with http
// are dropped, except Google avatars read from users.picture.

const UUID = "3f0c1d1e-5c1a-4a53-9d0e-2a4f7a6b8c90";

describe("public photo URLs", () => {
  const previous = process.env.PUBLIC_BASE_URL;
  beforeAll(() => {
    delete process.env.PUBLIC_BASE_URL;
    resetKeyCacheForTests();
  });
  afterAll(() => {
    if (previous !== undefined) process.env.PUBLIC_BASE_URL = previous;
  });

  test("a locally stored photo becomes a signed URL for its id", () => {
    const url = publicPhotoUrl({ id: 42, url: `photos/${UUID}.jpg` });
    expect(url).toMatch(/^\/media\/photos\/42\?exp=\d+&sig=[A-Za-z0-9_-]{43}$/);
  });

  test("a legacy /uploads/profiles file is served through the signed route too", () => {
    expect(publicPhotoUrl({ id: 7, url: "/uploads/profiles/3/1700000000-abc.jpg" })).toMatch(/^\/media\/photos\/7\?exp=/);
  });

  test("old external rows are dropped", () => {
    expect(publicPhotoUrl({ id: 1, url: "https://i.pravatar.cc/400?img=3" })).toBeNull();
    expect(publicPhotoUrl({ id: 1, url: "http://example.com/a.jpg" })).toBeNull();
    expect(publicPhotoUrl({ id: 1, url: "HTTPS://example.com/a.jpg" })).toBeNull();
  });

  test("only Google avatars survive as picture", () => {
    expect(publicAvatarUrl("https://lh3.googleusercontent.com/a/abc=s96-c")).toBe("https://lh3.googleusercontent.com/a/abc=s96-c");
    expect(publicAvatarUrl("https://i.pravatar.cc/400?img=3")).toBeNull();
    expect(publicAvatarUrl("https://lh3.googleusercontent.com.evil.example/a")).toBeNull();
    expect(publicAvatarUrl("https://evil.example/lh3.googleusercontent.com/a")).toBeNull();
    expect(publicAvatarUrl("http://lh3.googleusercontent.com/a")).toBeNull();
    expect(publicAvatarUrl("https://lh3.googleusercontent.com@evil.example/a")).toBeNull();
    expect(publicAvatarUrl("not a url")).toBeNull();
    expect(publicAvatarUrl(null)).toBeNull();
  });

  test("picture prefers the primary uploaded photo, falls back to the avatar", () => {
    const avatar = "https://lh3.googleusercontent.com/a/abc";
    expect(publicPicture({ id: 9, url: `photos/${UUID}.jpg` }, avatar)).toMatch(/^\/media\/photos\/9\?exp=/);
    expect(publicPicture(null, avatar)).toBe(avatar);
    expect(publicPicture(null, "https://i.pravatar.cc/1")).toBeNull();
    expect(publicPicture({ id: 9, url: "https://i.pravatar.cc/1" }, null)).toBeNull();
  });
});
