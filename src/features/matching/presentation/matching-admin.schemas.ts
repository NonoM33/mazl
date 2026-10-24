import { z } from "zod";
import type { MatchProfile } from "../domain/profile";

const MAX_ID = 2_147_483_647;
const isoDate = z.iso.datetime();
const shortText = z.string().max(100).nullable();

export const noteSchema = z.string().trim().min(3).max(500);

export const createVersionBody = z.object({
  params: z.unknown().refine((v) => v !== undefined, "params requis"),
  note: noteSchema,
  activate: z.boolean().optional(),
});

export const activateBody = z.object({ note: noteSchema });

export const abTestBody = z.object({
  variantId: z.number().int().min(1).max(MAX_ID),
  sharePercent: z.number().int().min(1).max(50),
});

const geoPoint = z.object({ latitude: z.number().min(-90).max(90), longitude: z.number().min(-180).max(180) }).strict();

export const matchProfileSchema: z.ZodType<MatchProfile> = z
  .object({
    userId: z.number().int(),
    gender: z.enum(["male", "female"]).nullable(),
    lookingFor: z.enum(["male", "female", "all"]).nullable(),
    age: z.number().int().min(0).max(120).nullable(),
    ageMin: z.number().int().min(0).max(120),
    ageMax: z.number().int().min(0).max(120),
    distanceMaxKm: z.number().min(0).max(40_000).nullable(),
    location: geoPoint.nullable(),
    denomination: shortText,
    kashrut: shortText,
    shabbat: shortText,
    intention: shortText,
    photoCount: z.number().int().min(0).max(100),
    hasBio: z.boolean(),
    promptCount: z.number().int().min(0).max(100),
    verification: z.enum(["none", "selfie", "identity"]),
    lastActiveAt: isoDate.nullable(),
    createdAt: isoDate,
    boostedUntil: isoDate.nullable(),
    likesReceived7d: z.number().int().min(0).max(1_000_000),
    openReports90d: z.number().int().min(0).max(1_000),
  })
  .strict();

export const previewBody = z.object({
  params: z.unknown().refine((v) => v !== undefined, "params requis"),
  compareWith: z.unknown().optional(),
  seed: z.number().int().min(-2_147_483_648).max(4_294_967_295),
  viewer: z.union([z.number().int().min(0), matchProfileSchema]),
  size: z.number().int().optional(),
});
