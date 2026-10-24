// Shapes of the API responses the web reads, as served by src/ (snake_case
// kept). Only the fields the web uses are listed. DECIMAL and COUNT columns
// arrive as strings from postgres.js.

export type Gender = "male" | "female";
export type LookingFor = "male" | "female" | "all";
export type VerificationLevel = "none" | "photo" | "identity";

export interface Envelope { readonly success: true }

export interface MeUser {
  readonly id: number;
  readonly email: string;
  readonly name: string | null;
  readonly picture: string | null;
  readonly provider: string;
  readonly hasProfile: boolean;
}

export interface OwnProfileRow {
  readonly user_id: number;
  readonly display_name: string | null;
  readonly birthdate: string | null;
  readonly gender: Gender | null;
  readonly bio: string | null;
  readonly location: string | null;
  readonly latitude: string | null;
  readonly longitude: string | null;
  readonly denomination: string | null;
  readonly kashrut_level: string | null;
  readonly shabbat_observance: string | null;
  readonly relationship_intention?: string | null;
  readonly looking_for: LookingFor | null;
  readonly age_min: number | null;
  readonly age_max: number | null;
  readonly distance_max: number | null;
  readonly is_complete: boolean;
  readonly is_verified: boolean;
  readonly verification_level: VerificationLevel | null;
  readonly birthdate_locked?: boolean;
}

export interface MeResponse extends Envelope {
  readonly user: MeUser;
  readonly profile: OwnProfileRow | null;
}

// A profile as listed by /api/discover, /api/daily-picks and /api/profile/:id.
export interface ProfileCard {
  readonly user_id: number;
  readonly display_name: string | null;
  readonly age: number | null;
  readonly gender: Gender | null;
  readonly bio: string | null;
  readonly location: string | null;
  readonly denomination: string | null;
  readonly kashrut_level: string | null;
  readonly shabbat_observance: string | null;
  readonly relationship_intention?: string | null;
  readonly is_verified: boolean;
  readonly photo_verified?: boolean;
  readonly identity_verified?: boolean;
  readonly verification_level?: VerificationLevel | null;
  readonly picture: string | null;
  readonly photos: readonly string[];
}

export interface DiscoverResponse extends Envelope { readonly profiles: readonly ProfileCard[] }
export interface DailyPicksResponse extends Envelope { readonly picks: readonly ProfileCard[]; readonly date: string; readonly refreshesAt: string }
export interface ProfileResponse extends Envelope { readonly profile: ProfileCard }

export type SwipeAction = "like" | "pass" | "super_like";
export interface SwipeResponse extends Envelope { readonly match: boolean; readonly targetUserId?: number; readonly credits?: CreditsView }

export interface CreditBucket { readonly daily_allowance: number; readonly daily_remaining: number; readonly purchased_balance: number; readonly available: number }
export interface CreditsView { readonly super_like: CreditBucket; readonly boost: CreditBucket; readonly resets_at: string }
export interface CreditsResponse extends Envelope { readonly credits: CreditsView }

export interface LikeAllowance { readonly daily_allowance: number | null; readonly remaining: number | null; readonly resets_at: string }
export interface LikeAllowanceResponse extends Envelope { readonly allowance: LikeAllowance }

export interface MatchSummary {
  readonly matchId: number;
  readonly matchedAt: string;
  readonly conversationId: number;
  readonly profile: { readonly user_id: number; readonly display_name: string | null; readonly age: number | null; readonly location: string | null; readonly is_verified: boolean; readonly picture: string | null };
}
export interface MatchesResponse extends Envelope { readonly matches: readonly MatchSummary[] }

export interface ReceivedLike { readonly user_id: number; readonly display_name: string | null; readonly picture: string | null; readonly age: number | null; readonly is_verified: boolean; readonly liked_at: string }
export interface LikesReceivedResponse extends Envelope { readonly count: number; readonly likes: readonly ReceivedLike[] }
export interface CountResponse extends Envelope { readonly count: number }

export interface OwnPhoto { readonly id: number; readonly url: string; readonly position: number; readonly is_primary: boolean }
export interface PhotosResponse extends Envelope { readonly photos: readonly OwnPhoto[] }
export interface PhotoUploadResponse extends Envelope { readonly photo: OwnPhoto }

export interface PromptDefinition { readonly id: string; readonly text: string; readonly category: string }
export interface PromptsCatalogResponse extends Envelope { readonly prompts: readonly PromptDefinition[] }
export interface OwnPrompt { readonly id: number; readonly prompt_id: string; readonly prompt_text: string; readonly answer: string; readonly position: number }
export interface OwnPromptsResponse extends Envelope { readonly prompts: readonly OwnPrompt[] }
export interface OwnPromptResponse extends Envelope { readonly prompt: OwnPrompt }

export interface ConversationSummary {
  readonly id: number;
  readonly matchId: number;
  readonly lastMessageAt: string | null;
  readonly createdAt: string;
  readonly lastMessage: string | null;
  readonly unreadCount: number;
  readonly otherUser: { readonly user_id: number; readonly display_name: string | null; readonly is_verified: boolean; readonly picture: string | null };
}
export interface ConversationsResponse extends Envelope { readonly conversations: readonly ConversationSummary[] }

export type MessageType = "text" | "photo" | "voice";
export interface MessageMedia { readonly id: number; readonly kind: "photo"; readonly url: string; readonly width: number | null; readonly height: number | null }
export interface MessageVoice { readonly id: number; readonly url: string; readonly duration_ms: number | null; readonly waveform: readonly number[] | null }
export interface MessageView {
  readonly id: number;
  readonly conversation_id: number;
  readonly sender_id: number;
  readonly client_id: string | null;
  readonly type: MessageType;
  readonly content: string;
  readonly media: readonly MessageMedia[];
  readonly voice: MessageVoice | null;
  readonly reply_to: { readonly id: number; readonly sender_id: number; readonly type: MessageType; readonly preview: string } | null;
  readonly reactions: readonly { readonly emoji: string; readonly user_ids: readonly number[] }[];
  readonly link_preview: { readonly url: string; readonly title: string | null; readonly description: string | null; readonly image_url: string | null; readonly site_name: string | null } | null;
  readonly created_at: string;
  readonly read_at: string | null;
  readonly unsent: boolean;
}
export interface MessagesResponse extends Envelope { readonly messages: readonly MessageView[]; readonly has_more: boolean }
export interface MessageResponse extends Envelope { readonly message: MessageView }
export interface ReactionsResponse extends Envelope { readonly reactions: MessageView["reactions"] }

export interface BoostStatus extends Envelope { readonly is_active: boolean; readonly expires_at: string | null; readonly remaining_boosts: number; readonly boosts_used_today: number; readonly credits?: CreditsView }

export interface VerificationStatus extends Envelope {
  readonly level: VerificationLevel;
  readonly is_verified: boolean;
  readonly photo: { readonly verified: boolean; readonly verified_at: string | null };
  readonly identity: { readonly verified: boolean; readonly verified_at: string | null };
}

export interface SubscriptionRow { readonly plan_type: string | null; readonly status: string | null; readonly store: string | null; readonly expires_at: string | null }
export interface SubscriptionResponse extends Envelope { readonly subscription: SubscriptionRow | null }

export interface BlockedUser { readonly user_id: number; readonly display_name: string | null; readonly picture: string | null; readonly blocked_at: string }
export interface BlockedResponse extends Envelope { readonly blocked: readonly BlockedUser[] }

export type ReportCategory = "fake_profile" | "inappropriate_photos" | "harassment" | "spam" | "underage" | "offline_behavior" | "other";

export interface EventRow {
  readonly id: number;
  readonly title: string;
  readonly description: string | null;
  readonly event_type: string | null;
  readonly location: string | null;
  readonly address: string | null;
  readonly date: string;
  readonly time: string | null;
  readonly end_time: string | null;
  readonly price: string | null;
  readonly currency: string | null;
  readonly max_attendees: number | null;
  readonly image_url: string | null;
  readonly attendee_count: string | number;
}
export interface EventsResponse extends Envelope { readonly events: readonly EventRow[] }
export interface EventResponse extends Envelope { readonly event: EventRow; readonly userRsvp: { readonly status: string } | null }

export type RelationshipStatus = "dating" | "in_relationship" | "engaged" | "married";
export interface CoupleView { readonly id: number; readonly partner_id: number; readonly partner_name: string | null; readonly partner_picture: string | null; readonly started_at: string | null; readonly met_on_mazl_at: string | null; readonly status: RelationshipStatus }
export interface CoupleResponse extends Envelope { readonly couple: CoupleView | null }
export interface CoupleRequestView { readonly id: number; readonly requester_id: number; readonly target_id: number; readonly status: string; readonly created_at: string; readonly requester_name: string | null; readonly requester_picture: string | null; readonly target_name: string | null; readonly target_picture: string | null }
export interface CoupleRequestsResponse extends Envelope { readonly sent: readonly CoupleRequestView[]; readonly received: readonly CoupleRequestView[] }

// Web-only routes (src/features/web-session, billing-web, privacy).
export interface WebAuthConfig extends Envelope { readonly google_client_id: string | null; readonly apple_services_id: string | null; readonly pow_difficulty: number }
export interface WebChallenge extends Envelope { readonly challenge: string; readonly difficulty: number; readonly expires_at: string }
export interface WebPairing extends Envelope { readonly pairing: { readonly id: string; readonly code: string; readonly browser_secret: string; readonly expires_at: string } }
export type PairingStatus = "pending" | "scanned" | "approved" | "denied" | "expired";
export interface WebPairingStatus extends Envelope { readonly status: PairingStatus; readonly user?: { readonly id: number; readonly name: string | null } }
export interface WebSessionInfo { readonly id: string; readonly browser: string; readonly method: "qr" | "google" | "apple"; readonly created_at: string; readonly last_seen_at: string; readonly expires_at: string; readonly current?: boolean; readonly idle_expires_at?: string }
export interface WebSessionResponse extends Envelope { readonly session: WebSessionInfo; readonly user: { readonly id: number; readonly name: string | null; readonly email: string } }
export interface WebSessionsResponse extends Envelope { readonly sessions: readonly WebSessionInfo[] }
export interface SocketTicket extends Envelope { readonly token: string; readonly expires_at: string }

export type OfferId = "plus_1m" | "plus_3m" | "plus_6m" | "plus_12m" | "boost_1" | "boost_3" | "superlikes_5" | "superlikes_15";
export interface Offer { readonly id: OfferId; readonly kind: "subscription" | "credits"; readonly months?: number; readonly credit_kind?: "boost" | "super_like"; readonly quantity?: number; readonly amount_ttc_cents: number; readonly per_month_ttc_cents?: number; readonly featured: boolean }
export interface BillingCatalog extends Envelope { readonly available: boolean; readonly currency: string; readonly offers: readonly Offer[]; readonly withdrawal: { readonly text: string; readonly version: string } }
export interface BillingStatus extends Envelope {
  readonly plus: { readonly active: boolean; readonly source: "apple" | "stripe" | null; readonly plan_type: string | null; readonly expires_at: string | null; readonly status: string | null };
  readonly stripe: { readonly subscription: { readonly offer: OfferId; readonly status: string; readonly current_period_end: string; readonly cancel_at_period_end: boolean } | null; readonly has_customer: boolean };
  readonly conflict: "double_subscription" | null;
  readonly can_subscribe: boolean;
  readonly blocked_reason: "apple_active" | "stripe_active" | null;
}
export interface RedirectResponse extends Envelope { readonly url: string }

export interface ConsentState { readonly granted: boolean | null; readonly version: string | null; readonly decided_at: string | null; readonly current_version: string; readonly text: string }
export interface ConsentsResponse extends Envelope { readonly consents: { readonly religious_data: ConsentState } }
