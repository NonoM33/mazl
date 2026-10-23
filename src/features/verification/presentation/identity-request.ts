import type { ChipFiles } from "../domain/types";
import { MAX_BODY_BYTES as MAX_FRAMES_BODY_BYTES, parseFaceSubmission } from "./face-request";

// Limits of POST /api/verification/identity: the live frames plus the chip
// files, sized like the chip library's own input caps.
export const MAX_CHIP_FILE_BYTES = { dg1: 1024, dg2: 2 * 1024 * 1024, sod: 64 * 1024 } as const;
export const MAX_IDENTITY_BODY_BYTES = MAX_FRAMES_BODY_BYTES + MAX_CHIP_FILE_BYTES.dg2 + 128 * 1024;

export type IdentityParse =
  | { readonly ok: true; readonly sessionId: string; readonly frames: Uint8Array[]; readonly chip: ChipFiles }
  | { readonly ok: false; readonly status: 400 | 413; readonly error: string };

type ChipField = keyof typeof MAX_CHIP_FILE_BYTES;

async function readChipFile(form: FormData, field: ChipField): Promise<Uint8Array | { status: 400 | 413; error: string }> {
  const value: unknown = form.get(field);
  if (!(value instanceof Blob) || value.size === 0) return { status: 400, error: `${field} is required` };
  if (value.size > MAX_CHIP_FILE_BYTES[field]) return { status: 413, error: `${field}_too_large` };
  return new Uint8Array(await value.arrayBuffer());
}

export async function parseIdentitySubmission(form: FormData): Promise<IdentityParse> {
  const frames = await parseFaceSubmission(form);
  if (!frames.ok) return frames;

  const read: Partial<Record<ChipField, Uint8Array>> = {};
  for (const field of ["dg1", "dg2", "sod"] as const) {
    const result = await readChipFile(form, field);
    if (!(result instanceof Uint8Array)) return { ok: false, ...result };
    read[field] = result;
  }
  const { dg1, dg2, sod } = read;
  if (!dg1 || !dg2 || !sod) return { ok: false, status: 400, error: "chip files are required" };
  return { ok: true, sessionId: frames.sessionId, frames: frames.frames, chip: { dg1, dg2, sod } };
}
