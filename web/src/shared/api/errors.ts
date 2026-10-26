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

// What the server still needs before it serves the feeds (409 profile_incomplete).
// Unknown codes are kept as they come so a new server value never breaks the page.
export type MissingProfileField = "gender" | "looking_for" | (string & {});

const MISSING_LABELS: Readonly<Record<string, string>> = {
  gender: "Votre genre",
  looking_for: "Qui vous recherchez",
};

export function describeMissingField(field: string): string {
  return MISSING_LABELS[field] ?? "Une information de votre profil";
}

// The fields listed by a 409 profile_incomplete, or null for any other failure.
export function incompleteProfileFields(error: unknown): readonly MissingProfileField[] | null {
  if (!(error instanceof ApiError) || error.status !== 409 || error.code !== "profile_incomplete") return null;
  const { missing } = error.body;
  return Array.isArray(missing) ? missing.filter((field): field is string => typeof field === "string") : [];
}

export type LoadFailure =
  | { readonly kind: "profile_incomplete"; readonly missing: readonly MissingProfileField[] }
  | { readonly kind: "error"; readonly message: string };

export function classifyLoadFailure(error: unknown): LoadFailure {
  const missing = incompleteProfileFields(error);
  return missing === null ? { kind: "error", message: describeError(error) } : { kind: "profile_incomplete", missing };
}
