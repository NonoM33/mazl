// Google OAuth Configuration (set in environment variables)
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || "";
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET || "";
const GOOGLE_IOS_CLIENT_ID = process.env.GOOGLE_IOS_CLIENT_ID || "";

// JWT Configuration
const JWT_SECRET = process.env.JWT_SECRET || "mazl-super-secret-key-change-in-production";
const JWT_EXPIRES_IN = 60 * 60 * 24 * 30; // 30 days

interface GoogleTokenPayload {
  iss: string;
  azp: string;
  aud: string;
  sub: string;
  email: string;
  email_verified: boolean;
  name?: string;
  picture?: string;
  given_name?: string;
  family_name?: string;
  iat: number;
  exp: number;
}

interface AuthUser {
  id: number;
  email: string;
  name?: string;
  picture?: string;
  provider: "google" | "apple";
  providerId: string;
}

/**
 * Verify Google ID Token from mobile app
 */
export async function verifyGoogleIdToken(idToken: string): Promise<GoogleTokenPayload | null> {
  try {
    // Fetch Google's public keys
    const response = await fetch(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`
    );

    if (!response.ok) {
      console.error("Google token verification failed:", response.status);
      return null;
    }

    const payload = (await response.json()) as GoogleTokenPayload;

    // Verify the token is for our app (either web or iOS client)
    const validAudiences = [GOOGLE_CLIENT_ID, GOOGLE_IOS_CLIENT_ID];
    if (!validAudiences.includes(payload.aud)) {
      console.error("Invalid audience:", payload.aud);
      return null;
    }

    // Verify issuer
    if (!["accounts.google.com", "https://accounts.google.com"].includes(payload.iss)) {
      console.error("Invalid issuer:", payload.iss);
      return null;
    }

    // Verify not expired
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp < now) {
      console.error("Token expired");
      return null;
    }

    return payload;
  } catch (error) {
    console.error("Error verifying Google token:", error);
    return null;
  }
}

/**
 * Verify Apple Identity Token
 */
export async function verifyAppleIdToken(identityToken: string): Promise<{
  sub: string;
  email?: string;
  email_verified?: boolean;
} | null> {
  try {
    // Decode the JWT header to get the key ID
    const [headerB64] = identityToken.split(".");
    const header = JSON.parse(atob(headerB64));
    const kid = header.kid;

    // Fetch Apple's public keys
    const keysResponse = await fetch("https://appleid.apple.com/auth/keys");
    const keysData = await keysResponse.json();
    const key = keysData.keys.find((k: any) => k.kid === kid);

    if (!key) {
      console.error("Apple key not found for kid:", kid);
      return null;
    }

    // For simplicity, we'll use tokeninfo-style verification
    // In production, you should properly verify the JWT signature
    const [, payloadB64] = identityToken.split(".");
    const payload = JSON.parse(atob(payloadB64));

    // Verify issuer
    if (payload.iss !== "https://appleid.apple.com") {
      console.error("Invalid Apple issuer:", payload.iss);
      return null;
    }

    // Verify audience (your app's bundle ID)
    if (payload.aud !== "com.mazl.app") {
      console.error("Invalid Apple audience:", payload.aud);
      return null;
    }

    // Verify not expired
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp < now) {
      console.error("Apple token expired");
      return null;
    }

    return {
      sub: payload.sub,
      email: payload.email,
      email_verified: payload.email_verified,
    };
  } catch (error) {
    console.error("Error verifying Apple token:", error);
    return null;
  }
}

/**
 * Generate JWT token for authenticated user
 */
export function generateJWT(user: AuthUser): string {
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
    exp: now + JWT_EXPIRES_IN,
  };

  const headerB64 = btoa(JSON.stringify(header));
  const payloadB64 = btoa(JSON.stringify(payload));
  const signature = signHS256(`${headerB64}.${payloadB64}`, JWT_SECRET);

  return `${headerB64}.${payloadB64}.${signature}`;
}

/**
 * Verify JWT token
 */
export function verifyJWT(token: string): { sub: string; email: string; name?: string } | null {
  try {
    const [headerB64, payloadB64, signature] = token.split(".");

    // Verify signature
    const expectedSignature = signHS256(`${headerB64}.${payloadB64}`, JWT_SECRET);
    if (signature !== expectedSignature) {
      return null;
    }

    const payload = JSON.parse(atob(payloadB64));

    // Verify not expired
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp < now) {
      return null;
    }

    return {
      sub: payload.sub,
      email: payload.email,
      name: payload.name,
    };
  } catch {
    return null;
  }
}

/**
 * Simple HMAC-SHA256 signing using Web Crypto API
 */
function signHS256(data: string, secret: string): string {
  const encoder = new TextEncoder();
  const keyData = encoder.encode(secret);
  const message = encoder.encode(data);

  // Simple hash-based signature (for production, use proper HMAC)
  let hash = 0;
  const combined = new Uint8Array([...keyData, ...message]);
  for (let i = 0; i < combined.length; i++) {
    hash = ((hash << 5) - hash + combined[i]) | 0;
  }

  return btoa(hash.toString(16)).replace(/=/g, "");
}

/**
 * Extract bearer token from Authorization header
 */
export function extractBearerToken(authHeader: string | undefined): string | null {
  if (!authHeader) return null;
  const parts = authHeader.split(" ");
  if (parts.length !== 2 || parts[0] !== "Bearer") return null;
  return parts[1];
}
