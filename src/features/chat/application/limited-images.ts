import { ChatError } from "../domain/errors";
import type { ChatImageProcessor, ProcessedImage } from "./ports";
import { SemaphoreFullError, type Semaphore } from "./semaphore";

// Decoding and re-encoding an image is CPU and memory heavy: only a few run at
// once for the whole process, chat photos and preview images alike. When the
// waiting line is full the caller is told the server is busy.
export function limitImageProcessing(inner: ChatImageProcessor, gate: Semaphore): ChatImageProcessor {
  async function limited(work: () => Promise<ProcessedImage>): Promise<ProcessedImage> {
    try {
      return await gate.run(work);
    } catch (error: unknown) {
      if (error instanceof SemaphoreFullError) throw new ChatError("busy");
      throw error;
    }
  }
  return {
    toChatJpeg: (bytes) => limited(() => inner.toChatJpeg(bytes)),
    toPreviewJpeg: (bytes) => limited(() => inner.toPreviewJpeg(bytes)),
  };
}
