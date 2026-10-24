import http from "node:http";
import https from "node:https";
import type { ClientRequest, IncomingMessage } from "node:http";
import { TransportTimeoutError, type PinnedRequest, type PinnedTransport, type RawResponse } from "../application/fetch-ports";

// One GET to an address the guard already validated. The connection is opened
// to `address` itself; the host name only travels in the Host header and, over
// TLS, as SNI and as the name the certificate must match. node:http never
// follows redirects and never decompresses, which is exactly what the guard
// needs.

const USER_AGENT = "MazlLinkPreview/1.0";

export interface TransportOptions {
  // Test hook: extra TLS options (a private CA for the local TLS server).
  readonly tls?: https.RequestOptions;
}

function headersOf(response: IncomingMessage): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [name, value] of Object.entries(response.headers)) {
    if (value !== undefined) out[name] = Array.isArray(value) ? value.join(", ") : value;
  }
  return out;
}

export function createPinnedHttpTransport(options: TransportOptions = {}): PinnedTransport {
  function get(request: PinnedRequest): Promise<RawResponse> {
    return new Promise<RawResponse>((resolve, reject) => {
      let settled = false;
      let outgoing: ClientRequest | undefined;
      const finish = (action: () => void): void => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        action();
      };
      const timer = setTimeout(() => {
        finish(() => reject(new TransportTimeoutError()));
        outgoing?.destroy();
      }, Math.max(1, request.timeoutMs));

      const common: http.RequestOptions = {
        host: request.address,
        port: request.port,
        method: "GET",
        path: request.path,
        agent: false,
        headers: {
          Host: request.hostHeader,
          Accept: request.accept,
          "Accept-Encoding": "identity",
          "User-Agent": USER_AGENT,
          Connection: "close",
        },
      };
      const sendOptions: https.RequestOptions = request.secure
        ? { ...options.tls, ...common, servername: request.hostname }
        : common;

      outgoing = (request.secure ? https : http).request(sendOptions, (response) => {
        const chunks: Buffer[] = [];
        let received = 0;
        let truncated = false;
        const done = (): void =>
          finish(() =>
            resolve({
              status: response.statusCode ?? 0,
              headers: headersOf(response),
              body: new Uint8Array(Buffer.concat(chunks)),
              truncated,
            }),
          );
        response.on("data", (chunk: Buffer) => {
          const room = request.maxBytes - received;
          if (chunk.length > room) {
            if (room > 0) chunks.push(chunk.subarray(0, room));
            received = request.maxBytes;
            truncated = true;
            done();
            outgoing?.destroy();
            return;
          }
          chunks.push(chunk);
          received += chunk.length;
        });
        response.on("end", done);
        response.on("error", (error) => finish(() => reject(error)));
        response.on("aborted", () => finish(() => reject(new Error("response aborted"))));
      });
      outgoing.on("error", (error) => finish(() => reject(error)));
      outgoing.end();
    });
  }
  return { get };
}
