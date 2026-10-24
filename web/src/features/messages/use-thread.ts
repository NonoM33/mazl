import { useCallback, useEffect, useRef, useState } from "react";
import { api } from "../../shared/api/client";
import { ApiError, describeError } from "../../shared/api/errors";
import type { MessageResponse, MessagesResponse, MessageView, ReactionsResponse } from "../../shared/api/types";
import { realtime } from "../../shared/realtime/socket";
import { useToast } from "../../shared/ui/toast";
import { messageOf, readEventOf, typingEventOf } from "./chat-events";
import {
  applyRead, mergeIncoming, mergePage, optimisticMessage, patchView, replaceItem, toggleReaction, type ThreadMessage,
} from "./thread-model";

// State of one open conversation: pages from the server, messages being sent,
// and everything the socket pushes. No message content ever goes to the console.

const PAGE = 30;
const TYPING_TTL_MS = 6000;
const TYPING_SEND_EVERY_MS = 3000;

export type ThreadStatus = "loading" | "ready" | "not-found" | "error";
export type ReplyTarget = NonNullable<MessageView["reply_to"]>;

export interface Thread {
  readonly status: ThreadStatus;
  readonly items: readonly ThreadMessage[];
  readonly hasMore: boolean;
  readonly loadingOlder: boolean;
  readonly otherTyping: boolean;
  readonly loadOlder: () => Promise<void>;
  readonly send: (content: string, replyTo: ReplyTarget | null) => void;
  readonly retry: (clientId: string) => void;
  readonly sendPhotos: (files: readonly File[], caption: string, replyTo: ReplyTarget | null) => Promise<boolean>;
  readonly react: (view: MessageView, emoji: string) => void;
  readonly unsend: (view: MessageView) => void;
  readonly notifyTyping: () => void;
  readonly reload: () => Promise<void>;
}

const oldestServerId = (items: readonly ThreadMessage[]): number | null => items.find((item) => item.state === "sent")?.view.id ?? null;

export function useThread(conversationId: number, myId: number): Thread {
  const toast = useToast();
  const [status, setStatus] = useState<ThreadStatus>("loading");
  const [items, setItems] = useState<readonly ThreadMessage[]>([]);
  const [hasMore, setHasMore] = useState(false);
  const [loadingOlder, setLoadingOlder] = useState(false);
  const [otherTyping, setOtherTyping] = useState(false);
  const typingTimer = useRef<number | null>(null);
  const lastTypingSent = useRef(0);
  const itemsRef = useRef(items);
  useEffect(() => { itemsRef.current = items; });

  const fetchFirstPage = useCallback(() => api.get<MessagesResponse>(`/api/conversations/${conversationId}/messages?limit=${PAGE}`), [conversationId]);
  const applyFirstPage = useCallback((page: MessagesResponse) => {
    const initial = !itemsRef.current.some((item) => item.state === "sent");
    setItems((current) => mergePage(current, page.messages));
    setHasMore((previous) => (initial ? page.has_more : previous));
    setStatus("ready");
  }, []);
  const failFirstPage = useCallback((error: unknown) => setStatus(error instanceof ApiError && error.isNotFound ? "not-found" : "error"), []);
  const reload = useCallback(() => fetchFirstPage().then(applyFirstPage, failFirstPage), [fetchFirstPage, applyFirstPage, failFirstPage]);

  useEffect(() => {
    let live = true;
    fetchFirstPage().then((page) => { if (live) applyFirstPage(page); }, (error: unknown) => { if (live) failFirstPage(error); });
    return () => { live = false; };
  }, [fetchFirstPage, applyFirstPage, failFirstPage]);

  const loadOlder = useCallback(async () => {
    const before = oldestServerId(itemsRef.current);
    if (before === null || loadingOlder) return;
    setLoadingOlder(true);
    try {
      const page = await api.get<MessagesResponse>(`/api/conversations/${conversationId}/messages?before=${before}&limit=${PAGE}`);
      setItems((current) => mergePage(current, page.messages));
      setHasMore(page.has_more);
    } catch (error) {
      toast.show(describeError(error));
    } finally {
      setLoadingOlder(false);
    }
  }, [conversationId, loadingOlder, toast]);

  const post = useCallback(async (clientId: string, body: Record<string, unknown>) => {
    try {
      const response = await api.post<MessageResponse>(`/api/conversations/${conversationId}/messages`, { client_id: clientId, ...body });
      setItems((current) => mergeIncoming(current, response.message));
      return true;
    } catch (error) {
      setItems((current) => replaceItem(current, clientId, { state: "failed" }));
      if (error instanceof ApiError && error.isRateLimited) toast.show(describeError(error));
      return false;
    }
  }, [conversationId, toast]);

  const send = useCallback((content: string, replyTo: ReplyTarget | null) => {
    const clientId = crypto.randomUUID();
    const local = optimisticMessage({ clientId, conversationId, senderId: myId, content, replyTo });
    setItems((current) => [...current, local]);
    realtime.send({ type: "chat:typing", payload: { conversationId, isTyping: false } });
    void post(clientId, { type: "text", content, ...(replyTo ? { reply_to_id: replyTo.id } : {}) });
  }, [conversationId, myId, post]);

  const retry = useCallback((clientId: string) => {
    const failed = itemsRef.current.find((item) => item.view.client_id === clientId);
    if (!failed) return;
    setItems((current) => replaceItem(current, clientId, { state: "sending" }));
    void post(clientId, { type: "text", content: failed.view.content, ...(failed.view.reply_to ? { reply_to_id: failed.view.reply_to.id } : {}) });
  }, [post]);

  const sendPhotos = useCallback(async (files: readonly File[], caption: string, replyTo: ReplyTarget | null) => {
    try {
      const ids: number[] = [];
      for (const file of files) {
        const form = new FormData();
        form.append("file", file);
        form.append("kind", "photo");
        const uploaded = await api.post<{ media: { id: number } }>(`/api/conversations/${conversationId}/media`, form);
        ids.push(uploaded.media.id);
      }
      const ok = await post(crypto.randomUUID(), { type: "photo", content: caption, media_ids: ids, ...(replyTo ? { reply_to_id: replyTo.id } : {}) });
      if (!ok) toast.show("La photo n'a pas pu être envoyée.");
      return ok;
    } catch (error) {
      toast.show(error instanceof ApiError && error.status === 400 ? "Cette photo n'est pas acceptée (JPEG, PNG ou HEIC, 10 Mo au plus)." : describeError(error));
      return false;
    }
  }, [conversationId, post, toast]);

  const react = useCallback((view: MessageView, emoji: string) => {
    setItems((current) => patchView(current, view.id, { reactions: toggleReaction(view.reactions, emoji, myId) }));
    api.post<ReactionsResponse>(`/api/messages/${view.id}/reactions`, { emoji }).then(
      (response) => setItems((current) => patchView(current, view.id, { reactions: response.reactions })),
      (error: unknown) => {
        setItems((current) => patchView(current, view.id, { reactions: view.reactions }));
        toast.show(describeError(error));
      },
    );
  }, [myId, toast]);

  const unsend = useCallback((view: MessageView) => {
    api.post<Partial<MessageResponse>>(`/api/messages/${view.id}/unsend`).then(
      (response) => setItems((current) => (response.message ? mergeIncoming(current, response.message) : patchView(current, view.id, { unsent: true, content: "", media: [], voice: null, link_preview: null }))),
      (error: unknown) => toast.show(error instanceof ApiError && error.status === 403 ? "Le délai de 15 minutes est dépassé." : describeError(error)),
    );
  }, [toast]);

  const notifyTyping = useCallback(() => {
    const now = Date.now();
    if (now - lastTypingSent.current < TYPING_SEND_EVERY_MS) return;
    lastTypingSent.current = now;
    realtime.send({ type: "chat:typing", payload: { conversationId, isTyping: true } });
  }, [conversationId]);

  useEffect(() => {
    const clearTyping = () => {
      if (typingTimer.current !== null) window.clearTimeout(typingTimer.current);
      typingTimer.current = null;
      setOtherTyping(false);
    };
    const onMessage = (payload: unknown) => {
      const message = messageOf(payload);
      if (message?.conversation_id !== conversationId) return;
      setItems((current) => mergeIncoming(current, message));
      if (message.sender_id !== myId) clearTyping();
    };
    const onRead = (payload: unknown) => {
      const event = readEventOf(payload);
      if (event?.conversationId !== conversationId || event.userId === myId) return;
      setItems((current) => applyRead(current, { upToId: event.upToId, readAt: event.readAt, readerId: event.userId }));
    };
    const onTyping = (payload: unknown) => {
      const event = typingEventOf(payload);
      if (event?.conversationId !== conversationId || event.userId === myId) return;
      if (!event.isTyping) { clearTyping(); return; }
      setOtherTyping(true);
      if (typingTimer.current !== null) window.clearTimeout(typingTimer.current);
      typingTimer.current = window.setTimeout(clearTyping, TYPING_TTL_MS);
    };
    const offs = [
      realtime.on("chat:message", onMessage),
      realtime.on("chat:updated", onMessage),
      realtime.on("chat:read", onRead),
      realtime.on("chat:typing", onTyping),
      // The server replays nothing after a reconnection: fetch what was missed.
      realtime.on("open", () => void reload()),
    ];
    return () => {
      for (const off of offs) off();
      clearTyping();
    };
  }, [conversationId, myId, reload]);

  return { status, items, hasMore, loadingOlder, otherTyping, loadOlder, send, retry, sendPhotos, react, unsend, notifyTyping, reload };
}
