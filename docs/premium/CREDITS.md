# Boosts et Super Likes : crédits tenus par le serveur

Contrat du 2026-10-24. Le serveur seul décide si un boost ou un super like peut
partir. L'app affiche ce que le serveur lui dit et n'accorde jamais rien d'elle-même.

## Règles

| type | inclus par jour, gratuit | inclus par jour, mazl+ | ensuite |
|---|---|---|---|
| `super_like` | 1 | 5 | crédits achetés |
| `boost` | 0 | 1 | crédits achetés |

- **mazl+** : une ligne `subscriptions` dont le statut est `active` et dont
  `expires_at` est dans le futur, au moment de la demande.
- **Jour** : jour calendaire du serveur (`DATE_TRUNC('day', NOW())`), comme le
  comptage des boosts existant.
- **Ordre de débit** : l'allocation du jour d'abord, les crédits achetés ensuite.
  Les crédits achetés n'expirent pas.
- **Rien de disponible** : HTTP 402, avec `error` à `super_likes_exhausted` ou à
  `boosts_exhausted`, plus le solde à jour (`credits`).
- **Boost déjà actif** : HTTP 409, `error: "boost_already_active"`. Rien n'est débité.
- **Super like rejoué** : une deuxième demande de super like vers la même
  personne, alors que le swipe enregistré est déjà un `super_like`, ne débite rien.
  L'app peut donc rejouer sans risque.
- **Échec après débit** : si l'enregistrement du swipe ou du boost échoue après le
  débit, le débit est annulé.
- **Concurrence** : deux demandes simultanées ne peuvent pas dépenser le même
  crédit. Le débit verrouille la ligne de solde (`SELECT … FOR UPDATE`) dans une
  transaction.

## Produits (App Store Connect, type Consommable)

| product id | type | quantité |
|---|---|---|
| `com.mazl.app.boost.1` | `boost` | 1 |
| `com.mazl.app.boost.3` | `boost` | 3 |
| `com.mazl.app.superlikes.5` | `super_like` | 5 |
| `com.mazl.app.superlikes.15` | `super_like` | 15 |

## Données

- `credit_balances (user_id → users ON DELETE CASCADE, kind, balance INT)`, avec
  une clé primaire `(user_id, kind)`. Le solde peut devenir négatif après un
  remboursement d'achat déjà consommé. Les achats suivants comblent d'abord cette
  dette.
- `credit_purchases (transaction_id PK, user_id → users ON DELETE CASCADE,
  product_id, kind, quantity, environment, purchased_at, refunded_at NULL,
  created_at)`. La clé est le **`transactionId`** du JWS, unique par achat de
  consommable, et non l'`originalTransactionId`.
- `credit_spends (id, user_id → users ON DELETE CASCADE, kind, source
  'daily'|'purchased', target_user_id NULL, created_at)` : le journal des débits.
  L'allocation du jour se compte sur les lignes `source = 'daily'` de la journée.
- La suppression de compte efface ces trois tables, comme `subscriptions`
  (cascade, et la fonction d'effacement de `db.ts` vérifiée).

## API

### `GET /api/credits` (authentifié)

```json
{ "success": true,
  "credits": {
    "super_like": { "daily_allowance": 5, "daily_remaining": 3, "purchased_balance": 12, "available": 15 },
    "boost":      { "daily_allowance": 1, "daily_remaining": 0, "purchased_balance": 2,  "available": 2 },
    "resets_at": "2026-10-25T00:00:00.000Z" } }
```

`available = daily_remaining + max(purchased_balance, 0)`. Le même objet `credits`
est renvoyé partout ci-dessous.

### `POST /api/credits/apple/verify` (authentifié)

- **Corps** : `{ "signedTransaction": "<JWS StoreKit 2>" }`.
- **Vérifications** : chaîne Apple et signature, avec le même `AppleJwsVerifier`
  que les abonnements. Le bundle doit valoir `com.mazl.app`, le produit doit être
  dans le tableau ci-dessus, `type` doit valoir `"Consumable"`, et la transaction
  ne doit pas être révoquée (`revocationDate` absent).
- **200** : `{ success, credited: true|false, kind, quantity, credits }`.
  `credited` vaut `false` quand cette transaction a déjà été créditée au même
  utilisateur (idempotent). Une transaction n'est créditée qu'une fois.
- **409** `transaction_owned_by_another_user` : la transaction appartient déjà à
  un autre utilisateur.
- **422** `invalid_transaction` : la transaction n'est pas fiable. **400**
  `invalid_body`.

### `POST /api/swipes`, avec `action: "super_like"`

Le débit a lieu avant l'enregistrement. La réponse 200 ajoute `credits`. Quand rien
n'est disponible : 402.

### `POST /api/boost/activate`

Le débit a lieu avant l'activation. La réponse ajoute `credits`. Quand rien n'est
disponible : 402 ; quand un boost est déjà actif : 409.

### `GET /api/boost/status`

Les clés existantes sont conservées. `remaining_boosts` vaut désormais
`credits.boost.available`, et la réponse ajoute `credits`.

### Notifications App Store V2

L'URL existante `/api/subscriptions/apple/notifications` reçoit aussi les
consommables.

- **`REFUND` ou `REVOKE` d'un consommable connu** : `refunded_at` est rempli et le
  solde baisse de la quantité. Cela ne se fait qu'une fois, même si Apple rejoue
  la notification.
- **`CONSUMPTION_REQUEST`** et les types sans effet : réponse 200, rien ne change.
- **Consommable inconnu** : réponse 200 avec `ignored`, comme pour un abonnement
  inconnu. Un `REFUND` ou `REVOKE` arrivé avant le crédit est tout de même
  mémorisé (`credit_revocations`, clé `transaction_id`, sans membre) : si le JWS
  de cet achat est présenté ensuite, `POST /api/credits/apple/verify` répond 422
  `invalid_transaction` et ne crédite rien. Le JWS gardé par le membre ne porte
  pas de `revocationDate`, seul ce registre sait que l'achat a été remboursé. Le
  crédit et le remboursement d'une même transaction sont sérialisés (verrou
  consultatif Postgres).
- Une notification de consommable ne doit jamais renvoyer 422 pour l'unique raison
  que la transaction n'a pas d'`expiresDate`.

## App (Flutter)

- **Produits** : `store_products.dart` décrit les quatre consommables (type et
  quantité).
- **Achat** : `StoreGateway` gagne `buyConsumable`. Sur Android, `autoConsume`
  vaut `false`.
- **Vérification** : le flux d'achats unique envoie les consommables à
  `POST /api/credits/apple/verify`. La transaction n'est terminée
  (`completePurchase`) qu'après le 200, ou après un 409 (refus définitif). Les
  autres réponses suivent les mêmes règles que les abonnements : la transaction
  est conservée et rejouée.
- **Solde** : un `CreditsService` lit `GET /api/credits`. Il se met aussi à jour
  avec le `credits` renvoyé par chaque swipe, boost ou vérification.
  `PremiumGate.remainingSuperLikes` et `remainingBoosts` lisent ce solde ;
  `useSuperLike` et `useBoost` disparaissent. Les likes gratuits restent comptés
  par l'app : c'est hors du périmètre de ce contrat.
- **Plus rien de disponible** : une feuille « packs » montre les deux packs du
  type concerné, au prix du store, et « Découvrir mazl+ » pour un non-abonné.
- **Boost** : le bouton n'est plus réservé à mazl+. Un utilisateur gratuit qui a
  acheté des boosts peut les utiliser.
- **Réponses du serveur** : un 402 renvoyé par le serveur relit le solde et ouvre
  la feuille ; un 409 « boost déjà actif » affiche un message.
