// App Store Connect API token: ES256 JWT, aud appstoreconnect-v1, lifetime capped at 20 minutes.
// https://developer.apple.com/documentation/appstoreconnectapi/generating-tokens-for-api-requests

export interface JwtSettings {
  readonly keyId: string;
  readonly issuerId: string;
  readonly privateKeyPem: string;
}

const LIFETIME_SECONDS = 15 * 60; // Apple refuses anything above 20 minutes.
const RENEW_MARGIN_SECONDS = 60;

const base64Url = (input: string | Uint8Array): string => Buffer.from(input).toString("base64url");

function pkcs8Der(pem: string): Uint8Array<ArrayBuffer> {
  const body = pem.replace(/-----[A-Z ]+-----/g, "").replace(/\s+/g, "");
  const bytes = Buffer.from(body, "base64");
  const der = new Uint8Array(new ArrayBuffer(bytes.length));
  der.set(bytes);
  return der;
}

export async function signAscToken(settings: JwtSettings, nowSeconds: number): Promise<{ readonly token: string; readonly expiresAt: number }> {
  const key = await crypto.subtle.importKey("pkcs8", pkcs8Der(settings.privateKeyPem), { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  const expiresAt = nowSeconds + LIFETIME_SECONDS;
  const header = base64Url(JSON.stringify({ alg: "ES256", kid: settings.keyId, typ: "JWT" }));
  const claims = base64Url(JSON.stringify({ iss: settings.issuerId, iat: nowSeconds, exp: expiresAt, aud: "appstoreconnect-v1" }));
  const signingInput = `${header}.${claims}`;
  // WebCrypto returns the raw r||s form that JWS ES256 expects (no DER).
  const signature = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(signingInput));
  return { token: `${signingInput}.${base64Url(new Uint8Array(signature))}`, expiresAt };
}

export class AscTokenProvider {
  private cached: { readonly token: string; readonly expiresAt: number } | undefined;

  constructor(
    private readonly settings: JwtSettings,
    private readonly clock: () => number = () => Date.now(),
  ) {}

  async token(): Promise<string> {
    const now = Math.floor(this.clock() / 1000);
    if (this.cached !== undefined && this.cached.expiresAt - RENEW_MARGIN_SECONDS > now) return this.cached.token;
    this.cached = await signAscToken(this.settings, now);
    return this.cached.token;
  }
}
