import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { gzipSync } from "node:zlib";
import { createPinnedHttpTransport } from "../../src/features/chat/infra/pinned-http-transport";
import { TransportTimeoutError, type PinnedRequest } from "../../src/features/chat/application/fetch-ports";

// The transport is the last line of the SSRF defence: it must connect to the
// address it is given (not to the host name), and bound size and time. These
// tests talk to LOCAL servers on purpose: the guard (tested elsewhere) is what
// refuses loopback, the transport is below it.

let plain: ReturnType<typeof Bun.serve>;
let secure: ReturnType<typeof Bun.serve>;
let certPem = "";
let workdir = "";
const seenHosts: string[] = [];

function certificateFor(name: string): { key: string; cert: string } {
  workdir = mkdtempSync(join(tmpdir(), "mazl-tls-"));
  const keyPath = join(workdir, "key.pem");
  const certPath = join(workdir, "cert.pem");
  execFileSync("openssl", [
    "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-keyout", keyPath, "-out", certPath,
    "-days", "2", "-subj", `/CN=${name}`, "-addext", `subjectAltName=DNS:${name}`,
  ], { stdio: "ignore" });
  return { key: readFileSync(keyPath, "utf8"), cert: readFileSync(certPath, "utf8") };
}

beforeAll(() => {
  const handler = async (req: Request): Promise<Response> => {
    const path = new URL(req.url).pathname;
    seenHosts.push(req.headers.get("host") ?? "");
    if (path === "/ok") return new Response("<html>hello</html>", { headers: { "content-type": "text/html" } });
    if (path === "/redirect") return new Response(null, { status: 302, headers: { location: "http://169.254.169.254/" } });
    if (path === "/big") return new Response(new Uint8Array(100_000).fill(65), { headers: { "content-type": "text/html" } });
    if (path === "/gzip") return new Response(gzipSync("<html>zipped</html>"), { headers: { "content-type": "text/html", "content-encoding": "gzip" } });
    if (path === "/drip") {
      const stream = new ReadableStream<Uint8Array>({
        async start(controller) {
          for (let i = 0; i < 50; i++) {
            controller.enqueue(new TextEncoder().encode("x"));
            await Bun.sleep(40);
          }
          controller.close();
        },
      });
      return new Response(stream, { headers: { "content-type": "text/html" } });
    }
    if (path === "/hang") { await Bun.sleep(1500); return new Response("late"); }
    return new Response("no", { status: 404 });
  };
  plain = Bun.serve({ port: 0, hostname: "127.0.0.1", fetch: handler });
  const pair = certificateFor("pinned.example");
  certPem = pair.cert;
  secure = Bun.serve({ port: 0, hostname: "127.0.0.1", fetch: handler, tls: { key: pair.key, cert: pair.cert } });
});

afterAll(() => {
  plain.stop(true);
  secure.stop(true);
  if (workdir) rmSync(workdir, { recursive: true, force: true });
});

function request(path: string, overrides: Partial<PinnedRequest> = {}): PinnedRequest {
  return {
    address: "127.0.0.1", port: plain.port as number, secure: false, hostname: "preview.example",
    hostHeader: "preview.example", path, accept: "text/html", timeoutMs: 2000, maxBytes: 1024, ...overrides,
  };
}

describe("plain HTTP", () => {
  const transport = createPinnedHttpTransport();

  test("connects to the given address while the Host header carries the name", async () => {
    seenHosts.length = 0;
    const response = await transport.get(request("/ok"));
    expect(response.status).toBe(200);
    expect(response.headers["content-type"]).toBe("text/html");
    expect(new TextDecoder().decode(response.body)).toBe("<html>hello</html>");
    expect(response.truncated).toBe(false);
    expect(seenHosts).toEqual(["preview.example"]);
  });

  test("a redirect is returned as is, never followed", async () => {
    const before = seenHosts.length;
    const response = await transport.get(request("/redirect"));
    expect(response.status).toBe(302);
    expect(response.headers.location).toBe("http://169.254.169.254/");
    expect(seenHosts.length - before).toBe(1);
  });

  test("the body is cut at maxBytes and flagged truncated", async () => {
    const response = await transport.get(request("/big", { maxBytes: 4096 }));
    expect(response.body.byteLength).toBe(4096);
    expect(response.truncated).toBe(true);
  });

  test("a compressed body is handed back raw with its encoding header (the guard refuses it)", async () => {
    const response = await transport.get(request("/gzip", { maxBytes: 10_000 }));
    expect(response.headers["content-encoding"]).toBe("gzip");
    expect(new TextDecoder().decode(response.body)).not.toContain("zipped");
  });

  test("a server that never answers is cut at the deadline", async () => {
    const started = Date.now();
    await expect(transport.get(request("/hang", { timeoutMs: 150 }))).rejects.toBeInstanceOf(TransportTimeoutError);
    expect(Date.now() - started).toBeLessThan(1000);
  });

  test("a body dripped slowly cannot outlive the deadline", async () => {
    const started = Date.now();
    await expect(transport.get(request("/drip", { timeoutMs: 200, maxBytes: 1_000_000 }))).rejects.toBeInstanceOf(TransportTimeoutError);
    expect(Date.now() - started).toBeLessThan(1000);
  });

  test("a closed port is a plain network error", async () => {
    await expect(transport.get(request("/ok", { port: 1 }))).rejects.toThrow();
  });
});

describe("HTTPS", () => {
  const transport = createPinnedHttpTransport({ tls: { ca: undefined } });

  function secureRequest(hostname: string, path = "/ok"): PinnedRequest {
    return request(path, { secure: true, port: secure.port as number, hostname, hostHeader: hostname });
  }

  test("the certificate is checked against the NAME, while the socket goes to the pinned IP", async () => {
    const trusting = createPinnedHttpTransport({ tls: { ca: certPem } });
    const response = await trusting.get(secureRequest("pinned.example"));
    expect(response.status).toBe(200);
  });

  test("a certificate for another name is refused", async () => {
    const trusting = createPinnedHttpTransport({ tls: { ca: certPem } });
    await expect(trusting.get(secureRequest("other.example"))).rejects.toThrow();
  });

  test("an untrusted certificate is refused (verification is on by default)", async () => {
    await expect(transport.get(secureRequest("pinned.example"))).rejects.toThrow();
  });
});
