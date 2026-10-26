# Connexion de revue App Store — contrat (2026-10-26)

Apple exige un compte de démonstration (identifiant + mot de passe) pour relire l'app.
MAZL ne connaît que Sign in with Apple et Google : on ajoute UN compte de revue, et un
seul, qui se connecte par identifiant + mot de passe.

## Serveur

`POST /api/auth/review` — public, limité par adresse IP.

Corps : `{ "username": "<identifiant>", "password": "<mot de passe>" }` (chaînes, 1 à 200 car.)

| statut | corps |
|---|---|
| 200 | `{ "success": true, "token": "<jwt>", "user": { "id": 42, "email": "app-review@mazl.app", "name": "Jonathan", "provider": "review", "isNew": false, "hasProfile": true } }` |
| 400 | `{ "success": false, "error": "credentials_required" }` |
| 401 | `{ "success": false, "error": "invalid_credentials" }` (identifiant OU mot de passe faux : jamais lequel) |
| 403 | `{ "success": false, "error": "account_disabled" }` |
| 404 | `{ "error": "Not found" }` quand la connexion de revue n'est pas configurée |
| 429 | trop de tentatives |

Configuration (Coolify, jamais dans le dépôt) : `REVIEW_LOGIN_USERNAME`, et
`REVIEW_LOGIN_PASSWORD_HASH` = `Bun.password.hash(motDePasse)` (argon2id). L'un des deux
absent : la route répond 404.

Le compte : `users.provider = 'review'`, `provider_id = <identifiant>`, profil complet
(gender, looking_for posés), invisible dans Discover des autres membres, exclu des
statistiques et des campagnes. Avec `SEED_TEST_PROFILES=true`, il reçoit les matchs et
conversations de démonstration comme le compte administrateur.

## App

Lien discret « Connexion par identifiant » sous les boutons Apple / Google de l'écran de
connexion, visible de tous (pas de geste caché : règle App Store 2.3.1). Il ouvre un écran
identifiant + mot de passe qui appelle la route ci-dessus et ouvre la session comme la
connexion Apple (JWT en stockage sécurisé, abonnement relu, push déclaré).
