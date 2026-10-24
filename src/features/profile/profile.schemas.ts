import { z } from "zod";
import { genderSchema, lookingForSchema } from "./domain/profile-completeness";

// PUT /api/profile: guard the numeric field TYPES (ageMin/ageMax/distanceMax,
// lat/long) and declare the string fields the handler reads so they stay
// well-typed. Everything is optional and `.passthrough()` keeps any other
// field the mobile app may send — nothing legitimate is rejected. gender and
// lookingFor are the exception: only 'male' / 'female' are accepted.
export const updateProfileBodySchema = z
  .object({
    displayName: z.string().optional(),
    birthdate: z.string().optional(),
    gender: genderSchema.optional(),
    bio: z.string().optional(),
    location: z.string().optional(),
    latitude: z.number().min(-90).max(90).optional(),
    longitude: z.number().min(-180).max(180).optional(),
    denomination: z.string().optional(),
    kashrutLevel: z.string().optional(),
    shabbatObservance: z.string().optional(),
    lookingFor: lookingForSchema.optional(),
    ageMin: z.number().optional(),
    ageMax: z.number().optional(),
    distanceMax: z.number().optional(),
  })
  .passthrough();
