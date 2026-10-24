import type { ProfileCard } from "../../web/src/shared/api/types";

export function card(id: number, overrides: Partial<ProfileCard> = {}): ProfileCard {
  return {
    user_id: id, display_name: `Membre ${id}`, age: 30, gender: "male", bio: null, location: "Paris", denomination: null,
    kashrut_level: null, shabbat_observance: null, relationship_intention: null, is_verified: false, picture: null, photos: [], ...overrides,
  };
}
