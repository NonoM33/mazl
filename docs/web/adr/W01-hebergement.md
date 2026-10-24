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
`/app` (la vitrine actuelle disparaît), et restent servis : `/api/*`, `/ws`, `/media/*`,
`/console` (back-office), les pages juridiques (`/cgu`, `/cgv`, `/confidentialite`, `/terms`,
`/privacy`) et le lien de dépôt de documents (`/verify`). L'ancienne console `/admin` n'y est
plus servie : elle reste sur `api.mazl.app`.
Coût de sécurité accepté : le site partage alors son origine avec la console du back-office ;
la console doit garder une CSP stricte. `app.mazl.app` reste l'option la plus isolée.
