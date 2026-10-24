import { useEffect } from "react";
import { api } from "../shared/api/client";
import type { ConversationsResponse } from "../shared/api/types";
import { useResource } from "../shared/hooks/use-resource";
import { realtime } from "../shared/realtime/socket";

// Unread messages for the rail badge: the conversation list, refreshed when a
// message arrives or is read.
export function useUnreadCount(enabled: boolean): number {
  const list = useResource(enabled ? "unread" : "unread-off", async (signal) => (enabled ? api.get<ConversationsResponse>("/api/conversations", signal) : null), 5 * 60_000);
  const { reload } = list;
  useEffect(() => {
    if (!enabled) return undefined;
    const offs = ["chat:message", "chat:read", "match:new"].map((type) => realtime.on(type, () => void reload()));
    return () => { for (const off of offs) off(); };
  }, [enabled, reload]);
  return list.state.data?.conversations.reduce((sum, item) => sum + item.unreadCount, 0) ?? 0;
}
