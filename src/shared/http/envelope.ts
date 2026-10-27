import type { Context } from "hono";
import type { ZodType } from "zod";

// The envelope of the member API: { success: true, data } or
// { success: false, error: <stable code> }. The app writes the sentence; the
// server only says WHAT happened, never the text of an exception.

type Status = 200 | 201 | 400 | 401 | 402 | 404 | 409 | 429 | 500;

export function ok<T>(c: Context, data: T, status: 200 | 201 = 200): Response {
  return c.json({ success: true, data }, status);
}

export function fail(c: Context, error: string, status: Exclude<Status, 200 | 201>): Response {
  return c.json({ success: false, error }, status);
}

export type JsonBody<T> = { readonly ok: true; readonly data: T } | { readonly ok: false };

// A JSON body checked against its schema; the caller answers 400 invalid_body.
export async function readJson<T>(c: Context, schema: ZodType<T>): Promise<JsonBody<T>> {
  let raw: unknown;
  try {
    raw = await c.req.json();
  } catch {
    return { ok: false };
  }
  const parsed = schema.safeParse(raw);
  return parsed.success ? { ok: true, data: parsed.data } : { ok: false };
}

export const INVALID_BODY = "invalid_body";
export const INTERNAL_ERROR = "internal_error";

export function logFailure(label: string, error: unknown): void {
  console.error(`${label}:`, error instanceof Error ? error.name : "unknown");
}
