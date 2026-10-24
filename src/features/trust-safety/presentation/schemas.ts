import { z } from "zod";
import {
  APPEAL_STATUSES,
  AUTHORITY_KINDS,
  AUTHORITY_STATUSES,
  DECISION_GROUNDS,
  PRIORITIES,
  REPORT_REASONS,
  REPORT_STATUSES,
  SANCTION_KINDS,
} from "../domain/types";

// Request validation of the back-office routes. Strict objects: an unknown key
// is a mistake worth reporting.

const page = {
  limit: z.coerce.number().int().min(1).max(100).default(25),
  offset: z.coerce.number().int().min(0).default(0),
};

const note = z.string().trim().min(3).max(2000);

export const reportsQuerySchema = z
  .object({
    status: z.enum(REPORT_STATUSES).optional(),
    priority: z.enum(PRIORITIES).optional(),
    assigned: z.enum(["me", "none", "all"]).default("all"),
    reason: z.enum(REPORT_REASONS).optional(),
    ...page,
  })
  .strict();

export const assignBodySchema = z.object({ to: z.union([z.literal("me"), z.null()]) }).strict();

export const sanctionInputSchema = z
  .object({
    kind: z.enum(SANCTION_KINDS),
    ground: z.enum(DECISION_GROUNDS),
    facts: z.string().trim().min(10).max(2000),
    durationDays: z.number().int().min(1).max(365).optional(),
  })
  .strict()
  .refine((value) => (value.kind !== "restriction" && value.kind !== "suspension") || value.durationDays !== undefined, {
    message: "durationDays is required for a restriction or a suspension",
    path: ["durationDays"],
  });

export const decisionBodySchema = z
  .object({
    outcome: z.enum(["dismissed", "actioned"]),
    note,
    sanction: sanctionInputSchema.optional(),
  })
  .strict()
  .refine((value) => value.outcome === "actioned" || value.sanction === undefined, {
    message: "a dismissed report carries no sanction",
    path: ["sanction"],
  });

export const conversationQuerySchema = z.object({ justification: z.string().trim().min(10).max(500) }).strict();

export const membersQuerySchema = z.object({ q: z.string().trim().min(1).max(100), ...page }).strict();

export const createSanctionBodySchema = z
  .object({
    kind: z.enum(SANCTION_KINDS),
    ground: z.enum(DECISION_GROUNDS),
    facts: z.string().trim().min(10).max(2000),
    durationDays: z.number().int().min(1).max(365).optional(),
    note,
  })
  .strict()
  .refine((value) => (value.kind !== "restriction" && value.kind !== "suspension") || value.durationDays !== undefined, {
    message: "durationDays is required for a restriction or a suspension",
    path: ["durationDays"],
  });

export const revokeBodySchema = z.object({ note }).strict();

export const appealsQuerySchema = z.object({ status: z.enum(APPEAL_STATUSES).optional(), ...page }).strict();

export const appealDecisionBodySchema = z.object({ outcome: z.enum(["upheld", "overturned"]), note }).strict();

const isoDate = z.string().regex(/^\d{4}-\d{2}-\d{2}(T[\d:.]+(Z|[+-]\d{2}:\d{2}))?$/, "ISO 8601 date expected");

export const authorityBodySchema = z
  .object({
    kind: z.enum(AUTHORITY_KINDS),
    authority: z.string().trim().min(2).max(200),
    reference: z.string().trim().min(1).max(100),
    receivedAt: isoDate.optional(),
    dueAt: isoDate.nullable().optional(),
    memberId: z.number().int().positive().nullable().optional(),
    scope: z.string().trim().min(3).max(2000),
    status: z.enum(AUTHORITY_STATUSES).default("received"),
    notes: z.string().trim().max(4000).nullable().optional(),
  })
  .strict();

export const authorityPatchSchema = z
  .object({
    status: z.enum(AUTHORITY_STATUSES).optional(),
    dueAt: isoDate.nullable().optional(),
    scope: z.string().trim().min(3).max(2000).optional(),
    notes: z.string().trim().max(4000).nullable().optional(),
    memberId: z.number().int().positive().nullable().optional(),
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, { message: "nothing to update" });

export const authoritiesQuerySchema = z.object({ status: z.enum(AUTHORITY_STATUSES).optional(), ...page }).strict();

const calendarDay = z.string().regex(/^\d{4}-\d{2}-\d{2}$/).refine((value) => !Number.isNaN(Date.parse(`${value}T00:00:00Z`)), "invalid date");

export const transparencyQuerySchema = z
  .object({ from: calendarDay, to: calendarDay, format: z.enum(["json", "csv"]).default("json") })
  .strict()
  .refine((value) => value.from <= value.to, { message: "from must not be after to", path: ["to"] })
  .refine((value) => Date.parse(value.to) - Date.parse(value.from) <= 366 * 86_400_000, { message: "period is limited to one year", path: ["to"] });

// The public appeal: the reference and code come with the statement of reasons.
export const publicAppealBodySchema = z
  .object({
    reference: z.string().trim().min(1).max(40),
    appealCode: z.string().trim().min(1).max(40),
    message: z.string().trim().min(10).max(2000),
  })
  .strict();
