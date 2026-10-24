import { useCallback, useEffect, useRef, useState } from "react";
import { MessageCircle } from "lucide-react";
import { api } from "../../shared/api/client";
import type { ConversationsResponse } from "../../shared/api/types";
import { useHotkeys } from "../../shared/hooks/use-hotkeys";
import { useResource } from "../../shared/hooks/use-resource";
import { displayName } from "../../shared/lib/format";
import { realtime } from "../../shared/realtime/socket";
import { useRouter } from "../../shared/router";
import { EmptyState } from "../../shared/ui/empty-state";
import { ConversationList } from "./conversation-list";
import { ProfileColumn } from "./profile-column";
import { ThreadColumn } from "./thread-column";
import "./messages.css";

// Messages: list, thread and profile side by side (docs/design/CHAT.md).

const REFRESH_EVENTS = ["chat:message", "chat:read", "match:new", "open"] as const;

export function MessagesScreen({ conversationId }: { readonly conversationId: number | null }) {
  const { navigate } = useRouter();
  const list = useResource("conversations", (signal) => api.get<ConversationsResponse>("/api/conversations", signal));
  const [query, setQuery] = useState("");
  const searchRef = useRef<HTMLInputElement>(null);
  const { reload, mutate } = list;
  const conversations = list.state.data?.conversations;
  const current = conversations?.find((item) => item.id === conversationId);

  useEffect(() => {
    const offs = REFRESH_EVENTS.map((type) => realtime.on(type, () => void reload()));
    return () => { for (const off of offs) off(); };
  }, [reload]);

  // A thread that marked its messages read clears its badge right away.
  const onRead = useCallback(() => {
    if (conversationId === null) return;
    mutate((data) => ({ ...data, conversations: data.conversations.map((item) => (item.id === conversationId ? { ...item, unreadCount: 0 } : item)) }));
    void reload();
  }, [conversationId, mutate, reload]);

  const onBlocked = useCallback(() => {
    navigate("/messages");
    void reload();
  }, [navigate, reload]);

  useHotkeys({
    "mod+k": () => { searchRef.current?.focus(); searchRef.current?.select(); },
    escape: () => {
      const search = searchRef.current;
      if (!search || (document.activeElement !== search && query.length === 0)) return;
      setQuery("");
      search.blur();
    },
  });

  return (
    <div className="cols cols-messages">
      <ConversationList conversations={conversations} failed={list.state.status === "error"} selectedId={conversationId} query={query} searchRef={searchRef}
        onQuery={setQuery} onSelect={(id) => navigate(`/messages/${id}`)} onExpired={() => void reload()} />
      {conversationId === null ? (
        <section className="thread-col"><EmptyState title="Vos messages" icon={<MessageCircle size={40} aria-hidden="true" />}>Choisissez une conversation dans la liste pour la lire et y répondre.</EmptyState></section>
      ) : (
        <ThreadColumn key={conversationId} conversation={current} conversationId={conversationId} onRead={onRead} onBlocked={onBlocked} />
      )}
      {current ? <ProfileColumn key={current.otherUser.user_id} userId={current.otherUser.user_id} fallbackName={displayName(current.otherUser.display_name)} onBlocked={onBlocked} /> : <aside className="profile-col" aria-hidden="true" />}
    </div>
  );
}
