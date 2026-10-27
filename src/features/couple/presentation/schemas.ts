import { z } from "zod";
import { checkinBody } from "../domain/checkin";
import { MAX_MEMBER_TEXT, MAX_STAFF_TEXT, MESSAGE_ROLES, REQUEST_KINDS, REQUEST_STATUSES, optionSchema } from "../domain/concierge";
import { moodBody, MOODS } from "../domain/mood";
import { OUTING_FILTERS } from "../domain/outings";
import { createRitualBody, RITUAL_KINDS, updateRitualBody } from "../domain/rituals";

// Wire formats of the daily couple space: requests (parsed at the edge) and
// responses (documented in the OpenAPI, checked against the examples by tests).

export const errorEnvelope = z.object({ success: z.literal(false), error: z.string(), message: z.string().optional() });
export const envelope = <T extends z.ZodType>(data: T) => z.object({ success: z.literal(true), data });

const iso = z.iso.datetime({ offset: true });
const day = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);

// ---------- requests ----------

export { checkinBody, createRitualBody, moodBody, updateRitualBody };

export const outingsQuery = z.enum(OUTING_FILTERS);

// A real calendar day: 2026-02-31 is refused.
const wantedAt = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/)
  .refine((value) => {
    const [year, month, dayOfMonth] = value.split("-").map(Number);
    if (year === undefined || month === undefined || dayOfMonth === undefined) return false;
    const parsed = new Date(Date.UTC(year, month - 1, dayOfMonth));
    return parsed.getUTCFullYear() === year && parsed.getUTCMonth() === month - 1 && parsed.getUTCDate() === dayOfMonth;
  }, "must be a real date");

export const createConciergeBody = z
  .object({
    text: z.string().trim().min(1).max(MAX_MEMBER_TEXT),
    wantedAt: wantedAt.optional(),
    city: z.string().trim().min(1).max(100).optional(),
    kind: z.enum(REQUEST_KINDS).optional(),
    kosher: z.boolean().optional(),
    budget: z.string().trim().min(1).max(80).optional(),
  })
  .strict();

export const conciergeMessageBody = z.object({ text: z.string().trim().min(1).max(MAX_MEMBER_TEXT) }).strict();
export const chooseBody = z.object({ index: z.number().int().min(0).max(2) }).strict();

export const staffPatchBody = z
  .object({
    status: z.enum(["booked", "closed"]).optional(),
    staffNote: z.string().max(4000).optional(),
    assignedTo: z.email().max(254).nullable().optional(),
  })
  .strict()
  .refine((body) => Object.keys(body).length > 0, { message: "at least one field is required" });

export const staffMessageBody = z.object({ text: z.string().trim().min(1).max(MAX_STAFF_TEXT) }).strict();
export const staffStatusQuery = z.enum(REQUEST_STATUSES);

// ---------- responses ----------

export const premiumDto = z.object({ active: z.boolean(), paidBy: z.enum(["me", "partner"]).nullable(), renewsAt: iso.nullable() });

export const outingDto = z.object({
  id: z.number().int(),
  kind: z.enum(["activity", "event"]),
  title: z.string(),
  subtitle: z.string(),
  imageUrl: z.string().nullable(),
  city: z.string().nullable(),
  startsAt: iso.nullable(),
  priceCents: z.number().int().nullable(),
  kosher: z.boolean(),
  saved: z.boolean(),
});

const moodValue = z.enum(MOODS);

export const todayDto = z.object({
  days: z.number().int(),
  partner: z.object({ id: z.number().int(), name: z.string(), picture: z.string().nullable() }),
  question: z.object({ id: z.number().int(), text: z.string(), myAnswered: z.boolean(), partnerAnswered: z.boolean() }),
  upcoming: z.array(z.object({ kind: z.enum(["date", "ritual", "event"]), title: z.string(), at: iso, subtitle: z.string(), refId: z.number().int() })).max(5),
  outing: outingDto.nullable(),
  mood: z.object({ mine: moodValue.nullable(), partner: moodValue.nullable() }),
  checkin: z.object({ due: z.boolean(), period: z.string().regex(/^\d{4}-\d{2}$/) }),
  premium: premiumDto,
});

export const moodResultDto = z.object({ mine: moodValue, partner: moodValue.nullable() });

export const ritualDto = z.object({
  id: z.number().int(),
  couple_id: z.number().int(),
  kind: z.enum(RITUAL_KINDS),
  title: z.string(),
  weekday: z.number().int().min(0).max(6).nullable(),
  time: z.string().regex(/^\d{2}:\d{2}$/).nullable(),
  enabled: z.boolean(),
  remind_minutes: z.number().int(),
});
export const ritualListDto = z.object({ rituals: z.array(ritualDto) });
export const ritualOneDto = z.object({ ritual: ritualDto });

export const outingsDto = z.object({ featured: outingDto.nullable(), items: z.array(outingDto) });

const rating = z.number().int().min(1).max(5);
export const checkinDto = z.object({
  period: z.string().regex(/^\d{4}-\d{2}$/),
  mine: z.object({ talk: rating, time: rating, close: rating }).nullable(),
  partnerDone: z.boolean(),
  summary: z
    .object({ aligned: z.number().int().min(0).max(3), lowest: z.enum(["talk", "time", "close"]), trend: z.enum(["up", "down", "same"]).nullable() })
    .nullable(),
});

export const dailyQuestionDto = z.object({ id: z.number().int(), text: z.string(), myAnswer: z.string().nullable(), partnerAnswer: z.string().nullable() });
export const questionHistoryDto = z.object({ questions: z.array(dailyQuestionDto.extend({ askedAt: day })) });
export const answeredDto = z.object({ recorded: z.literal(true) });

const status = z.enum(REQUEST_STATUSES);
export const conciergeListDto = z.object({
  requests: z.array(z.object({ id: z.number().int(), title: z.string(), status, wantedAt: day.nullable(), updatedAt: iso, step: z.number().int().min(1).max(3) })),
});

const constraints = z.object({ kosher: z.boolean().optional(), budget: z.string().optional() });
export const conciergeRequestDto = z.object({
  id: z.number().int(),
  title: z.string(),
  brief: z.string(),
  kind: z.enum(REQUEST_KINDS),
  status,
  step: z.number().int().min(1).max(3),
  wantedAt: day.nullable(),
  city: z.string().nullable(),
  constraints,
  options: z.array(optionSchema),
  chosenIndex: z.number().int().nullable(),
  createdAt: iso,
  updatedAt: iso,
});
export const conciergeMessageDto = z.object({ id: z.number().int(), role: z.enum(MESSAGE_ROLES), text: z.string(), createdAt: iso, mine: z.boolean() });
export const conciergeDetailDto = z.object({ request: conciergeRequestDto, messages: z.array(conciergeMessageDto) });

const coupleSummary = z.object({ firstNames: z.array(z.string()), months: z.number().int().min(0) });
export const staffListDto = z.object({
  requests: z.array(
    z.object({
      id: z.number().int(), title: z.string(), status, wantedAt: day.nullable(), updatedAt: iso, step: z.number().int().min(1).max(3),
      assignedTo: z.string().nullable(), couple: coupleSummary,
    }),
  ),
});
export const staffRequestDto = z.object({
  id: z.number().int(), title: z.string(), brief: z.string(), status, wantedAt: day.nullable(), city: z.string().nullable(), constraints,
  options: z.array(optionSchema), chosenIndex: z.number().int().nullable(), staffNote: z.string().nullable(), assignedTo: z.string().nullable(),
  createdAt: iso, updatedAt: iso,
});
export const staffDetailDto = z.object({
  request: staffRequestDto,
  couple: coupleSummary,
  messages: z.array(z.object({ id: z.number().int(), role: z.enum(MESSAGE_ROLES), authorId: z.number().int().nullable(), text: z.string(), createdAt: iso })),
});
export const staffMembersDto = z.object({ staff: z.array(z.object({ email: z.string(), name: z.string() })) });

export const openApiDocument = z.record(z.string(), z.unknown());
