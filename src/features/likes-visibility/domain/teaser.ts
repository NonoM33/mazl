// What a member without mazl+ may know of someone who liked them: a first name
// (the web client shows it; the app does not), the badge, when, and a 48 px
// blurred variant of the photo. Never the photo itself, never the id (it would
// open the full profile), never the age. « Voir qui vous a aimé » is a mazl+
// benefit (CGV §2.1, docs/premium/MONETISATION.md section 1).
//
// The field is `blurredPhotoUrl` as the contract names it.

export interface ReceivedLikeTeaser {
  readonly display_name: unknown;
  readonly is_verified: unknown;
  readonly liked_at: unknown;
  readonly is_super_like: boolean;
  // Signed URL of the blurred variant, null when the photo is not one of ours.
  readonly blurredPhotoUrl: string | null;
}

// Signs the blurred variant of the photo behind `picture` (a signed URL of this
// server); null when there is none.
export type BlurredUrlOf = (picture: unknown) => string | null;

export function teaserOf(like: Readonly<Record<string, unknown>>, blurredUrlOf: BlurredUrlOf): ReceivedLikeTeaser {
  return {
    display_name: like.display_name,
    is_verified: like.is_verified,
    liked_at: like.liked_at,
    is_super_like: like.is_super_like === true,
    blurredPhotoUrl: blurredUrlOf(like.picture),
  };
}
