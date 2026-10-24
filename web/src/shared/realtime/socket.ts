import { api } from "../api/client";
import type { SocketTicket } from "../api/types";

// One WebSocket per tab to /ws, opened with a 10-minute ticket of the web
// session (docs/web/adr/W02-sessions-web.md). The server closes it when the
// ticket expires (4001) or the session is revoked (4003): on 4001 we take a new
// ticket, on 4003 we stop. Frames are never logged (docs/chat/CONTRAT.md §0.3).

export interface SocketFrame { readonly type: string; readonly payload?: unknown }
type Listener = (payload: unknown) => void;

const PING_MS = 30_000;
const MAX_BACKOFF_MS = 60_000;

export class RealtimeClient {
  private socket: WebSocket | null = null;
  private readonly listeners = new Map<string, Set<Listener>>();
  private attempts = 0;
  private stopped = true;
  private ping: number | null = null;
  private retry: number | null = null;

  start(): void {
    if (!this.stopped) return;
    this.stopped = false;
    void this.connect();
  }

  stop(): void {
    this.stopped = true;
    if (this.retry !== null) window.clearTimeout(this.retry);
    this.clearPing();
    this.socket?.close(1000, "bye");
    this.socket = null;
  }

  on(type: string, listener: Listener): () => void {
    const set = this.listeners.get(type) ?? new Set<Listener>();
    set.add(listener);
    this.listeners.set(type, set);
    return () => set.delete(listener);
  }

  send(frame: SocketFrame): boolean {
    if (this.socket?.readyState !== WebSocket.OPEN) return false;
    this.socket.send(JSON.stringify(frame));
    return true;
  }

  private async connect(): Promise<void> {
    if (this.stopped) return;
    try {
      const { token } = await api.post<SocketTicket>("/api/web/socket-ticket");
      const scheme = window.location.protocol === "https:" ? "wss" : "ws";
      const socket = new WebSocket(`${scheme}://${window.location.host}/ws?token=${encodeURIComponent(token)}`);
      this.socket = socket;
      socket.onopen = () => this.opened();
      socket.onmessage = (event) => this.dispatch(event.data);
      socket.onclose = (event) => this.closed(event.code);
    } catch {
      this.scheduleReconnect();
    }
  }

  private opened(): void {
    this.attempts = 0;
    this.clearPing();
    this.ping = window.setInterval(() => this.send({ type: "ping" }), PING_MS);
    this.emit("open", null);
  }

  private closed(code: number): void {
    this.clearPing();
    this.socket = null;
    this.emit("close", code);
    if (code === 4003) this.stopped = true;
    else this.scheduleReconnect(code === 4001 ? 0 : undefined);
  }

  private scheduleReconnect(delay?: number): void {
    if (this.stopped) return;
    const backoff = delay ?? Math.min(MAX_BACKOFF_MS, 2000 * 2 ** this.attempts) + Math.random() * 1000;
    this.attempts += 1;
    this.retry = window.setTimeout(() => void this.connect(), backoff);
  }

  private dispatch(raw: unknown): void {
    if (typeof raw !== "string") return;
    try {
      const frame = JSON.parse(raw) as SocketFrame;
      if (typeof frame.type === "string") this.emit(frame.type, frame.payload);
    } catch {
      // Not JSON: ignored, and deliberately not logged.
    }
  }

  private emit(type: string, payload: unknown): void {
    for (const listener of this.listeners.get(type) ?? []) listener(payload);
  }

  private clearPing(): void {
    if (this.ping !== null) window.clearInterval(this.ping);
    this.ping = null;
  }
}

export const realtime = new RealtimeClient();
