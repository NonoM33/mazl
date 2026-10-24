import { z } from "zod";
import { STAFF_ROLES } from "../domain/roles";

const email = z.string().trim().min(3).max(254).email();

export const passwordLoginSchema = z.object({ email, password: z.string().min(1).max(1024) });
export const googleLoginSchema = z.object({ credential: z.string().min(1).max(8192) });
export const mfaLoginSchema = z.object({ challenge: z.string().min(1).max(4096), code: z.string().max(16) });
export const mfaConfirmSchema = z.object({ code: z.string().max(16) });
export const createStaffSchema = z.object({ email, role: z.enum(STAFF_ROLES) });
export const updateStaffSchema = z
  .object({ role: z.enum(STAFF_ROLES).optional(), active: z.boolean().optional() })
  .refine((patch) => patch.role !== undefined || patch.active !== undefined, { message: "role or active required" });
