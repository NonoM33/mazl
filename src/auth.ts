import { createHmac, timingSafeEqual, createPublicKey, verify as cryptoVerify } from "node:crypto";
import { createGoogleVerifier, type GoogleIdentity } from "./features/auth/google-token";

// Google OAuth Configuration (set in environment variables)
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || "";
const GOOGLE_IOS_CLIENT_ID = process.env.GOOGLE_IOS_CLIENT_ID || "";

// JWT Configuration
// Fail-fast: no secret must ever fall back to a hardcoded default.
function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value || value.length === 0) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

const JWT_SECRET = requireEnv("JWT_SECRET");
const JWT_EXPIRES_IN = 60 * 60 * 24 * 30; // 30 days

interface AuthUser {
  id: number;
  email: string;
  name?: string;
  picture?: string;
  provider: "google" | "apple";
  providerId: string;
}

// Members sign in from the iOS app or the web client.
const googleMembers = createGoogleVerifier({ audiences: [GOOGLE_CLIENT_ID, GOOGLE_IOS_CLIENT_ID] });

/**
 * Verify a Google ID token from the mobile app: issued to one of our clients,
 * not expired, with an email Google has verified.
 */
export function verifyGoogleIdToken(idToken: string): Promise<GoogleIdentity | null> {
  return googleMembers.verifyIdToken(idToken);
}

// The iOS app's bundle id. The web client signs in with its own Services ID.
const APPLE_APP_AUDIENCE = "com.mazl.app";

interface AppleKey {
  kid: string;
  kty: string;
  use: string;
  alg: string;
  n: string;
  e: string;
}

interface AppleKeysResponse {
  keys: AppleKey[];
}

/**
 * Verify Apple Identity Token
 */
export async function verifyAppleIdToken(identityToken: string, audience: string = APPLE_APP_AUDIENCE): Promise<{
  sub: string;
  email?: string;
  email_verified?: boolean;
} | null> {
  try {
    const parts = identityToken.split(".");
    if (parts.length !== 3) {
      return null;
    }
    const [headerB64, payloadB64, signatureB64] = parts;
    if (!headerB64 || !payloadB64 || !signatureB64) {
      return null;
    }

    // Decode the JWT header to get the key ID and algorithm.
    const header = decodeJwtSegment(headerB64);
    if (!header) {
      return null;
    }
    const kid = header.kid;
    const alg = header.alg;
    if (typeof kid !== "string" || alg !== "RS256") {
      console.error("Unsupported or missing Apple token header:", { alg, kid });
      return null;
    }

    // Fetch Apple's public keys and locate the matching one.
    const keysResponse = await fetch("https://appleid.apple.com/auth/keys");
    if (!keysResponse.ok) {
      console.error("Apple keys unavailable:", keysResponse.status);
      return null;
    }
    const keysData = (await keysResponse.json()) as AppleKeysResponse;
    const key = Array.isArray(keysData.keys) ? keysData.keys.find((k) => k.kid === kid) : undefined;

    if (!key) {
      console.error("Apple key not found for kid:", kid);
      return null;
    }

    // Verify the RS256 signature over `header.payload` with Apple's public key.
    if (!verifyAppleSignature(key, `${headerB64}.${payloadB64}`, signatureB64)) {
      console.error("Apple token signature verification failed");
      return null;
    }

    // Signature is valid: now decode and validate the claims.
    const payload = decodeJwtSegment(payloadB64);
    if (!payload) {
      return null;
    }

    // Verify issuer
    if (payload.iss !== "https://appleid.apple.com") {
      console.error("Invalid Apple issuer:", payload.iss);
      return null;
    }

    // Verify audience (your app's bundle ID)
    if (payload.aud !== audience) {
      console.error("Invalid Apple audience:", payload.aud);
      return null;
    }

    // Verify not expired
    const now = Math.floor(Date.now() / 1000);
    if (typeof payload.exp !== "number" || payload.exp < now) {
      console.error("Apple token expired");
      return null;
    }

    if (typeof payload.sub !== "string") {
      return null;
    }

    return {
      sub: payload.sub,
      email: typeof payload.email === "string" ? payload.email : undefined,
      email_verified:
        typeof payload.email_verified === "boolean"
          ? payload.email_verified
          : payload.email_verified === "true"
            ? true
            : undefined,
    };
  } catch (error) {
    console.error("Error verifying Apple token:", error);
    return null;
  }
}

/**
 * Verify the RS256 signature of an Apple identity token.
 * The public key is imported from the JWK (RSA modulus/exponent).
 * The JWT signature is base64url-encoded.
 */
function verifyAppleSignature(jwk: AppleKey, signingInput: string, signatureB64: string): boolean {
  try {
    const publicKey = createPublicKey({
      key: { kty: jwk.kty, n: jwk.n, e: jwk.e },
      format: "jwk",
    });
    const signature = Buffer.from(signatureB64, "base64url");
    return cryptoVerify(
      "RSA-SHA256",
      Buffer.from(signingInput, "utf8"),
      publicKey,
      signature
    );
  } catch (error) {
    console.error("Error verifying Apple signature:", error);
    return false;
  }
}

/**
 * Generate JWT token for authenticated user
 */
// Optional claims of tokens that are not the app's: `aud` names what the token
// is for (the web bridge's is "web-bridge"), `sid` the web session behind it.
export interface TokenClaims {
  readonly aud?: string;
  readonly sid?: string;
}

export function generateJWT(user: AuthUser, ttlSeconds: number = JWT_EXPIRES_IN, claims: TokenClaims = {}): string {
  const header = {
    alg: "HS256",
    typ: "JWT",
  };

  const now = Math.floor(Date.now() / 1000);
  const payload = {
    sub: user.id.toString(),
    email: user.email,
    name: user.name,
    provider: user.provider,
    iat: now,
    exp: now + ttlSeconds,
    ...claims,
  };

  const headerB64 = Buffer.from(JSON.stringify(header)).toString("base64url");
  const payloadB64 = Buffer.from(JSON.stringify(payload)).toString("base64url");
  const signature = signHS256(`${headerB64}.${payloadB64}`, JWT_SECRET);

  return `${headerB64}.${payloadB64}.${signature}`;
}

/**
 * Verify JWT token
 */
export function verifyJWT(token: string): { sub: string; email: string; name?: string; exp: number; aud?: string; sid?: string } | null {
  try {
    const [headerB64, payloadB64, signature, extra] = token.split(".");
    if (!headerB64 || !payloadB64 || !signature || extra !== undefined) {
      return null;
    }

    // Verify signature (constant-time)
    const expectedSignature = signHS256(`${headerB64}.${payloadB64}`, JWT_SECRET);
    if (!signaturesMatch(signature, expectedSignature)) {
      return null;
    }

    const payload = decodeJwtSegment(payloadB64);
    if (!payload) {
      return null;
    }

    // Verify not expired
    const now = Math.floor(Date.now() / 1000);
    if (typeof payload.exp !== "number" || payload.exp < now) {
      return null;
    }

    if (typeof payload.sub !== "string" || !/^[1-9]\d{0,9}$/.test(payload.sub) || typeof payload.email !== "string") {
      return null;
    }

    return {
      sub: payload.sub,
      email: payload.email,
      name: typeof payload.name === "string" ? payload.name : undefined,
      exp: payload.exp,
      aud: typeof payload.aud === "string" ? payload.aud : undefined,
      sid: typeof payload.sid === "string" ? payload.sid : undefined,
    };
  } catch {
    return null;
  }
}

type JwtClaims = Record<string, unknown>;

/**
 * Decode a base64/base64url JWT segment into a plain claims object.
 * Returns null if the segment is not valid JSON object.
 */
function decodeJwtSegment(segment: string): JwtClaims | null {
  try {
    // Node's base64 decoder reads both alphabets, with or without padding:
    // tokens issued before the switch to base64url stay readable.
    const parsed: unknown = JSON.parse(Buffer.from(segment, "base64").toString("utf8"));
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
      return null;
    }
    return parsed as JwtClaims;
  } catch {
    return null;
  }
}

/**
 * HMAC-SHA256 signing (base64url, no padding), consistent with the admin JWT.
 */
function signHS256(data: string, secret: string): string {
  return createHmac("sha256", secret).update(data).digest("base64url");
}

/**
 * Constant-time comparison of two signatures.
 * Different lengths are treated as a mismatch without throwing.
 */
function signaturesMatch(a: string, b: string): boolean {
  const bufferA = Buffer.from(a, "utf8");
  const bufferB = Buffer.from(b, "utf8");
  if (bufferA.length !== bufferB.length) {
    return false;
  }
  return timingSafeEqual(bufferA, bufferB);
}

/**
 * Extract bearer token from Authorization header
 */
export function extractBearerToken(authHeader: string | undefined): string | null {
  if (!authHeader) return null;
  const parts = authHeader.split(" ");
  const [scheme, value] = parts;
  if (parts.length !== 2 || scheme !== "Bearer" || !value) return null;
  return value;
}
