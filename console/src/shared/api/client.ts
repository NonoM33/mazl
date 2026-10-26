// Client d'API typé : enveloppe { success, data } | { success: false, error, message } → résultat discriminé.

export const API_BASE = "/api/backoffice";
export const TOKEN_KEY = "mazl.staff.token";

export type ApiResult<T> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly status: number; readonly code: string; readonly message: string };

export type FetchLike = (input: string, init?: RequestInit) => Promise<Response>;

export interface ApiClientDeps {
  readonly fetch: FetchLike;
  readonly getToken: () => string | null;
  readonly onUnauthorized: () => void;
  readonly onMfaRequired: () => void;
  readonly baseUrl?: string;
}

export type QueryValue = string | number | boolean | null | undefined;
export type Query = Readonly<Record<string, QueryValue>>;

export interface ApiClient {
  get<T>(path: string, query?: Query): Promise<ApiResult<T>>;
  post<T>(path: string, body?: unknown): Promise<ApiResult<T>>;
  patch<T>(path: string, body?: unknown): Promise<ApiResult<T>>;
  delete<T>(path: string): Promise<ApiResult<T>>;
}

const FALLBACK_MESSAGES: Readonly<Record<string, string>> = {
  network: "Connexion au serveur impossible. Vérifiez votre réseau puis réessayez.",
  bad_response: "Le serveur a renvoyé une réponse inattendue.",
  unauthorized: "Votre session a expiré. Reconnectez-vous.",
  forbidden: "Vous n'avez pas la permission d'effectuer cette action.",
  mfa_required: "Un second facteur est requis avant de continuer.",
  not_found: "Élément introuvable.",
  rate_limited: "Trop de tentatives. Patientez quelques instants.",
  same_decider: "Une contestation doit être tranchée par une autre personne que l'auteur de la décision.",
  invalid_credentials: "Identifiants incorrects.",
  invalid_code: "Code incorrect ou expiré.",
  invalid_body: "La requête est mal formée : vérifiez les champs saisis.",
  invalid_params: "Certains réglages sont hors des bornes autorisées.",
  invalid_preview: "La simulation demandée est invalide.",
  version_not_found: "Cette version n'existe plus.",
  no_ab_test: "Aucun test A/B n'est en cours.",
  variant_is_active: "Cette version est déjà la version active : elle ne peut pas être sa propre variante.",
  corrupt_version: "Cette version contient des réglages invalides et ne peut pas être utilisée.",
};

export function messageForError(code: string, serverMessage: string | undefined, status: number): string {
  if (serverMessage !== undefined && serverMessage.trim() !== "") return serverMessage;
  const known = FALLBACK_MESSAGES[code];
  if (known !== undefined) return known;
  if (status >= 500) return "Erreur du serveur. Réessayez dans un instant.";
  return "La requête a échoué.";
}

export function buildQueryString(query: Query | undefined): string {
  if (query === undefined) return "";
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value === null || value === undefined || value === "") continue;
    params.set(key, String(value));
  }
  const text = params.toString();
  return text === "" ? "" : `?${text}`;
}

function failure(status: number, code: string, message?: string): ApiResult<never> {
  return { ok: false, status, code, message: messageForError(code, message, status) };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

export function createApiClient(deps: ApiClientDeps): ApiClient {
  const base = deps.baseUrl ?? API_BASE;

  async function request<T>(method: string, path: string, query?: Query, body?: unknown): Promise<ApiResult<T>> {
    const headers: Record<string, string> = { Accept: "application/json" };
    const token = deps.getToken();
    if (token !== null) headers["Authorization"] = `Bearer ${token}`;
    const init: RequestInit = { method, headers };
    if (body !== undefined) {
      headers["Content-Type"] = "application/json";
      init.body = JSON.stringify(body);
    }
    let response: Response;
    try {
      response = await deps.fetch(`${base}${path}${buildQueryString(query)}`, init);
    } catch {
      return failure(0, "network");
    }
    let payload: unknown;
    try {
      payload = await response.json();
    } catch {
      return failure(response.status, response.status === 401 ? "unauthorized" : "bad_response");
    }
    if (isRecord(payload) && payload["success"] === true && response.ok) {
      return { ok: true, data: payload["data"] as T };
    }
    const code = isRecord(payload) && typeof payload["error"] === "string" ? payload["error"] : response.status === 401 ? "unauthorized" : "bad_response";
    const message = isRecord(payload) && typeof payload["message"] === "string" ? payload["message"] : undefined;
    if (response.status === 401 && token !== null) deps.onUnauthorized();
    if (response.status === 403 && code === "mfa_required") deps.onMfaRequired();
    return failure(response.status, code, message);
  }

  return {
    get: (path, query) => request("GET", path, query),
    post: (path, body) => request("POST", path, undefined, body),
    patch: (path, body) => request("PATCH", path, undefined, body),
    delete: (path) => request("DELETE", path),
  };
}

export interface TokenStorage {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
  removeItem(key: string): void;
}

export interface TokenStore {
  read(): string | null;
  write(token: string): void;
  clear(): void;
}

export function createTokenStore(storage: TokenStorage): TokenStore {
  return {
    read: () => storage.getItem(TOKEN_KEY),
    write: (token) => storage.setItem(TOKEN_KEY, token),
    clear: () => storage.removeItem(TOKEN_KEY),
  };
}
