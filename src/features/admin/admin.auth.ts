import type { Context } from "hono";
import { createHash, createHmac, timingSafeEqual } from "node:crypto";
import { clientIp } from "../../shared/http/client-ip";
import { createAttemptGuard } from "../../shared/http/rate-limit";

// ADMIN authentication. Admin routes use a dedicated admin JWT (HMAC-SHA256)
// plus an email whitelist, NOT the member `requireAuth` middleware.
// - The admin secret is ADMIN_JWT_SECRET, or a key derived from JWT_SECRET for
//   the admin purpose only: a member token can never verify as an admin one.
// - Tokens carry `aud: "mazl-admin"` and `ver: 2`. Tokens issued before the
//   2026-10-24 fix (when the Google sign-in trusted a bare email) have neither
//   and are refused, whatever secret signed them.
// - The whitelist is checked again on every request, so removing an address
//   from the environment revokes its tokens.
// - Credentials are read from HEADERS only (query strings leak into logs,
//   history and Referer). The one exception is `assertAdminFileDownload`.
// - Wrong passwords lock the client address out (5 failures / 15 min), right
//   password included, so guessing cannot continue in the background.

const ADMIN_AUDIENCE = "mazl-admin";
const ADMIN_TOKEN_VERSION = 2;
const ADMIN_TOKEN_TTL_SECONDS = 7 * 86400;

const ADMIN_JWT_SECRET: string = (() => {
  const dedicated = process.env.ADMIN_JWT_SECRET;
  if (dedicated) return dedicated;
  const memberSecret = process.env.JWT_SECRET;
  if (!memberSecret) {
    throw new Error("ADMIN_JWT_SECRET (or JWT_SECRET) must be set; refusing to start with a hard-coded admin secret");
  }
  return createHmac("sha256", memberSecret).update("mazl:admin-jwt").digest("hex");
})();

export const normalizeEmail = (email: string): string => email.trim().toLowerCase();

export const ADMIN_EMAILS: readonly string[] = ["renaudlemagicien@gmail.com", process.env.ADMIN_EMAIL]
  .filter((email): email is string => Boolean(email))
  .map(normalizeEmail);

export const isAdminEmail = (email: string): boolean => ADMIN_EMAILS.includes(normalizeEmail(email));

// Compares secrets in constant time, whatever their lengths.
export function secretsMatch(given: string, expected: string): boolean {
  const a = createHash("sha256").update(given).digest();
  const b = createHash("sha256").update(expected).digest();
  return timingSafeEqual(a, b) && given.length === expected.length;
}

export const adminPasswordAttempts = createAttemptGuard({ maxFailures: 5, windowMs: 15 * 60_000 });

const encodeSegment = (value: unknown): string => Buffer.from(JSON.stringify(value)).toString("base64url");
const signSegments = (data: string): string => createHmac("sha256", ADMIN_JWT_SECRET).update(data).digest("base64url");

export function generateAdminJWT(email: string): string {
  const now = Math.floor(Date.now() / 1000);
  const data = `${encodeSegment({ alg: "HS256", typ: "JWT" })}.${encodeSegment({
    email: normalizeEmail(email),
    role: "admin",
    aud: ADMIN_AUDIENCE,
    ver: ADMIN_TOKEN_VERSION,
    iat: now,
    exp: now + ADMIN_TOKEN_TTL_SECONDS,
  })}`;
  return `${data}.${signSegments(data)}`;
}

type AdminJwtVerification = { valid: boolean; email?: string; error?: string };

function decodeClaims(segment: string): Record<string, unknown> | null {
  try {
    const parsed: unknown = JSON.parse(Buffer.from(segment, "base64url").toString("utf8"));
    return typeof parsed === "object" && parsed !== null && !Array.isArray(parsed) ? (parsed as Record<string, unknown>) : null;
  } catch {
    return null;
  }
}

export function verifyAdminJWT(token: string): AdminJwtVerification {
  const [header, payload, signature, extra] = token.split(".");
  if (!header || !payload || !signature || extra !== undefined) return { valid: false, error: "Invalid token format" };
  if (!secretsMatch(signature, signSegments(`${header}.${payload}`))) return { valid: false, error: "Invalid signature" };

  const claims = decodeClaims(payload);
  if (!claims) return { valid: false, error: "Invalid token format" };
  if (claims.role !== "admin" || claims.aud !== ADMIN_AUDIENCE || claims.ver !== ADMIN_TOKEN_VERSION) {
    return { valid: false, error: "Not an admin token" };
  }
  if (typeof claims.exp !== "number" || claims.exp <= Math.floor(Date.now() / 1000)) return { valid: false, error: "Token expired" };
  if (typeof claims.email !== "string" || !isAdminEmail(claims.email)) return { valid: false, error: "Not an admin" };
  return { valid: true, email: claims.email };
}

export type AdminAuthResult = { ok: true; email?: string } | { ok: false; error: string };

// Password fallback through the x-admin-password header (scripts, tests).
function checkAdminPassword(c: Context): AdminAuthResult {
  const required = process.env.ADMIN_PASSWORD;
  if (!required) return { ok: false, error: "Unauthorized" };
  const given = c.req.header("x-admin-password");
  if (!given) return { ok: false, error: "Unauthorized" };
  const address = clientIp(c);
  if (adminPasswordAttempts.lockedFor(address) !== null) return { ok: false, error: "Too many attempts" };
  if (!secretsMatch(given, required)) {
    adminPasswordAttempts.recordFailure(address);
    return { ok: false, error: "Unauthorized" };
  }
  return { ok: true };
}

export function assertAdmin(c: Context): AdminAuthResult {
  const authHeader = c.req.header("Authorization") ?? "";
  if (authHeader.startsWith("Bearer ")) {
    const result = verifyAdminJWT(authHeader.substring(7));
    if (result.valid) return { ok: true, email: result.email };
  }
  return checkAdminPassword(c);
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
    if (result.valid) return { ok: true, email: result.email };
  }
  return { ok: false, error: "Unauthorized" };
}
