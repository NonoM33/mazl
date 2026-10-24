import { describe, expect, test } from "bun:test";
import sharp from "sharp";
import { sharpChatImages, MAX_CHAT_PIXELS } from "../../src/features/chat/infra/sharp-chat-images";
import { PhotoRejectedError } from "../../src/features/media/domain/errors";

// Security: a decompression bomb is a small file that decodes to a huge raster
// (a flat-coloured PNG of a few hundred bytes can claim 40 000 x 40 000). The
// chat caps the decoded size well below what the profile photos allow.

async function flatPng(width: number, height: number): Promise<Uint8Array> {
  const bytes = await sharp({ create: { width, height, channels: 3, background: { r: 10, g: 120, b: 200 } } }).png({ compressionLevel: 9 }).toBuffer();
  return new Uint8Array(bytes);
}

async function rejection(work: Promise<unknown>): Promise<PhotoRejectedError | null> {
  try {
    await work;
    return null;
  } catch (error: unknown) {
    if (error instanceof PhotoRejectedError) return error;
    throw error;
  }
}

describe("chat photo pixel cap", () => {
  test("the cap is 24 megapixels", () => expect(MAX_CHAT_PIXELS).toBe(24_000_000));

  test("a 5000 x 5000 image (25 Mpx) from a small file is refused as too large", async () => {
    const bomb = await flatPng(5000, 5000);
    expect(bomb.byteLength).toBeLessThan(1024 * 1024);
    expect((await rejection(sharpChatImages.toChatJpeg(bomb)))?.reason).toBe("too_large");
  });

  test("a 6000 x 6000 image (36 Mpx, allowed for profile photos) is refused too, whichever entry point", async () => {
    const bomb = await flatPng(6000, 6000);
    expect((await rejection(sharpChatImages.toChatJpeg(bomb)))?.reason).toBe("too_large");
    expect((await rejection(sharpChatImages.toPreviewJpeg(bomb)))?.reason).toBe("too_large");
  });

  test("a 4000 x 4000 image (16 Mpx) is accepted and shrunk to the chat size", async () => {
    const photo = await flatPng(4000, 4000);
    const result = await sharpChatImages.toChatJpeg(photo);
    expect(Math.max(result.width, result.height)).toBe(2048);
  });

  test("a normal phone photo (4032 x 3024, 12 Mpx) is accepted", async () => {
    const result = await sharpChatImages.toChatJpeg(await flatPng(4032, 3024));
    expect(result.width).toBe(2048);
  });
});
