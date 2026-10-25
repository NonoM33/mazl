import { sign } from "node:crypto";
import type { AppleSignInCredentials } from "./apple-config";

// The client secret of Sign in with Apple is a JWT signed ES256 with the .p8
// key (developer.apple.com, "Creating a client secret"). It is made for each
// call and lives a few minutes: Apple accepts up to six months, nothing needs
// that, and a short life limits what a leak would allow.

const LIFETIME_SECONDS = 5 * 60;
const AUDIENCE = "https://appleid.apple.com";

const encode = (value: unknown): string => Buffer.from(JSON.stringify(value)).toString("base64url");

export function createAppleClientSecret(credentials: AppleSignInCredentials, now: Date = new Date()): string {
  const issuedAt = Math.floor(now.getTime() / 1000);
  const signingInput = `${encode({ alg: "ES256", kid: credentials.keyId })}.${encode({
    iss: credentials.teamId,
    iat: issuedAt,
    exp: issuedAt + LIFETIME_SECONDS,
    aud: AUDIENCE,
    sub: credentials.bundleId,
  })}`;
  // JWS wants the raw r||s signature (IEEE P1363), not the DER form node uses by default.
  const signature = sign("sha256", Buffer.from(signingInput), { key: credentials.privateKey, dsaEncoding: "ieee-p1363" });
  return `${signingInput}.${signature.toString("base64url")}`;
}
