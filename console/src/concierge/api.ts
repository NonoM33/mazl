// Routes staff de la conciergerie (docs/couple/ESPACE-COUPLE.md §7), relatives à la base du client d'API.
import type { ApiClient, ApiResult } from "../shared/api/client";
import type { RequestDetailDto, RequestListDto, RequestPatch, RequestStatus, StaffMessageBody } from "./types";

/** Préfixe commun des routes staff de la conciergerie. */
export const CONCIERGE_PATH = "/concierge/requests";

/** Émis après une écriture : la barre latérale recompte les demandes à traiter sans attendre la minute. */
export const CONCIERGE_CHANGED = "mazl:concierge-changed";

export interface ConciergeApi {
  list(status?: RequestStatus): Promise<ApiResult<RequestListDto>>;
  get(id: number): Promise<ApiResult<RequestDetailDto>>;
  patch(id: number, patch: RequestPatch): Promise<ApiResult<RequestDetailDto>>;
  sendMessage(id: number, body: StaffMessageBody): Promise<ApiResult<RequestDetailDto>>;
}

export function conciergeApi(api: ApiClient): ConciergeApi {
  const base = CONCIERGE_PATH;
  return {
    list: (status) => api.get(base, { status }),
    get: (id) => api.get(`${base}/${id}`),
    patch: (id, patch) => api.patch(`${base}/${id}`, patch),
    sendMessage: (id, body) => api.post(`${base}/${id}/messages`, body),
  };
}
