// Logique pure de la conciergerie : onglets, pastilles, étapes, urgence, tri, compteur et actions permises.
import type { Tone } from "../shared/ui/Badge";
import { wantedDeadline } from "./dates";
import type { RequestListItemDto, RequestStatus, Step } from "./types";

export const URGENT_WITHIN_MS = 48 * 3_600_000;

export type TabId = "todo" | "ongoing" | "done";

export const TABS: readonly { readonly id: TabId; readonly label: string; readonly statuses: readonly RequestStatus[] }[] = [
  { id: "todo", label: "À traiter", statuses: ["new", "chosen"] },
  { id: "ongoing", label: "En cours", statuses: ["proposed", "booked"] },
  { id: "done", label: "Terminées", statuses: ["closed", "cancelled"] },
];

export function tabFromParam(param: string | undefined): TabId {
  return TABS.find((tab) => tab.id === param)?.id ?? "todo";
}

export function tabStatuses(tab: TabId): readonly RequestStatus[] {
  return TABS.find((candidate) => candidate.id === tab)?.statuses ?? [];
}

export const STATUS_LABELS: Readonly<Record<RequestStatus, string>> = {
  new: "Nouvelle",
  proposed: "Idées proposées",
  chosen: "Idée choisie",
  booked: "Réservée",
  closed: "Close",
  cancelled: "Annulée par le couple",
};

export const STATUS_TONES: Readonly<Record<RequestStatus, Tone>> = {
  new: "warning",
  proposed: "neutral",
  chosen: "accent",
  booked: "success",
  closed: "neutral",
  cancelled: "neutral",
};

/** Étapes vues par le couple : 1 reçue, 2 idée choisie, 3 réservée. */
export function stepOf(status: RequestStatus): Step {
  switch (status) {
    case "new":
    case "proposed":
    case "cancelled":
      return 1;
    case "chosen":
      return 2;
    case "booked":
    case "closed":
      return 3;
  }
}

export const STEP_LABELS: Readonly<Record<Step, string>> = { 1: "Demande reçue", 2: "Idée choisie", 3: "Réservée" };

const OPEN: readonly RequestStatus[] = ["new", "proposed", "chosen"];

/** Une demande dont l'échéance tombe dans moins de 48 h (ou est passée) et qui n'est ni réservée ni terminée. */
export function isUrgent(item: Pick<RequestListItemDto, "status" | "wantedAt">, now: Date): boolean {
  if (!OPEN.includes(item.status)) return false;
  const deadline = wantedDeadline(item.wantedAt);
  return deadline !== null && deadline - now.getTime() < URGENT_WITHIN_MS;
}

/** Urgentes d'abord, puis par date souhaitée croissante (sans date en dernier), puis la plus récemment mise à jour. */
export function sortByUrgency<T extends Pick<RequestListItemDto, "status" | "wantedAt" | "updatedAt" | "id">>(items: readonly T[], now: Date): readonly T[] {
  const key = (item: T): readonly [number, number, number] => [isUrgent(item, now) ? 0 : 1, wantedDeadline(item.wantedAt) ?? Number.POSITIVE_INFINITY, -Date.parse(item.updatedAt)];
  return [...items].sort((a, b) => {
    const [ua, wa, ra] = key(a);
    const [ub, wb, rb] = key(b);
    return ua - ub || (wa === wb ? 0 : wa < wb ? -1 : 1) || ra - rb || a.id - b.id;
  });
}

export function inTab<T extends Pick<RequestListItemDto, "status">>(items: readonly T[], tab: TabId): readonly T[] {
  const statuses = tabStatuses(tab);
  return items.filter((item) => statuses.includes(item.status));
}

/** Compteur de la barre latérale : demandes nouvelles et idées choisies, celles que l'équipe doit traiter. */
export function pendingCount(items: readonly Pick<RequestListItemDto, "status">[]): number {
  return items.filter((item) => item.status === "new" || item.status === "chosen").length;
}

export function tabCounts(items: readonly Pick<RequestListItemDto, "status">[]): Readonly<Record<TabId, number>> {
  return { todo: inTab(items, "todo").length, ongoing: inTab(items, "ongoing").length, done: inTab(items, "done").length };
}

export interface StaffActions {
  /** « Marquer réservé » : seulement quand le couple a choisi une idée. */
  readonly canMarkBooked: boolean;
  /** « Clore » : toute demande encore vivante. */
  readonly canClose: boolean;
  /** « Écrire au couple » et la note interne : tant que la demande n'est ni close ni annulée. */
  readonly canWrite: boolean;
}

export function actionsFor(status: RequestStatus): StaffActions {
  const alive = status !== "closed" && status !== "cancelled";
  return { canMarkBooked: status === "chosen", canClose: alive, canWrite: alive };
}
