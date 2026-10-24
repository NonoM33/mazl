// What a member without mazl+ may know of someone who liked them: a first
// name, the badge and when. No photo, no id (it would open the full profile),
// no age. « Voir qui vous a aimé » is a mazl+ benefit (CGV §2.1).

export interface ReceivedLikeTeaser {
  readonly display_name: unknown;
  readonly is_verified: unknown;
  readonly liked_at: unknown;
}

export function teaserOf(like: Readonly<Record<string, unknown>>): ReceivedLikeTeaser {
  return { display_name: like.display_name, is_verified: like.is_verified, liked_at: like.liked_at };
}
