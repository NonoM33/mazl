import { z } from "zod";

// What the app measured while a selfie check did not complete: counts and
// sizes only, never an image, an embedding or a position of a real face beyond
// rounded fractions. Logged as one line to find why a device cannot pass.
const count = z.number().int().min(0).max(100_000);
const fraction = z.number().min(-2).max(3);

export const captureDiagnosticsSchema = z
  .object({
    platform: z.enum(["ios", "android"]),
    frames: count,
    framesWithFace: count,
    feedback: z.record(z.string().regex(/^[a-zA-Z]{1,32}$/), count).refine((r) => Object.keys(r).length <= 12),
    imageWidth: count,
    imageHeight: count,
    sensorOrientation: z.number().int().min(0).max(359),
    rotation: z.number().int().min(0).max(359).nullable(),
    lastFace: z.object({ cx: fraction, cy: fraction, w: fraction, frameWidth: count, frameHeight: count }).nullable(),
  })
  .strict();

export type CaptureDiagnostics = z.infer<typeof captureDiagnosticsSchema>;

export function captureDiagnosticsLine(userId: number, d: CaptureDiagnostics): string {
  const feedback = Object.entries(d.feedback).map(([k, v]) => `${k}=${v}`).join(" ");
  const face = d.lastFace === null
    ? "no face"
    : `last face cx=${d.lastFace.cx.toFixed(2)} cy=${d.lastFace.cy.toFixed(2)} w=${d.lastFace.w.toFixed(2)} in ${d.lastFace.frameWidth}x${d.lastFace.frameHeight}`;
  return `Selfie diagnostics user ${userId} (${d.platform}): ${d.frames} frame(s), ${d.framesWithFace} with a face | ${feedback} | image ${d.imageWidth}x${d.imageHeight} sensor ${d.sensorOrientation} rotation ${d.rotation ?? "?"} | ${face}`;
}
