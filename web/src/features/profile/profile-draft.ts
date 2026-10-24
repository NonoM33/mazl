import type { Gender, OwnProfileRow } from "../../shared/api/types";

// The editable text fields of "Modifier le profil", the diff sent to PUT
// /api/profile (only what changed) and the validation done before sending.

export const LIMITS = { displayName: 50, bio: 1000, location: 100 } as const;
export const MIN_AGE = 18;

export type DraftField = "displayName" | "birthdate" | "gender" | "location" | "bio" | "denomination" | "kashrutLevel" | "shabbatObservance" | "relationshipIntention";

export interface ProfileDraft {
  readonly displayName: string;
  readonly birthdate: string;
  readonly gender: Gender | "";
  readonly location: string;
  readonly bio: string;
  readonly denomination: string;
  readonly kashrutLevel: string;
  readonly shabbatObservance: string;
  readonly relationshipIntention: string;
}

export type DraftErrors = Partial<Record<DraftField, string>>;

const FIELDS: readonly DraftField[] = ["displayName", "birthdate", "gender", "location", "bio", "denomination", "kashrutLevel", "shabbatObservance", "relationshipIntention"];

export function draftFromRow(row: OwnProfileRow | null): ProfileDraft {
  return {
    displayName: row?.display_name ?? "",
    birthdate: row?.birthdate?.slice(0, 10) ?? "",
    gender: row?.gender ?? "",
    location: row?.location ?? "",
    bio: row?.bio ?? "",
    denomination: row?.denomination ?? "",
    kashrutLevel: row?.kashrut_level ?? "",
    shabbatObservance: row?.shabbat_observance ?? "",
    relationshipIntention: row?.relationship_intention ?? "",
  };
}

export type ProfileChanges = Partial<Record<DraftField, string>>;

// Only the fields that differ from the saved profile. A locked birth date
// (checked by an identity document) and a never-set choice are never sent.
export function changedFields(saved: ProfileDraft, draft: ProfileDraft, options: { readonly birthdateLocked: boolean; readonly practiceAllowed: boolean }): ProfileChanges {
  const practice: readonly DraftField[] = ["denomination", "kashrutLevel", "shabbatObservance", "relationshipIntention"];
  const changes: Record<string, string> = {};
  for (const field of FIELDS) {
    if (field === "birthdate" && options.birthdateLocked) continue;
    if (practice.includes(field) && !options.practiceAllowed) continue;
    const next = draft[field].trim();
    if (next === saved[field].trim()) continue;
    if (next === "" && (field === "gender" || practice.includes(field))) continue;
    changes[field] = next;
  }
  return changes;
}

export function ageFromBirthdate(birthdate: string, now: Date = new Date()): number | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(birthdate);
  if (!match) return null;
  const [year, month, day] = [Number(match[1]), Number(match[2]), Number(match[3])];
  const parsed = new Date(Date.UTC(year, month - 1, day));
  if (parsed.getUTCFullYear() !== year || parsed.getUTCMonth() !== month - 1 || parsed.getUTCDate() !== day) return null;
  let age = now.getFullYear() - year;
  if (now.getMonth() + 1 < month || (now.getMonth() + 1 === month && now.getDate() < day)) age -= 1;
  return age;
}

function birthdateError(value: string): string | null {
  const age = ageFromBirthdate(value);
  if (age === null) return "Indiquez une date valide.";
  if (age < MIN_AGE) return `MAZL est réservé aux personnes de ${MIN_AGE} ans et plus.`;
  if (age > 99) return "Vérifiez cette date de naissance.";
  return null;
}

// Messages for the changed fields only: a field left alone is not re-judged.
export function validateChanges(changes: ProfileChanges): DraftErrors {
  const errors: Record<string, string> = {};
  const { displayName, birthdate, location, bio } = changes;
  if (displayName !== undefined) {
    if (displayName.length === 0) errors.displayName = "Votre prénom est nécessaire.";
    else if (displayName.length > LIMITS.displayName) errors.displayName = `${LIMITS.displayName} caractères au maximum.`;
  }
  if (birthdate !== undefined) {
    const message = birthdateError(birthdate);
    if (message) errors.birthdate = message;
  }
  if (location !== undefined && location.length > LIMITS.location) errors.location = `${LIMITS.location} caractères au maximum.`;
  if (bio !== undefined && bio.length > LIMITS.bio) errors.bio = `${LIMITS.bio} caractères au maximum.`;
  return errors;
}

// The server names the field in front of its message: "bio: String must ...".
export function fieldOfServerError(message: unknown): DraftField | null {
  if (typeof message !== "string") return null;
  const head = message.split(":")[0]?.trim() ?? "";
  return FIELDS.find((field) => field === head) ?? null;
}
