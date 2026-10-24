import { api } from "../../shared/api/client";
import type { DiscoverResponse, ProfileCard } from "../../shared/api/types";

// One lot of the feed (limit 20); the server answers 429 past 300 requests an hour.
export async function loadDiscoverLot(signal: AbortSignal): Promise<readonly ProfileCard[]> {
  return (await api.get<DiscoverResponse>("/api/discover?limit=20", signal)).profiles;
}
