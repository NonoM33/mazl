import sharp from "sharp";
import { InvalidImageError, type ImageDecoder, type RgbImage } from "../application/ports";

const MAX_LONG_SIDE = 1280;
// Refuses decompression bombs before sharp allocates for them.
const MAX_INPUT_PIXELS = 50_000_000;

export class SharpImageDecoder implements ImageDecoder {
  async decode(bytes: Uint8Array): Promise<RgbImage> {
    if (bytes.length === 0) throw new InvalidImageError("empty");
    try {
      const { data, info } = await sharp(bytes, { failOn: "error", limitInputPixels: MAX_INPUT_PIXELS })
        .rotate() // EXIF orientation; metadata is not carried into raw output
        .resize({ width: MAX_LONG_SIDE, height: MAX_LONG_SIDE, fit: "inside", withoutEnlargement: true })
        .removeAlpha()
        .toColourspace("srgb")
        .raw()
        .toBuffer({ resolveWithObject: true });
      if (info.channels !== 3) throw new InvalidImageError(`unexpected channel count ${info.channels}`);
      return { width: info.width, height: info.height, data: new Uint8Array(data.buffer, data.byteOffset, data.byteLength) };
    } catch (error: unknown) {
      if (error instanceof InvalidImageError) throw error;
      throw new InvalidImageError("undecodable");
    }
  }
}
