import { cosineSimilarity } from "../domain/similarity";
import type { Embedding } from "../domain/types";
import { InvalidImageError, type FaceEngine, type ImageDecoder } from "./ports";

// Group photos are fine: the user only has to appear in them. The cap keeps
// a crowd photo from costing a second of CPU.
const MAX_FACES_COMPARED = 5;

export interface PhotoEvaluation {
  readonly hasFace: boolean;
  readonly match: boolean;
}

export interface PhotoMatchingDeps {
  readonly decoder: ImageDecoder;
  readonly engine: FaceEngine;
}

// Compares a stored profile photo with the user's face reference. A photo that
// cannot be decoded or shows no face is simply "no face, no match".
export async function evaluatePhoto(
  deps: PhotoMatchingDeps,
  bytes: Uint8Array,
  reference: Embedding,
  threshold: number,
): Promise<PhotoEvaluation> {
  let image;
  try {
    image = await deps.decoder.decode(bytes);
  } catch (error: unknown) {
    if (error instanceof InvalidImageError) return { hasFace: false, match: false };
    throw error;
  }
  const faces = [...(await deps.engine.detect(image))].sort((a, b) => b.score - a.score).slice(0, MAX_FACES_COMPARED);
  if (faces.length === 0) return { hasFace: false, match: false };
  let best = -Infinity;
  for (const face of faces) {
    best = Math.max(best, cosineSimilarity(reference, await deps.engine.embed(image, face)));
  }
  return { hasFace: true, match: best >= threshold };
}
