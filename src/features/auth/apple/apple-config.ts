import { createPrivateKey, type KeyObject } from "node:crypto";
import { isDevelopmentEnvironment } from "../../../shared/runtime/development-environment";

// Sign in with Apple, server side: what the server needs to talk to Apple's
// token endpoints (docs/launch/V1-CONTRAT.md §4). The three variables come from
// the Apple developer account (a Sign in with Apple key, .p8):
//   APPLE_TEAM_ID, APPLE_SIGNIN_KEY_ID, APPLE_SIGNIN_PRIVATE_KEY (PEM).
// Without them the sign-in still works; only the revocation is skipped.

// The iOS app's bundle id: the client id of Sign in with Apple. (src/auth.ts
// verifies identity tokens against the same audience.)
export const APPLE_BUNDLE_ID = "com.mazl.app";
const APPLE_HOST = "https://appleid.apple.com";

type Env = Readonly<Record<string, string | undefined>>;

export class AppleSignInConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AppleSignInConfigError";
  }
}

export interface AppleSignInCredentials {
  readonly teamId: string;
  readonly keyId: string;
  readonly privateKey: KeyObject;
  readonly bundleId: string;
}

export type AppleSignInConfig =
  | { readonly available: false; readonly reason: string }
  | { readonly available: true; readonly credentials: AppleSignInCredentials; readonly apiBase: string };

// The base of Apple's API (tokens, revocation, public keys). A fake Apple for
// tests can replace it, in development or test only: identity tokens are checked
// against the keys this host serves.
export function appleApiBase(env: Env): string {
  const raw = env.APPLE_API_BASE?.trim();
  if (raw === undefined || raw === "") return APPLE_HOST;
  if (!isDevelopmentEnvironment(env)) throw new AppleSignInConfigError("APPLE_API_BASE is refused outside development and test");
  try {
    return new URL(raw).toString().replace(/\/+$/, "");
  } catch {
    throw new AppleSignInConfigError("APPLE_API_BASE is not a valid URL");
  }
}

const present = (value: string | undefined): string | undefined => {
  const trimmed = value?.trim();
  return trimmed === undefined || trimmed === "" ? undefined : trimmed;
};

// Env files often hold a PEM on one line, with "\n" written out.
const normalizePem = (value: string): string => value.replaceAll("\\n", "\n");

function loadKey(pem: string): KeyObject | null {
  try {
    const key = createPrivateKey(normalizePem(pem));
    const isP256 = key.asymmetricKeyType === "ec" && key.asymmetricKeyDetails?.namedCurve === "prime256v1";
    return isP256 ? key : null;
  } catch {
    return null;
  }
}

export function readAppleSignInConfig(env: Env): AppleSignInConfig {
  const apiBase = appleApiBase(env);
  const teamId = present(env.APPLE_TEAM_ID);
  const keyId = present(env.APPLE_SIGNIN_KEY_ID);
  const pem = present(env.APPLE_SIGNIN_PRIVATE_KEY);

  const missing = [
    ...(teamId === undefined ? ["APPLE_TEAM_ID"] : []),
    ...(keyId === undefined ? ["APPLE_SIGNIN_KEY_ID"] : []),
    ...(pem === undefined ? ["APPLE_SIGNIN_PRIVATE_KEY"] : []),
  ];
  if (teamId === undefined || keyId === undefined || pem === undefined) {
    return { available: false, reason: `missing ${missing.join(", ")}` };
  }

  const privateKey = loadKey(pem);
  if (privateKey === null) {
    return { available: false, reason: "APPLE_SIGNIN_PRIVATE_KEY is not a P-256 private key in PEM form" };
  }
  return { available: true, credentials: { teamId, keyId, privateKey, bundleId: APPLE_BUNDLE_ID }, apiBase };
}
