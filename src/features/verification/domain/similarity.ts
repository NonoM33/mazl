import type { Embedding } from "./types";

export class EmbeddingDimensionError extends Error {
  constructor(a: number, b: number) {
    super(`embedding dimensions differ: ${a} vs ${b}`);
    this.name = "EmbeddingDimensionError";
  }
}

// Cosine similarity, the metric the SFace threshold (0.363) is published for.
// Inputs need not be normalised; a zero vector matches nothing.
export function cosineSimilarity(a: Embedding, b: Embedding): number {
  if (a.length !== b.length) throw new EmbeddingDimensionError(a.length, b.length);
  let dot = 0;
  let normA = 0;
  let normB = 0;
  for (let i = 0; i < a.length; i++) {
    const x = a[i] ?? 0;
    const y = b[i] ?? 0;
    dot += x * y;
    normA += x * x;
    normB += y * y;
  }
  if (normA === 0 || normB === 0) return 0;
  return dot / Math.sqrt(normA * normB);
}
