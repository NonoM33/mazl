import { z } from "zod";
import * as ex from "./examples";
import * as s from "./schemas";
import type { ErrorSpec, OperationSpec } from "./types";

// The routes of docs/premium/MONETISATION.md and the existing routes whose answers changed.

const UNAUTHORIZED: ErrorSpec = { status: 401, code: "No token provided", description: "Pas de jeton de connexion valide, ou compte désactivé (account_disabled)." };
const INTERNAL: ErrorSpec = { status: 500, code: "internal_error", description: "Erreur inattendue du serveur (détail dans les journaux, jamais dans la réponse)." };
const INVALID_BODY: ErrorSpec = { status: 400, code: "invalid_body", description: "Le corps n'est pas du JSON valide ou ne respecte pas le schéma." };
const PLUS_REQUIRED: ErrorSpec = { status: 402, code: "mazl_plus_required", description: "La fonction est réservée aux abonnés mazl+." };
const RATE_LIMITED: ErrorSpec = { status: 429, code: "rate_limited", description: "Trop de requêtes : réessayer après Retry-After secondes." };

const memberCommon = [UNAUTHORIZED, INTERNAL] as const;
const idParam = (name: string, example: number, description: string) => ({ name, in: "path" as const, description, required: true, schema: z.coerce.number().int().min(1), example });

export const OPERATIONS: readonly OperationSpec[] = [
  {
    operationId: "getPremiumSettings", method: "get", path: "/api/premium/settings", tag: "Réglages mazl+",
    summary: "Lire les réglages mazl+ du membre, tels que le serveur les applique",
    description:
      "Qui : tout membre connecté, pour ses propres réglages uniquement. Le serveur dit ce qui est en vigueur : un passeport ou un mode discret " +
      "gardés d'un abonnement terminé sont rendus comme inactifs (passport null, incognito false) jusqu'au retour de mazl+. L'application ne garde aucun réglage mazl+ de son côté. " +
      "Aucun effet de bord.",
    auth: "member", parameters: [],
    success: { status: 200, description: "Les réglages en vigueur.", schema: s.settingsData, enveloped: true, example: ex.settingsPlus },
    errors: [...memberCommon],
  },
  {
    operationId: "setPassport", method: "put", path: "/api/discover/passport", tag: "Réglages mazl+",
    summary: "Choisir une autre ville pour Découvrir (passeport), ou revenir à la sienne",
    description:
      "Qui : un abonné mazl+ pour activer une ville ; tout membre pour revenir à sa ville (corps null), même après la fin de l'abonnement. " +
      "Le passeport ne change pas la ville affichée du membre : Découvrir le cherche là où il voyage, et les autres lisent « De passage à X » sur son profil (traveling_city). " +
      "Le serveur ignore le passeport dès que l'abonnement n'est plus actif. Effets de bord : écrit la ville choisie (centre-ville, pas une position du membre) ; limité à 60 écritures par heure.",
    auth: "member", parameters: [],
    body: { schema: s.passportBody, examples: { activate: { summary: "Aller à Tel-Aviv", value: ex.passport }, home: { summary: "Revenir à sa ville", value: null } } },
    success: { status: 200, description: "Le passeport en vigueur après l'écriture.", schema: s.passportData, enveloped: true, example: { passport: ex.passport } },
    errors: [INVALID_BODY, UNAUTHORIZED, PLUS_REQUIRED, RATE_LIMITED, INTERNAL],
  },
  {
    operationId: "setIncognito", method: "put", path: "/api/profile/incognito", tag: "Réglages mazl+",
    summary: "Activer ou couper le mode discret",
    description:
      "Qui : un abonné mazl+ pour l'activer ; tout membre pour le couper. En mode discret, seules les personnes que le membre a aimées le voient dans Découvrir " +
      "(le filtre est côté serveur, dans la sélection des candidats). Il cesse d'agir quand l'abonnement se termine. Effets de bord : écrit le réglage ; limité à 60 écritures par heure.",
    auth: "member", parameters: [],
    body: { schema: s.enabledBody, examples: { on: { summary: "Activer", value: { enabled: true } }, off: { summary: "Couper", value: { enabled: false } } } },
    success: { status: 200, description: "Le réglage après l'écriture.", schema: s.incognitoData, enveloped: true, example: { incognito: true } },
    errors: [INVALID_BODY, UNAUTHORIZED, PLUS_REQUIRED, RATE_LIMITED, INTERNAL],
  },
  {
    operationId: "setReadReceipts", method: "put", path: "/api/profile/read-receipts", tag: "Réglages mazl+",
    summary: "Envoyer ou non ses confirmations de lecture",
    description:
      "Qui : tout membre, abonné ou non, pour son propre réglage (activé par défaut). Quand il est coupé, personne ne voit quand ce membre lit ses messages, même un abonné. " +
      "Voir « Lu à » : GET /api/conversations/{id}/messages. Effets de bord : écrit le réglage ; limité à 60 écritures par heure.",
    auth: "member", parameters: [],
    body: { schema: s.enabledBody, examples: { off: { summary: "Ne plus envoyer", value: { enabled: false } }, on: { summary: "Envoyer", value: { enabled: true } } } },
    success: { status: 200, description: "Le réglage après l'écriture.", schema: s.receiptsData, enveloped: true, example: { send_read_receipts: false } },
    errors: [INVALID_BODY, UNAUTHORIZED, RATE_LIMITED, INTERNAL],
  },
  {
    operationId: "undoSwipe", method: "post", path: "/api/swipes/undo", tag: "Découverte",
    summary: "Reprendre le dernier passage ou like (retour arrière)",
    description:
      "Qui : tout membre pour ses propres choix. Un seul retour arrière gratuit par jour (compté par le serveur), illimité avec mazl+. Seul le dernier choix des dix dernières minutes peut être repris, " +
      "jamais un Super Like (payé) ni un like qui a formé un match. Le like repris ne rend pas le like du jour : le renvoyer à la même personne reste gratuit. " +
      "Effets de bord : supprime le choix enregistré ; consomme le retour gratuit du jour ; limité à 20 appels par minute.",
    auth: "member", parameters: [],
    success: { status: 200, description: "Le membre dont la carte revient, et les retours gratuits restants.", schema: s.undoData, enveloped: true, example: ex.undone },
    errors: [
      UNAUTHORIZED,
      { status: 402, code: "undo_limit_reached", description: "Le retour arrière gratuit du jour est utilisé." },
      { status: 404, code: "nothing_to_undo", description: "Aucun choix récent à reprendre." },
      { status: 409, code: "undo_not_possible", description: "Le dernier choix est un Super Like, ou il a formé un match." },
      RATE_LIMITED, INTERNAL,
    ],
  },
  {
    operationId: "getBoostBestTime", method: "get", path: "/api/boost/best-time", tag: "Boost",
    summary: "Connaître le meilleur moment pour lancer un Boost dans sa ville",
    description:
      "Qui : tout membre connecté, pour sa propre ville (celle de son profil) et sa propre programmation. L'affluence est un compteur de sessions par ville, jour et heure (UTC), sans aucun membre dedans ; " +
      "best_time reste null tant que la ville a moins de 50 sessions, pour ne pas désigner quelques personnes. Aucun effet de bord.",
    auth: "member", parameters: [],
    success: { status: 200, description: "La ville, le prochain meilleur moment et la programmation éventuelle.", schema: s.bestTimeData, enveloped: true, example: ex.bestTime },
    errors: [...memberCommon],
  },
  {
    operationId: "scheduleBoost", method: "post", path: "/api/boost/schedule", tag: "Boost",
    summary: "Programmer un Boost à une heure choisie",
    description:
      "Qui : tout membre qui a un Boost à dépenser (inclus mazl+ du jour ou acheté). Une seule programmation à la fois, entre 2 minutes et 7 jours devant. Le crédit n'est PAS pris maintenant : la tâche " +
      "de la minute le prend à l'heure dite, démarre le Boost et envoie une notification ; sans Boost à ce moment-là, rien n'est débité et le membre en est prévenu. " +
      "Effets de bord : écrit la programmation ; notification push à l'heure ; limité à 30 écritures par heure.",
    auth: "member", parameters: [],
    body: { schema: s.scheduleBodySchema, examples: { saturday: { summary: "Samedi 21 h UTC", value: { at: ex.at } } } },
    success: { status: 201, description: "La programmation enregistrée.", schema: s.scheduledData, enveloped: true, example: { scheduled_at: ex.at } },
    errors: [
      INVALID_BODY, UNAUTHORIZED,
      { status: 400, code: "invalid_time", description: "L'heure est passée, trop proche (moins de 2 minutes) ou à plus de 7 jours." },
      { status: 402, code: "boosts_exhausted", description: "Aucun Boost à dépenser." },
      { status: 409, code: "already_scheduled", description: "Un Boost est déjà programmé : l'annuler d'abord." },
      RATE_LIMITED, INTERNAL,
    ],
  },
  {
    operationId: "cancelBoostSchedule", method: "delete", path: "/api/boost/schedule", tag: "Boost",
    summary: "Annuler son Boost programmé",
    description:
      "Qui : tout membre, pour sa propre programmation seulement (celle d'un autre membre n'est ni lue ni touchée). Sans programmation, l'appel réussit sans rien changer. " +
      "Effets de bord : supprime la programmation en attente ; limité à 30 écritures par heure.",
    auth: "member", parameters: [],
    success: { status: 200, description: "Plus de programmation.", schema: s.scheduledData, enveloped: true, example: { scheduled_at: null } },
    errors: [UNAUTHORIZED, RATE_LIMITED, INTERNAL],
  },
  {
    operationId: "getReceivedLikes", method: "get", path: "/api/likes/received", tag: "Likes",
    summary: "Lire les likes reçus : fiches complètes pour un abonné, aperçu flou sinon",
    description:
      "Qui : tout membre connecté, pour les likes qu'il a reçus (ni matchés, ni bloqués). Le serveur décide : un non-abonné ne reçoit JAMAIS l'identifiant du membre, son âge, ni l'URL de sa photo nette, " +
      "seulement le badge, l'ancienneté, le prénom (pour le client web), is_super_like et l'URL signée d'une variante floue de 48 px (blurredPhotoUrl) ; count reste le vrai nombre. " +
      "Un abonné reçoit la fiche complète et, pour un Super Like, son mot. Aucun effet de bord.",
    auth: "member", parameters: [],
    success: { status: 200, description: "Le nombre réel, l'état d'abonnement et les likes.", schema: s.receivedLikesResponse, enveloped: false, example: ex.receivedPlus },
    errors: [...memberCommon],
  },
  {
    operationId: "swipe", method: "post", path: "/api/swipes", tag: "Découverte",
    summary: "Aimer, passer ou envoyer un Super Like, avec un mot facultatif",
    description:
      "Qui : tout membre, sur un membre actif non bloqué (sinon 404). Un like coûte un des likes du jour (10 sans abonnement, illimité avec mazl+) ; un Super Like coûte un crédit Super Like. " +
      "Le mot (note, 140 caractères, sans lien, comme un message) n'est permis qu'avec super_like et est vérifié avant tout débit ; il s'affiche sur la carte du destinataire dans Découvrir. " +
      "Effets de bord : écrit le choix (remplace le précédent sur la même personne) ; débite un crédit ; crée un match et ses notifications ; notification push au destinataire d'un like.",
    auth: "member", parameters: [],
    body: {
      schema: s.swipeBody,
      examples: { like: { summary: "Un like", value: { target_user_id: 41, action: "like" } }, word: { summary: "Un Super Like avec un mot", value: { target_user_id: 41, action: "super_like", note: "Votre sourire au Shabbat des jeunes" } } },
    },
    success: { status: 200, description: "Le choix est enregistré ; match dit si un match se forme.", schema: s.swipeResponse, enveloped: false, example: { success: true, match: false } },
    errors: [
      { status: 400, code: "invalid_note", description: "Le mot est vide, de plus de 140 caractères, contient un lien ou un caractère de contrôle." },
      { status: 400, code: "note_requires_super_like", description: "Un mot n'est permis qu'avec action = super_like." },
      UNAUTHORIZED,
      { status: 402, code: "likes_exhausted", description: "Les likes du jour sont partis (corps : allowance)." },
      { status: 402, code: "super_likes_exhausted", description: "Plus de Super Like à dépenser (corps : credits)." },
      { status: 404, code: "User not found", description: "Le membre n'existe pas, est fermé ou bloqué dans un sens ou l'autre." },
      INTERNAL,
    ],
  },
  {
    operationId: "discover", method: "get", path: "/api/discover", tag: "Découverte",
    summary: "Lire la pile de Découvrir, classée par le serveur",
    description:
      "Qui : tout membre au profil complet (sinon 409 profile_incomplete). Le serveur classe : les likes des abonnés mazl+ passent en premier sans fausser le reste du classement, " +
      "le passeport du viewer (mazl+) déplace la recherche, les membres en mode discret n'apparaissent qu'à ceux qu'ils ont aimés. Chaque profil dit si le membre vous a envoyé un Super Like " +
      "(super_liked_you, super_like_note) et s'il voyage (traveling_city). Effets de bord : la première page compte une session par heure dans la ville du membre (compteur anonyme pour le Boost).",
    auth: "member",
    parameters: [
      { name: "limit", in: "query", description: "Nombre de profils demandés (20 par défaut, 50 au plus).", required: false, schema: z.coerce.number().int().min(1).max(50), example: 20 },
      { name: "offset", in: "query", description: "Rang du premier profil de la page.", required: false, schema: z.coerce.number().int().min(0), example: 0 },
    ],
    success: { status: 200, description: "Une page de la pile.", schema: s.discoverResponse, enveloped: false, example: { success: true, profiles: [ex.discoverProfile] } },
    errors: [UNAUTHORIZED, { status: 409, code: "profile_incomplete", description: "Le profil n'a pas son genre ni ce que le membre cherche." }, RATE_LIMITED, INTERNAL],
  },
  {
    operationId: "getBlurredPhoto", method: "get", path: "/media/photos/{photoId}/blur", tag: "Médias",
    summary: "Récupérer la variante floue d'une photo de profil",
    description:
      "Qui : toute personne qui détient l'URL signée ; la signature est l'identifiant (aucune session). C'est la seule image qu'un non-abonné reçoit d'un membre qui l'a aimé. " +
      "Le serveur la fabrique : 48 px de large, flou gaussien fort, JPEG d'environ 2 Ko sans métadonnées, impossible à reconstituer. Toute demande refusée (signature fausse, périmée, photo supprimée) répond 404 pareil. " +
      "La signature de la photo nette n'ouvre pas la variante floue, ni l'inverse. Aucun effet de bord (variante gardée en mémoire dix minutes).",
    auth: "signature",
    parameters: [
      idParam("photoId", 12, "Identifiant de la photo, tel que l'URL signée le porte."),
      { name: "exp", in: "query", description: "Expiration de la signature, en secondes depuis 1970.", required: true, schema: z.coerce.number().int(), example: 1800000000 },
      { name: "sig", in: "query", description: "Signature HMAC de l'URL, en base64url.", required: true, schema: z.string().min(1), example: "exemple-de-signature" },
    ],
    success: { status: 200, description: "Le JPEG flou (image/jpeg).", schema: s.blurImage, enveloped: false, example: "(octets JPEG)", image: true },
    errors: [{ status: 404, code: "Not found", description: "Signature invalide ou périmée, ou photo absente.", body: { error: "Not found" } }],
  },
  {
    operationId: "listMessages", method: "get", path: "/api/conversations/{id}/messages", tag: "Chat",
    summary: "Lire les messages d'une conversation, avec « Lu à » pour les abonnés",
    description:
      "Qui : les deux membres de la conversation seulement (les autres reçoivent 404). read_at et is_read d'un message ne sont renvoyés à son AUTEUR que s'il est abonné mazl+ et que l'autre membre " +
      "n'a pas coupé ses confirmations de lecture ; sinon read_at vaut null et is_read false. L'heure de lecture est gardée dans tous les cas. Aucun effet de bord.",
    auth: "member",
    parameters: [
      idParam("id", 10, "Identifiant de la conversation."),
      { name: "before", in: "query", description: "Ne renvoyer que les messages d'identifiant inférieur.", required: false, schema: z.coerce.number().int().min(1), example: 300 },
      { name: "limit", in: "query", description: "Nombre de messages (30 par défaut, 50 au plus).", required: false, schema: z.coerce.number().int().min(1).max(50), example: 30 },
    ],
    success: { status: 200, description: "Une page de messages, du plus récent au plus ancien.", schema: s.messagesResponse, enveloped: false, example: { success: true, messages: [ex.message], has_more: false } },
    errors: [UNAUTHORIZED, { status: 404, code: "Not found", description: "La conversation n'existe pas ou le membre n'en fait pas partie." }, INTERNAL],
  },
  {
    operationId: "markConversationRead", method: "put", path: "/api/conversations/{id}/read", tag: "Chat",
    summary: "Marquer les messages reçus comme lus",
    description:
      "Qui : les deux membres de la conversation, pour les messages que l'AUTRE a écrits. L'heure de lecture est enregistrée. L'auteur n'en est informé (événement WebSocket chat:read) que s'il est abonné mazl+ " +
      "et que le lecteur envoie ses confirmations ; les appareils du lecteur le sont toujours, pour effacer leurs pastilles. Effets de bord : écrit read_at ; événement WebSocket ; limité par minute.",
    auth: "member",
    parameters: [idParam("id", 10, "Identifiant de la conversation.")],
    success: { status: 200, description: "Jusqu'à quel message la lecture est enregistrée.", schema: s.readResponse, enveloped: false, example: { success: true, up_to_id: 301, read_at: "2026-10-27T21:04:00.000Z" } },
    errors: [UNAUTHORIZED, { status: 404, code: "Not found", description: "La conversation n'existe pas ou le membre n'en fait pas partie." }, RATE_LIMITED, INTERNAL],
  },
  {
    operationId: "listEvents", method: "get", path: "/api/events", tag: "Événements",
    summary: "Lister les événements publiés, avec leur tarif membre",
    description:
      "Qui : publique, sans connexion. member_price_cents est le tarif réduit des abonnés mazl+ (centimes de la devise de l'événement, null sans tarif membre) : il est public, c'est l'argument pour s'abonner. " +
      "Seuls les événements publiés sont rendus. Aucun effet de bord.",
    auth: "optionalMember",
    parameters: [
      { name: "from", in: "query", description: "Date de début, AAAA-MM-JJ (aujourd'hui par défaut).", required: false, schema: z.string().regex(/^\d{4}-\d{2}-\d{2}$/), example: "2031-01-01" },
      { name: "limit", in: "query", description: "Nombre d'événements (50 au plus).", required: false, schema: z.coerce.number().int().min(1).max(50), example: 50 },
    ],
    success: { status: 200, description: "Les événements.", schema: s.eventsResponse, enveloped: false, example: { success: true, events: [ex.event] } },
    errors: [{ status: 400, code: "from: must be a valid YYYY-MM-DD date", description: "La date from n'est pas une date valide." }, INTERNAL],
  },
  {
    operationId: "getEvent", method: "get", path: "/api/events/{id}", tag: "Événements",
    summary: "Lire un événement publié, avec son tarif membre",
    description:
      "Qui : publique ; un jeton de connexion facultatif ajoute l'inscription et l'alerte du membre (user_rsvp_status, notify_requested). Un brouillon répond comme un identifiant inconnu (404). " +
      "member_price_cents : tarif réduit des abonnés mazl+, public. Aucun effet de bord.",
    auth: "optionalMember", parameters: [idParam("id", 5, "Identifiant de l'événement.")],
    success: { status: 200, description: "L'événement.", schema: s.eventResponse, enveloped: false, example: { success: true, event: { ...ex.event, user_rsvp_status: null, notify_requested: false }, userRsvp: null } },
    errors: [{ status: 400, code: "Invalid event id", description: "L'identifiant n'est pas un nombre entier positif." }, { status: 404, code: "Event not found", description: "L'événement n'existe pas ou n'est pas publié." }, INTERNAL],
  },
  {
    operationId: "createEvent", method: "post", path: "/api/admin/events", tag: "Administration des événements",
    summary: "Créer un événement, avec un tarif membre facultatif",
    description:
      "Qui : un administrateur (jeton de /api/admin/login). memberPriceCents est un nombre entier de centimes, jamais au-dessus du prix, sinon 400 member_price_invalid. " +
      "Effets de bord : crée l'événement (brouillon sauf isPublished).",
    auth: "admin", parameters: [],
    body: { schema: s.adminEventBody, examples: { paying: { summary: "Un Shabbat payant à tarif membre", value: { title: "Shabbat Exemple", date: "2031-01-01", price: 12.5, currency: "EUR", memberPriceCents: 800, isPublished: true } } } },
    success: { status: 200, description: "L'événement créé.", schema: s.adminEventResponse, enveloped: false, example: { success: true, event: ex.event } },
    errors: [
      { status: 400, code: "member_price_invalid", description: "Le tarif membre n'est pas un entier de centimes, ou dépasse le prix." },
      { status: 400, code: "Title and date required", description: "Le titre ou la date manque." },
      { status: 401, code: "Unauthorized", description: "Pas de session administrateur valide." }, INTERNAL,
    ],
  },
  {
    operationId: "updateEvent", method: "put", path: "/api/admin/events/{id}", tag: "Administration des événements",
    summary: "Modifier un événement, dont son tarif membre",
    description:
      "Qui : un administrateur. Seuls les champs envoyés changent ; memberPriceCents null supprime le tarif membre, absent le laisse tel quel, et il est comparé au prix que l'événement aura après la modification. " +
      "Effets de bord : met à jour l'événement.",
    auth: "admin", parameters: [idParam("id", 5, "Identifiant de l'événement.")],
    body: { schema: s.adminEventBody.partial(), examples: { memberPrice: { summary: "Fixer le tarif membre à 8 €", value: { memberPriceCents: 800 } }, remove: { summary: "Supprimer le tarif membre", value: { memberPriceCents: null } } } },
    success: { status: 200, description: "L'événement modifié.", schema: s.adminEventResponse, enveloped: false, example: { success: true, event: ex.event } },
    errors: [
      { status: 400, code: "member_price_invalid", description: "Le tarif membre n'est pas un entier de centimes, ou dépasse le prix." },
      { status: 401, code: "Unauthorized", description: "Pas de session administrateur valide." },
      { status: 404, code: "Not found", description: "L'événement n'existe pas." }, INTERNAL,
    ],
  },
];
