import { z } from "zod";

// The two attributes discovery cannot work without: who the member is and who
// they are looking for. Without them the feed has no way to filter, and
// showing "everyone" is a wrong answer, not a harmless default.

export const GENDER_VALUES = ["male", "female"] as const;
export type Gender = (typeof GENDER_VALUES)[number];

// "all" is an explicit choice (the web client offers « Tous »): only an
// absent answer is missing.
export const LOOKING_FOR_VALUES = ["male", "female", "all"] as const;

export const genderSchema = z.enum(GENDER_VALUES);
export const lookingForSchema = z.enum(LOOKING_FOR_VALUES);

export type MissingProfileField = "gender" | "looking_for";

/** Any profile-shaped record: a database row or a serialized profile. */
export type ProfilePreferences = Readonly<Record<string, unknown>>;

function isAccepted(schema: z.ZodType, value: unknown): boolean {
  return typeof value === "string" && schema.safeParse(value.trim().toLowerCase()).success;
}

/** The fields the member still has to give; empty when the profile is complete. */
export function missingProfileFields(profile: ProfilePreferences | null | undefined): MissingProfileField[] {
  const missing: MissingProfileField[] = [];
  if (!isAccepted(genderSchema, profile?.["gender"])) missing.push("gender");
  if (!isAccepted(lookingForSchema, profile?.["looking_for"])) missing.push("looking_for");
  return missing;
}

export const MINIMUM_AGE = 18;

/** What the completeness rule reads from a stored profile row. */
export interface ProfileCompletenessInput extends ProfilePreferences {
  readonly display_name?: unknown;
  readonly birthdate?: unknown;
}

function asDate(value: unknown): Date | null {
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value;
  if (typeof value !== "string") return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function isAdult(birthdate: Date, now: Date): boolean {
  let age = now.getUTCFullYear() - birthdate.getUTCFullYear();
  const beforeBirthday =
    now.getUTCMonth() < birthdate.getUTCMonth() ||
    (now.getUTCMonth() === birthdate.getUTCMonth() && now.getUTCDate() < birthdate.getUTCDate());
  if (beforeBirthday) age -= 1;
  return age >= MINIMUM_AGE;
}

/**
 * THE rule for `profiles.is_complete` (a member appears in the others' feeds
 * only when it holds): a display name, a birthdate making the member 18 or
 * older, and a valid gender and looking_for.
 */
export function isProfileComplete(profile: ProfileCompletenessInput | null | undefined, now: Date = new Date()): boolean {
  if (!profile) return false;
  const name = profile.display_name;
  if (typeof name !== "string" || name.trim() === "") return false;
  const birthdate = asDate(profile.birthdate);
  if (birthdate === null || !isAdult(birthdate, now)) return false;
  return missingProfileFields(profile).length === 0;
}
