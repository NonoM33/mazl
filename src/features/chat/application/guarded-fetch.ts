import { parseFetchTarget, type TargetRefusal } from "../domain/fetch-target";
import { isIpLiteral, isPublicAddress } from "../domain/ip-address";
import {
  TransportTimeoutError,
  type DnsResolver,
  type PinnedTransport,
  type RawResponse,
} from "./fetch-ports";

// The only way the server fetches a URL chosen by a member (CONTRAT.md §0.5).
//
//   1. the URL is parsed and restricted (scheme, port, credentials);
//   2. the host name is resolved HERE and EVERY returned address must be public;
//   3. the connection goes to one of those validated addresses, never to the
//      name, so a second DNS answer (rebinding) cannot change the destination;
//   4. no redirect is followed, only 200 with the right content type is kept,
//      the body is read up to a cap, and the whole exchange has a deadline.

export type FetchKind = "html" | "image";

export interface FetchOptions {
  readonly kind: FetchKind;
  readonly maxBytes: number;
  readonly timeoutMs: number;
}

export type FetchRefusal =
  | TargetRefusal
  | "blocked_address"
  | "dns_failed"
  | "redirect"
  | "status"
  | "content_type"
  | "content_encoding"
  | "too_large"
  | "timeout"
  | "network";

export type FetchOutcome =
  | { readonly ok: true; readonly body: Uint8Array; readonly contentType: string; readonly truncated: boolean }
  | { readonly ok: false; readonly reason: FetchRefusal };

export interface GuardedFetcher {
  fetch(rawUrl: string, options: FetchOptions): Promise<FetchOutcome>;
}

export interface GuardedFetcherDeps {
  readonly resolver: DnsResolver;
  readonly transport: PinnedTransport;
  readonly now?: () => number;
}

const HTML_ACCEPT = "text/html";
const IMAGE_ACCEPT = "image/jpeg,image/png,image/webp,image/gif";
const IMAGE_TYPES = new Set(["image/jpeg", "image/png", "image/webp", "image/gif"]);

function mediaType(headers: Readonly<Record<string, string>>): string {
  return (headers["content-type"] ?? "").split(";")[0]?.trim().toLowerCase() ?? "";
}

function acceptable(kind: FetchKind, type: string): boolean {
  return kind === "html" ? type === "text/html" : IMAGE_TYPES.has(type);
}

function judge(response: RawResponse, options: FetchOptions): FetchOutcome {
  if (response.status >= 300 && response.status < 400) return { ok: false, reason: "redirect" };
  if (response.status !== 200) return { ok: false, reason: "status" };
  const type = mediaType(response.headers);
  if (!acceptable(options.kind, type)) return { ok: false, reason: "content_type" };
  const encoding = (response.headers["content-encoding"] ?? "identity").trim().toLowerCase();
  if (encoding !== "identity" && encoding !== "") return { ok: false, reason: "content_encoding" };
  // A page keeps its head (that is where the tags are); a cut image is useless.
  if (options.kind === "image" && response.truncated) return { ok: false, reason: "too_large" };
  return { ok: true, body: response.body, contentType: type, truncated: response.truncated };
}

class DeadlineError extends Error {}

function withDeadline<T>(work: Promise<T>, remainingMs: number): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  const deadline = new Promise<never>((_resolve, reject) => {
    timer = setTimeout(() => reject(new DeadlineError()), Math.max(1, remainingMs));
  });
  return Promise.race([work, deadline]).finally(() => clearTimeout(timer));
}

export function createGuardedFetcher(deps: GuardedFetcherDeps): GuardedFetcher {
  const now = deps.now ?? Date.now;

  async function addressesOf(hostname: string, remainingMs: number): Promise<string[] | FetchRefusal> {
    if (isIpLiteral(hostname)) return [hostname];
    try {
      return await withDeadline(deps.resolver.resolveAll(hostname), remainingMs);
    } catch (error: unknown) {
      return error instanceof DeadlineError ? "timeout" : "dns_failed";
    }
  }

  async function fetchOne(rawUrl: string, options: FetchOptions): Promise<FetchOutcome> {
    const deadline = now() + options.timeoutMs;
    const parsed = parseFetchTarget(rawUrl);
    if (!parsed.ok) return parsed;
    const { target } = parsed;

    const resolved = await addressesOf(target.hostname, options.timeoutMs);
    if (typeof resolved === "string") return { ok: false, reason: resolved };
    if (resolved.length === 0) return { ok: false, reason: "dns_failed" };
    // One bad address spoils the whole answer: the choice must not depend on luck.
    if (!resolved.every(isPublicAddress)) return { ok: false, reason: "blocked_address" };

    let failure: FetchRefusal = "network";
    for (const address of resolved) {
      const remaining = deadline - now();
      if (remaining <= 0) return { ok: false, reason: "timeout" };
      try {
        const response = await deps.transport.get({
          address,
          port: target.port,
          secure: target.secure,
          hostname: target.hostname,
          hostHeader: target.hostHeader,
          path: target.path,
          accept: options.kind === "html" ? HTML_ACCEPT : IMAGE_ACCEPT,
          timeoutMs: remaining,
          maxBytes: options.maxBytes,
        });
        return judge(response, options);
      } catch (error: unknown) {
        failure = error instanceof TransportTimeoutError ? "timeout" : "network";
        if (failure === "timeout") return { ok: false, reason: failure };
      }
    }
    return { ok: false, reason: failure };
  }

  return { fetch: fetchOne };
}
