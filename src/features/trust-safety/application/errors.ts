// Expected failures of the use cases; the routes turn them into the envelope.
export type FailureStatus = 400 | 403 | 404 | 409;

export class TrustSafetyError extends Error {
  constructor(
    readonly code: string,
    readonly status: FailureStatus,
    message: string,
  ) {
    super(message);
    this.name = "TrustSafetyError";
  }
}

export function notFound(what: string): TrustSafetyError {
  return new TrustSafetyError("not_found", 404, `${what} introuvable`);
}
