import { describe, expect, test } from "bun:test";
import sharp from "sharp";
import { SharpImageDecoder } from "../../src/features/verification/infra/sharp-image-decoder";
import { InvalidImageError } from "../../src/features/verification/application/ports";

const decoder = new SharpImageDecoder();

// A 40x20 image: left half pure red, right half pure blue.
async function redBlueJpeg(orientation?: number): Promise<Uint8Array> {
  const raw = Buffer.alloc(40 * 20 * 3);
  for (let y = 0; y < 20; y++) {
    for (let x = 0; x < 40; x++) {
      const i = (y * 40 + x) * 3;
      if (x < 20) raw[i] = 255;
      else raw[i + 2] = 255;
    }
  }
  let img = sharp(raw, { raw: { width: 40, height: 20, channels: 3 } });
  if (orientation) img = img.withMetadata({ orientation });
  return new Uint8Array(await img.jpeg({ quality: 100, chromaSubsampling: "4:4:4" }).toBuffer());
}

function at(img: { width: number; data: Uint8Array }, x: number, y: number): number[] {
  const i = (y * img.width + x) * 3;
  return [img.data[i] ?? -1, img.data[i + 1] ?? -1, img.data[i + 2] ?? -1];
}

describe("SharpImageDecoder", () => {
  test("decodes to raw RGB, 3 bytes per pixel", async () => {
    const img = await decoder.decode(await redBlueJpeg());
    expect(img.width).toBe(40);
    expect(img.height).toBe(20);
    expect(img.data).toHaveLength(40 * 20 * 3);
    const red = at(img, 5, 10);
    expect(red[0]).toBeGreaterThan(240);
    expect(red[2]).toBeLessThan(15);
    const blue = at(img, 35, 10);
    expect(blue[2]).toBeGreaterThan(240);
    expect(blue[0]).toBeLessThan(15);
  });

  test("applies the EXIF orientation (6 = rotate 90 degrees clockwise)", async () => {
    const img = await decoder.decode(await redBlueJpeg(6));
    expect(img.width).toBe(20);
    expect(img.height).toBe(40);
    // Rotated clockwise, the red left half ends up on top.
    expect(at(img, 10, 5)[0]).toBeGreaterThan(240);
    expect(at(img, 10, 35)[2]).toBeGreaterThan(240);
  });

  test("caps the long side at 1280 and keeps the ratio", async () => {
    const big = await sharp({ create: { width: 2560, height: 1280, channels: 3, background: "#808080" } }).jpeg().toBuffer();
    const img = await decoder.decode(new Uint8Array(big));
    expect(img.width).toBe(1280);
    expect(img.height).toBe(640);
  });

  test("never enlarges a small image", async () => {
    const img = await decoder.decode(await redBlueJpeg());
    expect(Math.max(img.width, img.height)).toBe(40);
  });

  test("a grayscale or transparent PNG still yields 3 channels", async () => {
    const gray = await sharp({ create: { width: 8, height: 8, channels: 3, background: "#777777" } }).greyscale().png().toBuffer();
    expect((await decoder.decode(new Uint8Array(gray))).data).toHaveLength(8 * 8 * 3);
    const alpha = await sharp({ create: { width: 8, height: 8, channels: 4, background: { r: 10, g: 20, b: 30, alpha: 0.5 } } }).png().toBuffer();
    expect((await decoder.decode(new Uint8Array(alpha))).data).toHaveLength(8 * 8 * 3);
  });

  test("garbage and empty input throw InvalidImageError", async () => {
    await expect(decoder.decode(new Uint8Array([1, 2, 3, 4]))).rejects.toBeInstanceOf(InvalidImageError);
    await expect(decoder.decode(new Uint8Array(0))).rejects.toBeInstanceOf(InvalidImageError);
  });

  test("a truncated JPEG is rejected rather than half decoded", async () => {
    const jpeg = await redBlueJpeg();
    await expect(decoder.decode(jpeg.slice(0, Math.floor(jpeg.length / 2)))).rejects.toBeInstanceOf(InvalidImageError);
  });
});
