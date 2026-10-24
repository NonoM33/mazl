// Typed failures of the web-session feature; routes map them to HTTP codes.
export class WebSessionConfigError extends Error {
  override readonly name = "WebSessionConfigError";
}

export type PowFailure = "malformed" | "forged" | "expired" | "replayed" | "insufficient";
