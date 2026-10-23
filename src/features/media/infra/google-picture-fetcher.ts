import { PictureImportError } from "../domain/errors";
import type { RemoteImageFetcher } from "../application/ports";

// Downloads an already allow-listed URL. Redirects are refused (a redirect could
// leave the allow-listed host) and the body is read with a hard byte cap.
export const googlePictureFetcher: RemoteImageFetcher = {
  async fetch(url, { timeoutMs, maxBytes }) {
    let response: Response;
    try {
      response = await fetch(url, { redirect: "error", signal: AbortSignal.timeout(timeoutMs) });
    } catch {
      throw new PictureImportError("fetch_failed");
    }
    if (!response.ok || response.body === null) throw new PictureImportError("fetch_failed");
    return readCapped(response, maxBytes);
  },
};

async function readCapped(response: Response, maxBytes: number): Promise<Uint8Array> {
  const declared = Number(response.headers.get("content-length") ?? 0);
  if (declared > maxBytes) throw new PictureImportError("too_large");
  const chunks: Uint8Array[] = [];
  let total = 0;
  try {
    for await (const chunk of response.body as unknown as AsyncIterable<Uint8Array>) {
      total += chunk.byteLength;
      if (total > maxBytes) throw new PictureImportError("too_large");
      chunks.push(chunk);
    }
  } catch (error: unknown) {
    if (error instanceof PictureImportError) throw error;
    throw new PictureImportError("fetch_failed");
  }
  return new Uint8Array(Buffer.concat(chunks));
}
