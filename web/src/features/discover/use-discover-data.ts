import { api } from "../../shared/api/client";
import { ApiError } from "../../shared/api/errors";
import type { CreditsResponse, LikeAllowance, LikeAllowanceResponse, SubscriptionResponse } from "../../shared/api/types";
import { useResource, type ResourceHandle } from "../../shared/hooks/use-resource";
import { isPlus } from "./plus";

// The small reads around the deck.

export function useSuperLikeCredits(): ResourceHandle<CreditsResponse | null> {
  return useResource<CreditsResponse | null>("credits", async (signal) => {
    try {
      return await api.get<CreditsResponse>("/api/credits", signal);
    } catch (error) {
      if (error instanceof ApiError) return null;
      throw error;
    }
  }, null);
}

// GET /api/likes/allowance may not exist yet: a 404 simply shows nothing.
export function useLikeAllowance(): ResourceHandle<LikeAllowance | null> {
  return useResource<LikeAllowance | null>("likes-allowance", async (signal) => {
    try {
      return (await api.get<LikeAllowanceResponse>("/api/likes/allowance", signal)).allowance;
    } catch (error) {
      if (error instanceof ApiError) return null;
      throw error;
    }
  }, null);
}

export function usePlus(): boolean {
  const { state } = useResource<boolean>("plus", async (signal) => {
    try {
      return isPlus((await api.get<SubscriptionResponse>("/api/subscription", signal)).subscription, Date.now());
    } catch (error) {
      if (error instanceof ApiError) return false;
      throw error;
    }
  }, 5 * 60_000);
  return state.data ?? false;
}
