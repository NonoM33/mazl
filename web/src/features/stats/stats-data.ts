import { api } from "../../shared/api/client";
import type { BoostStatus, ConversationsResponse, CountResponse, CreditsResponse, CreditsView, MatchesResponse, MeResponse, OwnPhoto, OwnPromptsResponse, PhotosResponse, VerificationLevel, VerificationStatus } from "../../shared/api/types";

// Everything the dashboard shows, each from one API route. A route that
// fails leaves its figure at null: the screen says "indisponible" instead of
// inventing a number.

export interface StatsData {
  readonly likes: number | null;
  readonly matches: number | null;
  readonly conversations: number | null;
  readonly unread: number | null;
  readonly credits: CreditsView | null;
  readonly boost: BoostStatus | null;
  readonly level: VerificationLevel | null;
  readonly photos: readonly OwnPhoto[] | null;
  readonly prompts: number | null;
  readonly profile: MeResponse["profile"] | undefined;
}

async function settle<T>(task: Promise<T>): Promise<T | null> {
  try {
    return await task;
  } catch {
    return null;
  }
}

export async function loadStats(signal: AbortSignal): Promise<StatsData> {
  const [likes, matches, conversations, credits, boost, verification, photos, prompts, me] = await Promise.all([
    settle(api.get<CountResponse>("/api/likes/received/count", signal)),
    settle(api.get<MatchesResponse>("/api/matches", signal)),
    settle(api.get<ConversationsResponse>("/api/conversations", signal)),
    settle(api.get<CreditsResponse>("/api/credits", signal)),
    settle(api.get<BoostStatus>("/api/boost/status", signal)),
    settle(api.get<VerificationStatus>("/api/verification/status", signal)),
    settle(api.get<PhotosResponse>("/api/profile/photos", signal)),
    settle(api.get<OwnPromptsResponse>("/api/profile/prompts", signal)),
    settle(api.get<MeResponse>("/api/auth/me", signal)),
  ]);
  const active = conversations?.conversations.filter((conversation) => conversation.lastMessage !== null) ?? null;
  return {
    likes: likes?.count ?? null,
    matches: matches?.matches.length ?? null,
    conversations: active?.length ?? null,
    unread: active?.reduce((sum, conversation) => sum + conversation.unreadCount, 0) ?? null,
    credits: credits?.credits ?? null,
    boost,
    level: verification?.level ?? null,
    photos: photos?.photos ?? null,
    prompts: prompts?.prompts.length ?? null,
    profile: me === null ? undefined : me.profile,
  };
}
