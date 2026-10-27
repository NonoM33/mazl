import type { AuditTargetType } from "../application/ports";

export const AUDIT_TARGET_TYPES = [
  "member",
  "report",
  "sanction",
  "appeal",
  "conversation",
  "verification",
  "authority_request",
  "matching_params",
  "storefront_product",
  "storefront_campaign",
  "staff",
  "photo",
  "system",
] as const satisfies readonly AuditTargetType[];

// Compile-time check that the list above misses no member of AuditTargetType.
type Missing = Exclude<AuditTargetType, (typeof AUDIT_TARGET_TYPES)[number]>;
export const allTargetTypesListed: [Missing] extends [never] ? true : never = true;
