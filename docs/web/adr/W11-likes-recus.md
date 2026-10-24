# ADR-W11 — « Voir qui vous a aimé » réservé à mazl+ côté serveur

Date : 2026-10-24. Statut : accepté.

## Contexte
`GET /api/likes/received` renvoyait à tout membre la photo signée, l'identifiant et l'âge de
chaque personne qui l'a aimé. L'app et le site floutent la photo pour un membre gratuit, mais
ce flou est seulement visuel : la photo nette, et l'identifiant qui ouvre le profil complet,
se lisaient dans la réponse (outils du navigateur). « Voir qui vous a aimé » est un avantage
payant (CGV §2.1).

## Décision
- Feature `src/features/likes-visibility/` montée devant la route du matching (sans modifier
  le matching, réécrit dans une autre branche) : pour un membre sans mazl+ (même règle que
  `PgPlusStatus`), chaque like est réduit à `{ display_name, is_verified, liked_at }`.
  Le nombre et les réponses d'erreur ne changent pas ; avec mazl+, rien ne change.
- Effet sur l'app mobile : elle lit `user_id` et `picture` avec des valeurs par défaut
  (`mobile/lib/core/models/likes.dart`) ; un membre gratuit voit des cartes sans photo au lieu
  de photos floutées. À reprendre dans l'app (aplat flouté de la charte).
