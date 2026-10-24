import type { Gender, ProfileCard, VerificationLevel } from "../../shared/api/types";
import { ageFromBirthdate, type ProfileDraft } from "./profile-draft";

// The draft as another member would see it: same card the panel shows for
// anyone, fed by what is being typed.
export function previewCard(userId: number, draft: ProfileDraft, photos: readonly string[], level: VerificationLevel): ProfileCard {
  const gender: Gender | null = draft.gender === "" ? null : draft.gender;
  return {
    user_id: userId,
    display_name: draft.displayName.trim() || null,
    age: ageFromBirthdate(draft.birthdate),
    gender,
    bio: draft.bio.trim() || null,
    location: draft.location.trim() || null,
    denomination: draft.denomination || null,
    kashrut_level: draft.kashrutLevel || null,
    shabbat_observance: draft.shabbatObservance || null,
    relationship_intention: draft.relationshipIntention || null,
    is_verified: level !== "none",
    verification_level: level,
    picture: photos[0] ?? null,
    photos,
  };
}
