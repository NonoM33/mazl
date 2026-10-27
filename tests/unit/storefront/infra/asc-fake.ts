import { readFileSync } from "node:fs";
import { generateKeyPairSync } from "node:crypto";
import { createAppStorePricing } from "../../../../src/features/storefront/infra/app-store-connect";

// A fake App Store Connect that answers ONLY the exact method + path + query it was told about
// and answers 599 to anything else, so a wrong endpoint or parameter fails the test loudly.
export interface Call {
  readonly method: string;
  readonly url: string; // decoded, without the host
  readonly headers: Record<string, string>;
  readonly body: unknown;
}

type Reply = { status: number; body: unknown; headers?: Record<string, string> };

export function fixture(name: string): unknown {
  return JSON.parse(readFileSync(new URL(`./fixtures/${name}.json`, import.meta.url), "utf8"));
}

export class FakeAsc {
  readonly calls: Call[] = [];
  readonly unexpected: string[] = [];
  private readonly routes = new Map<string, Reply[]>();

  on(method: string, url: string, body: unknown, status = 200, headers: Record<string, string> = {}): this {
    const key = `${method} ${url}`;
    const list = this.routes.get(key) ?? [];
    list.push({ status, body, headers });
    this.routes.set(key, list);
    return this;
  }

  private readonly handlers: { method: string; url: string; respond: (call: Call) => Reply }[] = [];

  // A computed reply for an exact method + url (e.g. depends on the request body). Same strictness as `on`.
  handle(method: string, url: string, respond: (call: Call) => Reply): this {
    this.handlers.push({ method, url, respond });
    return this;
  }

  get = (url: string, body: unknown, status = 200, headers: Record<string, string> = {}): this => this.on("GET", url, body, status, headers);

  fetch = async (input: string, init: { method: string; headers: Record<string, string>; body?: string }): Promise<Response> => {
    const url = decodeURIComponent(input.replace("https://api.appstoreconnect.apple.com", ""));
    const call: Call = { method: init.method, url, headers: init.headers, body: init.body === undefined ? undefined : JSON.parse(init.body) };
    this.calls.push(call);
    const key = `${init.method} ${url}`;
    const handler = this.handlers.find((h) => h.method === init.method && h.url === url);
    if (handler !== undefined) {
      const reply = handler.respond(call);
      return new Response(JSON.stringify(reply.body), { status: reply.status, headers: reply.headers ?? {} });
    }
    const replies = this.routes.get(key);
    const reply = replies === undefined ? undefined : replies.length > 1 ? replies.shift() : replies[0];
    if (reply === undefined) {
      this.unexpected.push(key);
      return new Response(JSON.stringify({ errors: [{ status: "599", code: "TEST_UNEXPECTED", detail: key }] }), { status: 599 });
    }
    return new Response(JSON.stringify(reply.body), { status: reply.status, headers: reply.headers ?? {} });
  };

  writes(): Call[] {
    return this.calls.filter((c) => c.method !== "GET");
  }
}

export function testKeyPem(): string {
  const { privateKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
  return privateKey.export({ type: "pkcs8", format: "pem" }).toString();
}

export const NOW = Date.parse("2026-11-01T10:00:00Z");

export function pricingWith(fake: FakeAsc, extra: { numberOfCodes?: number } = {}) {
  const api = createAppStorePricing(
    { ASC_KEY_ID: "TESTKEY123", ASC_ISSUER_ID: "00000000-0000-0000-0000-000000000000", ASC_PRIVATE_KEY: testKeyEscaped() },
    { fetch: fake.fetch, clock: () => NOW, ...extra },
  );
  if (api === null) throw new Error("test configuration is incomplete");
  return api;
}

let cachedPem: string | undefined;
export function testKeyEscaped(): string {
  cachedPem ??= testKeyPem();
  return cachedPem.replace(/\n/g, "\\n");
}

export const SUB = "6826538779";
export const GROUP = "22508803";
export const APP = "6758543555";
export const SUB_LOOKUP = `/v1/subscriptionGroups/${GROUP}/subscriptions?filter[productId]=com.mazl.app.plus.3m&limit=200`;
