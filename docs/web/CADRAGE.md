# MAZL Web (bureau) — cadrage

> Version du 2026-10-24. Branche `feat/web-desktop`. Décisions détaillées : `docs/web/adr/`.
> Sources lues : `mobile/PRD_MAZL.md`, `mobile/USER_STORIES.md`, `docs/chat/CONTRAT.md`,
> `docs/couple/CONTRAT.md`, `docs/verification/CONTRAT.md`, `docs/premium/*.md`,
> `docs/design/*`, `mobile/lib/core/theme/*`, `mobile/lib/core/motion/mazl_motion.dart`.

## 1. Ce que l'on construit

Un site web **séparé** (pas Flutter web), pensé pour un écran de bureau (≥ 1100 px), servi sur
**`app.mazl.app`** par le même processus Bun que l'API (ADR-W01). Il consomme **les mêmes routes
d'API que l'application mobile** : la logique métier (découverte, match, chat, couple, crédits,
vérification) reste dans le backend, le web ne fait que présenter.

Ce que le web ajoute côté serveur, chaque fois dans une feature isolée :

| feature | rôle | ADR |
|---|---|---|
| `src/features/web-session/` | connexion par QR code, Google et Apple, sessions web courtes et révocables, anti-bot, pont cookie → JWT court | W02, W03 |
| `src/features/billing-web/` | Stripe Checkout, Customer Portal, webhook signé et idempotent, réconciliation du droit mazl+ et des crédits | W04, W05 |
| `src/features/privacy/` | consentement explicite « données de pratique religieuse » (art. 9) et export des données (art. 15/20) | W06 |
| `src/features/like-allowance/` | plafond de 10 likes par jour en formule gratuite, tenu par le serveur pour le web ET le mobile | W07 |
| `src/features/web-app/` | service des fichiers du site (bundle construit), en-têtes de sécurité stricts | W01 |

Le front vit dans `web/` (React 19 + TSX, bundler Bun, sans Vite ; ADR-W08).

## 2. Écrans et parcours

Cadre au-delà de 1100 px : barre latérale d'icônes (72 px) à gauche, contenu à droite.
En dessous de 1100 px, le site reste utilisable (colonnes repliées) mais n'est pas optimisé.

| route | écran | API consommée |
|---|---|---|
| `/app/connexion` | QR code (principal), Google, Apple ; écran « Pas encore de compte ? » avec QR vers l'App Store | `/api/web/auth/*` |
| `/app/consentement` | consentement art. 9 (affiché tant qu'il n'est pas donné) | `/api/privacy/consents` |
| `/app` | Accueil : Sélections du jour + « Le mot du Shadchan » (la sélection la plus compatible, avec les critères réellement partagés) | `/api/daily-picks`, `/api/auth/me` |
| `/app/decouvrir` | 3 colonnes : filtres 240 px, carte 480 px, profil 360 px ; clavier | `/api/discover`, `/api/swipes`, `/api/profile/:id`, `/api/credits`, `PUT /api/profile`, `/api/likes/allowance` |
| `/app/likes` | onglets « Ils vous ont aimé » et « Visiteurs » (visiteurs : pas d'API, état honnête) ; flou sans mazl+ | `/api/likes/received`, `/api/subscription` |
| `/app/messages[/:id]` | 3 colonnes : liste (Cmd/Ctrl+K pour chercher), fil, profil du match ; temps réel | `/api/conversations*`, `/api/messages/*`, `/ws`, `/api/web/socket-ticket` |
| `/app/profil` | mon profil « tel que vu par les autres » | `/api/auth/me`, `/api/profile/:id`, `/api/profile/prompts` |
| `/app/profil/modifier` | 6 photos glisser-déposer, 3 prompts, infos, pratique, aperçu en direct | `/api/profile/photos*`, `/api/profile/prompts*`, `/api/prompts`, `PUT /api/profile` |
| `/app/statistiques` | tableau de bord du profil (données réellement disponibles) | `/api/likes/received/count`, `/api/matches`, `/api/conversations`, `/api/boost/status`, `/api/verification/status`, `/api/credits` |
| `/app/couple` | mode couple (navigation exclusive, comme le mobile) | `/api/couple*` |
| `/app/evenements[/:id]` | événements, inscription | `/api/events*` |
| `/app/reglages` | compte, découverte, Shabbat, mode discret, sessions web, appareils, confidentialité, export, suppression | `/api/web/sessions`, `/api/privacy/*`, `/api/users/me*`, `/api/users/blocked` |
| `/app/premium` | mazl+ (1, 3, 6, 12 mois) et packs, prix TTC, renoncement L221-28 13°, portail | `/api/billing/*` |

Parcours critiques (testés en e2e Playwright) : connexion QR ; consentement ; découvrir au clavier
(like, passe, annulation, super like, plafond) ; match puis premier message en temps réel ; édition
du profil (ordre des photos, prompt) ; achat mazl+ jusqu'à la redirection Checkout (renoncement
obligatoire) ; révocation d'une session depuis l'app ; mode discret ; export et suppression.

### Réservé au mobile (le web affiche un QR code vers l'app)

Vérification selfie et puce NFC (le web affiche le badge), appel vidéo (v1), géolocalisation
précise (le web reprend la dernière position du mobile), notifications push (v1), achat via
l'App Store, création de compte (ADR-W03 : le web n'ouvre que des comptes existants).

### Clavier (aide par « ? »)

| touche | effet |
|---|---|
| ← | passer |
| → | like |
| ↑ | Super Like |
| Z | annuler le dernier « passer » (fenêtre de 5 s, ADR-W09) |
| I | détails du profil |
| Espace | photo suivante |
| Échap | fermer (visionneuse, aide, détail) |
| Échap ×2 | mode discret (écran neutre) |
| Cmd/Ctrl+K | chercher une conversation |
| ? | aide des raccourcis |

## 3. Manques côté API et réponses retenues

| manque | réponse dans ce chantier |
|---|---|
| connexion web, sessions révocables | feature `web-session` (nouvelles routes `/api/web/*`) |
| paiement web | feature `billing-web` (`/api/billing/*`) |
| export RGPD | `GET /api/users/me/export` (feature `privacy`), utilisable aussi par le mobile |
| consentement art. 9 tracé | `/api/privacy/consents` (feature `privacy`) |
| plafond de likes côté serveur | middleware `like-allowance` devant `POST /api/swipes`, `GET /api/likes/allowance` |
| filtres par courant, cashrout, Shabbat, intention, vérifié | **pas de nouveau filtre serveur** : l'algorithme de découverte est réécrit par la session back-office (`feat/backoffice-matching`). Le web règle âge, distance et genre recherché par `PUT /api/profile` (comme le mobile) et affine le lot reçu avec les filtres avancés (mazl+). Écart signalé au rapport. |
| annulation de swipe | pas de route : le web retient un « passer » 5 s avant de l'envoyer (ADR-W09) |
| visiteurs de profil | pas d'API (le mobile appelle une route absente) : onglet présent, état « bientôt disponible » |
| statistiques de profil | composé à partir des routes existantes, sans chiffre inventé |
| mode Shabbat serveur | calcul côté client (même méthode que le mobile : allumage 18 min avant le coucher, sortie à 8,5°) ; position = dernière position du profil, sinon Paris |
| Shadchan | pas d'API (écran mobile statique) : l'accueil explique la sélection la plus compatible du jour avec les critères réellement partagés |
| recherche de conversation | filtrage local de la liste `GET /api/conversations` (noms seulement, jamais le contenu) |

## 4. Sécurité et RGPD (rappel des exigences)

- URL de médias signées 1 h : jamais stockées (ni `localStorage`, ni service worker) ; listes
  rechargées avant 50 min ; une image en erreur provoque un rechargement des données.
- Une ressource hors conversation répond 404 (déjà vrai côté API ; le web affiche « introuvable »).
- Aucun contenu de message dans les journaux ni dans une quelconque mesure d'audience : **le web
  n'embarque aucun outil d'analytics, aucun pixel** (CSP `connect-src 'self'`).
- Session web courte et révocable : cookie `__Host-` HttpOnly, SameSite=Strict, inactivité 4 h,
  durée absolue 7 jours, révocable depuis l'app et depuis le web (ADR-W02).
- Mêmes plafonds que le mobile (les routes sont les mêmes), anti-bot à la connexion par preuve
  de travail sans service tiers (ADR-W03).
- Les captures d'écran ne peuvent pas être empêchées sur le web : c'est dit dans Réglages et dans
  la visionneuse photo ; le mode discret limite seulement le regard par-dessus l'épaule.
- Données de pratique religieuse (art. 9) : consentement explicite et séparé, retirable ;
  aucun pixel publicitaire dans l'espace connecté (ADR-W06).

## 5. Plan par lots

| lot | contenu | qui |
|---|---|---|
| 0 | cadrage, ADR, dépendances | orchestrateur |
| 1 | backend `web-session` (TDD : unitaires + intégration) | agent A |
| 2 | backend `billing-web` Stripe (TDD, faux respectant l'API Stripe) + CGV | agent B |
| 3 | backend `privacy` (consentement, export) + `like-allowance` | agent C |
| 4 | fondations du front : jetons, composants, routeur, client API, coque, service du bundle, CSP | orchestrateur |
| 5 | écrans (en parallèle, un dossier `web/src/features/<x>` par agent) | agents D à H |
| 6 | intégration, e2e Playwright, captures clair/sombre, `RAPPORT.md` | orchestrateur + agent |
