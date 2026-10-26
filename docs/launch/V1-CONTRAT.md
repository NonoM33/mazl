# Lancement v1 — contrats partagés entre les lots

Décidé par Renaud le 2026-10-25 : v1 sur iOS seul, sans connexion par e-mail,
filtres avancés appliqués par le serveur, retour arrière retiré de l'offre mazl+,
mode Shabbat sans promesse que l'app ne tient pas.

Ce fichier fixe ce que plusieurs lots partagent. Un lot qui a besoin d'en changer
une ligne s'arrête et le signale : il ne la change pas seul.

## 1. Notifications push (OneSignal)

Cible : `include_aliases: { external_id: ["user_<id>"] }` avec
`target_channel: "push"` (API actuelle `https://api.onesignal.com/notifications`,
en-tête `Authorization: Key <clé>`), le même identifiant que
`OneSignal.login('user_<id>')` côté app. Aucun autre format.

Champ `data` de chaque notification, et rien d'autre :

| type | champs | envoyée quand | l'app ouvre |
|---|---|---|---|
| `new_match` | `match_user_id` (nombre), `conversation_id` (nombre ou absent) | un match se forme, aux DEUX membres | `/chat/<conversation_id>` si présent, sinon `/matches` |
| `new_message` | `conversation_id` (nombre) | un message arrive et le destinataire n'a AUCUNE socket ouverte | `/chat/<conversation_id>` |
| `couple_request` | — | demande de couple reçue | `/couple/space` |
| `couple_question` | — | question du jour | `/couple/space` |
| `couple_accepted` | — | demande de couple acceptée | `/couple/space` |
| `new_like` | — | un like reçu qui ne forme pas de match ; au plus une fois toutes les 6 h par membre, jamais le nom de qui a aimé | `/likes` |
| `super_like` | — | un super like reçu qui ne forme pas de match ; une fois par expéditeur, sans son nom | `/likes` |
| `boost_ended` | — | un Boost se termine (balayage chaque minute ; pas pour un Boost fini depuis plus d'une heure) | `/boost` |
| `event_available` / `event_opened` | `event_id` (nombre) | un administrateur annonce un événement publié à une liste de membres (`POST /api/admin/push/event-available`) | `/events/<event_id>`, sinon `/events` |
| `admin_test` | — | push de test d'un administrateur (`POST /api/admin/push/test`) | rien (l'app s'ouvre) |

Le titre et le texte ne contiennent jamais le contenu du message (seulement le
prénom affiché de l'expéditeur), vouvoiement, sans emoji.
Les messages d'une même conversation sont regroupés côté OneSignal
(`collapse_id: "conv-<conversation_id>"`). Un membre bloqué, banni ou inactif ne
déclenche aucune notification.

## 2. Filtres avancés de Découvrir

Les filtres ne vivent PLUS dans le profil. `PUT /api/profile` garde `denomination`,
`kashrutLevel`, `shabbatObservance` pour décrire le membre LUI-MÊME uniquement.

```
GET /api/discover/filters  -> 200 { success: true, filters: Filters, plus: boolean }
PUT /api/discover/filters  body: Filters (partiel accepté, null = effacer le critère)
                           -> 200 { success: true, filters: Filters }
                           -> 400 { success: false, error: "<champ>: <raison>" }
                           -> 402 { success: false, error: "plus_required" } (critère avancé sans mazl+)
                           -> 409 { success: false, error: "religious_consent_required" }
                              (critère religieux sans consentement art. 9 valide)

Filters = {
  denominations:       string[] | null   // valeurs stockées de profiles.denomination
  kashrutLevels:       string[] | null   // valeurs de profiles.kashrut_level
  shabbatObservances:  string[] | null   // valeurs de profiles.shabbat_observance
  onlyVerified:        boolean           // défaut false
  onlyWithPhoto:       boolean           // défaut false
}
```

- Âge, distance et genre recherché restent dans le profil (`ageMin`, `ageMax`,
  `distanceMax`, `lookingFor`) et restent gratuits.
- Tous les critères de `Filters` sont mazl+. Ils sont gardés quand l'abonnement
  expire, mais NE S'APPLIQUENT PAS tant que le membre n'est pas mazl+.
- Un critère religieux posé exclut les candidats qui n'ont pas répondu.
- Pas de critère « études », « taille » ou « en ligne » : le profil ne porte pas
  ces données. L'écran les retire.
- Le retrait du consentement art. 9 efface aussi les critères religieux du membre.

## 3. Likes reçus

`GET /api/likes/received` ajoute `is_premium: boolean` à la racine de la réponse
(vrai si le membre est mazl+). La forme des éléments de `likes` ne change pas.

## 4. Sign in with Apple — révocation

`POST /api/auth/apple` accepte en plus `authorizationCode` (chaîne, optionnel).
Le serveur l'échange contre un refresh token Apple, le garde chiffré, et le
révoque à la suppression du compte. Variables : `APPLE_TEAM_ID`,
`APPLE_SIGNIN_KEY_ID`, `APPLE_SIGNIN_PRIVATE_KEY` (PEM). Absentes : la connexion
marche, la révocation est sautée avec un avertissement, la suppression réussit.

## 5. Session terminée

L'app déconnecte le membre et revient à l'écran de connexion quand :
- une requête authentifiée répond 401, ou 403 avec `error: "account_disabled"` ;
- la WebSocket se ferme avec le code 4001 ou 4003 (elle ne se reconnecte pas).

## 6. Liens publics

| lien | URL |
|---|---|
| Conditions d'utilisation | `https://mazl.app/cgu` |
| Conditions de vente | `https://mazl.app/cgv` |
| Confidentialité | `https://mazl.app/confidentialite` |
| Aide / contact | `mailto:hello@mazl.app` |

## Propriété des fichiers par lot

| lot | branche | possède |
|---|---|---|
| A — serveur : faux profils, push, likes | `v1/serveur` | `src/db.ts` (seed), `src/onesignal.ts`, hooks `onMatch` et envoi de message, `couple-notifier.ts`, `likes-visibility`, tests d'intégration périmés, `scripts/` |
| B — filtres avancés | `v1/filtres` | `src/features/matching/**` sauf `swipe.routes.ts` et `likes-visibility`, `filters_screen.dart`, un client Dart dédié (pas `api_service.dart`) |
| C — connexion et compte | `v1/compte` | `src/features/auth/**`, `src/features/account/**`, `auth_service.dart`, écrans d'auth, `settings_screen.dart`, `api_service.dart`, `websocket_service.dart`, `profile_setup_screen.dart`, `edit_profile_screen.dart` |
| D — offre, Découvrir, façades | `v1/offre` | `premium_screen.dart`, `discover_screen.dart`, `premium_gate.dart`, likes, Shabbat, appel vidéo, `push_notification_service.dart`, couple (liens morts) |
| E — publication iOS | `v1/ios` | `mobile/ios/**`, `mobile/android/**`, `pubspec.yaml`/`pubspec.lock`, `main.dart` |
