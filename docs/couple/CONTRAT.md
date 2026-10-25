# Contrat — mode couple

> Source de vérité pour l'activation, la sortie et le contenu du mode couple.
> Un changement ici change l'API : il se fait dans ce fichier d'abord.

## 0. Règles qui ne se négocient pas

1. **Le consentement des deux.** Un couple n'existe que si l'un a envoyé une
   demande et que l'autre l'a acceptée. Aucune route ne crée un couple pour
   quelqu'un d'autre (`POST /api/couple` ne crée plus rien, §2).
2. **Seulement entre deux membres qui ont matché**, et qu'aucun des deux n'a
   bloqué l'autre. Sinon on pourrait harceler n'importe qui avec des demandes.
3. **Le serveur est la vérité.** L'app ne garde en local qu'un cache ; à chaque
   démarrage et à chaque retour au premier plan, elle se recale sur
   `GET /api/couple`. Aucune donnée fictive dans le mode réel : une liste vide
   s'affiche vide.
4. **Une seule navigation à la fois.** En couple, les écrans de rencontre ne
   sont plus accessibles (et réciproquement), garanti par le routeur.

## 1. Forme d'un couple (vue de l'appelant)

```json
{ "id": 12, "partner_id": 45, "partner_name": "Myriam",
  "partner_picture": "<URL signée ou null>", "started_at": "<ISO>",
  "met_on_mazl_at": "<ISO>", "status": "in_relationship" }
```
Rendue par `GET /api/couple` (`{ success, couple: <forme> | null, milestones: [] }`),
par l'acceptation (§2) et dans l'événement `couple:accepted` (§3).
`partner_picture` = photo principale signée (feature media), sinon avatar Google, sinon null.

## 2. Routes

| route | comportement |
|---|---|
| `POST /api/couple` | **403** `{ success:false, error:"couple_request_required" }`. Plus jamais de création unilatérale. |
| `POST /api/couple/request` `{target_user_id}` | 403 `not_matched` si pas de match réciproque ou blocage dans un sens ; règles existantes sinon (soi-même, déjà en couple, demande déjà en attente). 200 `{ success, request: { id, requester_id, target_id, status:"pending", created_at, target_name, target_picture } }`. |
| `GET /api/couple/requests` | inchangé : `{ success, sent: [], received: [] }`. |
| `PUT /api/couple/request/:id` `{action}` | seul le destinataire. `accept` → 200 `{ success, action:"accepted", couple: <forme §1, vue du destinataire> }` ; `reject` → `{ success, action:"rejected" }`. |
| `DELETE /api/couple/request/:id` | seul l'émetteur, inchangé. |
| `DELETE /api/couple/:coupleId` | un des deux membres ; met fin au couple pour les deux. |
| `POST /api/dev/couple/*` | inchangées, 404 en production. |

## 3. Temps réel (WebSocket existant, `sendToUser`) et notifications

| événement | à qui | charge utile |
|---|---|---|
| `couple:request` | destinataire | `{ request: <forme reçue de GET requests> }` |
| `couple:accepted` | émetteur | `{ couple: <forme §1, vue de l'émetteur> }` |
| `couple:rejected` | émetteur | `{ request_id }` |
| `couple:ended` | l'autre membre | `{ couple_id }` |

Notification push (OneSignal, si configuré) à l'arrivée d'une demande et à son
acceptation, adressée à `user_<id>` (l'identifiant de `OneSignal.login`), sans
nom dans le titre (« Nouvelle demande de couple »), le prénom seulement dans le
corps. Le champ `data` ne porte que `type` : `couple_request` ou
`couple_accepted` (V1-CONTRAT §1 ; `couple_question` pour la question du jour).

Côté app, le temps réel n'est qu'un accélérateur : tant qu'une demande est en
attente et que l'app est au premier plan, elle relit `GET /api/couple/requests`
et `GET /api/couple` toutes les 10 s, et au retour au premier plan.

## 4. Parcours dans l'app

1. **Entrées** (Réglages « Activer », bannière des Matchs, profil d'un match) →
   écran de mise en place : choisir un match → **« Envoyer la demande »** →
   état « Demande envoyée à Myriam » avec « Annuler la demande ».
2. **Destinataire** : boîte de dialogue « Myriam souhaite activer le mode couple
   avec vous » (Accepter / Non merci), à l'ouverture, au retour au premier plan
   ou sur l'événement `couple:request`.
3. **Acceptation** : l'app prend le couple de la réponse (aucun second appel),
   archive les autres conversations de l'utilisateur
   (`POST /api/couple/archive-conversations`), montre Mazel Tov puis
   `/couple/activities`. L'émetteur, sur `couple:accepted` (ou au prochain
   recalage), voit Mazel Tov puis `/couple/activities`, et archive aussi ses
   conversations.
4. **Garde du routeur** : en couple, toute route de rencontre (`/discover`,
   `/matches`, `/chat`, `/events`, `/profile`…) redirige vers
   `/couple/activities` ; hors couple, toute route `/couple/*` sauf `/couple/setup`
   redirige vers `/discover`.
5. **Sortie** : Notre Espace → réglages → « Quitter le mode couple » →
   confirmation → `DELETE /api/couple/:id` → `/discover`. En cas d'échec, un
   message, et rien ne change. L'autre membre reçoit `couple:ended` et revient
   aussi au mode rencontre.

## 5. Démo (mode hors ligne)

Le partenaire fictif accepte tout seul : une demande envoyée à un match de démo
passe à « acceptée » 3 s plus tard (`GET /api/couple/requests` et
`GET /api/couple` le reflètent au prochain recalage). Le couple vit ensuite dans
`DemoStore` jusqu'à `DELETE`. Les contenus (activités, événements, dates,
souvenirs, liste de projets, statistiques) répondent avec les formes réelles,
ajouts compris. Aucune route du mode couple ne répond 503 en démo.
