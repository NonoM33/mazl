import { mkdtemp, rm, writeFile, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import sharp from "sharp";
import { detectImageFormat } from "../domain/chip/dg2";
import { InvalidImageError, type Jp2Decoder, type RgbImage } from "../application/ports";

const DEFAULT_BINARY = "opj_decompress";
const TIMEOUT_MS = 15_000;
const MAX_INPUT_BYTES = 8 * 1024 * 1024;
const MAX_PIXELS = 16_000_000;

// A missing decoder is a deployment fault, not a bad image: it must surface as
// a server error instead of refusing every JPEG 2000 passport as a mismatch.
export class Jp2DecoderUnavailableError extends Error {
  constructor() {
    super("opj_decompress is not installed or not executable");
    this.name = "Jp2DecoderUnavailableError";
  }
}

// JPEG 2000 (passport DG2) through OpenJPEG's opj_decompress. The face image
// is personal data: it lives only in a private, 0700 temp directory that is
// removed in `finally`, and never in a log line.
export class OpjJp2Decoder implements Jp2Decoder {
  constructor(private readonly binary: string = process.env.OPJ_DECOMPRESS ?? DEFAULT_BINARY) {}

  async decode(bytes: Uint8Array): Promise<RgbImage> {
    if (bytes.length === 0 || bytes.length > MAX_INPUT_BYTES) throw new InvalidImageError("jp2 size");
    if (detectImageFormat(bytes) !== "jp2") throw new InvalidImageError("not jpeg 2000");
    const dir = await mkdtemp(join(tmpdir(), "mazl-jp2-"));
    try {
      const isBox = bytes[0] === 0x00; // JP2 signature box vs raw codestream (FF 4F FF 51)
      const input = join(dir, isBox ? "in.jp2" : "in.j2k");
      const output = join(dir, "out.png");
      await writeFile(input, bytes, { mode: 0o600 });
      await this.run(input, output);
      return await this.toRgb(await readFile(output));
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  }

  private async run(input: string, output: string): Promise<void> {
    let proc;
    try {
      proc = Bun.spawn([this.binary, "-i", input, "-o", output], { stdout: "ignore", stderr: "ignore", timeout: TIMEOUT_MS, killSignal: "SIGKILL" });
    } catch {
      throw new Jp2DecoderUnavailableError();
    }
    const code = await proc.exited;
    if (code !== 0) throw new InvalidImageError("jp2 decode failed");
  }

  private async toRgb(png: Uint8Array): Promise<RgbImage> {
    try {
      const image = sharp(png, { limitInputPixels: MAX_PIXELS });
      const { data, info } = await image.removeAlpha().toColourspace("srgb").raw().toBuffer({ resolveWithObject: true });
      if (info.channels !== 3) throw new InvalidImageError("unexpected channel count");
      return { width: info.width, height: info.height, data: new Uint8Array(data) };
    } catch (e) {
      if (e instanceof InvalidImageError) throw e;
      throw new InvalidImageError("decoded jp2 unreadable");
    }
  }
}
