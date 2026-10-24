import { z } from "zod";
import { AUDIT_TARGET_TYPES } from "../domain/targets";

const optionalText = z.string().min(1).max(200).optional();

export const auditQuerySchema = z.object({
  actor: optionalText,
  action: optionalText,
  targetType: z.enum(AUDIT_TARGET_TYPES).optional(),
  targetId: optionalText,
  limit: z.coerce.number().int().min(1).max(200).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});
