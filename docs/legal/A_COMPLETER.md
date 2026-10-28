# À compléter par l'éditeur avant publication

Les cinq documents sont écrits dans `cgu.md`, `cgv.md`, `confidentialite.md`, `mentions-legales.md` et `cookies.md` (ce dossier). Ce sont les sources de vérité : les pages `public/*.html` en sont générées (`bun run legal:build`, vérifié par `bun test tests/unit/legal-pages.test.ts`). Chaque mention `[À COMPLÉTER : …]` s'affiche en surbrillance sur la page publiée et est comptée dans l'encadré du haut de page. Aucune donnée d'identification n'a été inventée.

Pour compléter : remplacer la mention dans le `.md`, lancer `bun run legal:build`, changer `version:` dans l'en-tête du document si le fond change, et passer `status: projet` à `status: en vigueur` quand le conseil de l'éditeur a validé le texte (l'encadré « en cours de validation » disparaît alors).

Les identités (raison sociale, siège, SIREN, TVA, directeur de la publication) ne figurent plus qu'à un seul endroit, `mentions-legales.md` ; les CGU, les CGV et la politique de confidentialité y renvoient.

## État au 2026-10-28

Tranché par Renaud le 2026-10-28 et reporté dans les textes : l'éditeur est **Renaud Cosson, entrepreneur individuel** (nom commercial MAZL), domicilié à une adresse de domiciliation ; contacts `hello@` (général, réclamations, rétractation, remboursements), `privacy@` (RGPD) et `legal@` (autorités, DSA) sur mazl.app ; aucun DPO désigné à ce jour ; prospection sur consentement ; préavis CGU de 30 jours ; pas de politique d'inactivité ni de plafond de responsabilité.

Durées fixées et appliquées par la purge automatique du serveur (feature `retention`) : positions 30 jours, sessions de vérification 12 mois, journal de modération 12 mois, empreinte d'un membre banni 5 ans. Sauvegardes : 14 dernières sauvegardes quotidiennes (réglage Coolify vérifié). Hébergeur : téléphone de Hetzner reporté, Helsinki retenu.

Reste ouvert : SIREN, adresse de domiciliation, situation TVA ; médiateur de la consommation (adhésion à faire) ; tribunal compétent pour un membre professionnel ; boîtes `privacy@` et `legal@` à créer chez OVH ; points B à G ci-dessous encore marqués dans les textes (conseil juridique, produit, AIPD).

## A. Identification de l'éditeur (`mentions-legales.md`, articles 1 et 2)

| Information | Remarque |
|---|---|
| Raison sociale, forme juridique, capital social | |
| Adresse du siège et adresse postale de contact | |
| SIREN et ville du RCS | |
| N° de TVA intracommunautaire | |
| Directeur de la publication (nom, fonction) | Obligation LCEN |
| Adresse e-mail de contact | `hello@mazl.app` figure sur le site ; à confirmer comme adresse de l'éditeur |
| Forme de l'éditeur | Un éditeur qui vend des abonnements agit à titre professionnel : l'anonymat réservé aux éditeurs non professionnels ne joue pas |

## B. Hébergement et point de contact DSA (`mentions-legales.md`, articles 3 et 4)

| Information | Remarque |
|---|---|
| Téléphone de Hetzner Online GmbH | Exigé par l'article 6, III, 1 de la LCEN ; à relever sur le site de l'hébergeur |
| Centre de données | **Vérifié** : mazl.app et api.mazl.app résolvent vers 157.180.43.90, plage « CLOUD-HEL1 » de Hetzner Online GmbH (Helsinki, Finlande) dans le registre RIPE. À confirmer dans la console Hetzner, puis retirer la mention |
| Adresse du point de contact unique (DSA art. 11 et 12) | Adresse dédiée, par exemple `legal@mazl.app`, ou `hello@mazl.app` |
| Langues acceptées par le point de contact | Français et anglais proposés |

## C. Consommation (`cgu.md` article 17, `cgv.md` articles 6 et 12)

| Information | Où |
|---|---|
| Médiateur de la consommation (nom, adresse, site) et preuve de l'adhésion | CGU 17, CGV 12 |
| Adresse du service de réclamation | CGU 17, CGV 12 |
| Mention de la plateforme européenne RLL (fermée en juillet 2025) : conserver ou retirer | CGU 17, CGV 12 |
| Adresse pour exercer la rétractation (si différente du contact) | CGV 6.3 |
| Adresse pour demander le remboursement d'un achat fait sur le site | CGV 7 |
| Tribunal compétent pour un membre professionnel | CGU 17 |

## D. Vente (`cgv.md`)

| Information | Où |
|---|---|
| Les prix du site (Stripe) sont-ils identiques à ceux de l'App Store ? Les prix écrits viennent de `docs/premium/APP-STORE-CONNECT.md` (19,99 / 44,99 / 69,99 / 99,99 € ; Boosts 7,99 / 19,99 ; Super Likes 4,99 / 11,99) et le prix de MAZL Couple de `docs/couple/ESPACE-COUPLE.md` (29,99 €). Un test compare les prix des CGV au fichier App Store Connect | CGV 3.1 |
| Que deviennent l'abonnement et les avantages du partenaire quand le couple prend fin ou quand le payeur supprime son compte ? Un membre qui a déjà mazl+ peut-il passer à MAZL Couple ? | CGV 2.2 |
| Émission de factures propres par MAZL ou seulement reçus Apple (TVA) | CGV 4 |
| Mentions de facturation à paramétrer dans Stripe (raison sociale, adresse, TVA) et confirmation que les factures Stripe font foi | CGV 4 |
| Renoncement à la rétractation pour les achats faits dans l'app : Apple le recueille-t-il valablement, ou faut-il ajouter une mention et une case sur l'écran d'achat (aucune n'a été repérée dans l'écran Premium) ? | CGV 6.2 |
| Prix de référence d'une réduction annoncée (le plus bas des 30 derniers jours, arrêté du 11 mars 2015) : engagement à valider, et à faire respecter par la vitrine des campagnes | CGV 3.3 |
| Ouverture des achats Android (Google Play) : non vérifiés côté serveur aujourd'hui | CGV 2.5 |

## E. Conditions d'utilisation (`cgu.md`)

| Information | Où |
|---|---|
| Préavis de notification d'une modification des CGU | CGU 2 |
| Canal d'envoi de l'exposé des motifs au membre (voir « Écarts » ci-dessous) | CGU 8.3 |
| Organe de règlement extrajudiciaire certifié (DSA art. 21), s'il y en a un | CGU 8.5 |
| Politique d'inactivité de compte (durée), si elle existe | CGU 13.2 |
| Plafond éventuel de responsabilité | CGU 14 |

## F. Données personnelles (`confidentialite.md`)

| Information | Où |
|---|---|
| E-mail dédié aux demandes RGPD | art. 1 et 10 |
| DPO : désignation ou décision motivée de ne pas en désigner (données sensibles à grande échelle) | art. 1 |
| Représentant UE : confirmer qu'il est sans objet | art. 1 |
| Sort des informations de pratique religieuse saisies avant le recueil du consentement (re-demander, puis effacer sans réponse) | art. 2.3 |
| Fondement et conservation des conversations de conciergerie ; conditions de conservation et de non-réutilisation chez Anthropic ; accord de traitement et mécanisme de transfert | art. 2.13, 4, 6, 7 |
| Base légale de la conservation de l'empreinte HMAC d'un membre banni, et durée maximale (aucune expiration dans le code) | art. 3 et 4 |
| Régime de la prospection (consentement ou intérêt légitime) pour les e-mails de campagne | art. 3 |
| Durées de purge à fixer : historique de positions (`location_updates`), sessions de vérification faciale, journal de modération, exposés des motifs et contestations, journaux techniques (IP), rotation des sauvegardes, pièces comptables | art. 4 |
| Purge des mesures d'audience au-delà de 25 mois à mettre en place dans OpenPanel | art. 4 |
| Mécanisme de transfert hors UE pour Resend, Anthropic, Google, Apple, Stripe (CCT, DPF) et accords de sous-traitance (art. 28) | art. 6, 7 |
| Date de l'analyse d'impact (AIPD) et éventuelle consultation de la CNIL | art. 13 |
| Déclaration « confidentialité des données » de l'App Store, cohérente avec la politique | art. 12 |

## G. Cookies (`cookies.md`)

| Information | Où |
|---|---|
| Le script de connexion Google (et Apple) de la page de connexion dépose-t-il des traceurs ? Faut-il recueillir le consentement avant d'afficher le bouton ? | art. 4 |
| Polices Google Fonts de la page d'envoi de documents (`public/verify.html`) : les héberger localement, puis retirer la mention | art. 4, et `confidentialite.md` art. 6 |

## H. Points qui demandent un avocat

1. **Un service de rencontre réservé en pratique à une communauté religieuse** : rédaction de l'objet du service (CGU 3) au regard du droit de la non-discrimination (accès à un service) et du traitement de données révélant la religion (article 9, consentement explicite, et le fait que le simple usage du service révèle l'appartenance).
2. **Qualification au titre du règlement (UE) 2022/2065** : fournisseur d'hébergement ou plateforme en ligne, micro ou petite entreprise (exemptions des articles 15, 19 et suivants), point de contact, rapport de transparence. Le texte des CGU, article 8, applique les obligations par prudence.
3. **Données sensibles dans la conciergerie** : une contrainte de cacherout saisie dans une demande transmise à une IA révèle une pratique religieuse. Fondement, information et consentement à faire valider.
4. **Biométrie** (gabarit du visage, comparaison avec la photo de la puce) : analyse d'impact (AIPD), consentement explicite, durée de conservation de l'empreinte HMAC d'un membre exclu.
5. **Achats dans l'app** : qui est le vendeur au sens du Code de la consommation (Apple ou MAZL), et validité du renoncement à la rétractation recueilli par Apple (CGV 6.2).
6. **Abonnement partagé MAZL Couple** : le partenaire n'est pas partie au contrat ; sort de ses droits à la fin du couple.
7. **Plafond de responsabilité**, tribunal pour les professionnels, clause d'inactivité, statut de l'éditeur (professionnel, pas d'anonymat).
8. **Prospection par e-mail** (consentement ou intérêt légitime) et information sur les cookies de la page de connexion.

## I. Écarts entre les textes et le produit à traiter avant de publier

1. **Aucun exposé des motifs n'est envoyé aujourd'hui.** `src/features/trust-safety/infra/silent-notifier.ts` ne fait que journaliser : le membre sanctionné n'est pas prévenu, ni de la décision (art. 17 du DSA), ni du résultat de sa contestation. Les CGU 8.3 promettent cet envoi : brancher un vrai notificateur (e-mail via Resend et/ou notification) ou retirer la promesse.
2. **Pas de page publique de contestation.** Le canal existe côté API (`POST /api/appeals`, référence et code) ; les CGU 8.4 indiquent l'e-mail. Une page simple sur le site serait préférable.
3. **MAZL Couple et la conciergerie** sont décrits d'après `docs/couple/ESPACE-COUPLE.md`, qui n'est pas encore sur `main` (branche `feat/espace-couple`). Publier ces textes en même temps que la fonctionnalité.
4. **Écran d'achat de l'app** : pas de mention de renoncement à la rétractation (voir D).
5. **Durées de purge** non codées (voir F) : positions, sessions de vérification, journaux, empreinte d'un membre banni, sauvegardes.
6. **Polices Google** de `public/verify.html` (voir G).

## J. Réglé par cette mise à jour

- L'écran de consentement aux données de pratique religieuse existe maintenant dans l'application (`religious_data_gate`, réglages) et le serveur ignore ces champs sans consentement (`religious-fields-guard`) : la mention « écran mobile à faire » est retirée.
- Les polices Google Fonts ne sont plus chargées par le site (la vitrine et les pages juridiques servent Geist en local) : la politique de confidentialité ne mentionne plus que la page d'envoi de documents.
- Hébergeur : vérifié par le registre RIPE (voir B), centre de données Helsinki.
- Pas de bandeau de cookies nécessaire à ce jour : un seul cookie strictement nécessaire, aucune mesure d'audience sans consentement ; voir `cookies.md`.
