// Google identity checks. Both kinds of token go to Google's tokeninfo
// endpoint, which validates the signature (ID token) or the grant (access
// token). This module then refuses anything that was not issued to one of our
// own client ids, has expired, or carries an email Google has not verified.

export interface GoogleIdentity {
  readonly sub: string;
  readonly email: string;
  readonly name?: string;
  readonly picture?: string;
}

export type TokenInfoFetch = (url: string) => Promise<Response>;

export interface GoogleVerifierOptions {
  readonly audiences: readonly string[];
  readonly fetch?: TokenInfoFetch;
  readonly now?: () => number;
}

export interface GoogleVerifier {
  verifyIdToken(idToken: string): Promise<GoogleIdentity | null>;
  verifyAccessToken(accessToken: string): Promise<GoogleIdentity | null>;
}

const TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo";
const GOOGLE_ISSUERS = ["accounts.google.com", "https://accounts.google.com"];
const MAX_TOKEN_LENGTH = 8192;

type Claims = Record<string, unknown>;

function isClaims(value: unknown): value is Claims {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function optionalString(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

export function createGoogleVerifier(options: GoogleVerifierOptions): GoogleVerifier {
  const audiences = options.audiences.filter((audience) => audience.length > 0);
  const get = options.fetch ?? ((url: string) => fetch(url));
  const now = options.now ?? (() => Math.floor(Date.now() / 1000));

  async function tokenInfo(kind: "id_token" | "access_token", token: string): Promise<Claims | null> {
    if (audiences.length === 0 || token.length === 0 || token.length > MAX_TOKEN_LENGTH) return null;
    try {
      const response = await get(`${TOKENINFO_URL}?${kind}=${encodeURIComponent(token)}`);
      if (!response.ok) return null;
      const body: unknown = await response.json();
      return isClaims(body) ? body : null;
    } catch (error) {
      console.error("Google tokeninfo unavailable:", error instanceof Error ? error.message : "unknown error");
      return null;
    }
  }

  function identityOf(claims: Claims): GoogleIdentity | null {
    if (typeof claims.aud !== "string" || !audiences.includes(claims.aud)) return null;
    if (claims.email_verified !== true && claims.email_verified !== "true") return null;
    const expiresAt = typeof claims.exp === "string" && claims.exp.length > 0 ? Number(claims.exp) : claims.exp;
    if (typeof expiresAt !== "number" || !Number.isFinite(expiresAt) || expiresAt <= now()) return null;
    const sub = optionalString(claims.sub);
    const email = optionalString(claims.email);
    if (!sub || !email) return null;
    return { sub, email, name: optionalString(claims.name), picture: optionalString(claims.picture) };
  }

  return {
    async verifyIdToken(idToken) {
      const claims = await tokenInfo("id_token", idToken);
      if (!claims || typeof claims.iss !== "string" || !GOOGLE_ISSUERS.includes(claims.iss)) return null;
      return identityOf(claims);
    },
    async verifyAccessToken(accessToken) {
      const claims = await tokenInfo("access_token", accessToken);
      return claims ? identityOf(claims) : null;
    },
  };
}
