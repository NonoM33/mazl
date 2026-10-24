import { z } from "zod";

// The two attributes discovery cannot work without: who the member is and who
// they are looking for. Without them the feed has no way to filter, and
// showing "everyone" is a wrong answer, not a harmless default.

export const GENDER_VALUES = ["male", "female"] as const;
export type Gender = (typeof GENDER_VALUES)[number];

export const genderSchema = z.enum(GENDER_VALUES);
export const lookingForSchema = z.enum(GENDER_VALUES);

export type MissingProfileField = "gender" | "looking_for";

/** Any profile-shaped record: a database row or a serialized profile. */
export type ProfilePreferences = Readonly<Record<string, unknown>>;

function isAccepted(value: unknown): boolean {
  return typeof value === "string" && genderSchema.safeParse(value.trim().toLowerCase()).success;
}

/** The fields the member still has to give; empty when the profile is complete. */
export function missingProfileFields(profile: ProfilePreferences | null | undefined): MissingProfileField[] {
  const missing: MissingProfileField[] = [];
  if (!isAccepted(profile?.["gender"])) missing.push("gender");
  if (!isAccepted(profile?.["looking_for"])) missing.push("looking_for");
  return missing;
}
