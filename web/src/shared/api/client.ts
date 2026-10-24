import { ApiError, NetworkError } from "./errors";

// Every call goes to the same origin with the web session cookie. The
// X-Mazl-Web header is what lets the server read that cookie (CSRF guard,
// docs/web/adr/W02-sessions-web.md); the page never holds a token.

type Json = null | boolean | number | string | readonly Json[] | { readonly [key: string]: Json | undefined };
type Body = Json | FormData | undefined;

export interface RequestOptions {
  readonly method?: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
  readonly body?: Body;
  readonly signal?: AbortSignal;
  readonly keepalive?: boolean;
  readonly headers?: Readonly<Record<string, string>>;
}

type UnauthorizedListener = () => void;
const unauthorizedListeners = new Set<UnauthorizedListener>();

export function onUnauthorized(listener: UnauthorizedListener): () => void {
  unauthorizedListeners.add(listener);
  return () => unauthorizedListeners.delete(listener);
}

function buildInit(options: RequestOptions): RequestInit {
  const headers: Record<string, string> = { "X-Mazl-Web": "1", Accept: "application/json", ...options.headers };
  const { body } = options;
  let payload: BodyInit | undefined;
  if (body instanceof FormData) payload = body;
  else if (body !== undefined) {
    headers["Content-Type"] = "application/json";
    payload = JSON.stringify(body);
  }
  return {
    method: options.method ?? (body === undefined ? "GET" : "POST"),
    headers,
    body: payload,
    credentials: "same-origin",
    cache: "no-store",
    signal: options.signal,
    keepalive: options.keepalive,
  };
}

async function readJson(response: Response): Promise<Record<string, unknown>> {
  const text = await response.text();
  if (text.length === 0) return {};
  try {
    const parsed: unknown = JSON.parse(text);
    return typeof parsed === "object" && parsed !== null && !Array.isArray(parsed) ? (parsed as Record<string, unknown>) : {};
  } catch {
    return {};
  }
}

function toApiError(response: Response, body: Record<string, unknown>): ApiError {
  const code = typeof body.error === "string" ? body.error : `http_${response.status}`;
  const header = Number.parseInt(response.headers.get("Retry-After") ?? "", 10);
  const fromBody = typeof body.retry_after === "number" ? body.retry_after : null;
  return new ApiError(response.status, code, Number.isFinite(header) ? header : fromBody, body);
}

export async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  let response: Response;
  try {
    response = await fetch(path, buildInit(options));
  } catch (cause) {
    if (cause instanceof DOMException && cause.name === "AbortError") throw cause;
    throw new NetworkError("network", { cause });
  }
  const body = await readJson(response);
  if (!response.ok || body.success === false) {
    const error = toApiError(response, body);
    if (error.isUnauthorized) for (const listener of unauthorizedListeners) listener();
    throw error;
  }
  return body as T;
}

export const api = {
  get: <T,>(path: string, signal?: AbortSignal) => request<T>(path, { signal }),
  post: <T,>(path: string, body?: Body) => request<T>(path, { method: "POST", body: body ?? {} }),
  put: <T,>(path: string, body?: Body) => request<T>(path, { method: "PUT", body: body ?? {} }),
  patch: <T,>(path: string, body?: Body) => request<T>(path, { method: "PATCH", body: body ?? {} }),
  delete: <T,>(path: string, body?: Body) => request<T>(path, { method: "DELETE", body }),
};
