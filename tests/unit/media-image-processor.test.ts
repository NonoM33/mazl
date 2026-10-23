import { describe, expect, test } from "bun:test";
import sharp from "sharp";
import { sharpImageProcessor } from "../../src/features/media/infra/sharp-image-processor";
import { PhotoRejectedError } from "../../src/features/media/domain/errors";

// CONTRAT.md §2.1: every upload is re-encoded to JPEG, EXIF orientation applied
// then ALL metadata (GPS included) dropped, long side <= 1600 px.

const MARKER = "SECRET-HOME-ADDRESS";

async function jpegWithGpsAndOrientation(width: number, height: number, orientation: number): Promise<Buffer> {
  return sharp({ create: { width, height, channels: 3, background: { r: 200, g: 30, b: 30 } } })
    .jpeg()
    .withExif({
      IFD0: { ImageDescription: MARKER, Copyright: MARKER },
      IFD3: {
        GPSLatitudeRef: "N",
        GPSLatitude: "48/1 51/1 30/1",
        GPSLongitudeRef: "E",
        GPSLongitude: "2/1 17/1 40/1",
      },
    })
    .withMetadata({ orientation })
    .toBuffer();
}

describe("sharp image processor", () => {
  test("fixture really carries EXIF, GPS and the marker (guards the test itself)", async () => {
    const input = await jpegWithGpsAndOrientation(300, 100, 6);
    const meta = await sharp(input).metadata();
    expect(meta.exif).toBeDefined();
    expect(meta.orientation).toBe(6);
    expect(input.includes(Buffer.from(MARKER))).toBe(true);
    expect(input.includes(Buffer.from("Exif\0\0", "binary"))).toBe(true);
  });

  test("output is a JPEG without any EXIF/GPS and the orientation is baked in", async () => {
    const input = await jpegWithGpsAndOrientation(300, 100, 6);
    const output = await sharpImageProcessor.toProfileJpeg(input);

    expect([...output.subarray(0, 3)]).toEqual([0xff, 0xd8, 0xff]); // JPEG magic
    expect(output.includes(Buffer.from("Exif\0\0", "binary"))).toBe(false);
    expect(output.includes(Buffer.from(MARKER))).toBe(false);
    const meta = await sharp(output).metadata();
    expect(meta.format).toBe("jpeg");
    expect(meta.exif).toBeUndefined();
    expect(meta.orientation).toBeUndefined();
    // EXIF orientation 6 = displayed rotated 90 degrees: 300x100 becomes 100x300.
    expect(meta.width).toBe(100);
    expect(meta.height).toBe(300);
  });

  test("a PNG upload becomes a JPEG", async () => {
    const png = await sharp({ create: { width: 64, height: 64, channels: 3, background: "#336699" } }).png().toBuffer();
    const output = await sharpImageProcessor.toProfileJpeg(png);
    expect((await sharp(output).metadata()).format).toBe("jpeg");
  });

  test("long side is capped at 1600 px, small images are not enlarged", async () => {
    const big = await sharp({ create: { width: 3200, height: 1000, channels: 3, background: "#888" } }).jpeg().toBuffer();
    const meta = await sharp(await sharpImageProcessor.toProfileJpeg(big)).metadata();
    expect(meta.width).toBe(1600);
    expect(meta.height).toBe(500);

    const small = await sharp({ create: { width: 200, height: 100, channels: 3, background: "#888" } }).jpeg().toBuffer();
    const smallMeta = await sharp(await sharpImageProcessor.toProfileJpeg(small)).metadata();
    expect(smallMeta.width).toBe(200);
  });

  test("refuses what cannot be decoded as a photo", async () => {
    const garbage = [
      Buffer.from("not an image at all"),
      Buffer.alloc(0),
      Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10"/></svg>'),
      Buffer.from("%PDF-1.4\n%fake\n"),
      Buffer.from("GIF89a-truncated"),
    ];
    for (const bytes of garbage) {
      await expect(sharpImageProcessor.toProfileJpeg(bytes)).rejects.toBeInstanceOf(PhotoRejectedError);
    }
  });

  test("refuses a truncated JPEG", async () => {
    const full = await sharp({ create: { width: 500, height: 500, channels: 3, background: "#abc" } }).jpeg().toBuffer();
    await expect(sharpImageProcessor.toProfileJpeg(full.subarray(0, 40))).rejects.toBeInstanceOf(PhotoRejectedError);
  });
});
