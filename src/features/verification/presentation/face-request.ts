import { z } from "zod";

// Limits of POST /api/verification/face/submit.
export const MAX_FRAME_BYTES = 2 * 1024 * 1024;
export const MAX_FRAMES = 8;
// Frames plus the multipart envelope; refused before the body is read.
export const MAX_BODY_BYTES = MAX_FRAMES * MAX_FRAME_BYTES + 64 * 1024;

export const sessionRequestSchema = z.object({ purpose: z.enum(["photo", "identity"]) });

export const submitFieldsSchema = z.object({ session_id: z.string().min(1).max(64) });

export type FrameParse =
  | { readonly ok: true; readonly sessionId: string; readonly frames: Uint8Array[] }
  | { readonly ok: false; readonly status: 400 | 413; readonly error: string };

const FRAME_KEY = /^frame_(\d{1,2})$/;

// Turns the multipart form into the ordered frame list. Frames must be
// frame_0..frame_{n-1} without gaps; a gap yields an empty list so that the
// use case answers wrong_frame_count (after consuming the session, as for any
// other failed attempt).
export async function parseFaceSubmission(form: FormData): Promise<FrameParse> {
  const fields = submitFieldsSchema.safeParse({ session_id: form.get("session_id") });
  if (!fields.success) return { ok: false, status: 400, error: "session_id is required" };

  const byIndex = new Map<number, Blob>();
  for (const [key, value] of form.entries() as IterableIterator<[string, unknown]>) {
    const match = FRAME_KEY.exec(key);
    if (!match) continue;
    if (!(value instanceof Blob)) return { ok: false, status: 400, error: `${key} must be a file` };
    if (value.size > MAX_FRAME_BYTES) return { ok: false, status: 413, error: "frame_too_large" };
    byIndex.set(Number(match[1]), value);
  }
  if (byIndex.size > MAX_FRAMES) return { ok: false, status: 400, error: "too_many_frames" };

  const files: Blob[] = [];
  for (let i = 0; i < byIndex.size; i++) {
    const file = byIndex.get(i);
    if (!file) return { ok: true, sessionId: fields.data.session_id, frames: [] };
    files.push(file);
  }
  const frames = await Promise.all(files.map(async (f) => new Uint8Array(await f.arrayBuffer())));
  return { ok: true, sessionId: fields.data.session_id, frames };
}
