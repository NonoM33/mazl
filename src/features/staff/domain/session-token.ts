import { createHmac, timingSafeEqual } from "node:crypto";

// Staff tokens: HMAC-SHA256 JWTs bound to the staff audiences, signed with a
// key of their own. A member token (other key) or an admin token (other key and
// audience "mazl-admin") can never verify here, and the other way round.

export const STAFF_AUDIENCE = "mazl-staff";
export const STAFF_MFA_AUDIENCE = "mazl-staff-mfa";
export const STAFF_TOKEN_VERSION = 1;
export const SESSION_TTL_SECONDS = 12 * 3600;
export const CHALLENGE_TTL_SECONDS = 5 * 60;

export class MissingStaffKeyError extends Error {
  constructor() {
    super("STAFF_JWT_SECRET (or JWT_SECRET) must be set; refusing to start without a staff signing key");
    this.name = "MissingStaffKeyError";
  }
}

// STAFF_JWT_SECRET, otherwise a key derived from JWT_SECRET for this purpose only.
export function resolveStaffKey(env: Readonly<Record<string, string | undefined>>): string {
  const dedicated = env.STAFF_JWT_SECRET;
  if (dedicated) return dedicated;
  const memberSecret = env.JWT_SECRET;
  if (!memberSecret) throw new MissingStaffKeyError();
  return createHmac("sha256", memberSecret).update("mazl:staff-jwt").digest("hex");
}

export interface SessionClaims {
  readonly email: string;
  readonly mfa: boolean;
}

export interface TokenSigner {
  signSession(claims: SessionClaims): string;
  verifySession(token: string): SessionClaims | null;
  signChallenge(email: string): string;
  verifyChallenge(token: string): string | null;
}

type Claims = Record<string, unknown>;

const encode = (value: unknown): string => Buffer.from(JSON.stringify(value)).toString("base64url");

function parseClaims(segment: string): Claims | null {
  try {
    const parsed: unknown = JSON.parse(Buffer.from(segment, "base64url").toString("utf8"));
    return typeof parsed === "object" && parsed !== null && !Array.isArray(parsed) ? (parsed as Claims) : null;
  } catch {
    return null;
  }
}

function sameSignature(given: string, expected: string): boolean {
  const a = Buffer.from(given);
  const b = Buffer.from(expected);
  return a.length === b.length && timingSafeEqual(a, b);
}

export function createTokenSigner(key: string, now: () => Date = () => new Date()): TokenSigner {
  const sign = (data: string): string => createHmac("sha256", key).update(data).digest("base64url");
  const seconds = (): number => Math.floor(now().getTime() / 1000);

  function issue(claims: Claims, audience: string, ttl: number): string {
    const issuedAt = seconds();
    const data = `${encode({ alg: "HS256", typ: "JWT" })}.${encode({
      ...claims,
      aud: audience,
      ver: STAFF_TOKEN_VERSION,
      iat: issuedAt,
      exp: issuedAt + ttl,
    })}`;
    return `${data}.${sign(data)}`;
  }

  function read(token: string, audience: string): Claims | null {
    const [header, payload, signature, extra] = token.split(".");
    if (!header || !payload || !signature || extra !== undefined) return null;
    if (!sameSignature(signature, sign(`${header}.${payload}`))) return null;
    const headerClaims = parseClaims(header);
    if (headerClaims?.alg !== "HS256") return null;
    const claims = parseClaims(payload);
    if (!claims || claims.aud !== audience || claims.ver !== STAFF_TOKEN_VERSION) return null;
    if (typeof claims.exp !== "number" || claims.exp <= seconds()) return null;
    if (typeof claims.email !== "string" || claims.email.length === 0) return null;
    return claims;
  }

  return {
    signSession: ({ email, mfa }) => issue({ email, mfa }, STAFF_AUDIENCE, SESSION_TTL_SECONDS),
    verifySession(token) {
      const claims = read(token, STAFF_AUDIENCE);
      if (!claims || typeof claims.mfa !== "boolean") return null;
      return { email: String(claims.email), mfa: claims.mfa };
    },
    signChallenge: (email) => issue({ email }, STAFF_MFA_AUDIENCE, CHALLENGE_TTL_SECONDS),
    verifyChallenge(token) {
      const claims = read(token, STAFF_MFA_AUDIENCE);
      return claims ? String(claims.email) : null;
    },
  };
}
