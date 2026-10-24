# Cadrage — back-office staff, modération et moteur de match

> 2026-10-24. Branche `feat/backoffice-matching`. Sources : [RECHERCHE-BACKOFFICE.md](RECHERCHE-BACKOFFICE.md)
> (modération, vérification, DSA, RGPD, rôles) et [RECHERCHE-MATCHING.md](RECHERCHE-MATCHING.md)
> (algorithmes des applications de rencontre). Les affirmations externes y sont sourcées.

## 1. L'existant

| Domaine | Ce qui existe | Limites constatées |
|---|---|---|
| Accès staff | `src/features/admin/admin.auth.ts` : jeton admin HMAC (`aud: mazl-admin`), liste blanche `ADMIN_EMAIL` + adresse de Renaud, mot de passe unique `ADMIN_PASSWORD`, connexion Google | Un seul rôle (tout ou rien), pas de second facteur, pas de gestion d'équipe |
| Journal | table `moderation_logs` (e-mail, action, cible, JSON) | Modifiable et supprimable, pas toutes les actions, aucune lecture sensible tracée |
| Signalements | table `reports` (motif, détails, statut, `message_id`), `GET/PUT /api/admin/reports` | Pas de priorité, pas de délai (SLA), pas d'assignation, pas de contexte (historique, conversation), décision = texte libre |
| Sanctions | `user_bans` + `banUser` (désactive le compte), empreinte de document pour les bannis définitifs | Pas de gradation (avertissement, restriction, suspension), pas d'exposé des motifs (DSA art. 17), pas de contestation |
| Vérification | documents (`/api/admin/pending`, revue des pièces), selfie et identité NFC (`src/features/verification`) | Écrans dans l'ancienne console, pas de file unifiée |
| Console | `public/admin.html` (80 Ko, HTML/JS inline, violet/rose Inter) | Hors charte « Encre & Tekhelet », monolithique, non testée, pensée pour un seul admin |
| Matching | `getDiscoverProfiles` (SQL) : filtres genre bidirectionnel, âge et distance côté demandeur, tri boost > concordance exacte courant/cashrout/chabbat > ancienneté | Égalité stricte des textes (« Massorti » ≠ « massorti »), pas de réciprocité dans le score, pas d'activité, pas de limite de surexposition, poids codés en dur, rien d'explicable ni de réglable ; `daily-picks` = les 5 premiers du même tri |
| Profil | courant, cashrout, chabbat en texte libre ; l'app envoie `relationship_intention` mais le serveur l'ignore | L'intention de mariage n'est pas stockée |

## 2. Les manques prioritaires (synthèse de la recherche, §7 de RECHERCHE-BACKOFFICE)

P0 retenus pour ce chantier :
1. **File de signalements priorisée** : motif normalisé → priorité P1 (mineur, danger physique) à P4, délai cible par priorité, assignation, retard visible.
2. **Contexte** : fiche membre (historique des signalements et sanctions, blocages reçus, ancienneté, vérification), signaux d'arnaque, message signalé ; la conversation complète est lisible uniquement avec un **motif écrit**, journalisé.
3. **Sanctions graduées** (avertissement, restriction, suspension, bannissement) avec **exposé des motifs** structuré (DSA art. 17) et une échelle qui *suggère* sans jamais décider.
4. **Contestation** (DSA art. 20) : canal public par référence + code (un banni ne peut plus se connecter), décidée par une autre personne que l'auteur de la sanction.
5. **Rôles** et moindre privilège, **second facteur TOTP** obligatoire en production.
6. **Journal d'audit immuable** : ajout seul (trigger qui refuse UPDATE/DELETE), chaînage SHA-256 vérifiable, lectures sensibles comprises.
7. **Floutage par défaut** des photos dans les files, dévoilement au clic.
8. **Registre des demandes d'autorités** (réquisitions, PHAROS, art. 18 DSA), rôle restreint.
9. **Tableau de bord** et **chiffres de transparence** (art. 15 DSA), export CSV.

Reportés (P1/P2, voir le rapport) : envoi réel des notifications au membre, accès « break-glass » temporisé, ancrage externe de la chaîne d'audit, intégrations tierces (estimation d'âge, Sift…), suivi des notifiants abusifs (art. 23), échantillonnage de prévalence.

## 3. Écrans de la console

| Écran | Rôle minimal | Contenu |
|---|---|---|
| Connexion | — | Google ou mot de passe (admin d'amorçage), puis code TOTP ; enrôlement guidé au premier passage |
| Tableau de bord | `dashboard.read` | file ouverte par priorité, retards, délai médian, sanctions 30 j, contestations, vérifications en attente, membres actifs, courbe 30 j |
| Signalements | `reports.read` | file triée priorité > échéance, filtres, assignation ; panneau de détail : motif, message, historique, signaux, sanction suggérée, décision avec exposé des motifs |
| Membres | `members.read` | recherche ; fiche : profil (photos floutées), signalements, sanctions, signaux, actions |
| Contestations | `appeals.decide` | file, sanction contestée et son exposé, décision maintenue / annulée |
| Vérification | `verification.review` | file des dossiers en attente (renvoie vers la revue existante) |
| Autorités | `authorities.manage` | registre : autorité, référence, échéance, périmètre, statut |
| Algorithme | `matching.read` / `matching.tune` | curseurs par critère, aperçu en direct sur une population synthétique, explication des scores, versions, retour arrière, A/B |
| Journal d'audit | `audit.read` | filtres, détail, vérification de la chaîne |
| Équipe | `staff.manage` | membres du staff, rôles, état du second facteur |
| Transparence | `dashboard.read` | chiffres de l'art. 15 sur une période, export CSV |

L'ancienne console (`/admin/dashboard`) reste en place pour les événements, campagnes et abonnements, accessible aux super-administrateurs le temps de la migration.

## 4. Rôles (`src/features/staff/domain/roles.ts`)

| Rôle | Permissions |
|---|---|
| Super-administrateur | tout, dont la gestion du staff (adresses de l'environnement `ADMIN_EMAIL`, non modifiables depuis la console) |
| Administrateur | tout sauf la gestion du staff |
| Modérateur | tableau de bord, membres, signalements (lecture, décision), conversations signalées (motivé), sanctions hors bannissement |
| Vérificateur | tableau de bord, membres, file de vérification |
| Support | tableau de bord, membres, signalements en lecture |
| Analyste | tableau de bord, algorithme en lecture, journal d'audit |

Chaque route demande **une permission**, jamais un rôle. Le rôle est relu en base à chaque requête : retirer quelqu'un prend effet immédiatement.

## 5. Journal d'audit

Table `audit_log` : `id, created_at, actor, action, target_type, target_id, justification, details, previous_hash, hash`. `hash = SHA-256(previous_hash || JSON canonique de l'entrée)`. Un trigger PostgreSQL refuse UPDATE et DELETE ; la vérification recalcule la chaîne et indique la première entrée rompue. Jamais de contenu de message, de document ou de secret dans `details`.

Actions journalisées : connexions (réussies et refusées), enrôlement TOTP, lecture d'une conversation (avec motif), lecture d'une fiche membre, décision et assignation de signalement, sanction et levée, décision de contestation, demande d'autorité, publication / activation / A-B des paramètres de match, gestion du staff.

## 6. Modération : règles du domaine

- **Priorité** : `underage` et `offline_behavior` → P1 (4 h), `harassment` et `scam` → P2 (24 h), `fake_profile` et `inappropriate_photos` → P3 (72 h), `spam` et `other` → P4 (7 j). Montée d'un cran si le membre a déjà ≥ 3 signalements ouverts ou une sanction dans les 90 jours.
- **Échelle de sanction suggérée** : selon la gravité du motif et l'historique (aucune → avertissement → restriction → suspension → bannissement) ; `underage` suggère la suspension immédiate en attendant la vérification d'âge. La suggestion n'est jamais appliquée seule.
- **Effets** : avertissement = trace et exposé ; restriction = invisible dans la découverte ; suspension = compte désactivé jusqu'à l'échéance ; bannissement = compte désactivé + empreinte de document (mécanisme existant).
- **Exposé des motifs** : référence, décision, portée et durée, faits, motif normalisé et clause des CGU, détection et décision automatisées (toujours « non » pour la décision), voies de recours.
- **Contestation** : ouverte 6 mois, décidée par une autre personne ; annuler une sanction la lève et réactive le compte.

## 7. Moteur de match (`src/features/matching/domain`)

Six étages, chacun réglable et expliqué :

```
candidats → filtres durs → 8 sous-scores ∈ [0,1] → somme pondérée dans chaque sens
          → réciprocité (moyenne harmonique par défaut) → multiplicateurs bornés
          → exploration (ε places) → classement + explication
```

- **Filtres durs, jamais compensés** : exclus (bloqués dans un sens ou l'autre, déjà vus, soi-même, compte fermé ou restreint), genre bidirectionnel, âge (tranche du demandeur, et réciproquement si `mutualAge`), distance (plus petite des deux limites si `mutualDistance`).
- **Sous-scores** : courant, cashrout, chabbat, intention en **distance ordinale** (`1 − |rangA − rangB| / tolérance`, rangs définis par des échelles versionnées avec les paramètres), âge (1 au centre de la tranche, `edgeScore` au bord), distance (`1 / (1 + d / d½)`), profil complet, vérification.
- **Réciprocité** : harmonique, géométrique, minimum ou sens unique.
- **Multiplicateurs** : fraîcheur (demi-vie d'inactivité, plancher), nouveaux (bonus dégressif), boost payant (plafonné ×2), surexposition (amortit les profils qui reçoivent beaucoup de likes), signalements ouverts (plancher : la sanction relève de la modération).
- **Exploration** : une part ε de chaque page donnée à des profils plausibles hors du haut du classement, tirés par un générateur pseudo-aléatoire **déterministe** (graine = demandeur + jour + version).
- **Propriétés testées** : réciprocité (score symétrique en mode harmonique), filtres durs jamais violés, bloqués et déjà vus jamais proposés, déterminisme à paramètres et graine égaux, bornes de chaque sous-score et multiplicateur, monotonie (un poids qui monte ne fait jamais descendre un candidat qui excelle sur ce seul critère).
- **Paramètres** : table `matching_param_versions` (JSON, auteur, note, parent), état actif + test A/B dans `matching_state`. Toute valeur est bornée par `NUMERIC_PARAMS`, à l'enregistrement comme dans les curseurs.

## 8. Réglage depuis la console

Curseurs générés depuis `NUMERIC_PARAMS`, aperçu en direct (le moteur réel, exécuté côté serveur sur une **population synthétique** déterministe : aucune donnée de membre n'est montrée), explication détaillée de chaque score, comparaison A/B de deux jeux de paramètres (déplacements de rang), historique des versions avec auteur, activation et retour arrière en un clic, test A/B en production sur une part des membres (1 à 50 %). Toute publication, activation ou A/B est journalisée.

## 9. Pile et livraison

- Back-end : nouvelles features `staff`, `audit`, `trust-safety`, `matching` (domaine pur, application, infra Postgres, présentation Hono), API sous `/api/backoffice/*`, enveloppe `{ success, data }`.
- Front : voir [adr/0001-console-react-bun.md](adr/0001-console-react-bun.md).
- Lots : (1) contrats ; (2) moteur de match en TDD ∥ staff + audit ∥ trust & safety ∥ socle de la console ; (3) intégration, matching en base et branchement de `/api/discover` ; (4) écrans ; (5) captures et rapport.
