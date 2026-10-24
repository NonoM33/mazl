import type { Context } from "hono";
import type { z } from "zod";
import { TrustSafetyError } from "../application/errors";
import { currentStaff, type StaffVariables } from "../../staff/application/ports";
import { roleGrants, type Permission } from "../../staff/domain/roles";

export type TsContext = Context<{ Variables: StaffVariables }>;

export function parseId(raw: string | undefined): number {
  const id = Number(raw);
  if (!Number.isInteger(id) || id <= 0 || id > 2_147_483_647) throw new TrustSafetyError("not_found", 404, "Ressource introuvable");
  return id;
}

function invalid(error: z.ZodError): TrustSafetyError {
  const first = error.issues[0];
  const where = first && first.path.length > 0 ? `${first.path.join(".")}: ` : "";
  return new TrustSafetyError("invalid_request", 400, `${where}${first?.message ?? "requête invalide"}`);
}

export function parseQuery<T>(c: TsContext, schema: z.ZodType<T>): T {
  const parsed = schema.safeParse(c.req.query());
  if (!parsed.success) throw invalid(parsed.error);
  return parsed.data;
}

export async function parseJson<T>(c: TsContext, schema: z.ZodType<T>): Promise<T> {
  let raw: unknown;
  try {
    raw = await c.req.json();
  } catch {
    throw new TrustSafetyError("invalid_request", 400, "Corps JSON invalide");
  }
  const parsed = schema.safeParse(raw);
  if (!parsed.success) throw invalid(parsed.error);
  return parsed.data;
}

// Extra permission checked against the role of the caller, for actions whose
// permission depends on the body (a ban needs sanctions.ban).
export function requireGrant(c: TsContext, permission: Permission): void {
  if (!roleGrants(currentStaff(c).role, permission)) {
    throw new TrustSafetyError("forbidden", 403, `Permission requise : ${permission}`);
  }
}

export function ok<T>(c: TsContext, data: T, status: 200 | 201 = 200): Response {
  return c.json({ success: true, data }, status);
}
