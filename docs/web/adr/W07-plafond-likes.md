# ADR-W07 — Plafond de likes tenu par le serveur

Date : 2026-10-24. Statut : accepté.

## Contexte
Le plafond de 10 likes par jour (formule gratuite, CGV §2.1) n'est compté que par l'app mobile,
dans ses préférences locales. Un second client (le web) doublerait le plafond, et un client
modifié l'ignore déjà.

## Décision
- Middleware `like-allowance` devant `POST /api/swipes` : pour `action: "like"` d'un membre sans
  mazl+, au-delà de 10 likes enregistrés le jour calendaire du serveur (même jour que les
  crédits), réponse `402 likes_exhausted` avec `resets_at`. Les « passer » et les Super Likes
  (déjà plafonnés par les crédits) ne sont pas concernés ; refaire un like déjà donné ne compte pas.
- `GET /api/likes/allowance` → `{ daily_allowance: 10 | null, remaining: n | null, resets_at }`.
- Le mobile garde son compteur local (premier rempart, sans réseau) ; il reçoit 402 seulement
  s'il le contourne. À brancher sur le 402 dans l'app (suite).
- Feature isolée, montée avant `registerMatchingRoutes` : aucun fichier du matching n'est modifié
  (l'algorithme est réécrit dans `feat/backoffice-matching`).
