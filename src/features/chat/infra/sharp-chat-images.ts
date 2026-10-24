import sharp from "sharp";
import type { ChatImageProcessor, ProcessedImage } from "../application/ports";
import { PhotoRejectedError } from "../../media/domain/errors";
import { reencodeJpeg } from "../../media/infra/sharp-image-processor";

// Chat photos use the same re-encoding as profile photos (metadata gone,
// orientation baked in, raster formats only); the size caps differ. The pixel
// cap is lower than the profile one: the declared size is read from the header
// before anything is decoded, so a small file that claims a huge raster is
// refused for the price of a header read.
const CHAT_MAX_SIDE_PX = 2048;
const PREVIEW_MAX_SIDE_PX = 1024;
export const MAX_CHAT_PIXELS = 24_000_000;

async function assertWithinPixelCap(bytes: Uint8Array): Promise<void> {
  let width: number | undefined;
  let height: number | undefined;
  try {
    ({ width, height } = await sharp(bytes, { limitInputPixels: false }).metadata());
  } catch {
    throw new PhotoRejectedError("undecodable");
  }
  // Unreadable dimensions are left to the re-encoder, which rejects them.
  if (width !== undefined && height !== undefined && width * height > MAX_CHAT_PIXELS) {
    throw new PhotoRejectedError("too_large");
  }
}

async function encode(bytes: Uint8Array, maxSide: number): Promise<ProcessedImage> {
  if (bytes.byteLength > 0) await assertWithinPixelCap(bytes);
  const { data, width, height } = await reencodeJpeg(bytes, maxSide);
  return { bytes: new Uint8Array(data), width, height };
}

export const sharpChatImages: ChatImageProcessor = {
  toChatJpeg: (bytes) => encode(bytes, CHAT_MAX_SIDE_PX),
  toPreviewJpeg: (bytes) => encode(bytes, PREVIEW_MAX_SIDE_PX),
};
