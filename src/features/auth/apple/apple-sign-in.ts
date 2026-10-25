import { open, seal } from "../../../shared/crypto/secret-box";
import { readAppleSignInConfig } from "./apple-config";
import { HttpAppleTokenApi, type AppleTokenApi } from "./apple-token-api";
import type { AppleTokenStore } from "./apple-token-store";

// Sign in with Apple, after the sign-in: App Store rule 5.1.1(v) asks that an
// account deleted in the app also revokes the member's Apple authorization.
//   sign-in  -> the app sends the one-time authorization code; the server
//               exchanges it for a refresh token and keeps it, encrypted;
//   deletion -> the token is read BEFORE the erasure, revoked right after it.
// Apple being down, or the three variables missing, never stops a sign-in nor
// a deletion: the failure is logged (without any code or token).

export interface AppleLog {
  warn(message: string): void;
  error(message: string): void;
}

// What the routes need, without knowing how Apple is called.
export interface AppleSignInPort {
  rememberAuthorization(userId: number, authorizationCode: string): Promise<void>;
  // Reads the member's token now; the returned function revokes it later. Never throws.
  beginRevocation(userId: number): Promise<() => Promise<void>>;
}

// A real authorization code is a few dozen characters.
const CODE_MAX_LENGTH = 512;

const contextOf = (userId: number): string => `apple-refresh-token:${userId}`;
const noop = async (): Promise<void> => undefined;
const kindOf = (error: unknown): string => (error instanceof Error ? error.message || error.name : "unknown error");

export class AppleSignIn implements AppleSignInPort {
  constructor(
    // null: the three variables are missing, nothing is called.
    private readonly api: AppleTokenApi | null,
    private readonly store: AppleTokenStore,
    private readonly log: AppleLog,
  ) {}

  async rememberAuthorization(userId: number, authorizationCode: string): Promise<void> {
    if (this.api === null || authorizationCode === "" || authorizationCode.length > CODE_MAX_LENGTH) return;
    try {
      const refreshToken = await this.api.exchangeAuthorizationCode(authorizationCode);
      await this.store.save(userId, seal(Buffer.from(refreshToken, "utf8"), contextOf(userId)));
    } catch (error) {
      this.log.error(`Apple authorization not kept for user ${userId}: ${kindOf(error)}`);
    }
  }

  async beginRevocation(userId: number): Promise<() => Promise<void>> {
    const api = this.api;
    if (api === null) return noop;
    let refreshToken: string;
    try {
      const sealed = await this.store.find(userId);
      if (sealed === null) return noop;
      refreshToken = open(sealed, contextOf(userId)).toString("utf8");
    } catch (error) {
      this.log.error(`Apple token of user ${userId} not read, not revoked: ${kindOf(error)}`);
      return noop;
    }
    return async () => {
      try {
        await api.revokeRefreshToken(refreshToken);
      } catch (error) {
        this.log.error(`Apple revocation failed for user ${userId}: ${kindOf(error)}`);
      }
    };
  }
}

export interface CreateAppleSignInOptions {
  readonly env: Readonly<Record<string, string | undefined>>;
  readonly store: AppleTokenStore;
  readonly log?: AppleLog;
  readonly fetch?: typeof fetch;
}

export function createAppleSignIn(options: CreateAppleSignInOptions): AppleSignIn {
  const log = options.log ?? console;
  const config = readAppleSignInConfig(options.env);
  if (!config.available) {
    log.warn(`Sign in with Apple: ${config.reason}. Signing in works, but a deleted account's Apple authorization will not be revoked (revocation skipped).`);
    return new AppleSignIn(null, options.store, log);
  }
  const api = new HttpAppleTokenApi({ credentials: config.credentials, base: config.apiBase, ...(options.fetch === undefined ? {} : { fetch: options.fetch }) });
  return new AppleSignIn(api, options.store, log);
}
