import sharp from "sharp";
import { PhotoRejectedError } from "../domain/errors";
import type { ImageProcessor } from "../application/ports";

// Re-encodes every upload. sharp drops all metadata (EXIF, GPS, ICC, XMP) unless
// asked to keep it, and rotate() with no argument bakes the EXIF orientation in
// before it is lost.

const MAX_SIDE_PX = 1600;
const JPEG_QUALITY = 85;
const MAX_INPUT_PIXELS = 50_000_000;
const RASTER_FORMATS = new Set(["jpeg", "png", "webp", "heif", "avif", "gif", "tiff"]);

async function assertRaster(bytes: Uint8Array): Promise<void> {
  const meta = await sharp(bytes, { limitInputPixels: MAX_INPUT_PIXELS }).metadata();
  if (!meta.format || !RASTER_FORMATS.has(meta.format)) {
    throw new PhotoRejectedError("unsupported_format");
  }
}

export interface ReencodedJpeg {
  readonly data: Buffer;
  readonly width: number;
  readonly height: number;
}

// Shared by profile photos and chat photos: any decodable raster image becomes a
// metadata-free JPEG whose long side is at most `maxSide` px.
export async function reencodeJpeg(bytes: Uint8Array, maxSide: number): Promise<ReencodedJpeg> {
  if (bytes.byteLength === 0) throw new PhotoRejectedError("empty");
  try {
    await assertRaster(bytes);
    const { data, info } = await sharp(bytes, { failOn: "error", limitInputPixels: MAX_INPUT_PIXELS })
      .rotate()
      .resize({ width: maxSide, height: maxSide, fit: "inside", withoutEnlargement: true })
      .jpeg({ quality: JPEG_QUALITY })
      .toBuffer({ resolveWithObject: true });
    return { data, width: info.width, height: info.height };
  } catch (error: unknown) {
    if (error instanceof PhotoRejectedError) throw error;
    throw new PhotoRejectedError("undecodable");
  }
}

export const sharpImageProcessor: ImageProcessor = {
  async toProfileJpeg(bytes: Uint8Array): Promise<Buffer> {
    return (await reencodeJpeg(bytes, MAX_SIDE_PX)).data;
  },
};
