import { mkdtempSync, readdirSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, test } from "bun:test";
import sharp from "sharp";
import { InvalidImageError } from "../../src/features/verification/application/ports";
import { OpjJp2Decoder } from "../../src/features/verification/infra/opj-jp2-decoder";

const compressor = Bun.which("opj_compress");
const decoder = new OpjJp2Decoder(Bun.which("opj_decompress") ?? "opj_decompress");
const present = compressor !== null && Bun.which("opj_decompress") !== null;
const jp2Test = present ? test : test.skip;

async function makeJp2(width: number, height: number, channels: 1 | 3, ext: "jp2" | "j2k"): Promise<Uint8Array> {
  const dir = mkdtempSync(join(tmpdir(), "mazl-jp2test-"));
  const px = Buffer.alloc(width * height * channels);
  for (let i = 0; i < px.length; i++) px[i] = (i * 7) % 251;
  await sharp(px, { raw: { width, height, channels } }).png().toFile(join(dir, "src.png"));
  const run = Bun.spawnSync([compressor as string, "-i", join(dir, "src.png"), "-o", join(dir, `out.${ext}`), "-n", "3"]);
  expect(run.exitCode).toBe(0);
  return new Uint8Array(readFileSync(join(dir, `out.${ext}`)));
}

const leftovers = (): string[] => readdirSync(tmpdir()).filter((n) => n.startsWith("mazl-jp2-"));

describe("OpjJp2Decoder (OpenJPEG opj_decompress)", () => {
  jp2Test("decodes a JP2 file to RGB with the right dimensions", async () => {
    const image = await decoder.decode(await makeJp2(48, 64, 3, "jp2"));
    expect(image.width).toBe(48);
    expect(image.height).toBe(64);
    expect(image.data.length).toBe(48 * 64 * 3);
    // PNG -> JP2 (lossless) -> RGB keeps the first pixel: bytes 0, 7, 14.
    expect([...image.data.slice(0, 3)]).toEqual([0, 7, 14]);
  });

  jp2Test("decodes a raw J2K codestream", async () => {
    const image = await decoder.decode(await makeJp2(40, 56, 3, "j2k"));
    expect([image.width, image.height]).toEqual([40, 56]);
  });

  jp2Test("expands a grayscale image to 3 channels", async () => {
    const image = await decoder.decode(await makeJp2(40, 56, 1, "jp2"));
    expect(image.data.length).toBe(40 * 56 * 3);
    expect(image.data[0]).toBe(image.data[1]);
    expect(image.data[1]).toBe(image.data[2]);
  });

  jp2Test("rejects garbage, truncated data and non-JP2 images, and leaves no temp directory", async () => {
    const before = leftovers().length;
    const good = await makeJp2(48, 64, 3, "jp2");
    await expect(decoder.decode(new Uint8Array(0))).rejects.toBeInstanceOf(InvalidImageError);
    await expect(decoder.decode(Uint8Array.of(0xff, 0xd8, 0xff, 0xe0, 0, 0))).rejects.toBeInstanceOf(InvalidImageError);
    await expect(decoder.decode(good.slice(0, 20))).rejects.toBeInstanceOf(InvalidImageError);
    const corrupt = good.slice();
    corrupt.fill(0xaa, 40, 120);
    await expect(decoder.decode(corrupt)).rejects.toBeInstanceOf(InvalidImageError);
    expect(leftovers().length).toBe(before);
  });

  test("a missing binary is an InvalidImageError, not a crash", async () => {
    const missing = new OpjJp2Decoder("/nonexistent/opj_decompress");
    const jp2 = Uint8Array.of(0, 0, 0, 0x0c, 0x6a, 0x50, 0x20, 0x20, 0x0d, 0x0a, 0x87, 0x0a, 1, 2, 3, 4);
    await expect(missing.decode(jp2)).rejects.toBeInstanceOf(InvalidImageError);
  });
});
