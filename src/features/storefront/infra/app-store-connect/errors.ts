// Typed errors of the App Store Connect adapter. Apple's own error code, status and
// detail are kept so the back-office can show them; nothing is retried silently.

export interface AscErrorEntry {
  readonly status: string | undefined;
  readonly code: string | undefined;
  readonly title: string | undefined;
  readonly detail: string | undefined;
  readonly pointer: string | undefined;
}

export class AscApiError extends Error {
  constructor(
    readonly status: number,
    readonly errors: readonly AscErrorEntry[],
    readonly method: string,
    readonly path: string,
    readonly retryAfterSeconds?: number,
  ) {
    super(describe(status, errors, method, path, retryAfterSeconds));
    this.name = "AscApiError";
  }

  get code(): string | undefined {
    return this.errors[0]?.code;
  }

  get detail(): string | undefined {
    return this.errors[0]?.detail;
  }

  get rateLimited(): boolean {
    return this.status === 429;
  }
}

function describe(status: number, errors: readonly AscErrorEntry[], method: string, path: string, retryAfter?: number): string {
  const first = errors[0];
  const apple = first === undefined ? "no error body" : `${first.code ?? "?"}: ${first.detail ?? first.title ?? "?"}`;
  const hint = status === 429 ? ` (rate limited${retryAfter === undefined ? "" : `, retry after ${retryAfter}s`})` : "";
  return `App Store Connect ${method} ${path} failed with ${status}${hint} - ${apple}`;
}

export class AscNetworkError extends Error {
  constructor(method: string, path: string, cause: unknown) {
    super(`App Store Connect ${method} ${path} could not be reached`, { cause });
    this.name = "AscNetworkError";
  }
}

export class AscResponseError extends Error {
  constructor(path: string, message: string) {
    super(`Unexpected App Store Connect response for ${path}: ${message}`);
    this.name = "AscResponseError";
  }
}

export class UnknownProductError extends Error {
  constructor(readonly productId: string) {
    super(`Product ${productId} does not exist in App Store Connect`);
    this.name = "UnknownProductError";
  }
}

export class UnsupportedProductError extends Error {
  constructor(readonly productId: string, operation: string) {
    super(`${operation} is only available for auto-renewable subscriptions (${productId})`);
    this.name = "UnsupportedProductError";
  }
}

export class PriceChangeError extends Error {
  constructor(
    readonly applied: readonly string[],
    readonly failures: readonly { readonly territory: string; readonly error: Error }[],
  ) {
    super(
      `Price change failed for ${failures.length} territories (${failures.map((f) => f.territory).join(", ")}); ${applied.length} applied`,
    );
    this.name = "PriceChangeError";
  }
}

export class OfferCodeError extends Error {
  constructor(message: string, cause?: unknown) {
    super(message, cause === undefined ? undefined : { cause });
    this.name = "OfferCodeError";
  }
}
