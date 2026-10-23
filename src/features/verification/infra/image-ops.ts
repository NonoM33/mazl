import type { RgbImage } from "../application/ports";
import type { SimilarityTransform } from "./similarity-transform";

// Minimal raster operations needed by the face engine, written to match
// OpenCV's conventions (pixel i has its centre at coordinate i for warps,
// at i + 0.5 for resizes) so that the models see what they were trained on.

// cv::warpAffine(INTER_LINEAR, BORDER_CONSTANT = 0). `m` maps source
// coordinates to output coordinates; each output pixel is pulled back
// through the inverse and sampled bilinearly.
export function warpAffineBilinear(src: RgbImage, m: SimilarityTransform, width: number, height: number): RgbImage {
  const det = m.a * m.a + m.b * m.b;
  const out = new Uint8Array(width * height * 3);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const dx = x - m.tx;
      const dy = y - m.ty;
      const sx = (m.a * dx + m.b * dy) / det;
      const sy = (-m.b * dx + m.a * dy) / det;
      sampleBilinear(src, sx, sy, out, (y * width + x) * 3);
    }
  }
  return { width, height, data: out };
}

function sampleBilinear(src: RgbImage, sx: number, sy: number, out: Uint8Array, offset: number): void {
  const x0 = Math.floor(sx);
  const y0 = Math.floor(sy);
  const fx = sx - x0;
  const fy = sy - y0;
  for (let ch = 0; ch < 3; ch++) {
    const v00 = pixel(src, x0, y0, ch);
    const v10 = pixel(src, x0 + 1, y0, ch);
    const v01 = pixel(src, x0, y0 + 1, ch);
    const v11 = pixel(src, x0 + 1, y0 + 1, ch);
    const top = v00 + (v10 - v00) * fx;
    const bottom = v01 + (v11 - v01) * fx;
    out[offset + ch] = Math.round(top + (bottom - top) * fy);
  }
}

// Outside the source image every channel is 0 (constant border).
function pixel(src: RgbImage, x: number, y: number, ch: number): number {
  if (x < 0 || y < 0 || x >= src.width || y >= src.height) return 0;
  return src.data[(y * src.width + x) * 3 + ch] ?? 0;
}

// cv::resize(INTER_LINEAR): half-pixel centres, edges clamped.
export function resizeBilinear(src: RgbImage, width: number, height: number): RgbImage {
  const out = new Uint8Array(width * height * 3);
  const scaleX = src.width / width;
  const scaleY = src.height / height;
  for (let y = 0; y < height; y++) {
    const sy = Math.min(Math.max((y + 0.5) * scaleY - 0.5, 0), src.height - 1);
    const y0 = Math.floor(sy);
    const y1 = Math.min(y0 + 1, src.height - 1);
    const fy = sy - y0;
    for (let x = 0; x < width; x++) {
      const sx = Math.min(Math.max((x + 0.5) * scaleX - 0.5, 0), src.width - 1);
      const x0 = Math.floor(sx);
      const x1 = Math.min(x0 + 1, src.width - 1);
      const fx = sx - x0;
      for (let ch = 0; ch < 3; ch++) {
        const top = clampedPixel(src, x0, y0, ch) * (1 - fx) + clampedPixel(src, x1, y0, ch) * fx;
        const bottom = clampedPixel(src, x0, y1, ch) * (1 - fx) + clampedPixel(src, x1, y1, ch) * fx;
        out[(y * width + x) * 3 + ch] = Math.round(top * (1 - fy) + bottom * fy);
      }
    }
  }
  return { width, height, data: out };
}

function clampedPixel(src: RgbImage, x: number, y: number, ch: number): number {
  return src.data[(y * src.width + x) * 3 + ch] ?? 0;
}
