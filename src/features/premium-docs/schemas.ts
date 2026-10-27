import { z } from "zod";
import { NOTE_MAX_CHARACTERS } from "../matching/domain/super-like-note";
import { passportSchema } from "../premium-settings/domain/settings";
import { scheduleBodySchema } from "../boost-timing/presentation/boost-timing.routes";

const isoDate = z.iso.datetime({ offset: true });

export const envelope = <T extends z.ZodType>(data: T) => z.object({ success: z.literal(true), data });
export const errorEnvelope = z.object({ success: z.literal(false), error: z.string().describe("Code stable : l'application écrit la phrase, jamais le serveur.") });

// ---------- requests ----------

export { passportSchema, scheduleBodySchema };
export const passportBody = passportSchema.nullable().describe("Une ville à activer, ou null pour revenir à sa ville.");
export const enabledBody = z.object({ enabled: z.boolean().describe("true pour activer, false pour désactiver.") });

export const swipeBody = z.object({
  target_user_id: z.number().int().min(1).describe("Identifiant du membre sur lequel on glisse."),
  action: z.enum(["like", "pass", "super_like"]),
  note: z.string().min(1).max(NOTE_MAX_CHARACTERS).optional().describe(`Le mot d'un Super Like : ${NOTE_MAX_CHARACTERS} caractères au plus, sans lien. Réservé à action = super_like.`),
});

// ---------- responses ----------

export const settingsData = z.object({
  is_plus: z.boolean().describe("L'abonnement mazl+ est actif, d'après le serveur."),
  passport: passportSchema.nullable().describe("Ville du passeport en vigueur ; null si aucun ou si l'abonnement est terminé."),
  incognito: z.boolean().describe("Mode discret en vigueur (mazl+)."),
  send_read_receipts: z.boolean().describe("Le membre envoie ses confirmations de lecture (activé par défaut)."),
});
export const passportData = z.object({ passport: passportSchema.nullable() });
export const incognitoData = z.object({ incognito: z.boolean() });
export const receiptsData = z.object({ send_read_receipts: z.boolean() });

export const undoData = z.object({
  target_user_id: z.number().int().describe("Le membre dont la carte revient dans la pile."),
  action: z.enum(["like", "pass"]).describe("Ce qui vient d'être annulé."),
  remaining_free_undos: z.number().int().min(0).nullable().describe("Retours arrière gratuits restant aujourd'hui ; null = illimité (mazl+)."),
});

export const bestTimeData = z.object({
  city: z.string().nullable().describe("Ville du membre d'après son profil, null sans ville."),
  best_time: z
    .object({
      starts_at: isoDate.describe("Prochaine occurrence de l'heure la plus fréquentée, en UTC."),
      weekday: z.number().int().min(1).max(7).describe("Jour de la semaine, lundi = 1."),
      hour: z.number().int().min(0).max(23).describe("Heure UTC."),
    })
    .nullable()
    .describe("null tant que la ville n'a pas assez de sessions mesurées."),
  scheduled_at: isoDate.nullable().describe("Heure du Boost programmé, null sans programmation."),
});
export const scheduledData = z.object({ scheduled_at: isoDate.nullable() });

const receivedTeaser = z.object({
  display_name: z.string().nullable().describe("Prénom : envoyé pour le client web, que l'application n'affiche pas (« Quelqu'un »)."),
  is_verified: z.boolean(),
  liked_at: isoDate,
  is_super_like: z.boolean(),
  blurredPhotoUrl: z.string().nullable().describe("URL signée de la variante floue de 48 px de large ; null sans photo exploitable."),
});

const receivedFull = z.object({
  user_id: z.number().int(),
  display_name: z.string().nullable(),
  picture: z.string().nullable(),
  age: z.number().int().nullable(),
  is_verified: z.boolean(),
  liked_at: isoDate,
  is_super_like: z.boolean(),
  note: z.string().nullable().describe("Le mot du Super Like, null sans mot."),
});

export const receivedLikesResponse = z.object({
  success: z.literal(true),
  count: z.number().int().min(0).describe("Le vrai nombre de likes reçus."),
  is_premium: z.boolean(),
  likes: z.array(z.union([receivedFull, receivedTeaser])).describe("Fiche complète pour un abonné, aperçu flou pour les autres."),
});

export const swipeResponse = z.object({
  success: z.literal(true),
  match: z.boolean(),
  targetUserId: z.number().int().optional().describe("Présent quand un match se forme."),
  credits: z.unknown().optional().describe("Soldes de crédits, pour un Super Like."),
});

const discoverProfile = z.object({
  user_id: z.number().int(),
  display_name: z.string().nullable(),
  age: z.number().int().nullable(),
  bio: z.string().nullable(),
  location: z.string().nullable(),
  photos: z.array(z.string()),
  super_liked_you: z.boolean().describe("Ce membre vous a envoyé un Super Like."),
  super_like_note: z.string().nullable().describe("Le mot de ce Super Like, null sans mot."),
  traveling_city: z.string().nullable().describe("Ville où le membre voyage avec son passeport (« De passage à X »), null sinon."),
});
export const discoverResponse = z.object({ success: z.literal(true), profiles: z.array(discoverProfile) });

const messageView = z.object({
  id: z.number().int(),
  conversation_id: z.number().int(),
  sender_id: z.number().int(),
  client_id: z.string().nullable(),
  type: z.enum(["text", "photo", "voice"]),
  content: z.string(),
  created_at: isoDate,
  read_at: isoDate.nullable().describe("Quand le message a été lu : renvoyé à son AUTEUR seulement s'il est abonné mazl+ et que le lecteur envoie ses confirmations."),
  is_read: z.boolean().describe("Équivalent booléen de read_at, soumis à la même règle."),
  unsent: z.boolean(),
});
export const messagesResponse = z.object({ success: z.literal(true), messages: z.array(messageView), has_more: z.boolean() });
export const readResponse = z.object({ success: z.literal(true), up_to_id: z.number().int().nullable(), read_at: isoDate.nullable() });

const event = z.object({
  id: z.number().int(),
  title: z.string(),
  date: z.string(),
  price: z.string().describe("Tarif normal, décimal sous forme de texte, dans la devise currency."),
  currency: z.string(),
  member_price_cents: z.number().int().min(0).nullable().describe("Tarif réduit des abonnés mazl+, en centimes de la devise ; null sans tarif membre. Public : il sert à donner envie de s'abonner."),
  is_published: z.boolean(),
});
export const eventsResponse = z.object({ success: z.literal(true), events: z.array(event) });
export const eventResponse = z.object({ success: z.literal(true), event: event.extend({ user_rsvp_status: z.string().nullable(), notify_requested: z.boolean() }), userRsvp: z.unknown().nullable() });

export const adminEventBody = z.object({
  title: z.string().min(1).describe("Titre de l'événement."),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  price: z.number().min(0).optional(),
  currency: z.string().length(3).optional(),
  memberPriceCents: z.number().int().min(0).max(10_000_000).nullable().optional().describe("Tarif membre en centimes, jamais au-dessus du prix ; null le supprime, absent le laisse tel quel."),
  isPublished: z.boolean().optional(),
});
export const adminEventResponse = z.object({ success: z.literal(true), event: event });

export const blurImage = z.string().describe("Octets d'un JPEG de 48 px de large, flou, sans métadonnées.");
