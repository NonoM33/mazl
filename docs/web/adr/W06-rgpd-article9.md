# ADR-W06 — Données de pratique religieuse (art. 9 RGPD), traceurs et export

Date : 2026-10-24. Statut : accepté.

## Décision
- **Consentement explicite et séparé** pour les champs `denomination`, `kashrut_level`,
  `shabbat_observance` (et l'intention), distinct des CGU : écran dédié au premier passage sur
  le web, case non pré-cochée, texte versionné ; enregistrement serveur
  `user_consents (user_id, purpose='religious_data', version, granted, source, decided_at)`.
- **Retrait** à tout moment dans Réglages : les trois champs sont effacés du profil et ne sont
  plus saisissables sur le web tant que le consentement n'est pas redonné.
- Le serveur **n'exige pas encore** ce consentement sur `PUT /api/profile` : l'app mobile n'a
  pas d'écran équivalent (voir `docs/legal/A_COMPLETER.md`, partie E) et l'exiger casserait
  l'inscription mobile. La route `/api/privacy/consents` est prête pour que l'app l'utilise ;
  ensuite seulement, le serveur pourra refuser ces champs sans consentement.
- **Aucun pixel publicitaire, aucun outil de mesure d'audience, aucun script tiers** dans
  l'espace connecté. Seule exception, et seulement sur la page de connexion : le script Google
  Identity Services (et Apple JS si configuré), nécessaire à la connexion demandée par le membre.
- **Export (art. 15 et 20)** : `GET /api/users/me/export` rend un fichier JSON lisible par une
  machine (compte, profil, photos sous forme de métadonnées, prompts, préférences, swipes
  donnés, matchs, messages envoyés, blocages et signalements émis, abonnement, crédits, couple,
  événements, consentements, sessions web, preuves de renoncement). Limité à 3 par jour.
  Les messages reçus ne sont pas inclus (données de l'autre membre).
