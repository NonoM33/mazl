import { createAppleClientSecret } from "./apple-client-secret";
import type { AppleSignInCredentials } from "./apple-config";

// The two calls to Apple's token endpoints. The HTTP client is injected, so
// the unit tests talk to a fake Apple and nothing real is called.

export interface AppleTokenApi {
  // POST /auth/token with the authorization code the app received: returns the refresh token.
  exchangeAuthorizationCode(code: string): Promise<string>;
  // POST /auth/revoke: the member is no longer signed in with Apple for this app.
  revokeRefreshToken(refreshToken: string): Promise<void>;
}

export class AppleApiError extends Error {
  constructor(
    message: string,
    readonly status: number | null,
    readonly appleError: string | null = null,
  ) {
    super(message);
    this.name = "AppleApiError";
  }
}

export interface HttpAppleTokenApiOptions {
  readonly credentials: AppleSignInCredentials;
  readonly base: string;
  readonly fetch?: typeof fetch;
  readonly now?: () => Date;
  readonly timeoutMs?: number;
}

const DEFAULT_TIMEOUT_MS = 5000;

export class HttpAppleTokenApi implements AppleTokenApi {
  private readonly fetchImpl: typeof fetch;
  private readonly now: () => Date;
  private readonly timeoutMs: number;

  constructor(private readonly options: HttpAppleTokenApiOptions) {
    this.fetchImpl = options.fetch ?? fetch;
    this.now = options.now ?? (() => new Date());
    this.timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  }

  async exchangeAuthorizationCode(code: string): Promise<string> {
    const response = await this.post("/auth/token", { grant_type: "authorization_code", code });
    const body: unknown = await response.json().catch(() => null);
    const refreshToken = typeof body === "object" && body !== null ? (body as Record<string, unknown>).refresh_token : undefined;
    if (typeof refreshToken !== "string" || refreshToken === "") {
      throw new AppleApiError("Apple's token answer carries no refresh token", response.status);
    }
    return refreshToken;
  }

  async revokeRefreshToken(refreshToken: string): Promise<void> {
    await this.post("/auth/revoke", { token: refreshToken, token_type_hint: "refresh_token" });
  }

  private async post(path: string, fields: Record<string, string>): Promise<Response> {
    const { credentials, base } = this.options;
    const form = new URLSearchParams({
      client_id: credentials.bundleId,
      client_secret: createAppleClientSecret(credentials, this.now()),
      ...fields,
    });
    let response: Response;
    try {
      response = await this.fetchImpl(`${base}${path}`, {
        method: "POST",
        headers: { "content-type": "application/x-www-form-urlencoded" },
        body: form,
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch (error) {
      // Only the kind of failure is kept: the message of a network error may carry the URL.
      throw new AppleApiError(`Apple ${path} unreachable (${error instanceof Error ? error.name : "unknown"})`, null);
    }
    if (!response.ok) {
      const body: unknown = await response.json().catch(() => null);
      const code = typeof body === "object" && body !== null ? (body as Record<string, unknown>).error : undefined;
      const appleError = typeof code === "string" ? code : null;
      throw new AppleApiError(`Apple ${path} refused (HTTP ${response.status}${appleError === null ? "" : `, ${appleError}`})`, response.status, appleError);
    }
    return response;
  }
}
