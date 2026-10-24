# À compléter par l'éditeur avant publication

Chaque mention `[À COMPLÉTER : …]` des trois documents (`cgu.md`, `cgv.md`, `confidentialite.md`, puis les pages HTML de `public/` à régénérer) est listée ici. Aucune donnée d'identification n'a été inventée. Après complétion : mettre à jour les `.md` (sources de vérité), reporter dans `public/cgu.html`, `public/cgv.html`, `public/confidentialite.html`, et changer la date de version.

## A. Identification de l'éditeur (CGU art. 1, CGV art. 1, Confidentialité art. 1)

| Information | Où | Remarque |
|---|---|---|
| Raison sociale | CGU 1, CGV 1, Conf. 1 | |
| Forme juridique et capital social | CGU 1, CGV 1, Conf. 1 | |
| Adresse du siège | CGU 1, CGV 1, Conf. 1 | |
| SIREN et ville du RCS | CGU 1, CGV 1, Conf. 1 | |
| N° de TVA intracommunautaire | CGU 1, CGV 1 | |
| Directeur de la publication | CGU 1 | Obligation LCEN |
| E-mail de contact général | CGU 1 et 17, CGV 1 | `hello@mazl.app` figure sur le site et dans les e-mails ; à confirmer |
| Adresse postale de contact | CGU 17 | |
| Hébergeur : confirmer Hetzner (Gunzenhausen, DE), centre de données, coordonnées | CGU 1, Conf. 6 | Le code déploie via Coolify ; l'hébergeur exact est à confirmer |

## B. Consommation (CGU art. 16, CGV art. 12)

| Information | Où |
|---|---|
| Médiateur de la consommation choisi (nom, adresse, site) et adhésion | CGU 16, CGV 12 |
| Mention de la plateforme européenne RLL (fermée en juillet 2025) : conserver ou retirer | CGU 16, CGV 12 |
| Adresse du service de réclamation / service client | CGU 16, CGV 12 |
| Adresse pour exercer la rétractation | CGV 6.3 |
| Tribunal compétent pour un membre professionnel | CGU 16 |

## C. Vente (CGV)

| Information | Où |
|---|---|
| Prix et offres en vigueur (le code ne fixe pas les prix : ils viennent d'App Store Connect ; `docs/premium/APP-STORE-CONNECT.md` donne 19,99 / 44,99 / 69,99 / 99,99 EUR et 7,99 / 19,99 / 4,99 / 11,99 EUR) | CGV 3 |
| Émission de factures propres par MAZL ou seulement reçus Apple (TVA) | CGV 4 |
| **Preuve du renoncement exprès au droit de rétractation sur l'écran d'achat** : aucune case ni mention de renoncement n'a été repérée dans l'écran Premium actuel (`premium_screen.dart`) ; sans elle, l'exception de l'art. L221-28 ne joue pas | CGV 6.2 |
| Ouverture des achats Android (Google Play) : non vérifiés côté serveur aujourd'hui | CGV 2.4 |

## D. Conditions d'utilisation (CGU)

| Information | Où |
|---|---|
| Préavis de notification d'une modification des CGU | CGU 2 |
| Point de contact unique et représentant légal au titre du règlement (UE) 2022/2065 (DSA) si applicable | CGU 7.3 |
| Politique d'inactivité de compte (durée), si elle existe | CGU 12.2 |
| Plafond éventuel de responsabilité | CGU 13 |

## E. Données personnelles (Confidentialité)

| Information | Où |
|---|---|
| E-mail dédié aux demandes RGPD | Conf. 1 et 10 |
| DPO : désignation ou décision motivée de ne pas en désigner (données sensibles à grande échelle) | Conf. 1 |
| Représentant UE : confirmer qu'il est sans objet | Conf. 1 |
| **Consentement explicite pour les données de pratique religieuse** : vérifier qu'un écran dédié existe dans l'app (texte, version, date) ; seul le consentement à la reconnaissance faciale est visible dans le code (`consentText`) | Conf. 2.3 |
| Base légale de la conservation de l'empreinte HMAC d'un membre banni, et durée maximale (aucune expiration dans le code) | Conf. 3 et 4 |
| Régime de la prospection (consentement ou intérêt légitime) pour les e-mails de campagne | Conf. 3 |
| Confirmer l'absence d'outil de mesure d'audience (site et app) et de tout traceur | Conf. 3, 12 |
| Durées de purge à fixer : historique de mises à jour de position (`location_updates`), sessions de vérification faciale (`face_verification_sessions`), journal de modération (`moderation_logs`), journaux techniques (IP), rotation des sauvegardes, pièces comptables | Conf. 4 |
| Mécanisme de transfert hors UE pour Resend, OneSignal, Google, Apple (CCT, DPF) et accords de sous-traitance (art. 28) | Conf. 6, 7 |
| Date de l'analyse d'impact (AIPD) et éventuelle consultation de la CNIL | Conf. 13 |
| Déclaration « confidentialité des données » de l'App Store, cohérente avec la politique | Conf. 12 |
