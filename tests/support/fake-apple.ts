import { generateKeyPairSync, sign, type KeyObject } from "node:crypto";

// A fake of the three Apple endpoints Sign in with Apple uses, answering the
// REAL paths with the shapes documented by Apple:
//   POST /auth/token   (grant_type=authorization_code, form-encoded)
//   POST /auth/revoke  (token + token_type_hint, form-encoded)
//   GET  /auth/keys    (the JWKS that signs identity tokens)
// It records what it receives so a test can check what the server sent. The
// keys here are throwaway: nothing is an Apple key.

export interface AppleRequest {
  readonly method: string;
  readonly path: string;
  readonly form: Readonly<Record<string, string>>;
}

export interface FakeAppleOptions {
  // Refresh token handed out for each authorization code (default: "r-" + code).
  readonly refreshTokenFor?: (code: string) => string;
}

export class FakeApple {
  readonly requests: AppleRequest[] = [];
  // Next answers of /auth/token and /auth/revoke, in place of the normal one.
  tokenAnswer: { status: number; body: unknown } | null = null;
  revokeAnswer: { status: number; body: unknown } | null = null;
  // Delay before answering, to test the timeout.
  delayMs = 0;

  readonly identityKeyId = "fake-id-key";
  private readonly identityPair = generateKeyPairSync("rsa", { modulusLength: 2048 });
  private server: ReturnType<typeof Bun.serve> | null = null;

  constructor(private readonly options: FakeAppleOptions = {}) {}

  get url(): string {
    if (this.server === null) throw new Error("fake Apple is not started");
    return `http://127.0.0.1:${this.server.port}`;
  }

  start(): this {
    this.server = Bun.serve({ port: 0, hostname: "127.0.0.1", fetch: (request) => this.handle(request) });
    return this;
  }

  async stop(): Promise<void> {
    await this.server?.stop(true);
    this.server = null;
  }

  requestsTo(path: string): AppleRequest[] {
    return this.requests.filter((request) => request.path === path);
  }

  // An identity token the way Apple signs it (RS256, kid of the published key).
  identityToken(claims: { sub: string; email?: string; aud?: string; exp?: number }): string {
    const header = { alg: "RS256", kid: this.identityKeyId, typ: "JWT" };
    const payload = {
      iss: "https://appleid.apple.com",
      aud: claims.aud ?? "com.mazl.app",
      exp: claims.exp ?? Math.floor(Date.now() / 1000) + 600,
      iat: Math.floor(Date.now() / 1000),
      sub: claims.sub,
      ...(claims.email === undefined ? {} : { email: claims.email, email_verified: "true" }),
    };
    const input = `${segment(header)}.${segment(payload)}`;
    return `${input}.${sign("RSA-SHA256", Buffer.from(input), this.identityPair.privateKey).toString("base64url")}`;
  }

  private async handle(request: Request): Promise<Response> {
    const path = new URL(request.url).pathname;
    const form = request.method === "POST" ? Object.fromEntries(new URLSearchParams(await request.text())) : {};
    this.requests.push({ method: request.method, path, form });
    if (this.delayMs > 0) await Bun.sleep(this.delayMs);

    if (path === "/auth/keys" && request.method === "GET") {
      const jwk = this.identityPair.publicKey.export({ format: "jwk" });
      return Response.json({ keys: [{ kid: this.identityKeyId, kty: "RSA", use: "sig", alg: "RS256", n: jwk.n, e: jwk.e }] });
    }
    if (path === "/auth/token" && request.method === "POST") {
      if (this.tokenAnswer !== null) return Response.json(this.tokenAnswer.body, { status: this.tokenAnswer.status });
      const code = form.code ?? "";
      const refresh = this.options.refreshTokenFor?.(code) ?? `r-${code}`;
      return Response.json({
        access_token: `a-${code}`,
        token_type: "Bearer",
        expires_in: 3600,
        refresh_token: refresh,
        id_token: "unused",
      });
    }
    if (path === "/auth/revoke" && request.method === "POST") {
      if (this.revokeAnswer !== null) return Response.json(this.revokeAnswer.body, { status: this.revokeAnswer.status });
      return new Response("", { status: 200 });
    }
    return new Response("not found", { status: 404 });
  }
}

const segment = (value: unknown): string => Buffer.from(JSON.stringify(value)).toString("base64url");

export interface TestSigningKey {
  readonly pem: string;
  readonly publicKey: KeyObject;
}

// A throwaway P-256 key shaped like an Apple .p8 (PKCS#8 PEM).
export function testSigningKey(): TestSigningKey {
  const pair = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
  return { pem: pair.privateKey.export({ type: "pkcs8", format: "pem" }).toString(), publicKey: pair.publicKey };
}

// The three variables the server reads, pointing at a fake Apple.
export function appleEnv(key: TestSigningKey, apiBase?: string): Record<string, string> {
  return {
    APPLE_TEAM_ID: "TEAM123456",
    APPLE_SIGNIN_KEY_ID: "KEY1234567",
    APPLE_SIGNIN_PRIVATE_KEY: key.pem,
    ...(apiBase === undefined ? {} : { APPLE_API_BASE: apiBase }),
  };
}

// Verifies an ES256 JWT with WebCrypto, written from RFC 7515/7518 (the
// signature is the raw r||s, 64 bytes), independently of the code that made it.
export async function verifyEs256(jwt: string, publicKey: KeyObject): Promise<{ header: Record<string, unknown>; payload: Record<string, unknown> }> {
  const [h, p, s] = jwt.split(".");
  if (h === undefined || p === undefined || s === undefined) throw new Error("not a JWS compact serialization");
  const signature = Buffer.from(s, "base64url");
  if (signature.length !== 64) throw new Error(`ES256 signature must be 64 bytes, got ${signature.length}`);
  const key = await crypto.subtle.importKey("jwk", publicKey.export({ format: "jwk" }), { name: "ECDSA", namedCurve: "P-256" }, false, ["verify"]);
  const valid = await crypto.subtle.verify({ name: "ECDSA", hash: "SHA-256" }, key, signature, Buffer.from(`${h}.${p}`));
  if (!valid) throw new Error("signature does not verify");
  return {
    header: JSON.parse(Buffer.from(h, "base64url").toString("utf8")) as Record<string, unknown>,
    payload: JSON.parse(Buffer.from(p, "base64url").toString("utf8")) as Record<string, unknown>,
  };
}
