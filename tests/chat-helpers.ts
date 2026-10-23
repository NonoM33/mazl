import { createHash, createHmac } from "node:crypto";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { BASE_URL, auth, db, json, makeUser, type TestUser } from "./media-helpers";

export { BASE_URL, auth, db, json, makeUser, type TestUser };

// Shared helpers of the chat integration tests (docs/chat/CONTRAT.md). They need
// a running server (TEST_API_URL) and direct access to its database
// (TEST_DATABASE_URL) to backdate rows and to inspect what the API hides.

export const WS_URL = process.env.TEST_WS_URL ?? `${BASE_URL.replace(/^http/, "ws")}/ws`;
export const VOICE_FIXTURE = new Uint8Array(readFileSync(join(import.meta.dir, "fixtures/chat/voice.m4a")));
export const WAVEFORM = JSON.stringify(Array.from({ length: 48 }, (_, i) => (i * 2) % 101));

export interface Pair {
  readonly a: TestUser;
  readonly b: TestUser;
  readonly conversationId: number;
}

export async function makeMatch(label: string): Promise<Pair> {
  const a = await makeUser(`${label}a`);
  const b = await makeUser(`${label}b`);
  const swipe = (user: TestUser, target: number) =>
    fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: json(user.token), body: JSON.stringify({ target_user_id: target, action: "like" }) });
  await swipe(a, b.id);
  await swipe(b, a.id);
  const listed = (await (await fetch(`${BASE_URL}/api/conversations`, { headers: auth(a.token) })).json()) as { conversations: Array<{ id: number }> };
  const conversationId = listed.conversations[0]?.id;
  if (conversationId === undefined) throw new Error("makeMatch: no conversation was created");
  return { a, b, conversationId };
}

export interface ApiMessage {
  id: number;
  conversation_id: number;
  sender_id: number;
  client_id: string | null;
  type: "text" | "photo" | "voice";
  content: string;
  media: Array<{ id: number; kind: string; url: string; width: number; height: number }>;
  voice: { id: number; url: string; duration_ms: number; waveform: number[] } | null;
  reply_to: { id: number; sender_id: number; type: string; preview: string } | null;
  reactions: Array<{ emoji: string; user_ids: number[] }>;
  link_preview: { url: string; title: string | null; description: string | null; image_url: string | null; site_name: string | null } | null;
  created_at: string;
  read_at: string | null;
  unsent: boolean;
}

export async function send(token: string, conversationId: number, body: Record<string, unknown>): Promise<{ status: number; body: { success: boolean; message?: ApiMessage; error?: string } }> {
  const res = await fetch(`${BASE_URL}/api/conversations/${conversationId}/messages`, { method: "POST", headers: json(token), body: JSON.stringify(body) });
  return { status: res.status, body: (await res.json()) as { success: boolean; message?: ApiMessage; error?: string } };
}

export async function sendText(token: string, conversationId: number, content: string, extra: Record<string, unknown> = {}): Promise<ApiMessage> {
  const { status, body } = await send(token, conversationId, { content, ...extra });
  if (status !== 200 || !body.message) throw new Error(`sendText failed ${status}: ${JSON.stringify(body)}`);
  return body.message;
}

export async function upload(token: string, conversationId: number, fields: { kind: string; file?: Uint8Array; durationMs?: number; waveform?: string; name?: string; mime?: string }): Promise<Response> {
  const form = new FormData();
  if (fields.file) form.append("file", new File([fields.file], fields.name ?? "upload.bin", { type: fields.mime ?? "application/octet-stream" }));
  form.append("kind", fields.kind);
  if (fields.durationMs !== undefined) form.append("duration_ms", String(fields.durationMs));
  if (fields.waveform !== undefined) form.append("waveform", fields.waveform);
  return fetch(`${BASE_URL}/api/conversations/${conversationId}/media`, { method: "POST", headers: auth(token), body: form });
}

export interface ApiMedia { id: number; kind: "photo" | "voice"; url: string; width?: number; height?: number; duration_ms?: number; waveform?: number[] }

export async function uploadOk(token: string, conversationId: number, fields: Parameters<typeof upload>[2]): Promise<ApiMedia> {
  const res = await upload(token, conversationId, fields);
  const body = (await res.json()) as { success: boolean; media?: ApiMedia };
  if (res.status !== 200 || !body.media) throw new Error(`upload failed ${res.status}: ${JSON.stringify(body)}`);
  return body.media;
}

export const absolute = (url: string): string => (url.startsWith("http") ? url : `${BASE_URL}${url}`);

// Independent of the server code: HMAC-SHA256(MEDIA_SIGNING_KEY, "chat:<id>:<exp>") in base64url.
// Without MEDIA_SIGNING_KEY the server derives its development key from
// SHA-256("mazl-development-only:MEDIA_SIGNING_KEY").
export function craftChatUrl(mediaId: number, exp: number, prefix = "chat"): string {
  const configured = process.env.MEDIA_SIGNING_KEY;
  const key = configured ? Buffer.from(configured, "base64") : createHash("sha256").update("mazl-development-only:MEDIA_SIGNING_KEY").digest();
  const sig = createHmac("sha256", key).update(`${prefix}:${mediaId}:${exp}`).digest("base64url");
  return `${BASE_URL}/media/chat/${mediaId}?exp=${exp}&sig=${sig}`;
}

export interface Socket {
  readonly events: Array<{ type: string; payload: Record<string, unknown> }>;
  next(type: string, timeoutMs?: number): Promise<{ type: string; payload: Record<string, unknown> }>;
  send(frame: unknown): void;
  close(): void;
}

export async function connect(token: string): Promise<Socket> {
  const ws = new WebSocket(`${WS_URL}?token=${token}`);
  const events: Socket["events"] = [];
  const waiters: Array<{ type: string; resolve: (e: Socket["events"][number]) => void }> = [];
  ws.onmessage = (frame) => {
    try {
      const event = JSON.parse(String(frame.data)) as Socket["events"][number];
      if (event.type === "pong") return;
      const waiter = waiters.findIndex((w) => w.type === event.type);
      if (waiter >= 0) waiters.splice(waiter, 1)[0]!.resolve(event);
      else events.push(event);
    } catch { /* not JSON */ }
  };
  await new Promise<void>((resolve, reject) => { ws.onopen = () => resolve(); ws.onerror = () => reject(new Error("ws error")); });
  await new Promise((r) => setTimeout(r, 100));
  return {
    events,
    send: (frame) => ws.send(JSON.stringify(frame)),
    close: () => ws.close(),
    next(type, timeoutMs = 4000) {
      const queued = events.findIndex((e) => e.type === type);
      if (queued >= 0) return Promise.resolve(events.splice(queued, 1)[0]!);
      return new Promise((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error(`no ${type} within ${timeoutMs} ms`)), timeoutMs);
        waiters.push({ type, resolve: (e) => { clearTimeout(timer); resolve(e); } });
      });
    },
  };
}

// Waits for a quiet period during which `type` must NOT arrive.
export async function expectNone(socket: Socket, type: string, ms = 600): Promise<boolean> {
  await new Promise((r) => setTimeout(r, ms));
  return !socket.events.some((e) => e.type === type);
}
