import { useEffect, useRef, useState } from "react";
import { api } from "../../shared/api/client";

// Tells the server the thread was read up to the newest received message, once
// per message, only while the page is visible (docs/chat/CONTRAT.md §2).
export function useReadMarker(conversationId: number, newestReceivedId: number | null, onMarked: () => void): void {
  const marked = useRef<{ conversation: number; id: number } | null>(null);
  const [visible, setVisible] = useState(() => document.visibilityState === "visible");

  useEffect(() => {
    const update = () => setVisible(document.visibilityState === "visible");
    document.addEventListener("visibilitychange", update);
    return () => document.removeEventListener("visibilitychange", update);
  }, []);

  useEffect(() => {
    if (!visible || newestReceivedId === null) return;
    const done = marked.current;
    if (done?.conversation === conversationId && done.id >= newestReceivedId) return;
    marked.current = { conversation: conversationId, id: newestReceivedId };
    api.put(`/api/conversations/${conversationId}/read`, { up_to_id: newestReceivedId }).then(onMarked, () => {
      // Not marked: the next message or visit tries again.
      marked.current = null;
    });
  }, [visible, conversationId, newestReceivedId, onMarked]);
}
