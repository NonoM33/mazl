// Duplicate-frame detection on 32x32 grayscale thumbnails. A replayed still
// image, or the same frame uploaded several times, differs by less than the
// sensor noise of two genuinely distinct captures.

export const THUMBNAIL_SIZE = 32;
// Frames closer than this (mean absolute difference, 0-255 scale) are the
// same image: the contract requires strictly more than 2/255.
export const DUPLICATE_MAX_DIFFERENCE = 2;

interface RgbPixels {
  readonly width: number;
  readonly height: number;
  readonly data: Uint8Array;
}

// Area-averaged luma thumbnail, row-major, THUMBNAIL_SIZE x THUMBNAIL_SIZE.
export function toGrayThumbnail(image: RgbPixels): Uint8Array {
  const out = new Uint8Array(THUMBNAIL_SIZE * THUMBNAIL_SIZE);
  for (let ty = 0; ty < THUMBNAIL_SIZE; ty++) {
    const y0 = Math.floor((ty * image.height) / THUMBNAIL_SIZE);
    const y1 = Math.max(y0 + 1, Math.floor(((ty + 1) * image.height) / THUMBNAIL_SIZE));
    for (let tx = 0; tx < THUMBNAIL_SIZE; tx++) {
      const x0 = Math.floor((tx * image.width) / THUMBNAIL_SIZE);
      const x1 = Math.max(x0 + 1, Math.floor(((tx + 1) * image.width) / THUMBNAIL_SIZE));
      out[ty * THUMBNAIL_SIZE + tx] = Math.round(averageLuma(image, x0, x1, y0, y1));
    }
  }
  return out;
}

function averageLuma(image: RgbPixels, x0: number, x1: number, y0: number, y1: number): number {
  let sum = 0;
  let count = 0;
  for (let y = y0; y < y1 && y < image.height; y++) {
    for (let x = x0; x < x1 && x < image.width; x++) {
      const i = (y * image.width + x) * 3;
      sum += 0.299 * (image.data[i] ?? 0) + 0.587 * (image.data[i + 1] ?? 0) + 0.114 * (image.data[i + 2] ?? 0);
      count++;
    }
  }
  return count === 0 ? 0 : sum / count;
}

export function meanAbsoluteDifference(a: Uint8Array, b: Uint8Array): number {
  if (a.length !== b.length) throw new RangeError("thumbnails differ in size");
  let total = 0;
  for (let i = 0; i < a.length; i++) total += Math.abs((a[i] ?? 0) - (b[i] ?? 0));
  return total / a.length;
}

// True when any two frames, not only neighbours, are the same image.
export function findDuplicateFrames(thumbnails: readonly Uint8Array[]): boolean {
  for (let i = 0; i < thumbnails.length; i++) {
    for (let j = i + 1; j < thumbnails.length; j++) {
      const a = thumbnails[i];
      const b = thumbnails[j];
      if (a && b && meanAbsoluteDifference(a, b) <= DUPLICATE_MAX_DIFFERENCE) return true;
    }
  }
  return false;
}
