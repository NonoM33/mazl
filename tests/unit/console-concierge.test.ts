// Logique pure de la conciergerie de la console : onglets, pastilles, étapes, urgence, tri, compteur, actions, dates de Paris.
import { describe, expect, test } from "bun:test";
import { formatCoupleDuration, formatStamp, formatWantedDay, formatWantedDayLong, wantedDeadline } from "../../console/src/concierge/dates";
import { conciergeErrorMessage } from "../../console/src/concierge/errors";
import { assignRequest, closeRequest, markBookedRequest, staffMessageRequest, staffNoteRequest } from "../../console/src/concierge/request-bodies";
import { actionsFor, inTab, isUrgent, pendingCount, sortByUrgency, STATUS_LABELS, STATUS_TONES, stepOf, tabCounts, tabFromParam, tabStatuses } from "../../console/src/concierge/status";
import { REQUEST_STATUSES, type RequestListItemDto, type RequestStatus } from "../../console/src/concierge/types";

// Mardi 27 octobre 2026, 10 h à Paris (CET, UTC+1 depuis le 25 octobre) = 09 h UTC.
const NOW = new Date("2026-10-27T09:00:00.000Z");

const item = (id: number, status: RequestStatus, wantedAt: string | null, updatedAt = "2026-10-26T12:00:00.000Z"): RequestListItemDto => ({
  id,
  title: `Demande ${String(id)}`,
  status,
  wantedAt,
  updatedAt,
  step: stepOf(status),
  assignedTo: null,
  couple: { firstNames: ["Léa", "Daniel"], months: 12 },
});

describe("onglets", () => {
  test("chaque statut est dans exactement un onglet", () => {
    for (const status of REQUEST_STATUSES) {
      const tabs = (["todo", "ongoing", "done"] as const).filter((tab) => tabStatuses(tab).includes(status));
      expect({ status, tabs: tabs.length }).toEqual({ status, tabs: 1 });
    }
  });

  test("À traiter = nouvelles et idées choisies ; En cours = idées proposées et réservées ; Terminées = closes et annulées", () => {
    expect(tabStatuses("todo")).toEqual(["new", "chosen"]);
    expect(tabStatuses("ongoing")).toEqual(["proposed", "booked"]);
    expect(tabStatuses("done")).toEqual(["closed", "cancelled"]);
  });

  test("un paramètre inconnu retombe sur « À traiter »", () => {
    expect(tabFromParam(undefined)).toBe("todo");
    expect(tabFromParam("nimportequoi")).toBe("todo");
    expect(tabFromParam("done")).toBe("done");
  });

  test("filtrage et décomptes par onglet", () => {
    const all = [item(1, "new", null), item(2, "chosen", null), item(3, "proposed", null), item(4, "booked", null), item(5, "closed", null), item(6, "cancelled", null), item(7, "new", null)];
    expect(inTab(all, "todo").map((row) => row.id)).toEqual([1, 2, 7]);
    expect(tabCounts(all)).toEqual({ todo: 3, ongoing: 2, done: 2 });
  });
});

describe("compteur de la barre latérale", () => {
  test("compte les demandes nouvelles et les idées choisies, rien d'autre", () => {
    const all = [item(1, "new", null), item(2, "chosen", null), item(3, "proposed", null), item(4, "booked", null), item(5, "closed", null), item(6, "cancelled", null)];
    expect(pendingCount(all)).toBe(2);
    expect(pendingCount([])).toBe(0);
  });
});

describe("pastilles et étapes", () => {
  test("un libellé français et un ton pour chaque statut", () => {
    expect(STATUS_LABELS).toEqual({ new: "Nouvelle", proposed: "Idées proposées", chosen: "Idée choisie", booked: "Réservée", closed: "Close", cancelled: "Annulée par le couple" });
    expect(STATUS_TONES).toEqual({ new: "warning", proposed: "neutral", chosen: "accent", booked: "success", closed: "neutral", cancelled: "neutral" });
  });

  test("étapes du contrat : reçue (1), idée choisie (2), réservée (3)", () => {
    expect(REQUEST_STATUSES.map((status) => [status, stepOf(status)])).toEqual([
      ["new", 1],
      ["proposed", 1],
      ["chosen", 2],
      ["booked", 3],
      ["closed", 3],
      ["cancelled", 1],
    ]);
  });
});

describe("urgence (échéance à moins de 48 h)", () => {
  test("demain à Paris est urgent, dans quatre jours non", () => {
    expect(isUrgent(item(1, "new", "2026-10-28"), NOW)).toBe(true);
    expect(isUrgent(item(1, "new", "2026-10-31"), NOW)).toBe(false);
  });

  test("la limite est minuit à Paris : le 29 à 00 h (CET) est à 39 h, le 30 à 00 h est à 63 h", () => {
    expect(wantedDeadline("2026-10-29")).toBe(Date.parse("2026-10-28T23:00:00.000Z"));
    expect(isUrgent(item(1, "chosen", "2026-10-29"), NOW)).toBe(true);
    expect(isUrgent(item(1, "chosen", "2026-10-30"), NOW)).toBe(false);
  });

  test("pile 48 h n'est plus urgent, une minute avant l'est", () => {
    const exactly = new Date("2026-10-26T23:00:00.000Z"); // 48 h avant le 29 à 00 h Paris
    expect(isUrgent(item(1, "new", "2026-10-29"), exactly)).toBe(false);
    expect(isUrgent(item(1, "new", "2026-10-29"), new Date(exactly.getTime() + 60_000))).toBe(true);
  });

  test("une date passée reste urgente tant que la demande est ouverte", () => {
    expect(isUrgent(item(1, "new", "2026-10-20"), NOW)).toBe(true);
  });

  test("jamais urgent sans date, ni une fois réservée, close ou annulée", () => {
    expect(isUrgent(item(1, "new", null), NOW)).toBe(false);
    for (const status of ["booked", "closed", "cancelled"] as const) expect(isUrgent(item(1, status, "2026-10-28"), NOW)).toBe(false);
  });

  test("le changement d'heure d'hiver ne décale pas l'échéance (25 octobre 2026, 03 h → 02 h)", () => {
    const lastSummerDay = new Date("2026-10-24T22:00:00.000Z"); // dimanche 25 à 00 h Paris (CEST)
    expect(wantedDeadline("2026-10-25")).toBe(lastSummerDay.getTime());
    expect(wantedDeadline("2026-10-26")).toBe(Date.parse("2026-10-25T23:00:00.000Z"));
  });

  test("une date impossible n'est pas une échéance", () => {
    expect(wantedDeadline("2026-02-30")).toBeNull();
    expect(wantedDeadline("demain")).toBeNull();
  });
});

describe("tri par urgence", () => {
  test("urgentes d'abord, puis date souhaitée croissante, sans date en dernier, puis la plus récente", () => {
    const rows = [
      item(1, "new", null),
      item(2, "chosen", "2026-11-05"),
      item(3, "new", "2026-10-28"),
      item(4, "new", "2026-10-31"),
      item(5, "new", "2026-10-29"),
      item(6, "new", null, "2026-10-27T08:00:00.000Z"),
    ];
    expect(sortByUrgency(rows, NOW).map((row) => row.id)).toEqual([3, 5, 4, 2, 6, 1]);
  });

  test("ne modifie pas la liste d'origine", () => {
    const rows = [item(1, "new", "2026-11-05"), item(2, "new", "2026-10-28")];
    sortByUrgency(rows, NOW);
    expect(rows.map((row) => row.id)).toEqual([1, 2]);
  });
});

describe("actions permises", () => {
  test("« Marquer réservé » seulement quand le couple a choisi une idée", () => {
    expect(REQUEST_STATUSES.filter((status) => actionsFor(status).canMarkBooked)).toEqual(["chosen"]);
  });

  test("« Clore » et « Écrire au couple » tant que la demande est vivante", () => {
    expect(REQUEST_STATUSES.filter((status) => actionsFor(status).canClose)).toEqual(["new", "proposed", "chosen", "booked"]);
    expect(REQUEST_STATUSES.filter((status) => actionsFor(status).canWrite)).toEqual(["new", "proposed", "chosen", "booked"]);
  });
});

describe("dates à l'heure de Paris", () => {
  test("date souhaitée courte et longue, sans glissement de jour", () => {
    expect(formatWantedDay("2026-10-29")).toBe("jeu. 29 oct.");
    expect(formatWantedDayLong("2026-10-29")).toBe("jeudi 29 octobre");
    expect(formatWantedDay("2026-12-04")).toBe("ven. 4 déc.");
    expect(formatWantedDay(null)).toBe("—");
    expect(formatWantedDay("2026-13-40")).toBe("—");
    expect(formatWantedDayLong(null)).toBe("Pas de date précise");
  });

  test("horodatage d'un message : heure d'été puis heure d'hiver", () => {
    expect(formatStamp("2026-10-20T12:05:00.000Z")).toMatch(/^20 oct\.(,| à) 14:05$/);
    expect(formatStamp("2026-10-27T13:05:00.000Z")).toMatch(/^27 oct\.(,| à) 14:05$/);
    expect(formatStamp("pas une date")).toBe("—");
  });

  test("durée du couple", () => {
    expect(formatCoupleDuration(0)).toBe("moins d'un mois");
    expect(formatCoupleDuration(8)).toBe("8 mois");
    expect(formatCoupleDuration(12)).toBe("1 an");
    expect(formatCoupleDuration(27)).toBe("2 ans et 3 mois");
    expect(formatCoupleDuration(60)).toBe("5 ans");
    expect(formatCoupleDuration(-1)).toBe("—");
  });
});

describe("corps de requête et erreurs", () => {
  test("forme des corps du contrat §7", () => {
    expect(markBookedRequest()).toEqual({ status: "booked" });
    expect(closeRequest()).toEqual({ status: "closed" });
    expect(staffNoteRequest("  appeler le traiteur  ")).toEqual({ staffNote: "appeler le traiteur" });
    expect(assignRequest("admin@example.com")).toEqual({ assignedTo: "admin@example.com" });
    expect(assignRequest(null)).toEqual({ assignedTo: null });
    expect(staffMessageRequest("  Bonne nouvelle !  ")).toEqual({ text: "Bonne nouvelle !" });
  });

  test("un code connu est dit en clair, un code inconnu garde le message du serveur", () => {
    expect(conciergeErrorMessage({ code: "invalid_transition", message: "" })).toContain("a changé entre-temps");
    expect(conciergeErrorMessage({ code: "concierge_closed", message: "" })).toContain("close ou annulée");
    expect(conciergeErrorMessage({ code: "boom", message: "Le serveur a rencontré un problème." })).toBe("Le serveur a rencontré un problème.");
  });
});
