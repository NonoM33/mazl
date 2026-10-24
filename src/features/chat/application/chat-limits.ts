import { createSlidingWindow, type SlidingWindow } from "./sliding-window";

// Every per-user ceiling of the chat, in one place. `send` is shared by the
// REST route and the WebSocket `chat:send` frame: using both does not double
// the quota.

const MINUTE_MS = 60_000;

export const SEND_PER_MINUTE = 90;
export const SOCKET_TYPING_PER_MINUTE = 60;
export const SOCKET_READ_PER_MINUTE = 60;
export const REST_ACTIONS_PER_MINUTE = 120;

export interface ChatLimits {
  readonly send: SlidingWindow;
  readonly socketTyping: SlidingWindow;
  readonly socketRead: SlidingWindow;
  readonly history: SlidingWindow;
  readonly reactions: SlidingWindow;
  readonly unsend: SlidingWindow;
  readonly markRead: SlidingWindow;
}

export function createChatLimits(now?: () => number): ChatLimits {
  const window = (max: number): SlidingWindow =>
    createSlidingWindow(now === undefined ? { max, windowMs: MINUTE_MS } : { max, windowMs: MINUTE_MS, now });
  return {
    send: window(SEND_PER_MINUTE),
    socketTyping: window(SOCKET_TYPING_PER_MINUTE),
    socketRead: window(SOCKET_READ_PER_MINUTE),
    history: window(REST_ACTIONS_PER_MINUTE),
    reactions: window(REST_ACTIONS_PER_MINUTE),
    unsend: window(REST_ACTIONS_PER_MINUTE),
    markRead: window(REST_ACTIONS_PER_MINUTE),
  };
}
