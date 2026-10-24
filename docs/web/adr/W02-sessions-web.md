# ADR-W02 — Sessions web courtes, révocables, et pont vers les routes existantes

Date : 2026-10-24. Statut : accepté.

## Contexte
L'API authentifie par `Authorization: Bearer <JWT>` valable 30 jours, sans révocation
individuelle. Un JWT de 30 jours dans le `localStorage` d'un navigateur de bureau partagé serait
volable par XSS et impossible à révoquer. Le web doit pourtant appeler les mêmes routes.

## Décision
- Session web = ligne `web_sessions` (identifiant aléatoire 256 bits, seul son SHA-256 est
  stocké), créée par une connexion réussie (QR, Google, Apple).
- Cookie `__Host-mazl_web` : `HttpOnly`, `Secure`, `SameSite=Strict`, `Path=/`, sans `Domain`.
  Le JavaScript du site ne voit jamais de jeton.
- **Inactivité 4 h, durée absolue 7 jours.** Révocable : depuis le web (« Se déconnecter »,
  « Déconnecter les autres sessions ») et depuis l'app (liste des sessions web).
- **Pont** (`bridge`) au point d'entrée `Bun.serve` : une requête `/api/*` sans `Authorization`,
  portant le cookie ET l'en-tête `X-Mazl-Web: 1` (et, pour une méthode non sûre, un `Origin`
  égal à l'origine du site) est complétée par un JWT de **60 secondes** signé avec le même
  secret. Les routes existantes et `requireAuth` ne changent pas. Sans l'en-tête, le cookie est
  ignoré : protection CSRF en plus de `SameSite=Strict`. L'en-tête interne
  `X-Mazl-Web-Session` est toujours retiré de la requête entrante puis posé par le pont, pour
  que les routes sensibles (approuver une connexion QR) refusent une session web.
- WebSocket : `POST /api/web/socket-ticket` rend un JWT de 10 minutes rattaché à la session ;
  les sockets d'une session révoquée sont fermées tout de suite (code 4003 côté session web
  seulement, le mobile n'est pas touché).
- `generateJWT` reçoit une durée optionnelle (seule modification de `src/auth.ts`).

## Conséquences
- Une requête web coûte une lecture de session (clé primaire) en plus du contrôle de compte.
- Les sessions d'un compte supprimé disparaissent (`ON DELETE CASCADE`) ; un compte banni est
  déjà refusé par `requireAuth`.
