import { request } from "../../shared/api/client";
import type { SwipeAction, SwipeResponse } from "../../shared/api/types";

// `keepalive` lets a pass still leave when the page is closing.
export function postSwipe(targetUserId: number, action: SwipeAction, keepalive = false): Promise<SwipeResponse> {
  return request<SwipeResponse>("/api/swipes", { method: "POST", body: { target_user_id: targetUserId, action }, keepalive });
}
