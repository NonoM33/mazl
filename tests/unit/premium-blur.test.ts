import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import sharp from "sharp";
import { createBlurCache } from "../../src/features/media/application/blur-cache";
import { photoIdOfSignedUrl, signBlurredPhotoUrl, signPhotoUrl, verifyBlurSignature, verifyPhotoSignature } from "../../src/features/media/application/photo-signer";
import { blurredJpeg, BLUR_WIDTH_PX } from "../../src/features/media/infra/sharp-image-processor";
import { resetKeyCacheForTests } from "../../src/shared/crypto/keys";

// docs/premium/MONETISATION.md section 1: the variant shown to a member without
// mazl+ is 48 px wide, about 2 KB, and holds no detail that could be sharpened.

const previousKey = process.env.MEDIA_SIGNING_KEY;
const previousBase = process.env.PUBLIC_BASE_URL;
beforeAll(() => {
  process.env.MEDIA_SIGNING_KEY = Buffer.alloc(32, 9).toString("base64");
  delete process.env.PUBLIC_BASE_URL;
  resetKeyCacheForTests();
});
afterAll(() => {
  if (previousKey === undefined) delete process.env.MEDIA_SIGNING_KEY;
  else process.env.MEDIA_SIGNING_KEY = previousKey;
  if (previousBase !== undefined) process.env.PUBLIC_BASE_URL = previousBase;
  resetKeyCacheForTests();
});

// A 1200 x 1600 portrait: a bright "face" disc with fine dark stripes (high frequency detail) on a dark ground.
async function portraitWithFineDetail(stripePhase: number): Promise<Buffer> {
  const width = 1200;
  const height = 1600;
  const pixels = Buffer.alloc(width * height * 3);
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const inFace = (x - 600) ** 2 + (y - 700) ** 2 < 350 ** 2;
      const stripe = Math.floor((x + stripePhase) / 4) % 2 === 0;
      const value = inFace ? (stripe ? 235 : 40) : 30;
      const offset = (y * width + x) * 3;
      pixels[offset] = value;
      pixels[offset + 1] = value;
      pixels[offset + 2] = value;
    }
  }
  return sharp(pixels, { raw: { width, height, channels: 3 } }).jpeg({ quality: 92 }).toBuffer();
}

describe("the blurred variant", () => {
  test("is a 48 px wide JPEG of about 2 KB, whatever the size of the photo", async () => {
    const output = await blurredJpeg(await portraitWithFineDetail(0));
    const meta = await sharp(output).metadata();
    expect([meta.format, meta.width]).toEqual(["jpeg", BLUR_WIDTH_PX]);
    expect(meta.height).toBe(64);
    expect(output.byteLength).toBeLessThan(3000);
  });

  test("carries no metadata", async () => {
    const withGps = await sharp({ create: { width: 200, height: 300, channels: 3, background: { r: 10, g: 90, b: 160 } } })
      .jpeg()
      .withExif({ IFD0: { ImageDescription: "SECRET-HOME-ADDRESS" }, IFD3: { GPSLatitudeRef: "N", GPSLatitude: "48/1 51/1 30/1" } })
      .toBuffer();
    const output = await blurredJpeg(withGps);
    expect((await sharp(output).metadata()).exif).toBeUndefined();
    expect(output.includes(Buffer.from("SECRET-HOME-ADDRESS"))).toBe(false);
  });

  test("cannot be sharpened: two photos that differ only by their fine detail give the same variant", async () => {
    const [a, b] = await Promise.all([blurredJpeg(await portraitWithFineDetail(0)), blurredJpeg(await portraitWithFineDetail(2))]);
    const [pixelsA, pixelsB] = await Promise.all([sharp(a).raw().toBuffer(), sharp(b).raw().toBuffer()]);
    expect(pixelsA.byteLength).toBe(pixelsB.byteLength);
    let largest = 0;
    for (let i = 0; i < pixelsA.byteLength; i += 1) largest = Math.max(largest, Math.abs((pixelsA[i] ?? 0) - (pixelsB[i] ?? 0)));
    // JPEG noise at most: the stripes (235 / 40) are gone from both.
    expect(largest).toBeLessThan(12);
  });

  test("something that is not an image is refused", async () => {
    await expect(blurredJpeg(new TextEncoder().encode("not an image"))).rejects.toThrow();
    await expect(blurredJpeg(new Uint8Array(0))).rejects.toThrow();
  });
});

describe("signed blurred URLs", () => {
  const NOW = 1_800_000_000_000;

  test("the url is relative to the media route and verifies", () => {
    const url = signBlurredPhotoUrl(12, NOW);
    const match = /^\/media\/photos\/12\/blur\?exp=(\d+)&sig=([\w-]+)$/.exec(url);
    expect(match).not.toBeNull();
    expect(verifyBlurSignature(12, match?.[1], match?.[2], NOW)).toBe(true);
  });

  test("a signature for the sharp photo never opens the blurred one, nor the reverse", () => {
    const sharpUrl = new URL(`http://x${signPhotoUrl(12, NOW)}`);
    const blurUrl = new URL(`http://x${signBlurredPhotoUrl(12, NOW)}`);
    const sharpArgs = [sharpUrl.searchParams.get("exp") ?? undefined, sharpUrl.searchParams.get("sig") ?? undefined] as const;
    const blurArgs = [blurUrl.searchParams.get("exp") ?? undefined, blurUrl.searchParams.get("sig") ?? undefined] as const;
    expect(verifyBlurSignature(12, ...sharpArgs, NOW)).toBe(false);
    expect(verifyPhotoSignature(12, ...blurArgs, NOW)).toBe(false);
  });

  test("another photo, an expired link or a missing signature are refused", () => {
    const url = new URL(`http://x${signBlurredPhotoUrl(12, NOW)}`);
    const exp = url.searchParams.get("exp") ?? undefined;
    const sig = url.searchParams.get("sig") ?? undefined;
    expect(verifyBlurSignature(13, exp, sig, NOW)).toBe(false);
    expect(verifyBlurSignature(12, exp, sig, NOW + 3_700_000)).toBe(false);
    expect(verifyBlurSignature(12, exp, undefined, NOW)).toBe(false);
    expect(verifyBlurSignature(12, undefined, sig, NOW)).toBe(false);
  });

  test("the photo id is read from a signed url of this server, from nothing else", () => {
    expect(photoIdOfSignedUrl(signPhotoUrl(41, NOW))).toBe(41);
    expect(photoIdOfSignedUrl(signBlurredPhotoUrl(41, NOW))).toBe(41);
    expect(photoIdOfSignedUrl("https://lh3.googleusercontent.com/a/abc=s96-c")).toBeNull();
    expect(photoIdOfSignedUrl("/demo/photos/anna.jpg")).toBeNull();
    expect(photoIdOfSignedUrl(null)).toBeNull();
    expect(photoIdOfSignedUrl(42)).toBeNull();
  });
});

describe("the blur cache", () => {
  const bytes = (n: number) => new Uint8Array([n]);

  test("keeps a variant until it expires", () => {
    const cache = createBlurCache({ maxEntries: 5, ttlMs: 1000 });
    cache.set("1:a", bytes(1), 0);
    expect(cache.get("1:a", 999)).toEqual(bytes(1));
    expect(cache.get("1:a", 1000)).toBeNull();
  });

  test("drops the least recently used entry past its size", () => {
    const cache = createBlurCache({ maxEntries: 2, ttlMs: 10_000 });
    cache.set("a", bytes(1), 0);
    cache.set("b", bytes(2), 0);
    expect(cache.get("a", 1)).toEqual(bytes(1));
    cache.set("c", bytes(3), 2);
    expect(cache.get("b", 3)).toBeNull();
    expect(cache.get("a", 3)).toEqual(bytes(1));
    expect(cache.get("c", 3)).toEqual(bytes(3));
  });
});
