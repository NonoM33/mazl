import { describe, expect, test } from "bun:test";
import { createGuardedFetcher } from "../../src/features/chat/application/guarded-fetch";
import type { DnsResolver, PinnedRequest, PinnedTransport, RawResponse } from "../../src/features/chat/application/fetch-ports";

// SSRF guard, CONTRAT.md §0.5. The fakes below record what the guard asks of
// the network, so each test states what must (or must never) reach it.

function resolverOf(table: Record<string, string[]>): DnsResolver & { calls: string[] } {
  const calls: string[] = [];
  return {
    calls,
    async resolveAll(hostname) {
      calls.push(hostname);
      const found = table[hostname];
      if (!found) throw new Error("ENOTFOUND");
      return found;
    },
  };
}

function html(extra: Partial<RawResponse> = {}): RawResponse {
  return {
    status: 200,
    headers: { "content-type": "text/html; charset=utf-8" },
    body: new TextEncoder().encode("<html><head><title>Hi</title></head></html>"),
    truncated: false,
    ...extra,
  };
}

function transportReturning(response: RawResponse): PinnedTransport & { requests: PinnedRequest[] } {
  const requests: PinnedRequest[] = [];
  return {
    requests,
    async get(request) {
      requests.push(request);
      return response;
    },
  };
}

const PAGE = { kind: "html", maxBytes: 512 * 1024, timeoutMs: 5000 } as const;

describe("what reaches the network", () => {
  test("a public host: connects to the VALIDATED address, keeps the name for Host/SNI", async () => {
    const transport = transportReturning(html());
    const guard = createGuardedFetcher({ resolver: resolverOf({ "example.com": ["93.184.216.34"] }), transport });
    const result = await guard.fetch("https://example.com/page?q=1", PAGE);
    expect(result.ok).toBe(true);
    expect(transport.requests).toHaveLength(1);
    const request = transport.requests[0]!;
    expect(request.address).toBe("93.184.216.34");
    expect(request.hostname).toBe("example.com");
    expect(request.hostHeader).toBe("example.com");
    expect([request.secure, request.port, request.path]).toEqual([true, 443, "/page?q=1"]);
    expect(request.maxBytes).toBe(512 * 1024);
    expect(request.timeoutMs).toBeLessThanOrEqual(5000);
  });

  test("DNS rebinding: a public-looking name resolving to loopback is refused, nothing connects", async () => {
    const transport = transportReturning(html());
    const guard = createGuardedFetcher({ resolver: resolverOf({ "totally-public.example": ["127.0.0.1"] }), transport });
    expect(await guard.fetch("http://totally-public.example/", PAGE)).toEqual({ ok: false, reason: "blocked_address" });
    expect(transport.requests).toHaveLength(0);
  });

  test("a mixed answer (one public, one private address) is refused as a whole", async () => {
    const transport = transportReturning(html());
    const resolver = resolverOf({ "mixed.example": ["93.184.216.34", "10.0.0.5"] });
    const guard = createGuardedFetcher({ resolver, transport });
    expect(await guard.fetch("http://mixed.example/", PAGE)).toEqual({ ok: false, reason: "blocked_address" });
    expect(transport.requests).toHaveLength(0);
  });

  const hostile: Array<[string, string[]]> = [
    ["metadata.example", ["169.254.169.254"]],
    ["v6-loop.example", ["::1"]],
    ["mapped.example", ["::ffff:127.0.0.1"]],
    ["ula.example", ["fd00::1"]],
    ["linklocal.example", ["fe80::1"]],
    ["cgnat.example", ["100.64.0.1"]],
    ["multicast.example", ["224.0.0.251"]],
    ["zero.example", ["0.0.0.0"]],
    ["garbage.example", ["not-an-ip"]],
  ];
  for (const [host, addresses] of hostile) {
    test(`${host} -> ${addresses.join(",")} is refused`, async () => {
      const transport = transportReturning(html());
      const guard = createGuardedFetcher({ resolver: resolverOf({ [host]: addresses }), transport });
      expect(await guard.fetch(`https://${host}/`, PAGE)).toEqual({ ok: false, reason: "blocked_address" });
      expect(transport.requests).toHaveLength(0);
    });
  }

  const literals = [
    "http://127.0.0.1/", "http://[::1]/", "http://2130706433/", "http://0x7f.1/", "http://127.1/",
    "http://169.254.169.254/latest/meta-data", "http://10.0.0.1/", "http://192.168.1.1/", "http://172.16.0.1/",
    "http://[::ffff:127.0.0.1]/", "http://[::ffff:a00:1]/", "http://[fe80::1]/", "http://[fd00::1]/",
    "http://100.64.0.1/", "http://0.0.0.0/", "http://224.0.0.1/", "http://[ff02::1]/",
  ];
  for (const url of literals) {
    test(`IP literal ${url} is refused without any DNS or connection`, async () => {
      const transport = transportReturning(html());
      const resolver = resolverOf({});
      const guard = createGuardedFetcher({ resolver, transport });
      expect(await guard.fetch(url, PAGE)).toEqual({ ok: false, reason: "blocked_address" });
      expect(resolver.calls).toHaveLength(0);
      expect(transport.requests).toHaveLength(0);
    });
  }

  test("a public IP literal is allowed and not resolved", async () => {
    const transport = transportReturning(html());
    const resolver = resolverOf({});
    const guard = createGuardedFetcher({ resolver, transport });
    expect((await guard.fetch("http://93.184.216.34/", PAGE)).ok).toBe(true);
    expect(resolver.calls).toHaveLength(0);
    expect(transport.requests[0]?.address).toBe("93.184.216.34");
  });

  test("bad port, scheme and credentials never reach DNS", async () => {
    const transport = transportReturning(html());
    const resolver = resolverOf({ "example.com": ["93.184.216.34"] });
    const guard = createGuardedFetcher({ resolver, transport });
    expect(await guard.fetch("http://example.com:8080/", PAGE)).toEqual({ ok: false, reason: "bad_port" });
    expect(await guard.fetch("ftp://example.com/", PAGE)).toEqual({ ok: false, reason: "bad_scheme" });
    expect(await guard.fetch("http://a:b@example.com/", PAGE)).toEqual({ ok: false, reason: "credentials" });
    expect(resolver.calls).toHaveLength(0);
    expect(transport.requests).toHaveLength(0);
  });

  test("a name that does not resolve is a dns failure", async () => {
    const guard = createGuardedFetcher({ resolver: resolverOf({}), transport: transportReturning(html()) });
    expect(await guard.fetch("http://nope.example/", PAGE)).toEqual({ ok: false, reason: "dns_failed" });
  });

  test("a resolver that never answers is cut at the deadline", async () => {
    const hanging: DnsResolver = { resolveAll: () => new Promise<string[]>(() => undefined) };
    const guard = createGuardedFetcher({ resolver: hanging, transport: transportReturning(html()) });
    const started = Date.now();
    expect(await guard.fetch("http://slow.example/", { ...PAGE, timeoutMs: 80 })).toEqual({ ok: false, reason: "timeout" });
    expect(Date.now() - started).toBeLessThan(1000);
  });

  test("falls over to the next validated address when connecting fails, never to an unvalidated one", async () => {
    const requests: string[] = [];
    const transport: PinnedTransport = {
      async get(request) {
        requests.push(request.address);
        if (request.address === "93.184.216.34") throw new Error("ECONNREFUSED");
        return html();
      },
    };
    const guard = createGuardedFetcher({ resolver: resolverOf({ "two.example": ["93.184.216.34", "8.8.8.8"] }), transport });
    expect((await guard.fetch("http://two.example/", PAGE)).ok).toBe(true);
    expect(requests).toEqual(["93.184.216.34", "8.8.8.8"]);
  });
});

describe("what comes back", () => {
  const resolver = () => resolverOf({ "example.com": ["93.184.216.34"] });

  for (const status of [301, 302, 303, 307, 308]) {
    test(`a ${status} redirect is not followed (one request only)`, async () => {
      const transport = transportReturning({ status, headers: { location: "http://169.254.169.254/" }, body: new Uint8Array(), truncated: false });
      const guard = createGuardedFetcher({ resolver: resolver(), transport });
      expect(await guard.fetch("http://example.com/", PAGE)).toEqual({ ok: false, reason: "redirect" });
      expect(transport.requests).toHaveLength(1);
    });
  }

  test("non-200 statuses are refused", async () => {
    for (const status of [204, 400, 403, 404, 500]) {
      const guard = createGuardedFetcher({ resolver: resolver(), transport: transportReturning(html({ status })) });
      expect(await guard.fetch("http://example.com/", PAGE)).toEqual({ ok: false, reason: "status" });
    }
  });

  test("only text/html is accepted for a page", async () => {
    for (const type of ["application/json", "text/plain", "image/png", "application/xhtml+xml", "application/octet-stream", ""]) {
      const guard = createGuardedFetcher({ resolver: resolver(), transport: transportReturning(html({ headers: { "content-type": type } })) });
      expect(await guard.fetch("http://example.com/", PAGE)).toEqual({ ok: false, reason: "content_type" });
    }
    const guard = createGuardedFetcher({ resolver: resolver(), transport: transportReturning(html({ headers: {} })) });
    expect(await guard.fetch("http://example.com/", PAGE)).toEqual({ ok: false, reason: "content_type" });
  });

  test("TEXT/HTML with parameters in any case is accepted", async () => {
    const guard = createGuardedFetcher({ resolver: resolver(), transport: transportReturning(html({ headers: { "content-type": "TEXT/HTML; Charset=ISO-8859-1" } })) });
    expect((await guard.fetch("http://example.com/", PAGE)).ok).toBe(true);
  });

  test("a compressed body is refused (we ask for identity and cannot bound a decompression)", async () => {
    const guard = createGuardedFetcher({ resolver: resolver(), transport: transportReturning(html({ headers: { "content-type": "text/html", "content-encoding": "gzip" } })) });
    expect(await guard.fetch("http://example.com/", PAGE)).toEqual({ ok: false, reason: "content_encoding" });
  });

  test("a page longer than the cap is kept up to the cap (the head is enough)", async () => {
    const guard = createGuardedFetcher({ resolver: resolver(), transport: transportReturning(html({ truncated: true })) });
    const result = await guard.fetch("http://example.com/", PAGE);
    expect(result.ok && result.truncated).toBe(true);
  });

  test("an image longer than the cap is refused, not cut", async () => {
    const png = html({ headers: { "content-type": "image/png" }, truncated: true });
    const guard = createGuardedFetcher({ resolver: resolver(), transport: transportReturning(png) });
    expect(await guard.fetch("http://example.com/i.png", { kind: "image", maxBytes: 100, timeoutMs: 5000 })).toEqual({ ok: false, reason: "too_large" });
  });

  test("images: raster types only; SVG is refused", async () => {
    for (const [type, accepted] of [["image/jpeg", true], ["image/png", true], ["image/webp", true], ["image/gif", true], ["image/svg+xml", false], ["text/html", false]] as const) {
      const guard = createGuardedFetcher({ resolver: resolver(), transport: transportReturning(html({ headers: { "content-type": type } })) });
      const result = await guard.fetch("http://example.com/i", { kind: "image", maxBytes: 1000, timeoutMs: 5000 });
      expect(result.ok).toBe(accepted);
    }
  });

  test("a transport failure (reset, timeout) is reported, not thrown", async () => {
    const transport: PinnedTransport = { get: async () => { throw new Error("ECONNRESET"); } };
    const guard = createGuardedFetcher({ resolver: resolver(), transport });
    expect(await guard.fetch("http://example.com/", PAGE)).toEqual({ ok: false, reason: "network" });
  });
});
