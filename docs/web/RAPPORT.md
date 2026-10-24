# MAZL Web — rapport pour Renaud

> 24 octobre 2026. Branche locale `feat/web-desktop` (dépôt `/Users/nono/mazl`, worktree
> `/Users/nono/mazl-web`). **Rien n'est poussé ni déployé** : c'est à toi de le décider.
> Le cadrage est dans `docs/web/CADRAGE.md`, les onze décisions dans `docs/web/adr/`.

## En bref

- Le **site web bureau** de MAZL est fait : 14 écrans, en clair et en sombre, fidèles à la
  charte « Encre & Tekhelet ». Il appelle **les mêmes routes d'API que l'app**, sans en
  dupliquer la logique.
- **Connexion** par QR code depuis l'app (comme WhatsApp Web), Google ou Apple. Les sessions
  web sont courtes et révocables depuis l'app.
- **Paiement web Stripe**, en mode TEST : Checkout, portail client, webhook signé et
  idempotent. Le droit mazl+ et les crédits sont réconciliés avec l'App Store, et le
  renoncement au droit de rétractation est recueilli et prouvé. Les CGV et la politique de
  confidentialité sont à jour.
- **RGPD** : consentement explicite et séparé pour la pratique religieuse (art. 9), export
  des données en JSON, aucun traceur dans l'espace membre.
- **App iOS** : nouvel écran Réglages › Confidentialité et sécurité › « Ordinateurs
  connectés », avec lecteur de QR, liste et révocation des ordinateurs.
- **Deux failles corrigées** dans l'API existante :
  - « Voir qui vous a aimé » : la photo nette partait chez les membres gratuits.
  - Le plafond de 10 likes par jour n'était compté que par l'app.
- **Tests** :
  - unitaires : 2051 verts, 0 échec (modèles de visage téléchargés par `bun run models:fetch`) ;
  - intégration : la suite complète (`tests/*.test.ts` hors `*-pg`) passe contre un vrai
    serveur, Postgres et le faux Stripe : 554 réussis, 0 échec ;
  - e2e : 13 scénarios Playwright (83 cas) verts, chacun sur une base vierge ;
  - Flutter : 1623 tests verts, `dart analyze` propre ;
  - typecheck et ESLint stricts : zéro avertissement.
- La branche contient **déjà** `feat/backoffice-matching` (PR #6), fusionnée et testée
  ensemble, à la demande de la session back-office.

## Ce qui est fait

### Côté serveur (une feature isolée par sujet, dans `src/features/`)

| feature | contenu | ADR |
|---|---|---|
| `web-session` | connexion par QR code (appairage de 120 s à usage unique, approbation dans l'app), par Google ou Apple (comptes existants seulement) ; preuve de travail anti-bot sans service tiers ; sessions web (cookie `__Host-`, HttpOnly, SameSite=Strict, 4 h d'inactivité, 7 jours au plus) ; « pont » qui transforme le cookie en JWT de 60 s pour que toutes les routes existantes marchent sans changement ; ticket WebSocket ; révocation qui ferme aussi les sockets | W02, W03 |
| `web-app` | sert le site construit sous `/app` avec une CSP stricte, cache long pour les fichiers hachés, gzip ; isolement par hôte avec `WEB_ORIGIN` | W01 |
| `billing-web` | Stripe Checkout (mazl+ 1, 3, 6, 12 mois ; Boost 1 et 3 ; Super Likes 5 et 15), portail client, webhook (signature officielle, idempotence, état relu chez Stripe), projection sur la ligne unique `subscriptions`, crédits par `recordPurchase` (pas de double crédit), remboursements, preuve du renoncement, résiliation à la suppression du compte | W04, W05 |
| `privacy` | consentement art. 9 versionné et historisé, retrait qui efface les champs ; `GET /api/users/me/export` (JSON, 3 par jour, listes d'autorisation, aucun secret) | W06 |
| `like-allowance` | 10 likes par jour sans mazl+, comptés par le serveur (`402 likes_exhausted`), `GET /api/likes/allowance` | W07 |
| `likes-visibility` | sans mazl+, les likes reçus ne contiennent plus photo, identifiant ni âge | W11 |

Pour tenir le temps réel, deux modifications minimales hors de ces features : `src/auth.ts`
(durée de JWT et audience Apple paramétrables) et le câblage dans `src/index.ts`.

### Le site (`web/`, React 19 + Bun, sans Vite)

| écran | ce qu'il fait |
|---|---|
| Connexion | QR code, Google, Apple, « Pas encore de compte ? » (QR vers l'App Store) |
| Consentement | art. 9, refus possible, puis retrait dans Réglages |
| Accueil | Sélections du jour, « Le mot du Shadchan » (critères réellement partagés), raccourcis |
| Découvrir | 3 colonnes (filtres 240 px, carte 480 px, profil 360 px), clavier ← → ↑ Z I Espace, « passer » annulable 5 s, feuille de match, Boost, filtres avancés mazl+ |
| Likes et visiteurs | likes reçus floutés sans mazl+, réponse directe avec ; visiteurs : état honnête |
| Messages | 3 colonnes (liste, fil, profil), Cmd/Ctrl+K, temps réel, envoi optimiste, photos, lecture des vocaux, réactions, réponse, retrait, signalement, anti-arnaque, blocage, demande de mode couple |
| Profil | « tel que vu par les autres », badge ou QR de vérification |
| Modifier le profil | 6 photos en glisser-déposer (et au clavier), 3 prompts, informations, pratique (si consentement), aperçu en direct |
| Statistiques | uniquement des chiffres que l'API connaît, complétude du profil |
| Événements | liste, détail, inscription |
| Couple | navigation exclusive, Notre espace, activités, calendrier des fêtes, événements, bannière de demande, Mazel Tov |
| Réglages | compte, thème, pause Shabbat, mode discret, ordinateurs connectés, confidentialité, export, bloqués, vérification, suppression |
| mazl+ | prix TTC lus chez Stripe, case de renoncement obligatoire, paiement, portail, cas App Store, double abonnement |
| transverses | pause Shabbat et fêtes, mode discret (Échap ×2), aide clavier (« ? ») |

Réservé au mobile, avec un QR vers l'app : vérification selfie et puce NFC, appel vidéo,
position précise, notifications, achats App Store, création de compte, enregistrement de
messages vocaux.

### Côté app iOS (`mobile/`)
- Écran « Ordinateurs connectés » : liste, déconnexion d'un ou de tous les ordinateurs.
- Lecteur de QR (`mobile_scanner`), qui n'accepte que `mazl-web:<code>`.
- Feuille de confirmation : navigateur, heure, avertissement contre le scan d'un code tendu
  par un tiers.

## Captures (`docs/web/captures/`)

Chaque écran en clair et en sombre, en 1440 × 900 (rétina), sur une communauté fictive
(silhouettes synthétiques, aucune personne réelle) :

| | |
|---|---|
| 01 connexion | 15 réglages · ordinateurs connectés |
| 02 accueil | 16 mazl+ |
| 03 découvrir | 17 mazl+ actif |
| 04 découvrir · filtres mazl+ | 18 événements |
| 05 match (clair) | 19 événement · détail |
| 06 messages | 20 couple · notre espace |
| 07 messages · recherche | 21 couple · activités |
| 08 messages · actions | 22 couple · calendrier |
| 09 profil | 23 couple · événements (clair) |
| 10 modifier le profil | 24 consentement art. 9 |
| 11 statistiques | 25 pause Shabbat |
| 12 likes (sans mazl+) | 26 mode discret (clair) |
| 13 likes (mazl+) | 27 raccourcis clavier |
| 14 réglages | |

## Lancer le site

```bash
cd /Users/nono/mazl-web
bun install
bun run web:build                     # construit web/dist (le Dockerfile le fait aussi)
NODE_ENV=development bun src/index.ts # puis http://localhost:3000/app
bun run web:watch                     # reconstruit le site à chaque modification
```

- **En local**, sans l'app de téléphone, connecte-toi par le QR avec un membre de test :
  `tests/e2e/support/browser.ts` montre l'enchaînement des appels (le « téléphone », c'est
  le JWT du membre).
- **Vérifications** :
  - `bun run typecheck` ;
  - `bun run web:check` (TypeScript et ESLint stricts du site) ;
  - `bun test tests/unit tests/web-client` ;
  - `bun run test:e2e` : construit le site et lance un serveur par scénario sur une base
    jetable, avec un faux Stripe ; il faut le Postgres de test sur le port 55471, sinon
    `TEST_DATABASE_URL`.
- **Variables** : toutes sont dans `.env.example`.
  - `WEB_ORIGIN` ;
  - `APPLE_WEB_SERVICES_ID` (facultatif) ;
  - `WEB_POW_DIFFICULTY` (18 par défaut) ;
  - `STRIPE_*`.

## Passer Stripe en production

1. **Compte Stripe** au nom de l'éditeur : raison sociale, SIREN, TVA, IBAN. Ce sont aussi
   les mentions `[À COMPLÉTER]` des CGV.
2. **Mode test d'abord** (Développeurs › Clés API) :
   - créer 8 produits, chacun avec un prix en euros et `Tax behavior = Inclusive` (TTC) :
     mazl+ 1, 3, 6 et 12 mois (récurrents, intervalle de 1, 3, 6 et 12 mois), Boost ×1,
     Boost ×3, Super Likes ×5, Super Likes ×15 ;
   - reporter chaque `price_…` dans `STRIPE_PRICE_PLUS_1M` … `STRIPE_PRICE_SUPERLIKES_15`.
3. **Portail client** (Paramètres › Facturation) : résiliation en fin de période, mise à jour
   du moyen de paiement, factures, changement de formule.
4. **Webhook** (Développeurs › Webhooks) : URL `https://<domaine>/api/billing/stripe/webhook`.
   - Événements : `checkout.session.completed`, `checkout.session.async_payment_succeeded`,
     `customer.subscription.updated`, `customer.subscription.deleted`,
     `invoice.payment_failed`, `charge.refunded`, `charge.dispute.created`.
   - Copier le secret de signature dans `STRIPE_WEBHOOK_SECRET`.
5. **Essai de bout en bout** en mode test, avec la carte 4242 4242 4242 4242 (et
   `stripe listen` en local).
6. **Passage en production** :
   - refaire les produits, les prix et le webhook en mode live, puis mettre `sk_live_…`
     ET `STRIPE_ALLOW_LIVE=true` (sinon le serveur refuse de démarrer, volontairement) ;
   - option : offre de bienvenue à 9,99 € via un coupon Stripe (non codée).
7. **Juridique** : faire relire la mention de renoncement et les CGV mises à jour, et
   compléter `docs/legal/A_COMPLETER.md`.
8. **Sans clé**, rien ne casse : le site affiche « Le paiement sur le site sera bientôt
   disponible », et les routes de paiement répondent 503.

**App Store** (ADR W05) : l'app iOS ne doit montrer **ni lien ni bouton** vers le paiement web
(vitrine française). Elle peut reconnaître un mazl+ acheté sur le site (règle 3.1.3(b)), et
c'est ce qu'elle fait.

## Décisions prises (détail dans `docs/web/adr/`)

- **W01 Hébergement** : `app.mazl.app`, même processus que l'API. Option ajoutée à la demande
  transmise par la session back-office : `WEB_ORIGIN=https://mazl.app` sert le site à la
  racine de `mazl.app`. `/cgu`, `/cgv`, `/confidentialite`, `/verify`, `/console` et l'API
  restent servis ; l'ancien `/admin` reste sur `api.mazl.app`.
- **W02 Sessions web** : cookie `__Host-`, 4 h d'inactivité, 7 jours au plus, pont vers un JWT
  de 60 s, révocables depuis l'app.
- **W03 Connexion** : QR d'abord, Google et Apple pour les comptes existants seulement ; preuve
  de travail au lieu d'un captcha tiers.
- **W04 Stripe** : un seul droit mazl+ par membre. Un achat web est refusé si un abonnement
  App Store est actif. Le double abonnement est détecté et expliqué.
- **W05 App Store** : aucun lien d'achat dans l'app.
- **W06 RGPD** : consentement art. 9 recueilli sur le web et dans l'app, exigé par le serveur
  (champs ignorés sans accord) ; export JSON complet.
- **W07** plafond de likes côté serveur ; **W08** pile (React, CSS natif, lucide, uqr,
  kosher-zmanim) ; **W09** « Annuler » sans route (passe retenu 5 s) ; **W10** pause Shabbat
  calculée comme l'app, mode discret ; **W11** likes reçus réduits sans mazl+.
- **Vouvoiement** partout, comme l'UI mobile actuelle.

## Ce qui reste, et ce qu'il faut savoir

### Avant une mise en production
1. **Publier la nouvelle version iOS** (lecteur QR). Sans elle, la connexion web ne marche
   que par Google (client web configuré, domaine autorisé dans la console Google) ou par
   Apple (Services ID à créer).
2. **Un seul conteneur pour `mazl.app` et `api.mazl.app`.** Le registre des WebSockets et les
   limites de débit sont en mémoire, par processus. Si le site et l'API tournent dans deux
   applications Coolify, un message envoyé depuis l'app n'arrive pas en temps réel sur le
   site. Je l'ai signalé à la session back-office.
3. DNS et domaine Coolify, `WEB_ORIGIN`, HTTPS obligatoire (cookie `__Host-`) : rien n'a
   été touché.

### Écarts connus, assumés et documentés
- **Filtres avancés** (courant, cashrout, Shabbat, intention, vérifié) : l'API n'en a pas.
  Le web affine le lot reçu, et le moteur de classement du back-office est le bon endroit
  pour en faire de vrais filtres.
- **Visiteurs de profil et vues** : aucune mesure côté serveur. L'onglet le dit, et le
  mobile appelle déjà des routes absentes.
- **« Revenir en arrière »** : aucune route serveur. Le web retient un « passer » 5 s.
- **App mobile, à reprendre** :
  - gérer le `402 likes_exhausted` (aujourd'hui, seul son compteur local l'en empêche) ;
  - afficher des cartes floutées sans photo dans « Ils vous ont aimé ».
- **Couple** :
  - `GET /api/couple/:id/question` renvoie la réponse du partenaire avant qu'on ait répondu.
    Le web la masque, mais le serveur devrait le faire.
  - Les événements de couple payants n'ont pas de route de paiement. Le web les montre
    « Paiement requis ».
- **Messages** : pas de glisser pour répondre, pas de double-tap ❤️, pas de défilement vers
  le message cité, pas d'enregistrement vocal (le navigateur n'enregistre pas en AAC/M4A).
- **Une socket par onglet** : au-delà de 5 sockets (app et onglets confondus), le serveur
  ferme la plus ancienne.
- **Deux faux Stripe dans les tests** (`tests/support/fake-stripe.ts` pour l'intégration,
  `tests/e2e/support/fake-stripe-server.ts` pour l'e2e avec page de paiement) : à fusionner.

### Tests
- Les tests de vérification faciale exigent les modèles ONNX : `bun run models:fetch` avant
  la suite.
- La suite d'intégration complète a d'abord montré 19 échecs : la session back-office les a
  relevés et je les ai corrigés :
  - trois tests lisaient l'identifiant ou la photo des likes reçus sans mazl+ (contrat W11) ;
  - le test d'export écrivait dans une table de remplacement ;
  - un test fermait la connexion à la base que partagent tous les fichiers d'intégration.
  Elle est maintenant verte : 554 réussis, 0 échec (après les correctifs de sécurité).

## Sécurité : relecture indépendante et correctifs (24 octobre 2026)

Une relecture de sécurité indépendante, transmise par la session d'origine, a relevé un
point haut, six moyens et sept bas. Chacun a été vérifié dans le code, corrigé en TDD (un
test qui échoue sur l'ancien code, puis le correctif) et commité à part. La session
back-office a remis sa PR #7 en brouillon en attendant.

| point | constat vérifié | correctif | commit |
|---|---|---|---|
| H1 (haut) | le ticket WebSocket était un JWT de 10 min donné à la page : utilisé comme `Bearer`, il ouvrait toute l'API et pouvait approuver un QR (session de 7 j) | ticket opaque, aléatoire, à usage unique, 60 s, oublié à la révocation ; JWT du pont marqué `aud: "web-bridge"` + id de session ; les routes d'appairage n'acceptent que les jetons de l'app | `4948f60` |
| M1 | connexion Google/Apple sans contrôle d'origine ; Hono lit un `text/plain` comme du JSON (formulaire tiers) | tout `POST /api/web/auth/*` exige `application/json` (415) et refuse une autre origine (403) | `59cc208` |
| M2 | deux onglets ouvraient deux Checkout et deux abonnements | expiration des Checkout d'abonnement ouverts du client, création sérialisée par membre ; au webhook, le second abonnement (plus récent qu'un Stripe vivant, ou nouveau face à un App Store vivant) est annulé et remboursé | `f5ba7dd` |
| M3 | le plafond comptait `swipes` (upsert : un « passer » rendait un like) ; course vérification/écriture | journal du jour en ajout seul, réservation sous `pg_advisory_xact_lock`, rendue si le swipe échoue ; 15 likes simultanés → exactement 10 | `12af87e` |
| M4 | `PUT /api/profile` gardait la pratique sans consentement ou après retrait | le serveur ignore en silence les 4 champs sans consentement valide ; l'app reçoit l'écran de consentement (création, édition, réglages, retrait) | `ca8d4db`, `ce2a46d`…`5ce5cb0` |
| M5 | `/verify` et `/console` sur l'origine du site, CSP `'unsafe-inline'` ; `verify.js` importait `/admin-escape.js`, absent : la page cassait | sur l'hôte du site, `/verify*`, `/console*`, `/admin*` redirigent vers l'hôte de l'API (requête conservée) ; seules les pages juridiques, sans script, restent | `994cf50` |
| M6 | le reprise des crédits dépendait de `charge.metadata.offer` ; pas de litiges | remboursement total et `charge.dispute.created` → `refundPurchase(paymentIntent)` décidé d'après `credit_purchases` (révocation mémorisée si le remboursement arrive avant le crédit) | `4bf6e19` |
| B1, B8 | tickets identiques dans la même seconde ; ticket valable après révocation | réglés par H1 (ticket aléatoire, usage unique, oublié à la révocation) | `4948f60` |
| B2 | à l'effacement, seuls les abonnements connus de MAZL étaient annulés ; le client Stripe restait | tous les abonnements du client chez Stripe sont annulés, puis le client est supprimé après l'effacement (Stripe garde les factures) | `b48897b` |
| B3 | un remboursement d'abonnement sans annulation garde mazl+ | **non codé, procédure** : pour rembourser un abonnement, l'annuler immédiatement dans Stripe (le webhook `customer.subscription.deleted` retire mazl+) ; à automatiser si le support rembourse souvent | — |
| B4 | pas de confirmation du renoncement sur support durable (L221-13) | le texte daté du renoncement s'affiche au paiement et figure en pied de la facture e-mailée des packs. **Reste** : pour l'abonnement, Checkout n'a pas de pied de facture par session, il faut un e-mail de confirmation (non envoyé, e-mails réels interdits dans ce chantier). **Juridique** : la base L221-28 13° (contenu numérique) est discutable pour un abonnement, qui ressemble plutôt à un service (L221-28 1° ne joue qu'après pleine exécution ; sinon L221-25, paiement au prorata en cas de rétractation) : à faire trancher par le conseil | `731a116` |
| B6 | l'écran d'approbation ne montrait que le navigateur et l'heure | adresse IP masquée du navigateur (`198.51.100.x`) affichée dans l'app. Pas de ville : il faudrait un service de géolocalisation IP (tiers, transfert de données), écarté | `2501dec` |
| B7 | l'export RGPD omettait la modération et la vérification | sanctions, suspensions, actions visant le compte, sessions de selfie, vérification d'identité, présence d'un gabarit facial, tentatives, dossier de liste d'attente ; sans nom d'agent, notes internes, gabarit ni empreinte de document | `93805e4` |

Points de vigilance qui restent :
- les membres qui ont renseigné leur pratique avant ce changement n'ont pas de consentement
  tracé : leurs données restent, mais ne sont plus modifiables sans accord ; leur demander
  l'accord (l'app le fait à l'ouverture de l'édition), et décider d'un effacement en
  l'absence de réponse ;
- les notes internes des agents (documents, sanctions) ne sont pas exportées : à valider
  avec le conseil (l'art. 15 peut les viser) ;
- `/console` vit désormais sur l'hôte de l'API (`api.mazl.app/console`) quand
  `WEB_ORIGIN=https://mazl.app` : signalé à la session back-office ;
- `GET /api/couple/:id/question` renvoie encore la réponse du partenaire avant la sienne
  (masquée par le site, à corriger côté serveur par le propriétaire du mode couple).

## Organisation
- **Orchestration** : moi (Opus) pour le cadrage, les contrats, la relecture de chaque diff,
  les corrections et l'intégration ; 12 sous-agents Sonnet, chacun dans son worktree :
  - 3 pour le backend (sessions, Stripe, RGPD et plafond) ;
  - 5 pour les écrans ;
  - 1 pour l'app mobile ;
  - 3 pour l'exploration.
- **Correctifs faits à l'intégration** :
  - CSP des médias signés (hôte de l'API) ;
  - fuite des likes reçus ;
  - fuseau du serveur e2e ;
  - identifiants du faux Stripe ;
  - logo de la barre ;
  - consentement des membres de test ;
  - isolement des scénarios e2e.
- Les worktrees des agents (`/Users/nono/mazl-web-a` à `-i`) sont fusionnés. Leurs branches
  `web/*` peuvent être supprimées.
