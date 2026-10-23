import { z } from "zod";
import {
  DEFAULT_FACE_CONSISTENCY_THRESHOLD,
  DEFAULT_FACE_MATCH_THRESHOLD,
  type FaceThresholds,
} from "../domain/thresholds";

export class FaceConfigError extends Error {
  constructor(message: string) {
    super(`face verification configuration: ${message}`);
    this.name = "FaceConfigError";
  }
}

export interface FaceConfig {
  readonly modelsDir: string;
  readonly thresholds: FaceThresholds;
}

// A cosine similarity: finite, within [-1, 1]. An unset or empty variable
// means "use the default"; a malformed one stops the boot.
const cosine = (name: string, fallback: number) =>
  z
    .string()
    .optional()
    .transform((raw, ctx) => {
      if (raw === undefined || raw.trim() === "") return fallback;
      const value = Number(raw);
      if (!Number.isFinite(value) || value < -1 || value > 1) {
        ctx.addIssue({ code: "custom", message: `${name} must be a number between -1 and 1` });
        return z.NEVER;
      }
      return value;
    });

const schema = z.object({
  FACE_MODELS_DIR: z.string().optional(),
  FACE_MATCH_THRESHOLD: cosine("FACE_MATCH_THRESHOLD", DEFAULT_FACE_MATCH_THRESHOLD),
  FACE_CONSISTENCY_THRESHOLD: cosine("FACE_CONSISTENCY_THRESHOLD", DEFAULT_FACE_CONSISTENCY_THRESHOLD),
});

export function readFaceConfig(env: Record<string, string | undefined>): FaceConfig {
  const parsed = schema.safeParse(env);
  if (!parsed.success) throw new FaceConfigError(parsed.error.issues[0]?.message ?? "invalid");
  const dir = parsed.data.FACE_MODELS_DIR?.trim();
  return {
    modelsDir: dir ? dir : "models",
    thresholds: { match: parsed.data.FACE_MATCH_THRESHOLD, consistency: parsed.data.FACE_CONSISTENCY_THRESHOLD },
  };
}
