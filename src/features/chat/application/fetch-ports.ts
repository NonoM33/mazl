// Ports of the server-side fetch used by link previews. The guard only knows
// these interfaces; the node:dns and node:http(s) adapters live in ../infra.

export interface DnsResolver {
  // Every A and AAAA address of the host. Rejects when the name does not resolve.
  resolveAll(hostname: string): Promise<string[]>;
}

export interface PinnedRequest {
  // The ALREADY VALIDATED address to connect to. The transport never resolves names.
  readonly address: string;
  readonly port: number;
  readonly secure: boolean;
  // Host name for the Host header and, over TLS, for SNI and certificate checks.
  readonly hostname: string;
  readonly hostHeader: string;
  readonly path: string;
  readonly accept: string;
  readonly timeoutMs: number;
  readonly maxBytes: number;
}

export interface RawResponse {
  readonly status: number;
  // Lower-case header names.
  readonly headers: Readonly<Record<string, string>>;
  // At most maxBytes of the body.
  readonly body: Uint8Array;
  // True when the body was longer than maxBytes and reading stopped.
  readonly truncated: boolean;
}

export interface PinnedTransport {
  // One GET, no redirect followed, no decompression. Rejects on any network
  // error or when timeoutMs elapses.
  get(request: PinnedRequest): Promise<RawResponse>;
}

// Thrown by a transport when timeoutMs elapses, so the guard can report it apart
// from other network errors.
export class TransportTimeoutError extends Error {
  constructor() {
    super("transport timed out");
    this.name = "TransportTimeoutError";
  }
}
