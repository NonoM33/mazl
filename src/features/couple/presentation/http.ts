import type { Context } from "hono";
import type { ZodType } from "zod";

// Small helpers shared by the couple space routes.

export type Status = 200 | 201 | 400 | 402 | 403 | 404 | 409 | 429 | 500;

export function ok(c: Context, data: unknown, status: 200 | 201 = 200, extra: Record<string, unknown> = {}): Response {
  return c.json({ success: true as const, data, ...extra }, status);
}

export function fail(c: Context, status: Exclude<Status, 200 | 201>, error: string, message?: string): Response {
  return c.json({ success: false as const, error, ...(message === undefined ? {} : { message }) }, status);
}

type Parsed<T> = { readonly ok: true; readonly data: T } | { readonly ok: false; readonly message: string };

export async function readBody<T>(c: Context, schema: ZodType<T>): Promise<Parsed<T>> {
  let raw: unknown;
  try {
    raw = await c.req.json();
  } catch {
    return { ok: false, message: "corps JSON illisible" };
  }
  const parsed = schema.safeParse(raw);
  if (parsed.success) return { ok: true, data: parsed.data };
  const issue = parsed.error.issues[0];
  const path = issue?.path.join(".") ?? "";
  return { ok: false, message: `${path === "" ? "" : `${path}: `}${issue?.message ?? "invalide"}` };
}

const POSTGRES_INTEGER_MAX = 2_147_483_647;

// A path id as a positive integer, or null.
export function routeId(raw: string | undefined): number | null {
  if (raw === undefined || !/^\d{1,10}$/.test(raw)) return null;
  const id = Number(raw);
  return id >= 1 && id <= POSTGRES_INTEGER_MAX ? id : null;
}
