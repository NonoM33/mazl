import { createHash, timingSafeEqual } from "node:crypto";

// The App Store review sign-in (docs/launch/REVIEW-LOGIN-CONTRAT.md): Apple needs
// a user name and a password to review the app, and MAZL only signs in with
// Apple or Google. ONE account signs in this way; its password lives in the
// hosting as an argon2id hash, never in the repository.

export const REVIEW_PROVIDER = "review" as const;

const FIELD_MAX = 200;

export interface ReviewLoginConfig {
  readonly username: string;
  readonly passwordHash: string;
}

export interface ReviewCredentials {
  readonly username: string;
  readonly password: string;
}

export type PasswordVerifier = (password: string, hash: string) => Promise<boolean>;

/** The configuration, or null when the review sign-in is switched off. */
// A raw argon2id hash is full of "$", which a hosting may take for variables:
// it can be given as base64:<hash in base64> instead.
const BASE64_PREFIX = "base64:";
const decodeHash = (value: string | undefined): string | undefined =>
  value?.startsWith(BASE64_PREFIX) ? Buffer.from(value.slice(BASE64_PREFIX.length), "base64").toString("utf8").trim() : value;

export function readReviewLoginConfig(env: Readonly<Record<string, string | undefined>>): ReviewLoginConfig | null {
  const username = env.REVIEW_LOGIN_USERNAME?.trim();
  const passwordHash = decodeHash(env.REVIEW_LOGIN_PASSWORD_HASH?.trim());
  if (!username || !passwordHash) return null;
  return { username, passwordHash };
}

const isField = (value: unknown): value is string => typeof value === "string" && value.length > 0 && value.length <= FIELD_MAX;

export function parseReviewCredentials(body: unknown): ReviewCredentials | null {
  if (typeof body !== "object" || body === null) return null;
  const { username, password } = body as Record<string, unknown>;
  if (!isField(username) || !isField(password)) return null;
  return { username: username.trim(), password };
}

// Digests have the same length whatever the input, so the comparison takes the
// same time for every guess.
const digest = (value: string): Buffer => createHash("sha256").update(value).digest();

/**
 * Whether the credentials are the review account's. The password is always
 * checked, even for a wrong user name, so the answer time does not tell
 * which of the two was wrong.
 */
export async function checkReviewCredentials(
  config: ReviewLoginConfig,
  credentials: ReviewCredentials,
  verify: PasswordVerifier,
): Promise<boolean> {
  const sameUsername = timingSafeEqual(digest(credentials.username), digest(config.username));
  const passwordMatches = await verify(credentials.password, config.passwordHash).catch(() => false);
  return sameUsername && passwordMatches;
}

export const verifyWithBun: PasswordVerifier = (password, hash) => Bun.password.verify(password, hash);
