import { z } from "zod";
import type { Permission } from "../../staff/domain/roles";
import * as ex from "./examples";
import * as s from "./schemas";

// The routes of the daily couple space (docs/couple/ESPACE-COUPLE.md), declared
// once: they are registered from this list and the OpenAPI document is generated
// from it (docs/api/couple-openapi.json).

export const MEMBER_BASE = "/api/couple";
export const STAFF_BASE = "/api/backoffice/concierge";
export const DOC_PATH = "/api/backoffice/couple/openapi";

export interface ErrorSpec {
  readonly status: 400 | 401 | 402 | 403 | 404 | 409 | 429 | 500;
  readonly code: string;
  readonly message?: string;
  readonly description: string;
}

export interface ParameterSpec {
  readonly name: string;
  readonly in: "path" | "query";
  readonly description: string;
  readonly required: boolean;
  readonly schema: z.ZodType;
  readonly example: unknown;
}

export interface OperationSpec {
  readonly operationId: string;
  readonly method: "get" | "post" | "patch" | "delete";
  // OpenAPI notation, {id}; the router uses :id.
  readonly path: string;
  readonly tag: string;
  readonly summary: string;
  readonly description: string;
  readonly audience: "member" | "staff";
  // Staff routes: the permission asked.
  readonly permission: Permission | null;
  // Member routes reserved to MAZL Couple answer 402 without it.
  readonly premium: boolean;
  readonly parameters: readonly ParameterSpec[];
  readonly body?: { readonly schema: z.ZodType; readonly examples: Readonly<Record<string, { readonly summary: string; readonly value: unknown }>> };
  readonly success: { readonly status: 200 | 201; readonly description: string; readonly schema: z.ZodType; readonly example: unknown };
  readonly errors: readonly ErrorSpec[];
}

const UNAUTHORIZED_MEMBER: ErrorSpec = { status: 401, code: "No token provided", description: "Pas de jeton, jeton invalide (« Invalid token ») ou compte désactivé (« account_disabled »)." };
const NOT_IN_COUPLE: ErrorSpec = { status: 400, code: "Not in a couple", description: "L'appelant n'est dans aucun couple actif." };
const INVALID_BODY: ErrorSpec = { status: 400, code: "invalid_body", message: "text: Too small", description: "Corps absent, illisible ou hors schéma." };
const INVALID_QUERY: ErrorSpec = { status: 400, code: "invalid_query", message: "filter: valeur inconnue", description: "Paramètre de requête hors des valeurs permises." };
const PREMIUM_REQUIRED: ErrorSpec = { status: 402, code: "couple_subscription_required", description: "Le couple n'a pas d'abonnement MAZL Couple actif." };
const CONCIERGE_NOT_FOUND: ErrorSpec = { status: 404, code: "concierge_not_found", description: "Demande inconnue, ou qui appartient à un autre couple (jamais distingué)." };
const CONCIERGE_CLOSED: ErrorSpec = { status: 409, code: "concierge_closed", description: "La demande est close ou annulée." };
const INVALID_TRANSITION: ErrorSpec = { status: 409, code: "invalid_transition", description: "Le statut actuel de la demande ne permet pas cette opération." };
const RATE_LIMITED: ErrorSpec = { status: 429, code: "concierge_rate_limited", description: "20 messages au plus par couple et par jour ont été envoyés à la conciergerie." };
const INTERNAL: ErrorSpec = { status: 500, code: "internal_error", description: "Erreur inattendue du serveur (détail dans les journaux, jamais dans la réponse)." };
const STAFF_UNAUTHORIZED: ErrorSpec = { status: 401, code: "unauthorized", message: "Connexion requise.", description: "Pas de session staff valide." };
const STAFF_FORBIDDEN: ErrorSpec = { status: 403, code: "forbidden", message: "Droits insuffisants.", description: "Le rôle de la session n'a pas la permission concierge.manage." };
const MFA_REQUIRED: ErrorSpec = { status: 403, code: "mfa_required", message: "Second facteur requis.", description: "La session n'a pas passé le second facteur (TOTP) exigé." };

const memberErrors = [UNAUTHORIZED_MEMBER, NOT_IN_COUPLE, INTERNAL];
const premiumErrors = [UNAUTHORIZED_MEMBER, NOT_IN_COUPLE, PREMIUM_REQUIRED, INTERNAL];
const staffErrors = [STAFF_UNAUTHORIZED, STAFF_FORBIDDEN, MFA_REQUIRED, INTERNAL];

const WHO_MEMBER = "Qui : un membre connecté, appartenant à un couple actif ; il n'agit que sur son propre couple.";
const WHO_PREMIUM = "Qui : un membre connecté d'un couple actif disposant de MAZL Couple (402 couple_subscription_required sinon) ; il n'agit que sur les demandes de son couple, une demande d'un autre couple est un 404.";
const WHO_STAFF = "Qui : administrateur ou super-administrateur (permission concierge.manage).";

const idParam = (what: string, example: number): ParameterSpec => ({ name: "id", in: "path", description: `Numéro ${what}.`, required: true, schema: z.number().int().min(1), example });

const rituals = "rituals";
const TAG_TODAY = "Aujourd'hui";
const TAG_AGENDA = "Agenda";
const TAG_OUTINGS = "Sorties";
const TAG_US = "Nous deux";
const TAG_CONCIERGE = "Conciergerie";
const TAG_STAFF = "Conciergerie (équipe)";
const TAG_DOC = "Documentation";

export const OPERATIONS: readonly OperationSpec[] = [
  {
    operationId: "coupleToday", method: "get", path: `${MEMBER_BASE}/today`, tag: TAG_TODAY, audience: "member", permission: null, premium: false, parameters: [],
    summary: "L'écran Aujourd'hui du couple",
    description:
      `${WHO_MEMBER} Rend en une réponse : le nombre de jours ensemble, le partenaire, la question du jour (texte dans la langue d'Accept-Language, la réponse de l'autre n'est jamais incluse), ` +
      "les 5 prochains éléments sur 45 jours (dates du couple, rituels activés, inscriptions aux événements), une sortie proposée, les humeurs du jour, le bilan du mois et les droits MAZL Couple. " +
      "Effets de bord : la question du jour est tirée et enregistrée à la première lecture de la journée ; rien d'autre.",
    success: { status: 200, description: "L'écran Aujourd'hui.", schema: s.todayDto, example: ex.todayExample },
    errors: memberErrors,
  },
  {
    operationId: "coupleMood", method: "post", path: `${MEMBER_BASE}/mood`, tag: TAG_TODAY, audience: "member", permission: null, premium: false, parameters: [],
    summary: "Dire comment on se sent aujourd'hui",
    description:
      `${WHO_MEMBER} Enregistre l'humeur du jour du membre (great, good, meh ou talk) ; une seconde humeur le même jour remplace la première. ` +
      "Effets de bord : choisir « talk » (« On doit parler ») envoie à l'autre membre un push doux sans aucun texte libre (data.type couple_mood), une seule fois par jour ; les autres humeurs n'envoient rien.",
    body: { schema: s.moodBody, examples: { good: { summary: "Une bonne journée", value: { mood: "good" } }, talk: { summary: "Besoin de parler", value: { mood: "talk" } } } },
    success: { status: 200, description: "L'humeur enregistrée et celle de l'autre.", schema: s.moodResultDto, example: { mine: "good", partner: null } },
    errors: [INVALID_BODY, ...memberErrors],
  },
  {
    operationId: "coupleRitualsList", method: "get", path: `${MEMBER_BASE}/rituals`, tag: TAG_AGENDA, audience: "member", permission: null, premium: false, parameters: [],
    summary: "Lister les rituels du couple",
    description:
      `${WHO_MEMBER} Les rituels du couple : Shabbat ensemble (activé), Soirée sans écran le mardi et Appeler les parents le dimanche (désactivés) sont créés avec le couple. ` +
      "Effets de bord : aucun. Les rappels push de ces rituels sont réservés à MAZL Couple, la liste est lisible sans abonnement.",
    success: { status: 200, description: "Les rituels.", schema: s.ritualListDto, example: { rituals: [ex.ritualExample, ex.weeklyRitualExample] } },
    errors: memberErrors,
  },
  {
    operationId: "coupleRitualsCreate", method: "post", path: `${MEMBER_BASE}/${rituals}`, tag: TAG_AGENDA, audience: "member", permission: null, premium: false, parameters: [],
    summary: "Ajouter un rituel personnalisé",
    description:
      `${WHO_MEMBER} Crée un rituel (shabbat, weekly ou custom) avec son jour (0 = dimanche), son heure HH:MM (inutile pour Shabbat, calculé) et le délai du rappel en minutes. ` +
      "Effets de bord : une ligne est écrite ; si le couple a MAZL Couple, un push de rappel part aux deux membres avant chaque occurrence.",
    body: { schema: s.createRitualBody, examples: { custom: { summary: "Un brunch du dimanche", value: { kind: "custom", title: "Brunch du dimanche", weekday: 0, time: "11:00", remind_minutes: 90 } } } },
    success: { status: 201, description: "Le rituel créé.", schema: s.ritualOneDto, example: { ritual: { ...ex.weeklyRitualExample, id: 4, kind: "custom", title: "Brunch du dimanche", weekday: 0, time: "11:00", enabled: true, remind_minutes: 90 } } },
    errors: [INVALID_BODY, ...memberErrors],
  },
  {
    operationId: "coupleRitualsUpdate", method: "patch", path: `${MEMBER_BASE}/${rituals}/{id}`, tag: TAG_AGENDA, audience: "member", permission: null, premium: false, parameters: [idParam("du rituel", 2)],
    summary: "Modifier ou activer un rituel",
    description:
      `${WHO_MEMBER} Change le titre, le jour, l'heure, l'activation ou le délai de rappel ; seuls les champs présents changent, null efface le jour ou l'heure. Un rituel d'un autre couple est un 404. ` +
      "Effets de bord : une ligne est mise à jour ; l'activation décide des rappels push (MAZL Couple).",
    body: { schema: s.updateRitualBody, examples: { enable: { summary: "Activer", value: { enabled: true } }, move: { summary: "Changer l'heure", value: { time: "21:00" } } } },
    success: { status: 200, description: "Le rituel mis à jour.", schema: s.ritualOneDto, example: { ritual: { ...ex.weeklyRitualExample, enabled: true } } },
    errors: [INVALID_BODY, { status: 404, code: "ritual_not_found", description: "Rituel inconnu ou d'un autre couple." }, ...memberErrors],
  },
  {
    operationId: "coupleRitualsDelete", method: "delete", path: `${MEMBER_BASE}/${rituals}/{id}`, tag: TAG_AGENDA, audience: "member", permission: null, premium: false, parameters: [idParam("du rituel", 2)],
    summary: "Supprimer un rituel",
    description:
      `${WHO_MEMBER} Supprime le rituel ; il n'est pas recréé (les rituels par défaut ne sont donnés qu'une fois). Un rituel d'un autre couple est un 404. ` +
      "Effets de bord : la ligne et ses rappels futurs disparaissent ; les rappels déjà envoyés restent journalisés.",
    success: { status: 200, description: "Rituel supprimé.", schema: z.object({ deleted: z.literal(true) }), example: { deleted: true } },
    errors: [{ status: 404, code: "ritual_not_found", description: "Rituel inconnu ou d'un autre couple." }, ...memberErrors],
  },
  {
    operationId: "coupleOutings", method: "get", path: `${MEMBER_BASE}/outings`, tag: TAG_OUTINGS, audience: "member", permission: null, premium: false,
    parameters: [{ name: "filter", in: "query", description: "tonight (événements de ce soir), week (7 jours), kosher, cheap (4000 centimes au plus) ou mazl (partenaires et mises en avant). Sans filtre, tout.", required: false, schema: s.outingsQuery, example: "week" }],
    summary: "Les sorties du couple, avec filtres",
    description:
      `${WHO_MEMBER} Réunit les activités (hors celles écartées par le couple) et les événements couples à venir ; « saved » vaut vrai pour une activité enregistrée ou un événement auquel le couple est inscrit. ` +
      "La sortie à la une est un événement mis en avant, sinon une activité partenaire. Effets de bord : aucun.",
    success: { status: 200, description: "La sortie à la une et la liste.", schema: s.outingsDto, example: { featured: ex.outingExample, items: [ex.activityOutingExample] } },
    errors: [INVALID_QUERY, ...memberErrors],
  },
  {
    operationId: "coupleCheckinGet", method: "get", path: `${MEMBER_BASE}/checkin`, tag: TAG_US, audience: "member", permission: null, premium: false, parameters: [],
    summary: "Le bilan du mois du couple",
    description:
      `${WHO_MEMBER} Rend la période (AAAA-MM, heure de Paris), les notes du membre, si l'autre a répondu et, seulement quand les deux ont répondu, une synthèse (nombre de thèmes alignés, thème le plus bas, tendance). ` +
      "Jamais la note de l'autre. Effets de bord : aucun.",
    success: { status: 200, description: "Le bilan du mois.", schema: s.checkinDto, example: ex.checkinOpenExample },
    errors: memberErrors,
  },
  {
    operationId: "coupleCheckinPost", method: "post", path: `${MEMBER_BASE}/checkin`, tag: TAG_US, audience: "member", permission: null, premium: false, parameters: [],
    summary: "Répondre au bilan du mois",
    description:
      `${WHO_MEMBER} Enregistre trois notes de 1 à 5 (parler, temps, proximité), une fois par mois et par membre. Les notes ne sont lisibles ni par l'autre membre ni par l'équipe. ` +
      "Effets de bord : une ligne est écrite ; la synthèse apparaît chez les deux dès que le second a répondu.",
    body: { schema: s.checkinBody, examples: { nominal: { summary: "Trois notes", value: { talk: 4, time: 3, close: 5 } } } },
    success: { status: 200, description: "Le bilan après réponse.", schema: s.checkinDto, example: ex.checkinDoneExample },
    errors: [INVALID_BODY, { status: 409, code: "checkin_already_done", description: "Ce membre a déjà répondu pour ce mois." }, ...memberErrors],
  },
  {
    operationId: "coupleQuestionGet", method: "get", path: `${MEMBER_BASE}/{coupleId}/question`, tag: TAG_US, audience: "member", permission: null, premium: false,
    parameters: [{ name: "coupleId", in: "path", description: "Numéro du couple de l'appelant.", required: true, schema: z.number().int().min(1), example: 12 }],
    summary: "La question du jour",
    description:
      `${WHO_MEMBER} Rend la question du jour du couple dans la langue d'Accept-Language (fr, en, he, es ou ru ; fr par défaut) ; elle est tirée dans une banque de 120 questions, sans répétition tant que la banque n'est pas épuisée. ` +
      "La réponse de l'autre membre est null tant que l'appelant n'a pas répondu. Le champ historique « question » porte la même valeur que « data ». Effets de bord : la question du jour est tirée et enregistrée à la première lecture de la journée.",
    success: { status: 200, description: "La question et les réponses visibles.", schema: s.dailyQuestionDto, example: ex.dailyQuestionExample },
    errors: [{ status: 403, code: "Forbidden", description: "Le couple demandé n'est pas celui de l'appelant." }, UNAUTHORIZED_MEMBER, INTERNAL],
  },
  {
    operationId: "coupleQuestionAnswer", method: "post", path: `${MEMBER_BASE}/{coupleId}/question/{questionId}/answer`, tag: TAG_US, audience: "member", permission: null, premium: false,
    parameters: [
      { name: "coupleId", in: "path", description: "Numéro du couple de l'appelant.", required: true, schema: z.number().int().min(1), example: 12 },
      { name: "questionId", in: "path", description: "Numéro de la question du jour.", required: true, schema: z.number().int().min(1), example: 8 },
    ],
    summary: "Répondre à la question du jour",
    description:
      `${WHO_MEMBER} Enregistre la réponse du membre (1 à 2000 caractères) ; la répondre à nouveau la remplace. ` +
      "Effets de bord : à la première réponse du membre, l'autre reçoit un push (data.type couple_question) sans le texte de la question ni de la réponse.",
    body: { schema: z.object({ answer: z.string().trim().min(1).max(2000) }), examples: { nominal: { summary: "Une réponse", value: { answer: "Le dîner du vendredi." } } } },
    success: { status: 200, description: "Réponse enregistrée.", schema: s.answeredDto, example: { recorded: true } },
    errors: [INVALID_BODY, { status: 403, code: "Forbidden", description: "Le couple demandé n'est pas celui de l'appelant." }, { status: 404, code: "Question not found", description: "Question inconnue ou d'un autre couple." }, UNAUTHORIZED_MEMBER, INTERNAL],
  },
  {
    operationId: "coupleQuestionHistory", method: "get", path: `${MEMBER_BASE}/{coupleId}/questions`, tag: TAG_US, audience: "member", permission: null, premium: false,
    parameters: [{ name: "coupleId", in: "path", description: "Numéro du couple de l'appelant.", required: true, schema: z.number().int().min(1), example: 12 }],
    summary: "L'historique des questions du jour",
    description:
      `${WHO_MEMBER} Rend, du plus récent au plus ancien, les questions auxquelles l'appelant a répondu, avec les deux réponses ; une question sans réponse de l'appelant n'y figure pas. ` +
      "Effets de bord : aucun.",
    success: { status: 200, description: "Les questions répondues.", schema: s.questionHistoryDto, example: { questions: [{ ...ex.answeredQuestionExample, askedAt: "2026-10-26" }] } },
    errors: [{ status: 403, code: "Forbidden", description: "Le couple demandé n'est pas celui de l'appelant." }, UNAUTHORIZED_MEMBER, INTERNAL],
  },
  {
    operationId: "conciergeList", method: "get", path: `${MEMBER_BASE}/concierge`, tag: TAG_CONCIERGE, audience: "member", permission: null, premium: true, parameters: [],
    summary: "Les demandes de conciergerie du couple",
    description: `${WHO_PREMIUM} Liste les demandes des deux membres, la plus récemment active d'abord, avec leur étape (1 reçue, 2 idée choisie, 3 réservée). Effets de bord : aucun.`,
    success: { status: 200, description: "Les demandes.", schema: s.conciergeListDto, example: { requests: [{ id: 31, title: "Dîner casher pour notre anniversaire", status: "proposed", wantedAt: "2026-11-13", updatedAt: "2026-10-27T10:00:05.000Z", step: 1 }] } },
    errors: premiumErrors,
  },
  {
    operationId: "conciergeCreate", method: "post", path: `${MEMBER_BASE}/concierge`, tag: TAG_CONCIERGE, audience: "member", permission: null, premium: true, parameters: [],
    summary: "Faire une demande à la conciergerie",
    description:
      `${WHO_PREMIUM} Crée la demande et appelle l'assistant : jusqu'à 3 idées (statut proposed). Sans assistant, ou si sa réponse est invalide, le statut reste new et un message de l'équipe annonce une réponse prochaine : jamais d'erreur pour le couple. ` +
      "Effets de bord : le texte, la date souhaitée, la ville et les contraintes (cacherout, budget) sont envoyés à un service d'IA ; jamais un nom, un e-mail, un téléphone ni une photo (les e-mails et numéros tapés dans le texte sont masqués). 20 messages par couple et par jour au plus.",
    body: {
      schema: s.createConciergeBody,
      examples: {
        nominal: { summary: "Un dîner", value: { text: "Dîner casher pour notre anniversaire, quelque chose de calme.", wantedAt: "2026-11-13", city: "Paris", kind: "table", kosher: true, budget: "100 euros" } },
        minimal: { summary: "Seulement le texte", value: { text: "Une idée de week-end surprise ?" } },
      },
    },
    success: { status: 201, description: "La demande et la conversation.", schema: s.conciergeDetailDto, example: ex.conciergeDetailExample },
    errors: [INVALID_BODY, RATE_LIMITED, ...premiumErrors],
  },
  {
    operationId: "conciergeGet", method: "get", path: `${MEMBER_BASE}/concierge/{id}`, tag: TAG_CONCIERGE, audience: "member", permission: null, premium: true, parameters: [idParam("de la demande", 31)],
    summary: "Une demande et sa conversation",
    description: `${WHO_PREMIUM} Rend la demande (idées proposées, idée choisie, étape) et tous ses messages (couple, assistant, équipe). « mine » vaut vrai pour les messages de l'appelant. Effets de bord : aucun.`,
    success: { status: 200, description: "La demande.", schema: s.conciergeDetailDto, example: ex.conciergeDetailExample },
    errors: [CONCIERGE_NOT_FOUND, ...premiumErrors],
  },
  {
    operationId: "conciergeMessage", method: "post", path: `${MEMBER_BASE}/concierge/{id}/messages`, tag: TAG_CONCIERGE, audience: "member", permission: null, premium: true, parameters: [idParam("de la demande", 31)],
    summary: "Écrire dans une demande",
    description:
      `${WHO_PREMIUM} Ajoute un message ; l'un ou l'autre membre peut écrire. Tant que la demande est new ou proposed, l'assistant répond et peut proposer de nouvelles idées ; une fois une idée choisie, l'équipe reprend la main. ` +
      "Effets de bord : même envoi limité à l'IA que la création (texte, date, ville, contraintes, jamais d'identité) ; compte dans la limite de 20 messages par jour ; une demande close ou annulée est refusée.",
    body: { schema: s.conciergeMessageBody, examples: { nominal: { summary: "Une précision", value: { text: "Plutôt autour de 80 euros, si possible." } } } },
    success: { status: 201, description: "La demande mise à jour.", schema: s.conciergeDetailDto, example: ex.conciergeDetailExample },
    errors: [INVALID_BODY, CONCIERGE_NOT_FOUND, CONCIERGE_CLOSED, RATE_LIMITED, ...premiumErrors],
  },
  {
    operationId: "conciergeChoose", method: "post", path: `${MEMBER_BASE}/concierge/{id}/choose`, tag: TAG_CONCIERGE, audience: "member", permission: null, premium: true, parameters: [idParam("de la demande", 31)],
    summary: "Choisir une idée proposée",
    description:
      `${WHO_PREMIUM} Retient l'idée d'indice donné (0 à 2) parmi les idées proposées ; le statut passe à chosen. Rien n'est réservé ni payé : l'équipe MAZL confirme et réserve. ` +
      "Effets de bord : la demande apparaît « choisie » dans le back-office de l'équipe ; aucun push.",
    body: { schema: s.chooseBody, examples: { first: { summary: "La première idée", value: { index: 0 } } } },
    success: { status: 200, description: "La demande avec l'idée choisie.", schema: s.conciergeDetailDto, example: { request: { ...ex.conciergeRequestExample, status: "chosen", step: 2, chosenIndex: 0 }, messages: ex.conciergeMessagesExample } },
    errors: [INVALID_BODY, CONCIERGE_NOT_FOUND, CONCIERGE_CLOSED, INVALID_TRANSITION, ...premiumErrors],
  },
  {
    operationId: "conciergeCancel", method: "post", path: `${MEMBER_BASE}/concierge/{id}/cancel`, tag: TAG_CONCIERGE, audience: "member", permission: null, premium: true, parameters: [idParam("de la demande", 31)],
    summary: "Annuler une demande",
    description: `${WHO_PREMIUM} Passe la demande à cancelled ; impossible une fois réservée (409 invalid_transition) ou déjà close (409 concierge_closed). Effets de bord : la demande disparaît de la file active de l'équipe.`,
    success: { status: 200, description: "La demande annulée.", schema: s.conciergeDetailDto, example: { request: { ...ex.conciergeRequestExample, status: "cancelled" }, messages: ex.conciergeMessagesExample } },
    errors: [CONCIERGE_NOT_FOUND, CONCIERGE_CLOSED, INVALID_TRANSITION, ...premiumErrors],
  },
  {
    operationId: "staffConciergeList", method: "get", path: `${STAFF_BASE}/requests`, tag: TAG_STAFF, audience: "staff", permission: "concierge.manage", premium: false,
    parameters: [{ name: "status", in: "query", description: "Ne garder que ce statut : new, proposed, chosen, booked, closed ou cancelled.", required: false, schema: s.staffStatusQuery, example: "chosen" }],
    summary: "La file des demandes de conciergerie",
    description: `${WHO_STAFF} Les 200 demandes les plus récemment actives, avec les prénoms du couple et sa durée en mois, rien d'autre de leur profil. Effets de bord : aucun.`,
    success: { status: 200, description: "Les demandes.", schema: s.staffListDto, example: ex.staffListExample },
    errors: [{ status: 400, code: "invalid_query", description: "status n'est pas un statut connu." }, ...staffErrors],
  },
  {
    operationId: "staffConciergeGet", method: "get", path: `${STAFF_BASE}/requests/{id}`, tag: TAG_STAFF, audience: "staff", permission: "concierge.manage", premium: false, parameters: [idParam("de la demande", 31)],
    summary: "Une demande avec sa conversation",
    description: `${WHO_STAFF} Rend la demande complète (note interne, assignation), le couple (prénoms, durée) et tous les messages. Effets de bord : aucun (les écritures sont auditées, pas les lectures).`,
    success: { status: 200, description: "La demande.", schema: s.staffDetailDto, example: ex.staffDetailExample },
    errors: [{ status: 404, code: "concierge_not_found", description: "Demande inconnue." }, ...staffErrors],
  },
  {
    operationId: "staffConciergePatch", method: "patch", path: `${STAFF_BASE}/requests/{id}`, tag: TAG_STAFF, audience: "staff", permission: "concierge.manage", premium: false, parameters: [idParam("de la demande", 31)],
    summary: "Réserver, clore, annoter ou assigner une demande",
    description:
      `${WHO_STAFF} Passe la demande à booked (seulement si une idée est choisie) ou closed, change la note interne et l'adresse e-mail du collègue assigné (un membre du staff ayant concierge.manage, ou null). ` +
      "Effets de bord : une ligne dans l'audit staff ; les statuts booked et closed s'affichent chez le couple.",
    body: { schema: s.staffPatchBody, examples: { book: { summary: "Réservée", value: { status: "booked", staffNote: "Table confirmée à 20h par téléphone." } }, assign: { summary: "Assigner", value: { assignedTo: "equipe@example.com" } } } },
    success: { status: 200, description: "La demande mise à jour.", schema: s.staffDetailDto, example: ex.staffDetailExample },
    errors: [{ status: 400, code: "invalid_body", message: "assignedTo: staff inconnu", description: "Corps hors schéma, ou collègue inconnu." }, { status: 404, code: "concierge_not_found", description: "Demande inconnue." }, CONCIERGE_CLOSED, INVALID_TRANSITION, ...staffErrors],
  },
  {
    operationId: "staffConciergeMessage", method: "post", path: `${STAFF_BASE}/requests/{id}/messages`, tag: TAG_STAFF, audience: "staff", permission: "concierge.manage", premium: false, parameters: [idParam("de la demande", 31)],
    summary: "Répondre au couple",
    description:
      `${WHO_STAFF} Ajoute un message de l'équipe (1000 caractères au plus) à la conversation. ` +
      "Effets de bord : push aux deux membres (data.type couple_concierge, sans le texte) ; une ligne dans l'audit staff sans le contenu du message.",
    body: { schema: s.staffMessageBody, examples: { nominal: { summary: "Confirmation", value: { text: "Bonjour, nous avons une table à 20h, pouvez-vous confirmer ?" } } } },
    success: { status: 201, description: "La demande avec le nouveau message.", schema: s.staffDetailDto, example: ex.staffDetailExample },
    errors: [{ status: 400, code: "invalid_body", message: "text: Too big", description: "Corps hors schéma ou message de plus de 1000 caractères." }, { status: 404, code: "concierge_not_found", description: "Demande inconnue." }, CONCIERGE_CLOSED, ...staffErrors],
  },
  {
    operationId: "staffConciergeStaff", method: "get", path: `${STAFF_BASE}/staff`, tag: TAG_STAFF, audience: "staff", permission: "concierge.manage", premium: false, parameters: [],
    summary: "Les collègues à qui assigner une demande",
    description: `${WHO_STAFF} Liste l'adresse et le nom des membres du staff actifs qui ont la permission concierge.manage. Effets de bord : aucun.`,
    success: { status: 200, description: "Les collègues.", schema: s.staffMembersDto, example: ex.staffMembersExample },
    errors: staffErrors,
  },
  {
    operationId: "coupleOpenApi", method: "get", path: DOC_PATH, tag: TAG_DOC, audience: "staff", permission: "operations.manage", premium: false, parameters: [],
    summary: "Ce document OpenAPI",
    description: `Qui : administrateur ou super-administrateur (permission operations.manage). Rend la description OpenAPI 3.1 de l'espace couple ; en production la route répond 404 (la carte des routes n'y est pas distribuée). Effets de bord : aucun.`,
    success: { status: 200, description: "Le document OpenAPI.", schema: s.openApiDocument, example: { openapi: "3.1.0" } },
    errors: [{ status: 404, code: "not_found", description: "Désactivée en production." }, ...staffErrors],
  },
];

export const honoPath = (path: string): string => path.replace(/\{(\w+)\}/g, ":$1");
