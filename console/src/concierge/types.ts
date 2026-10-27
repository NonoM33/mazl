// Formes de la conciergerie du couple côté staff, calquées sur docs/couple/ESPACE-COUPLE.md §7.
// Les champs de la table `concierge_requests` / `concierge_messages` passent en camelCase.
// Tout ce que le contrat ne tranche pas est marqué « à confirmer » ci-dessous et repris dans le rapport de livraison.

export const REQUEST_STATUSES = ["new", "proposed", "chosen", "booked", "closed", "cancelled"] as const;
export type RequestStatus = (typeof REQUEST_STATUSES)[number];

export const MESSAGE_ROLES = ["member", "assistant", "staff"] as const;
export type MessageRole = (typeof MESSAGE_ROLES)[number];

/** Étapes du couple : 1 reçue, 2 idée choisie, 3 réservée. */
export type Step = 1 | 2 | 3;

/** Idée proposée par l'assistant : `options jsonb [{ title, details, priceHint }]`. */
export interface ConciergeOption {
  readonly title: string;
  readonly details: string;
  readonly priceHint: string;
}

/** Contraintes envoyées par le couple (cacherout, budget). À confirmer : clés exactes. */
export interface ConciergeConstraints {
  readonly kosher?: boolean;
  readonly budget?: string;
}

/** Ce que le staff voit du couple : les prénoms et la durée, rien d'autre. À confirmer : noms des champs. */
export interface CoupleSummary {
  readonly firstNames: readonly string[];
  readonly months: number;
}

/** Ligne de `GET /api/backoffice/concierge/requests`. À confirmer : la liste reprend les champs de la liste couple plus ceux-ci. */
export interface RequestListItemDto {
  readonly id: number;
  readonly title: string;
  readonly status: RequestStatus;
  /** Date souhaitée, `YYYY-MM-DD`, jour de Paris. */
  readonly wantedAt: string | null;
  readonly updatedAt: string;
  readonly step: Step;
  readonly assignedTo: string | null;
  readonly couple: CoupleSummary;
}

export interface RequestListDto {
  readonly requests: readonly RequestListItemDto[];
}

/** Ligne `concierge_requests` vue par le staff (sans `created_by` ni `couple_id`). */
export interface RequestDto {
  readonly id: number;
  readonly title: string;
  readonly brief: string;
  readonly wantedAt: string | null;
  readonly city: string | null;
  readonly constraints: ConciergeConstraints;
  readonly status: RequestStatus;
  readonly options: readonly ConciergeOption[];
  readonly chosenIndex: number | null;
  readonly staffNote: string;
  readonly assignedTo: string | null;
  readonly createdAt: string;
  readonly updatedAt: string;
}

/** Ligne `concierge_messages`. */
export interface MessageDto {
  readonly id: number;
  readonly role: MessageRole;
  readonly authorId: number | null;
  readonly text: string;
  readonly createdAt: string;
}

/** `GET requests/:id`, et réponse des deux écritures (PATCH et POST message). À confirmer : enveloppe. */
export interface RequestDetailDto {
  readonly request: RequestDto;
  readonly couple: CoupleSummary;
  readonly messages: readonly MessageDto[];
}

/** `PATCH requests/:id` : les trois champs sont facultatifs, au moins un est présent. */
export interface RequestPatch {
  readonly status?: "booked" | "closed";
  readonly staffNote?: string;
  readonly assignedTo?: string | null;
}

/** `POST requests/:id/messages`. */
export interface StaffMessageBody {
  readonly text: string;
}

export const STAFF_NOTE_MAX = 2000;
export const STAFF_MESSAGE_MAX = 1000;
