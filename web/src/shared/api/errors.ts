// Errors of the HTTP layer. The API answers `{ success: false, error }` with a
// code or a short message; the web keeps the code and the status.

export class ApiError extends Error {
  override readonly name = "ApiError";

  constructor(
    readonly status: number,
    readonly code: string,
    readonly retryAfter: number | null = null,
    readonly body: Readonly<Record<string, unknown>> = {},
  ) {
    super(`${status} ${code}`);
  }

  get isUnauthorized(): boolean {
    return this.status === 401;
  }

  get isNotFound(): boolean {
    return this.status === 404;
  }

  get isRateLimited(): boolean {
    return this.status === 429;
  }
}

export class NetworkError extends Error {
  override readonly name = "NetworkError";
}

// Wording shown to the member for an error; never the raw server text.
export function describeError(error: unknown): string {
  if (error instanceof NetworkError) return "Connexion impossible. Vérifiez votre réseau, puis réessayez.";
  if (!(error instanceof ApiError)) return "Une erreur inattendue est survenue.";
  if (error.isRateLimited) {
    const wait = error.retryAfter ?? 60;
    return `Doucement : réessayez dans ${wait < 120 ? `${wait} s` : `${Math.ceil(wait / 60)} min`}.`;
  }
  if (error.isNotFound) return "Introuvable.";
  if (error.status === 503) return "Service momentanément indisponible.";
  if (error.status >= 500) return "Le serveur n'a pas pu répondre. Réessayez dans un instant.";
  return "La demande n'a pas abouti.";
}
