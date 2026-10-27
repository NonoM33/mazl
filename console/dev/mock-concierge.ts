// Maquette de /api/backoffice/concierge/requests : mêmes formes que le contrat docs/couple/ESPACE-COUPLE.md §7, état en mémoire.
// tests/unit/console-concierge-contract.test.ts valide chaque réponse de cette maquette contre des schémas écrits d'après le contrat.
// Couples fictifs (prénoms inventés, aucune donnée de membre). Les dates sont relatives à l'heure du lancement : il y a
// toujours une demande urgente (échéance dans moins de 48 h), une à venir, une réservée, une close et une annulée.
//
// Pour voir les erreurs du serveur : un message ou une note qui contient « erreur serveur » est refusé (500).
import type { Hono } from "hono";
import { stepOf } from "../src/concierge/status";
import type { ConciergeOption, CoupleSummary, MessageDto, MessageRole, RequestDetailDto, RequestDto, RequestListItemDto, RequestStatus } from "../src/concierge/types";
import { REQUEST_STATUSES, STAFF_MESSAGE_MAX, STAFF_NOTE_MAX } from "../src/concierge/types";
import type { MeDto } from "../src/shared/api/contracts";

type Guard = (c: never) => MeDto;
type Body = Record<string, unknown>;

const HOUR = 3_600_000;
const DAY = 24 * HOUR;
const PARIS_DAY = new Intl.DateTimeFormat("en-CA", { timeZone: "Europe/Paris", year: "numeric", month: "2-digit", day: "2-digit" });

const inDays = (days: number): string => PARIS_DAY.format(Date.now() + days * DAY);
const ago = (ms: number): string => new Date(Date.now() - ms).toISOString();

interface Stored {
  request: RequestDto;
  couple: CoupleSummary;
  messages: MessageDto[];
}

let nextMessageId = 100;
const message = (role: MessageRole, text: string, agoMs: number): MessageDto => {
  nextMessageId += 1;
  return { id: nextMessageId, role, authorId: role === "assistant" ? null : role === "staff" ? 7 : 41, text, createdAt: ago(agoMs) };
};

const NO_AI_REPLY = "Merci, votre demande est bien arrivée. L'équipe vous répond dans la journée.";

function build(id: number, couple: CoupleSummary, request: Omit<RequestDto, "id" | "constraints" | "options" | "chosenIndex" | "staffNote" | "assignedTo"> & Partial<Pick<RequestDto, "constraints" | "options" | "chosenIndex" | "staffNote" | "assignedTo">>, messages: MessageDto[]): Stored {
  return { couple, messages, request: { constraints: {}, options: [], chosenIndex: null, staffNote: "", assignedTo: null, ...request, id } };
}

const OPTIONS_SURPRISE: readonly ConciergeOption[] = [
  { title: "Dîner en terrasse sur les quais", details: "Table au bord de l'eau, menu casher de saison, bougies et petit mot sur la table.", priceHint: "environ 90 à 120 € pour deux" },
  { title: "Atelier de cuisine casher à deux", details: "Un chef vous apprend trois plats ; vous dînez ensuite ce que vous avez préparé.", priceHint: "environ 140 € pour deux" },
  { title: "Soirée jazz et plateau de mezzés", details: "Un club intimiste du Marais, places assises réservées près de la scène.", priceHint: "environ 70 € pour deux" },
];

const OPTIONS_WEEKEND: readonly ConciergeOption[] = [
  { title: "Week-end à Strasbourg", details: "Hôtel au centre, repas du vendredi soir chez un traiteur casher, balade en bateau le samedi soir.", priceHint: "environ 420 € pour deux nuits" },
  { title: "Deux nuits en Provence", details: "Maison d'hôtes avec cuisine, paniers casher livrés avant Shabbat.", priceHint: "environ 380 € pour deux nuits" },
];

const OPTIONS_HANUKKAH: readonly ConciergeOption[] = [
  { title: "Dîner de Hanoucca avec beignets maison", details: "Un traiteur casher livre un repas complet et une hanoukia si vous n'en avez pas encore.", priceHint: "environ 110 € pour deux" },
  { title: "Soirée allumage de la hanoukia en ville", details: "Allumage collectif puis chocolat chaud, places limitées.", priceHint: "gratuit, participation libre" },
];

function seed(): Stored[] {
  return [
    build(
      1,
      { firstNames: ["Léa", "Daniel"], months: 27 },
      { title: "Table casher pour fêter notre anniversaire", brief: "On fête nos deux ans et on aimerait une vraie table casher, calme, pas trop bruyante. Un endroit où l'on peut discuter.", wantedAt: inDays(1), city: "Paris 17e", status: "new", constraints: { kosher: true, budget: "100 à 150 €" }, createdAt: ago(3 * HOUR), updatedAt: ago(3 * HOUR) },
      [message("member", "On fête nos deux ans et on aimerait une vraie table casher, calme, pas trop bruyante.", 3 * HOUR), message("assistant", NO_AI_REPLY, 3 * HOUR - 60_000)],
    ),
    build(
      2,
      { firstNames: ["Myriam", "Eli"], months: 60 },
      { title: "Surprise pour les 5 ans de Myriam", brief: "Je voudrais organiser une surprise pour les cinq ans de Myriam, quelque chose de romantique mais sans grande foule.", wantedAt: inDays(9), city: "Paris", status: "chosen", constraints: { kosher: true }, options: OPTIONS_SURPRISE, chosenIndex: 1, staffNote: "Eli préfère un créneau avant 21 h. Voir avec le traiteur de la rue des Rosiers.", assignedTo: "gestion@example.com", createdAt: ago(2 * DAY), updatedAt: ago(5 * HOUR) },
      [
        message("member", "Je voudrais organiser une surprise pour les cinq ans de Myriam, quelque chose de romantique mais sans grande foule.", 2 * DAY),
        message("assistant", "Voici trois idées romantiques et calmes, toutes compatibles avec le casher. Dites-moi laquelle vous tente et l'équipe MAZL s'occupe de la suite.", 2 * DAY - 90_000),
        message("member", "L'atelier de cuisine à deux me plaît beaucoup, mais c'est une surprise : est-ce possible sans qu'elle le sache ?", 6 * HOUR),
        message("assistant", "Oui, l'équipe confirmera avec vous les détails pour que Myriam ne se doute de rien.", 6 * HOUR - 60_000),
      ],
    ),
    build(
      3,
      { firstNames: ["Sarah", "Jonathan"], months: 8 },
      { title: "Week-end à deux, avec Shabbat", brief: "On aimerait partir un week-end loin de Paris, avec un Shabbat tranquille et des repas casher. On vient de se mettre ensemble, rien de trop luxueux.", wantedAt: inDays(21), city: "Strasbourg ou ailleurs", status: "proposed", constraints: { kosher: true, budget: "400 €" }, options: OPTIONS_WEEKEND, createdAt: ago(DAY), updatedAt: ago(DAY) },
      [message("member", "On aimerait partir un week-end loin de Paris, avec un Shabbat tranquille et des repas casher.", DAY), message("assistant", "Deux idées pour un week-end avec Shabbat : Strasbourg ou la Provence. Laquelle vous plaît ?", DAY - 80_000)],
    ),
    build(
      4,
      { firstNames: ["Noa", "Gabriel"], months: 14 },
      { title: "Cadeau pour les 30 ans de Noa", brief: "Je cherche un cadeau original pour les 30 ans de Noa, qui adore la céramique et les livres. Pas de bijou.", wantedAt: inDays(5), city: "Lyon", status: "new", createdAt: ago(40 * 60_000), updatedAt: ago(40 * 60_000) },
      [message("member", "Je cherche un cadeau original pour les 30 ans de Noa, qui adore la céramique et les livres. Pas de bijou.", 40 * 60_000), message("assistant", NO_AI_REPLY, 40 * 60_000 - 45_000)],
    ),
    build(
      5,
      { firstNames: ["Rachel", "Avi"], months: 40 },
      { title: "Soirée de Hanoucca à deux", brief: "On n'a pas de famille à Paris cette année, on voudrait fêter Hanoucca tous les deux, avec un vrai repas.", wantedAt: inDays(38), city: "Paris 11e", status: "proposed", constraints: { kosher: true }, options: OPTIONS_HANUKKAH, createdAt: ago(4 * DAY), updatedAt: ago(4 * DAY) },
      [message("member", "On n'a pas de famille à Paris cette année, on voudrait fêter Hanoucca tous les deux, avec un vrai repas.", 4 * DAY), message("assistant", "Deux idées pour une belle soirée de Hanoucca à deux.", 4 * DAY - 70_000)],
    ),
    build(
      6,
      { firstNames: ["Déborah", "Yoni"], months: 19 },
      { title: "Dîner d'anniversaire de Yoni", brief: "Une table pour deux au calme pour l'anniversaire de Yoni.", wantedAt: inDays(3), city: "Paris 9e", status: "booked", constraints: { kosher: true }, options: OPTIONS_SURPRISE.slice(0, 1), chosenIndex: 0, staffNote: "Réservé chez le traiteur à 20 h, confirmation reçue par e-mail.", assignedTo: "admin@example.com", createdAt: ago(5 * DAY), updatedAt: ago(DAY) },
      [message("member", "Une table pour deux au calme pour l'anniversaire de Yoni.", 5 * DAY), message("assistant", "Une idée de dîner en terrasse, casher.", 5 * DAY - 60_000), message("staff", "C'est réservé pour 20 h, nous vous envoyons l'adresse précise par message.", DAY)],
    ),
    build(
      7,
      { firstNames: ["Ruth", "Tom"], months: 33 },
      { title: "Brunch du dimanche matin", brief: "Un brunch casher le dimanche pour fêter nos fiançailles.", wantedAt: inDays(-12), city: "Paris 16e", status: "closed", constraints: { kosher: true }, staffNote: "Terminé, retour très positif du couple.", assignedTo: "admin@example.com", createdAt: ago(20 * DAY), updatedAt: ago(11 * DAY) },
      [message("member", "Un brunch casher le dimanche pour fêter nos fiançailles.", 20 * DAY), message("staff", "Tout est réservé, belle fête à vous deux !", 15 * DAY)],
    ),
    build(
      8,
      { firstNames: ["Esther", "Jules"], months: 6 },
      { title: "Escapade de printemps", brief: "Une idée d'escapade pour un long week-end au printemps.", wantedAt: null, city: null, status: "cancelled", createdAt: ago(9 * DAY), updatedAt: ago(8 * DAY) },
      [message("member", "Une idée d'escapade pour un long week-end au printemps.", 9 * DAY)],
    ),
  ];
}

const store: Stored[] = seed();

const listItem = (stored: Stored): RequestListItemDto => ({
  id: stored.request.id,
  title: stored.request.title,
  status: stored.request.status,
  wantedAt: stored.request.wantedAt,
  updatedAt: stored.request.updatedAt,
  step: stepOf(stored.request.status),
  assignedTo: stored.request.assignedTo,
  couple: stored.couple,
});

const detail = (stored: Stored): RequestDetailDto => ({ request: stored.request, couple: stored.couple, messages: stored.messages });
const isStatus = (value: string): value is RequestStatus => (REQUEST_STATUSES as readonly string[]).includes(value);

export function registerConciergeMock(api: Hono, meOf: Guard): void {
  const base = "/concierge/requests";
  const ok = <T,>(data: T): { success: true; data: T } => ({ success: true, data });
  const fail = (error: string, message?: string): { success: false; error: string; message?: string } => (message === undefined ? { success: false, error } : { success: false, error, message });
  const allowed = (c: never): boolean => (meOf(c).permissions as readonly string[]).includes("concierge.manage");
  const json = async (c: { req: { json: () => Promise<unknown> } }): Promise<Body | null> => {
    try {
      const body = await c.req.json();
      return typeof body === "object" && body !== null && !Array.isArray(body) ? (body as Body) : null;
    } catch {
      return null;
    }
  };
  const find = (id: string): Stored | undefined => store.find((entry) => String(entry.request.id) === id);
  const touch = (stored: Stored, changes: Partial<RequestDto>): void => {
    stored.request = { ...stored.request, ...changes, updatedAt: new Date().toISOString() };
  };

  api.get(base, (c) => {
    if (!allowed(c as never)) return c.json(fail("forbidden"), 403);
    const status = c.req.query("status");
    if (status !== undefined && status !== "" && !isStatus(status)) return c.json(fail("invalid_query", "status inconnu"), 400);
    const rows = store.filter((entry) => status === undefined || status === "" || entry.request.status === status).map(listItem);
    return c.json(ok({ requests: rows }));
  });

  api.get(`${base}/:id`, (c) => {
    if (!allowed(c as never)) return c.json(fail("forbidden"), 403);
    const stored = find(c.req.param("id"));
    return stored === undefined ? c.json(fail("concierge_not_found"), 404) : c.json(ok(detail(stored)));
  });

  api.patch(`${base}/:id`, async (c) => {
    if (!allowed(c as never)) return c.json(fail("forbidden"), 403);
    const stored = find(c.req.param("id"));
    if (stored === undefined) return c.json(fail("concierge_not_found"), 404);
    const body = await json(c);
    const keys = body === null ? [] : Object.keys(body);
    const status = body?.["status"];
    const note = body?.["staffNote"];
    const assignee = body?.["assignedTo"];
    const valid =
      body !== null &&
      keys.length > 0 &&
      keys.every((key) => key === "status" || key === "staffNote" || key === "assignedTo") &&
      (status === undefined || status === "booked" || status === "closed") &&
      (note === undefined || (typeof note === "string" && note.length <= STAFF_NOTE_MAX)) &&
      (assignee === undefined || assignee === null || (typeof assignee === "string" && assignee.length > 0));
    if (!valid) return c.json(fail("invalid_body"), 400);
    if (typeof note === "string" && note.includes("erreur serveur")) return c.json(fail("internal_error", "Le serveur a rencontré un problème. Réessayez dans un instant."), 500);
    const current = stored.request.status;
    if (status === "booked" && current !== "chosen") return c.json(fail("invalid_transition", `Une demande « ${current} » ne peut pas être marquée réservée.`), 409);
    if (status === "closed" && (current === "closed" || current === "cancelled")) return c.json(fail("invalid_transition", `Une demande « ${current} » ne peut plus être close.`), 409);
    touch(stored, { ...(status === undefined ? {} : { status }), ...(typeof note === "string" ? { staffNote: note } : {}), ...(assignee === undefined ? {} : { assignedTo: assignee }) });
    return c.json(ok(detail(stored)));
  });

  api.post(`${base}/:id/messages`, async (c) => {
    if (!allowed(c as never)) return c.json(fail("forbidden"), 403);
    const stored = find(c.req.param("id"));
    if (stored === undefined) return c.json(fail("concierge_not_found"), 404);
    const body = await json(c);
    const text = body?.["text"];
    if (body === null || Object.keys(body).length !== 1 || typeof text !== "string" || text.trim() === "" || text.length > STAFF_MESSAGE_MAX) return c.json(fail("invalid_body"), 400);
    if (stored.request.status === "closed" || stored.request.status === "cancelled") return c.json(fail("concierge_closed"), 409);
    if (text.includes("erreur serveur")) return c.json(fail("internal_error", "Le serveur a rencontré un problème. Réessayez dans un instant."), 500);
    nextMessageId += 1;
    stored.messages = [...stored.messages, { id: nextMessageId, role: "staff", authorId: 7, text, createdAt: new Date().toISOString() }];
    touch(stored, {});
    return c.json(ok(detail(stored)), 201);
  });
}
