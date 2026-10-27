import { z } from "zod";

export const RITUAL_KINDS = ["shabbat", "weekly", "custom"] as const;
export type RitualKind = (typeof RITUAL_KINDS)[number];

export interface Ritual {
  readonly id: number;
  readonly coupleId: number;
  readonly kind: RitualKind;
  readonly title: string;
  readonly weekday: number | null;
  readonly time: string | null;
  readonly enabled: boolean;
  readonly remindMinutes: number;
}

export type NewRitual = Omit<Ritual, "id" | "coupleId">;

// Created with the couple: Shabbat together on, the other two off (section 3).
export const DEFAULT_RITUALS: readonly NewRitual[] = [
  { kind: "shabbat", title: "Shabbat ensemble", weekday: 5, time: null, enabled: true, remindMinutes: 60 },
  { kind: "weekly", title: "Soirée sans écran", weekday: 2, time: "20:00", enabled: false, remindMinutes: 60 },
  { kind: "weekly", title: "Appeler les parents", weekday: 0, time: "11:00", enabled: false, remindMinutes: 60 },
];

const time = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, "must be a time (HH:MM)");

const fields = {
  kind: z.enum(RITUAL_KINDS),
  title: z.string().trim().min(1).max(120),
  weekday: z.number().int().min(0).max(6).nullable(),
  time: time.nullable(),
  enabled: z.boolean(),
  remind_minutes: z.number().int().min(0).max(10_080),
};

// POST body: kind and title are required, the rest has defaults.
export const createRitualBody = z
  .object({
    kind: fields.kind,
    title: fields.title,
    weekday: fields.weekday.optional(),
    time: fields.time.optional(),
    enabled: fields.enabled.optional(),
    remind_minutes: fields.remind_minutes.optional(),
  })
  .strict();

export const updateRitualBody = z
  .object({
    title: fields.title.optional(),
    weekday: fields.weekday.optional(),
    time: fields.time.optional(),
    enabled: fields.enabled.optional(),
    remind_minutes: fields.remind_minutes.optional(),
  })
  .strict()
  .refine((body) => Object.keys(body).length > 0, { message: "at least one field is required" });

export function newRitualFrom(body: z.infer<typeof createRitualBody>): NewRitual {
  return {
    kind: body.kind,
    title: body.title,
    weekday: body.weekday ?? (body.kind === "shabbat" ? 5 : null),
    time: body.kind === "shabbat" ? null : (body.time ?? null),
    enabled: body.enabled ?? true,
    remindMinutes: body.remind_minutes ?? 60,
  };
}
