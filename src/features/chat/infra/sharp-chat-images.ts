import type { ChatImageProcessor, ProcessedImage } from "../application/ports";
import { reencodeJpeg } from "../../media/infra/sharp-image-processor";

// Chat photos use the same re-encoding as profile photos (metadata gone,
// orientation baked in, raster formats only); only the size cap differs.
const CHAT_MAX_SIDE_PX = 2048;
const PREVIEW_MAX_SIDE_PX = 1024;

async function encode(bytes: Uint8Array, maxSide: number): Promise<ProcessedImage> {
  const { data, width, height } = await reencodeJpeg(bytes, maxSide);
  return { bytes: new Uint8Array(data), width, height };
}

export const sharpChatImages: ChatImageProcessor = {
  toChatJpeg: (bytes) => encode(bytes, CHAT_MAX_SIDE_PX),
  toPreviewJpeg: (bytes) => encode(bytes, PREVIEW_MAX_SIDE_PX),
};
