# ADR-W01 — Hébergement : `app.mazl.app`, même processus que l'API

Date : 2026-10-24. Statut : accepté (à confirmer par Renaud avant le DNS).

## Contexte
Deux options : `mazl.app/app` (même origine que la vitrine et la console d'administration) ou
`app.mazl.app` (origine dédiée). La vitrine et la console autorisent `'unsafe-inline'` dans leur
CSP ; une faille XSS sur ces pages, sur la même origine, pourrait agir avec la session web d'un
membre (cookies et `fetch` même origine).

## Décision
- Le site est servi sur **`app.mazl.app`**, origine dédiée, avec une CSP stricte sans
  `'unsafe-inline'` pour les scripts, `frame-ancestors 'none'`, `connect-src 'self'`.
- **Même conteneur et même processus Bun** que l'API (une seule application Coolify, un domaine
  de plus) : pas de CORS, pas de second déploiement, WebSocket sur la même origine.
- Le bundle est **construit** (`bun run web:build` → `web/dist`, noms hachés) puis servi par la
  feature `src/features/web-app/` sous `/app/*` avec ses propres en-têtes (une route
  `HTMLBundle` de `Bun.serve` ne permet pas de poser la CSP). En développement, `web/dev.ts`
  utilise l'import HTML de Bun avec HMR et relaie `/api` et `/ws` vers le backend.
- Variable `WEB_ORIGIN` (ex. `https://app.mazl.app`). Quand elle est définie :
  - le cookie de session n'est accepté et posé que si l'en-tête `Host` correspond ;
  - sur `app.mazl.app`, tout chemin hors `/app`, `/api`, `/ws`, `/media` redirige vers `/app` ;
  - sur un autre hôte, `/app` redirige vers `WEB_ORIGIN`.
  Sans `WEB_ORIGIN` (développement, tests), le site est servi sous `/app` de l'hôte courant.
- `index.html` : `Cache-Control: no-store` ; ressources hachées : `public, max-age=31536000, immutable`.

## Conséquences
- À faire au déploiement (non fait, interdit sans accord) : enregistrement DNS `app.mazl.app`,
  domaine ajouté à l'application Coolify, `WEB_ORIGIN` défini, étape `bun run web:build` dans le
  `Dockerfile` (ajoutée dans ce chantier).

## Complément du 2026-10-24 : servir le site à la racine de `mazl.app`
Renaud a demandé, via la session back-office, que `https://mazl.app` serve le nouveau client.
C'est une affaire de configuration : `WEB_ORIGIN=https://mazl.app`. Sur cet hôte, `/` mène à
`/app` (la vitrine actuelle disparaît), et restent servis : `/api/*`, `/ws`, `/media/*` et les
pages juridiques statiques, sans script (`/cgu`, `/cgv`, `/confidentialite`, `/terms`,
`/privacy`).

Relecture de sécurité M5 : les pages qui ont leurs propres scripts et une CSP plus lâche ne
partagent jamais l'origine du site. Sur l'hôte du site, `/verify*` (lien de dépôt de
documents, `verify.js` et `admin-escape.js`), `/console*` (back-office) et `/admin*`
redirigent vers l'hôte de l'API (`PUBLIC_BASE_URL`, par exemple `https://api.mazl.app`),
requête comprise : les liens déjà envoyés par e-mail restent valides. Sans hôte d'API
distinct, seul le lien de dépôt de documents reste servi ; la console et `/admin` jamais.

## 2026-10-24 : découplage du site et de l'API
Décision de Renaud : « il faut découpler le back-end du front » et plus aucune perte lors des
mises en production. Le choix « même conteneur et même processus » ci-dessus est **remplacé** ;
les règles de sécurité de cette décision (CSP stricte, `frame-ancestors 'none'`, cache,
isolement par hôte, relecture M5) sont **conservées à l'identique**.

- Deux conteneurs, deux déploiements Coolify : le **site** (`web/Dockerfile`, Caddy) sert
  `mazl.app` ; l'**API** (`Dockerfile`) sert `api.mazl.app` et ne sert plus le site quand
  `SERVE_WEBSITE=false` (défaut inchangé tant que la bascule n'est pas faite).
- Le site sert le client construit (`web/dist`) sous `/app` et les pages juridiques, avec
  exactement les en-têtes et règles de cache de `src/features/web-app/`. Le Caddyfile est
  rendu au démarrage à partir de ces modules (`security-headers.ts`, `cache-rules.ts`,
  `site-rules.ts`), pas recopié : la source des règles reste unique, et les tests comparent le
  texte généré au code de l'API.
- Les règles d'hôte du complément du 2026-10-24 restent : `/` mène à `/app` ; `/verify*`,
  `/console*`, `/admin*` redirigent vers `PUBLIC_BASE_URL` (chemin et requête gardés) ; `/terms`
  et `/privacy` redirigent vers les pages juridiques.
- Le site fait **proxy** de `/api/*`, `/ws` (mise à niveau WebSocket comprise) et `/media/*` vers
  l'API (`API_UPSTREAM`, réseau Docker interne). Le client reste ainsi **sur la même origine** :
  le cookie `__Host-mazl_web` (`SameSite=Strict`) et le contrôle CSRF (`Origin` = `WEB_ORIGIN`)
  sont inchangés, et le site transmet l'en-tête `Host` d'origine, que l'API compare à `WEB_ORIGIN`.
- Adresse du client : le site renvoie à l'API une seule entrée d'`X-Forwarded-For`, le vrai
  client, de sorte que `TRUSTED_PROXY_HOPS=1` et les limites de débit par membre ne changent pas.
- Un site qui ne joint plus l'API reste affiché et répond `/health` ; les connexions refusées
  sont réessayées 5 s, ce qui couvre le changement de conteneur d'un déploiement de l'API.
- Pourquoi Caddy : un seul binaire statique, image officielle à version épinglée, qui fait les
  fichiers (gzip précompressé), les redirections, le proxy HTTP et WebSocket (sans réglage
  d'en-têtes `Upgrade`) et la lecture de `X-Forwarded-For` de droite à gauche
  (`trusted_proxies_strict`, `{client_ip}`) en quelques lignes générées. nginx aurait convenu
  (module realip), au prix d'une configuration plus longue pour le même résultat.
- Ce qui s'applique désormais à l'API : `/` et les anciennes adresses du site (`/app*`, pages
  juridiques) redirigent vers `WEB_ORIGIN` ; la vitrine historique, `script.js` ne sont plus servis.
- Vitrine (`landing/`, ajoutée à la racine de `mazl.app` entre-temps) : même règle que le
  client. `landing/dist` est construit dans `web/Dockerfile` ; le site sert `index.html` à `/`
  (jamais mis en cache) et le reste sous `/l/` (fichiers hachés et polices `immutable`, copies
  gzip si acceptées, un fichier absent, `/l/` lui-même et les `.gz` appelés par leur nom sont des
  404 jamais mis en cache), avec les mêmes en-têtes que le client. `www.<hôte du site>` redirige
  en 301 vers le site, chemin et requête gardés. Le préfixe `/l/` et la règle `www` vivent dans
  `site-rules.ts`, la règle de cache dans `cache-rules.ts`. Sans `landing/dist`, l'API continue de
  rediriger `/` vers `/app` ; le conteneur du site, lui, construit toujours la vitrine.
- Procédure de bascule, variables, chemins surveillés : `docs/deploy/README.md`.
