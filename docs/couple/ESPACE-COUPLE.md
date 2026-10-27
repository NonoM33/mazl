# Contrat — espace couple quotidien et MAZL Couple

> Décidé par Renaud le 2026-10-27 : « le plus dur ce n'est pas de trouver l'amour mais de le
> garder : au quotidien l'app doit les aider ». Maquettes validées :
> https://claude.ai/artifact/DpsVNTqb7CVyoHUHQG3FWL (9 écrans). Complète `docs/couple/CONTRAT.md`
> (activation, consentement, routeur) sans le remplacer : ses règles §0 restent vraies.
> Un changement d'API passe par ce fichier d'abord.

## 0. Décisions

1. **Abonnement MAZL Couple : 29,99 €/mois**, produit Apple `com.mazl.app.couple.1m` (groupe
   d'abonnements mazl+, niveau le plus haut), offre web Stripe `couple_1m`
   (`STRIPE_PRICE_COUPLE_1M`). **Un seul des deux paie, les deux en profitent**, et chacun a
   les droits mazl+ tant que l'abonnement couple est actif. Sans abonnement : l'espace couple
   reste visible (Aujourd'hui, Agenda, Sorties, question du jour, bilan) en version limitée ;
   la conciergerie et les rappels push sont réservés à MAZL Couple (402
   `couple_subscription_required`).
2. **Conciergerie = assistant IA + équipe.** L'assistant propose (3 idées max), ne réserve
   jamais rien et n'engage aucun paiement ; l'équipe MAZL confirme et réserve depuis le
   back-office. Sans clé d'IA (`ANTHROPIC_API_KEY` absente) : la demande part directement à
   l'équipe, avec un message « l'équipe vous répond » — jamais d'erreur pour le couple.
3. **Navigation couple : 5 onglets** dans cet ordre : Aujourd'hui (`/couple/today`), Agenda
   (`/couple/agenda`), Sorties (`/couple/outings`), Conciergerie (`/couple/concierge`), Nous deux
   (`/couple/us` : question du jour, bilan, souvenirs, projets, réglages du couple). Les routes
   existantes (`/couple/activities`, `/couple/calendar`, `/couple/events`, `/couple/space`)
   redirigent vers la nouvelle place de leur contenu ; le garde `couple_guard.dart` vise
   `/couple/today`.
4. **Vie privée.**
   - Question du jour : la réponse de l'autre n'est lisible qu'après avoir répondu soi-même.
   - Bilan : chacun répond seul ; le couple ne voit qu'une synthèse quand les deux ont répondu ;
     aucune réponse individuelle n'est montrée à l'autre ; rien n'est visible du staff.
   - Conciergerie : n'est envoyé à l'IA que le texte de la demande, la date souhaitée, la ville et
     les contraintes (cacherout, budget). Jamais de nom complet, d'e-mail, de téléphone, de photo
     ni de données de vérification. Mention dans l'écran : « Vos demandes sont lues par un
     assistant automatique puis par l'équipe MAZL. »
5. **Coût IA borné** : 20 messages assistant par couple et par jour (429 `concierge_rate_limited`),
   réponse ≤ 600 tokens, modèle `claude-sonnet-5-5` (configurable `CONCIERGE_MODEL`).

## 1. Droits

`GET /api/couple` ajoute à la réponse existante :
```json
{ "premium": { "active": true, "paidBy": "partner" | "me" | null, "renewsAt": "<ISO>|null" } }
```
Le serveur calcule `active` à partir des abonnements des DEUX membres (produit
`com.mazl.app.couple.1m` vérifié par la chaîne StoreKit existante, ou abonnement Stripe
`couple_1m`). Les droits mazl+ d'un membre (`/api/auth/me`, likes illimités…) sont aussi vrais si
`premium.active`. `planTypeForProduct` reconnaît `com.mazl.app.couple.1m` → `couple_monthly`.

## 2. Aujourd'hui — `GET /api/couple/today`

```json
{ "success": true, "data": {
  "days": 214, "partner": { "id": 45, "name": "David", "picture": "<URL signée|null>" },
  "question": { "id": 8, "text": "…", "myAnswered": false, "partnerAnswered": true },
  "upcoming": [ { "kind": "date" | "ritual" | "event", "title": "…", "at": "<ISO>", "subtitle": "…", "refId": 3 } ],
  "outing": null | { <forme Sortie §4> },
  "mood": { "mine": null | "great" | "good" | "meh" | "talk", "partner": null | "great"|"good"|"meh"|"talk" },
  "checkin": { "due": true, "period": "2026-11" },
  "premium": { <§1> }
} }
```
- `upcoming` : les 5 prochains éléments sur 45 jours (dates du couple, rituels, inscriptions
  aux événements). Les fêtes juives restent calculées dans l'app (kosher_dart), pas ici.
- `POST /api/couple/mood` `{ "mood": "great"|"good"|"meh"|"talk" }` : humeur du jour du membre.
  « talk » (« On doit parler ») envoie à l'autre un push doux sans texte libre.

## 3. Agenda et rituels

- Dates : routes existantes `/api/couple/dates` (GET, POST, PUT, DELETE), avec `remind_days_before`.
- Rituels : table `couple_rituals` (`id, couple_id, kind: "shabbat"|"weekly"|"custom", title,
  weekday 0-6 | null, time "HH:MM" | null, enabled bool, remind_minutes int`, créés par défaut à
  la formation du couple : Shabbat ensemble activé, Soirée sans écran (mardi) et Appeler les
  parents (dimanche) désactivés).
  - `GET /api/couple/rituals` → `{ success, data: { rituals: [...] } }`
  - `POST /api/couple/rituals`, `PATCH /api/couple/rituals/:id`, `DELETE /api/couple/rituals/:id`.
- **Rappels** (MAZL Couple seulement) : une tâche toutes les 60 s envoie un push aux DEUX membres
  pour (a) une date dont la veille ou `remind_days_before` arrive, (b) un rituel activé
  `remind_minutes` avant. Shabbat : l'heure d'allumage est calculée côté serveur (kosher-zmanim)
  pour la ville du couple (celle du membre qui a créé le couple), sinon Paris. Table
  `couple_reminders_sent` pour ne jamais envoyer deux fois. Titre de push sans nom ni détail
  intime. `data.type = "couple_reminder"`, `data.route = "/couple/agenda"`.

## 4. Sorties — `GET /api/couple/outings?filter=tonight|week|kosher|cheap|mazl`

```json
{ "success": true, "data": { "featured": <Sortie|null>, "items": [ <Sortie> ] } }
```
Sortie : `{ "id", "kind": "activity"|"event", "title", "subtitle", "imageUrl", "city", "startsAt": "<ISO>|null", "priceCents": int|null, "kosher": bool, "saved": bool }`.
Source : `couple_activities` et `couple_events` existants. Sauvegarde : routes existantes
`/api/couple/activities/:id/save`. Les faux contenus de la phase TestFlight (12 activités,
6 événements couples, photos Unsplash libres vérifiées, coordonnées de quartier) sont écrits par
la graine `SEED_TEST_PROFILES` comme les faux événements, et retirés par la purge.

## 5. Question du jour

- Banque de 120 questions en 5 langues (fr, en, he, es, ru), une par jour et par couple, sans
  répétition tant que la banque n'est pas épuisée (remplace les 10 questions en dur).
- `GET /api/couple/:coupleId/question` renvoie `{ id, text, myAnswer, partnerAnswer }` où
  `partnerAnswer` est `null` tant que l'appelant n'a pas répondu ; `text` dans la langue
  d'`Accept-Language`.
- Quand un membre répond, push à l'autre (`data.type = "couple_question"`, sans le texte).
- `GET /api/couple/:coupleId/questions` : historique (les deux réponses, seulement les questions
  où l'appelant a répondu).

## 6. Bilan du couple (mensuel)

- `GET /api/couple/checkin` → `{ period: "2026-11", mine: null | {talk,time,close}, partnerDone: bool, summary: null | { aligned: 0..3, lowest: "talk"|"time"|"close", trend: "up"|"down"|"same"|null } }`.
- `POST /api/couple/checkin` `{ talk: 1..5, time: 1..5, close: 1..5 }` (une fois par mois et par
  membre ; 409 `checkin_already_done`).
- `summary` n'existe que si les deux ont répondu. « aligned » = nombre de thèmes où les deux
  notes diffèrent d'au plus 1. Jamais les notes de l'autre.

## 7. Conciergerie

Tables : `concierge_requests` (`id, couple_id, created_by, title, brief, wanted_at date|null,
city, constraints jsonb, status: "new"|"proposed"|"chosen"|"booked"|"closed"|"cancelled",
options jsonb [{ title, details, priceHint }], chosen_index int|null, staff_note, assigned_to,
created_at, updated_at`) et `concierge_messages` (`id, request_id, role: "member"|"assistant"|"staff",
author_id|null, text, created_at`).

Routes couple (MAZL Couple, 402 sinon) :
| route | effet |
|---|---|
| `GET /api/couple/concierge` | `{ requests: [{ id, title, status, wantedAt, updatedAt, step: 1..3 }] }` (étapes : reçue, idée choisie, réservée) |
| `POST /api/couple/concierge` `{ text, wantedAt?, city?, kind?: "table"|"surprise"|"gift"|"weekend"|"other" }` | crée la demande, appelle l'assistant → `{ request, messages }` (options proposées, statut `proposed`) ; sans IA → statut `new` et message de l'équipe |
| `GET /api/couple/concierge/:id` | `{ request, messages }` |
| `POST /api/couple/concierge/:id/messages` `{ text }` | message du membre ; l'assistant répond (nouvelles options possibles) |
| `POST /api/couple/concierge/:id/choose` `{ index }` | le couple choisit une idée → statut `chosen`, l'équipe est notifiée (back-office) |
| `POST /api/couple/concierge/:id/cancel` | statut `cancelled` |

Les deux membres voient et écrivent dans les mêmes demandes. L'assistant : sortie JSON validée
par zod `{ reply: string ≤ 600 car., options: [{ title, details, priceHint }] (0..3) }` ; toute
sortie invalide → message de repli et statut `new`. Le prompt système interdit de promettre une
réservation, un prix exact ou une disponibilité, et rappelle les contraintes casher.

Routes staff (`/api/backoffice/concierge/...`, permission `concierge.manage` : admin et
super-admin ; audit staff sur chaque écriture) : `GET requests?status=`, `GET requests/:id`,
`PATCH requests/:id` `{ status?, staffNote?, assignedTo? }`, `POST requests/:id/messages` `{ text }`
(message `staff`, push au couple `data.type = "couple_concierge"`). Le staff voit le prénom des
deux membres, la durée du couple et la conversation, rien d'autre de leur profil.

## 8. App

- Écrans selon les maquettes, 100 % iPhone Duo (`~/.claude/regles/iphone-duo.md`), clair/sombre,
  5 langues, retour en haut de la colonne.
- Écran MAZL Couple (paywall) : prix StoreKit de `com.mazl.app.couple.1m`, achat natif, puis
  vérification serveur existante ; restaurer.
- Push : `couple_reminder` → `/couple/agenda`, `couple_question` → `/couple/us`,
  `couple_concierge` → `/couple/concierge`.
