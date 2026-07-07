import type { Context } from "hono";
import { createHmac } from "node:crypto";

// ADMIN-specific authentication helpers, moved verbatim (behaviour-preserving)
// from the monolith (src/index.ts). Admin routes authenticate with a dedicated
// admin JWT (HMAC-SHA256) plus an email whitelist — NOT the user `requireAuth`
// middleware. The admin secret fails fast at boot rather than silently falling
// back to a hard-coded value, and credentials/tokens are accepted from the
// request HEADER only (query-string tokens leak into logs, history and Referer
// headers). The single exception is `assertAdminFileDownload`, used only by the
// read-only file-download endpoint, which additionally accepts a signed admin
// JWT via the `token` query param because an <a href> navigation cannot set an
// Authorization header. No password is ever accepted via query string.

export function getAdminPassword(c: Context): string {
  // Only accept the admin password via header, never via query string
  // (query strings leak into logs, browser history and Referer headers).
  return c.req.header("x-admin-password") || "";
}

// Admin JWT secret (use a different secret than user JWT).
// Fail fast at boot rather than silently falling back to a hard-coded secret.
const ADMIN_JWT_SECRET: string = (() => {
  const secret = process.env.ADMIN_JWT_SECRET || process.env.JWT_SECRET;
  if (!secret) {
    throw new Error(
      "ADMIN_JWT_SECRET (or JWT_SECRET) must be set; refusing to start with a hard-coded admin secret",
    );
  }
  return secret;
})();

// Admin whitelist for Google login
export const ADMIN_EMAILS: string[] = [
  "renaudlemagicien@gmail.com",
  process.env.ADMIN_EMAIL,
].filter((email): email is string => Boolean(email));

// Generate admin JWT token
export function generateAdminJWT(email: string): string {
  const header = { alg: "HS256", typ: "JWT" };
  const payload = {
    email,
    role: "admin",
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 86400 * 7, // 7 days
  };

  const base64Header = btoa(JSON.stringify(header)).replace(/=/g, "");
  const base64Payload = btoa(JSON.stringify(payload)).replace(/=/g, "");
  const data = `${base64Header}.${base64Payload}`;

  // HMAC-SHA256 signature
  const hmac = createHmac("sha256", ADMIN_JWT_SECRET);
  hmac.update(data);
  const signature = hmac.digest("base64url");

  return `${data}.${signature}`;
}

type AdminJwtVerification = { valid: boolean; email?: string; error?: string };

// Verify admin JWT token
export function verifyAdminJWT(token: string): AdminJwtVerification {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return { valid: false, error: "Invalid token format" };

    const [header, payload, signature] = parts;
    if (!header || !payload || !signature) return { valid: false, error: "Invalid token format" };
    const data = `${header}.${payload}`;

    // Verify signature
    const hmac = createHmac("sha256", ADMIN_JWT_SECRET);
    hmac.update(data);
    const expectedSig = hmac.digest("base64url");

    if (signature !== expectedSig) return { valid: false, error: "Invalid signature" };

    // Decode payload
    const decodedPayload = JSON.parse(atob(payload)) as { email?: string; role?: string; exp?: number };

    // Check expiration
    if (decodedPayload.exp && decodedPayload.exp < Math.floor(Date.now() / 1000)) {
      return { valid: false, error: "Token expired" };
    }

    // Check role
    if (decodedPayload.role !== "admin") {
      return { valid: false, error: "Not an admin token" };
    }

    return { valid: true, email: decodedPayload.email };
  } catch {
    return { valid: false, error: "Token verification failed" };
  }
}

export type AdminAuthResult = { ok: true; email?: string } | { ok: false; error: string };

export function assertAdmin(c: Context): AdminAuthResult {
  // Admin JWT token from the Authorization header only (no query-string tokens:
  // they leak into logs, history and Referer headers).
  const authHeader = c.req.header("Authorization") || "";
  if (authHeader.startsWith("Bearer ")) {
    const token = authHeader.substring(7);
    const result = verifyAdminJWT(token);
    if (result.valid) {
      return { ok: true, email: result.email };
    }
  }

  // Fallback to password method via header only (for backward compatibility).
  const required = process.env.ADMIN_PASSWORD;
  if (!required) return { ok: false, error: "ADMIN_PASSWORD not set" };
  if (getAdminPassword(c) !== required) return { ok: false, error: "Unauthorized" };
  return { ok: true };
}

// Admin auth for browser file downloads only. An <a href> navigation cannot set
// an Authorization header, so this single read-only endpoint additionally accepts
// a signed admin JWT via the `token` query param. No password is ever accepted here.
export function assertAdminFileDownload(c: Context): AdminAuthResult {
  const headerResult = assertAdmin(c);
  if (headerResult.ok) return headerResult;

  const tokenParam = c.req.query("token");
  if (tokenParam) {
    const result = verifyAdminJWT(tokenParam);
    if (result.valid) {
      return { ok: true, email: result.email };
    }
  }

  return { ok: false, error: "Unauthorized" };
}
