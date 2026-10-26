# Plan de marquage MAZL (mesure d'usage)

Décidé le 2026-10-26. Outil : **OpenPanel auto-hébergé** sur le Coolify Perso de Renaud
(aucun tiers, données sur notre serveur). Contrat commun au serveur (`src/features/analytics/`),
à l'app (`mobile/lib/core/analytics/`) et au site (`web/src/features/analytics/`).

## 1. Principes

1. **Rien ne part sans consentement.** Finalité `analytics`, distincte du consentement
   religieux (art. 9) et des CGU, recueillie dans l'app et sur le site, refusable aussi
   facilement qu'acceptable, retirable dans les réglages. Le serveur vérifie le
   consentement à chaque événement, qu'il vienne de l'app ou de lui-même.
2. **Le serveur est le seul à parler à OpenPanel.** L'app et le site envoient leurs
   événements à `POST /api/analytics/events` ; le serveur filtre (liste blanche stricte),
   pseudonymise et relaie. La clé OpenPanel ne quitte jamais le serveur, et l'app ne
   contacte aucun domaine tiers.
3. **Identifiant pseudonyme.** `profileId` = HMAC-SHA256(`ANALYTICS_ID_KEY`, id du membre),
   32 caractères hexadécimaux. Jamais l'e-mail, le nom, l'id numérique, l'id Apple.
   Une fois le compte supprimé, plus rien ne relie ce pseudonyme à une personne.
4. **Aucune donnée personnelle ni sensible** : jamais le courant, la cacheroute, le Shabbat,
   l'intention, l'orientation, le texte d'un message, une photo, l'id d'un autre membre,
   une position, une adresse IP (le relais envoie `__ip = 127.0.0.1` : pas de
   géolocalisation), un e-mail, un numéro, un jeton.
5. **Liste blanche, pas liste noire.** Un événement inconnu est refusé ; une propriété
   inconnue est retirée ; une valeur hors du format prévu fait refuser l'événement.

## 2. Événements

Propriétés communes ajoutées par le serveur : `platform` (`ios`, `android`, `web`, `server`),
`app_version` (`1.2.3` ou `1.2.3+45`), `env` (`production`, `staging`, `development`).

### Envoyés par l'app ou le site (relais `POST /api/analytics/events`)

| événement | propriétés | quand |
|---|---|---|
| `app_opened` | — | démarrage à froid de l'app (ou ouverture du site) |
| `screen_viewed` | `screen` : NOM de route (`discover`, `chat`…), jamais un chemin avec un id | chaque changement d'écran ; relayé vers l'événement natif `screen_view` d'OpenPanel (`__path` = `/<screen>`), pour ses rapports Pages |
| `onboarding_step_viewed` | `step` (entier 0..30), `step_name` (identifiant) | chaque étape de l'inscription (création du profil) |
| `signup_completed` | — | profil terminé, première arrivée dans l'app |
| `paywall_viewed` | `source` (identifiant de l'écran d'origine) | ouverture de l'écran mazl+ / crédits |
| `purchase_started` | `product_id` (identifiant StoreKit) | appui sur « acheter » |
| `purchase_cancelled` | `product_id` | achat abandonné par le membre |
| `analytics_consent_granted` | — | juste après l'accord (premier événement envoyé) |

Identifiant (`screen`, `step_name`, `source`, `plan_type`, `product`) : `^[a-z][a-zA-Z0-9_]{0,39}$`.
`product_id` : `^[a-z0-9][a-z0-9._]{0,79}$`.

### Émis par le serveur (plus fiable que l'app)

| événement | propriétés | quand |
|---|---|---|
| `swipe` | `action` : `like`, `pass`, `super_like` | `POST /api/swipes` réussi |
| `match_created` | `via` : `like`, `super_like` ; `role` : `initiator` (celui qui swipe en dernier) ou `receiver` | swipe réciproque ; émis pour CHAQUE membre consentant |
| `message_sent` | — | message enregistré (HTTP ou WebSocket) |
| `purchase_validated` | abonnement : `kind` = `subscription`, `product_id`, `plan_type` ; consommable : `kind` = `consumable`, `product` (`super_like`, `boost`) | reçu Apple vérifié par le serveur ; abonnement : achat ou restauration ; consommable : seulement s'il est crédité (un reçu rejoué ne compte pas) |
| `verification_submitted` | `step` : `face` / `identity` ; `outcome` : `approved` / `rejected` | soumission de vérification traitée |

### Ce qu'on en tire dans OpenPanel

- **Écrans vus** : `screen_viewed` par `screen`.
- **Entonnoir d'inscription** : `app_opened` → `onboarding_step_viewed` (step 0..n) → `signup_completed`
  → `swipe` → `match_created` → `message_sent`.
- **Rétention** : jours actifs par `profileId` (cohortes de rétention natives d'OpenPanel).
- **Achats** : `paywall_viewed` → `purchase_started` → `purchase_validated`.
- **Vérification** : `verification_submitted` par `step` et `outcome`.

Les événements serveur sont observés sur les réponses des routes (`src/features/analytics/presentation/server-events.ts`) : les autres features ignorent l'analytique. Les messages passent par le notificateur du chat (HTTP et WebSocket).

## 3. Avant la connexion

Les événements de l'écran d'accueil et de connexion sont gardés **en mémoire seulement**
(100 au plus, jamais sur le disque) et partent avec leur heure d'origine si le membre
accepte la mesure juste après sa connexion. S'il refuse, ou ferme l'app, ils sont perdus.

## 4. Consentement

- Texte versionné côté serveur : finalité `analytics`, version `2026-10-26`
  (`src/features/privacy/domain/consent.ts`).
- `GET /api/privacy/consents` renvoie `religious_data` ET `analytics`.
- `PUT /api/privacy/consents/analytics` `{granted, version, source}` ; un retrait coupe
  l'envoi immédiatement (cache du serveur invalidé, file de l'app vidée).
- Question posée une fois, après la connexion, avec « Accepter » et « Refuser » de même poids ;
  modifiable dans Réglages › Mesure d'audience (app) et Réglages › Confidentialité (site, où la
  question est une bannière qui ne bloque rien).

## 5. iOS

- **App Tracking Transparency non requise** : Apple définit le suivi comme le fait de relier
  des données de l'app à des données d'autres entreprises à des fins publicitaires, ou de les
  partager avec des courtiers en données. Ici : outil auto-hébergé, aucun IDFA, aucun partage,
  aucune publicité, aucun croisement avec d'autres apps ou sites.
- `PrivacyInfo.xcprivacy` : `NSPrivacyCollectedDataTypeProductInteraction`, lié à l'utilisateur
  (pseudonyme), sans suivi, finalité `NSPrivacyCollectedDataTypePurposeAnalytics`.
- App Store Connect, « Confidentialité de l'app » : Données d'usage › Interactions avec le
  produit, Analyse, liées à l'identité, pas de suivi.

## 6. Configuration serveur

| variable | rôle |
|---|---|
| `OPENPANEL_API_URL` | `https://opapi-fsok0kcs8c8s8o08o0csk88g.157.180.43.90.sslip.io` |
| `OPENPANEL_CLIENT_ID` / `OPENPANEL_CLIENT_SECRET` | client d'écriture du projet (stg et prod ont chacun le leur) |
| `ANALYTICS_ID_KEY` | clé du pseudonyme (32 octets aléatoires) ; la changer coupe le lien avec l'historique |

Sans ces variables, l'analytique est désactivée : rien n'est envoyé, l'API répond quand même.
