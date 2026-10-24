# Déploiement de MAZL : deux conteneurs, deux déploiements

Décision de Renaud du 2026-10-24 : le site web et l'API se déploient séparément, pour qu'une mise
en production de l'un ne coupe jamais l'autre. Le détail technique et les règles de sécurité
sont dans `docs/web/adr/W01-hebergement.md` (section « 2026-10-24 : découplage »).

| conteneur | construit depuis | sert | domaine |
|---|---|---|---|
| **API** | `Dockerfile` (racine) | `/api/*`, `/ws`, `/media/*`, `/verify*`, `/console*`, `/admin*` | `api.mazl.app` |
| **Site** | `web/Dockerfile` | le client web sous `/app`, les pages juridiques, un proxy vers l'API | `mazl.app` |

Le site est un conteneur Caddy (version 2.10.2, épinglée par son empreinte dans `web/Dockerfile`).
Caddy fait d'un seul processus le service de fichiers, les redirections, le proxy HTTP et le
proxy WebSocket (`/ws`), avec la mise à jour d'`X-Forwarded-For` dont l'API a besoin (voir plus
bas). Le client web reste sur la **même origine** que `/api` : le cookie de session
(`SameSite=Strict`) et le contrôle CSRF (`Origin` = `WEB_ORIGIN`) ne changent pas.

Le Caddyfile n'est pas écrit à la main : `web/front/entrypoint.sh` le produit au démarrage
(`web/front/render.ts`) à partir des modules que l'API utilise pour servir le même site
(`src/features/web-app/security-headers.ts`, `cache-rules.ts`, `site-rules.ts`). Les en-têtes
(CSP, `frame-ancestors`, HSTS…), les règles de cache et les règles d'hôte ne peuvent donc pas
diverger ; les tests `tests/unit/web-front-*.test.ts` lisent le texte généré et le comparent à
ces modules. Réglages faux ou absents : le conteneur s'arrête avant de servir quoi que ce soit.

## Variables d'environnement

### Conteneur API (variables existantes inchangées)

| variable | valeur | remarque |
|---|---|---|
| `SERVE_WEBSITE` | `false` au moment de la bascule | **nouvelle**. Absente ou autre valeur : l'API sert le site comme avant (rien ne casse avant la bascule). `false`, `0`, `no`, `off` : elle ne monte ni le client web, ni la vitrine, ni les pages juridiques ; `/`, `/app*`, `/cgu`, `/cgv`, `/confidentialite`, `/terms`, `/privacy` redirigent vers `WEB_ORIGIN`. `/verify*`, `/console*`, `/admin*` restent sur l'API. |
| `WEB_ORIGIN` | `https://mazl.app` | **inchangée**, toujours nécessaire à l'API : le cookie de session n'est accepté que si l'en-tête `Host` correspond, et le contrôle CSRF compare `Origin` à cette valeur. |
| `PUBLIC_BASE_URL` | `https://api.mazl.app` | inchangée. |
| `TRUSTED_PROXY_HOPS` | `1` (défaut) | inchangée : voir « Adresse du client ». |

Les autres (`DATABASE_URL`, `JWT_SECRET`, `ADMIN_JWT_SECRET`, `ADMIN_PASSWORD`,
`DATA_ENCRYPTION_KEY`, `MEDIA_SIGNING_KEY`, `DOC_FINGERPRINT_KEY`, Stripe, S3…) ne bougent pas.

### Conteneur site

| variable | obligatoire | exemple | rôle |
|---|---|---|---|
| `API_UPSTREAM` | oui | `http://mazl-api-internal:3000` | où joindre l'API : origine seule, sans chemin. Réseau Docker interne en production ; une URL publique `https://…` marche pour tester le proxy (limite plus bas). |
| `WEB_ORIGIN` | oui | `https://mazl.app` | adresse publique du site : HSTS (si `https`), cible des redirections vers le client. |
| `PUBLIC_BASE_URL` | oui | `https://api.mazl.app` | adresse publique de l'API : cible des redirections `/verify*`, `/console*`, `/admin*` (chemin et requête conservés) et origine des médias signés autorisée dans la CSP. Doit différer de `WEB_ORIGIN`. |
| `TRUSTED_PROXIES` | non | `private_ranges` (défaut) | adresses dont on croit `X-Forwarded-For` (Traefik). CIDR ou `private_ranges`, séparés par des espaces. |
| `PORT` | non | `8080` (défaut) | port d'écoute ; à déclarer dans Coolify (« Ports Exposes »). |

Aucun secret dans le conteneur du site.

## Adresse du client (limites de débit par membre)

`src/shared/http/client-ip.ts` fait confiance aux `TRUSTED_PROXY_HOPS` dernières entrées
d'`X-Forwarded-For` (1 par défaut : Traefik). Via le site la chaîne devient client → Traefik →
site → API. Le site lit l'en-tête de droite à gauche en sautant les proxys de confiance
(`trusted_proxies_strict`), retient le client, puis envoie à l'API **une seule** entrée
(`header_up X-Forwarded-For {client_ip}`) et retire `Forwarded` et `X-Real-Ip`. L'API, à un saut,
lit donc le vrai client, et ce qu'un navigateur écrit dans l'en-tête ne passe pas. Si le pair
direct n'est pas de confiance (conteneur exposé sans Traefik), l'adresse du pair remplace tout.

Vérifié par `web/front/e2e/run.sh` (partie A) : en-tête usurpé `6.6.6.6, 203.0.113.9` → l'API reçoit
`203.0.113.9` seul ; pair non fiable → l'API reçoit l'adresse du pair, jamais l'en-tête.
Contrôle manuel après déploiement : depuis une machine connue, appeler une route limitée par
adresse avec `-H 'X-Forwarded-For: 6.6.6.6'` et vérifier que la limite suit votre adresse.

## Chemins surveillés par Coolify (Watch Paths)

Une modification du site ne doit pas redéployer l'API, et inversement. Coolify prend des motifs
glob, avec exclusion par `!` dans les versions récentes (voir la vérification plus bas).

**Application site** (`web/Dockerfile`, base `/`) :

```
web/src/**
web/assets/**
web/index.html
web/build.ts
web/tsconfig.json
web/Dockerfile
web/front/**
!web/front/e2e/**
public/cgu.html
public/cgv.html
public/confidentialite.html
public/style.css
public/favicon.svg
src/features/web-app/cache-rules.ts
src/features/web-app/security-headers.ts
src/features/web-app/site-rules.ts
package.json
bun.lock
```

Les trois fichiers de `src/features/web-app/` sont le contrat partagé (en-têtes, cache, règles
d'hôte) : les modifier redéploie légitimement les deux conteneurs. `package.json` et `bun.lock`
sont partagés aussi, le client web étant construit avec les dépendances de la racine.

**Application API** (`Dockerfile`, base `/`) :

```
src/**
scripts/**
!scripts/deploy/**
console/**
assets/**
data/**
package.json
bun.lock
Dockerfile
.dockerignore
public/verify.html
public/verify.js
public/admin*
public/style.css
public/favicon.svg
```

`scripts/**` contient le téléchargement des modèles de visage (`fetch-face-models.ts`, étape du
`Dockerfile`). Tant que l'image de l'API construit encore le client web (voir « Phase 2 »), `web/**`
n'est volontairement pas surveillé : après la bascule, l'API ne sert plus ces fichiers.

À vérifier à la première configuration : que la version de Coolify installée comprend bien la
négation `!` (sinon, ôter la ligne : l'effet se limite à un redéploiement inutile).

## Bascule (runbook)

Le DNS ne change pas : `mazl.app` et `api.mazl.app` pointent déjà vers le serveur ; c'est
l'application Coolify (donc l'étiquette Traefik) qui reçoit le domaine. Toute étape est
réversible tant que la phase 2 n'est pas faite.

**Point à vérifier en premier, sur stg : comment le site joint l'API.** Activer « Connect to
Predefined Network » sur les deux applications. Puis relever, sur le serveur, le nom DNS de l'API
sur ce réseau (`docker inspect <conteneur API>`, section `Networks › Aliases`). Si seul un nom
suffixé par un horodatage existe (il change à chaque déploiement de l'API), donner un alias fixe à
l'application API (Coolify › Custom Docker Options › `--network-alias mazl-api-internal`) ou
retenir l'alias d'application, et l'écrire dans `API_UPSTREAM`. Ne pas passer en production sans
un nom stable. Le site réessaie 5 s une connexion refusée (`lb_try_duration`), ce qui absorbe le
changement de conteneur au déploiement de l'API, pas un nom introuvable.

### Staging d'abord

1. Déployer l'API stg avec ce code, `SERVE_WEBSITE` **non défini** : rien ne change (vérifier la
   vitrine et `/app` comme avant).
2. Créer l'application « site » stg : même dépôt, build pack Dockerfile, base `/`, Dockerfile
   `/web/Dockerfile`, port 8080, chemin de santé `/health`, chemins surveillés ci-dessus, domaine
   de test (par exemple `stg-site.mazl.157.180.43.90.sslip.io`). Variables : `API_UPSTREAM`,
   `WEB_ORIGIN` = ce domaine en `https`, `PUBLIC_BASE_URL` = l'URL publique de l'API stg.
3. Sur l'API stg : `WEB_ORIGIN` = le domaine de test, `SERVE_WEBSITE=false`, redéployer.
4. Contrôles (remplacer `$SITE` par l'origine du site) :
   - `curl -sI $SITE/` → 302 vers `$SITE/app` ;
   - `curl -sI $SITE/app/` → 200, avec `Content-Security-Policy` contenant `frame-ancestors 'none'`,
     `Cache-Control: no-store` ; un fichier haché sous `/app/` → `immutable` ;
   - `curl -s $SITE/api/health` → 200 (proxy) ; `curl -s $SITE/health` → `ok` ;
   - `curl -sI $SITE/console` et `/verify?token=x` → 302 vers l'hôte de l'API, chemin et requête gardés ;
   - `/terms` → 301 `/cgu` ; `/cgu`, `/cgv`, `/confidentialite` → 200 ;
   - WebSocket : `curl -si -H 'Connection: Upgrade' -H 'Upgrade: websocket' -H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' $SITE/ws` → `401 Token required` de l'API (pas de 502) ;
   - dans un navigateur : connexion par QR, envoi d'un message en temps réel (le WebSocket passe par le proxy), « Se déconnecter » ;
   - côté API : `api.<stg>/` redirige vers le site, `api.<stg>/verify.html` reste servi.
5. Déployer l'API stg une seconde fois pendant qu'une page du site est ouverte : le site reste
   affiché, les appels `/api` n'échouent pas plus de quelques secondes.

### Production

6. Sauvegarde fraîche (`bun scripts/deploy/deploy.ts prod` la fait avant tout déploiement de
   l'API) puis déployer l'API prod avec ce code, `SERVE_WEBSITE` toujours **non défini** : aucun
   changement visible.
7. Créer l'application « site » prod comme en 2, sous un **domaine temporaire** (pas encore
   `mazl.app`), `WEB_ORIGIN=https://mazl.app`, `PUBLIC_BASE_URL=https://api.mazl.app`,
   `API_UPSTREAM` = l'adresse interne validée en stg. Contrôler avec `curl -H 'Host: <domaine temporaire>'`
   les points 4 qui ne dépendent pas du cookie (en-têtes, redirections, proxy, `/health`).
8. Bascule, en un seul geste (quelques minutes à faire hors pic) :
   a. API prod : retirer `mazl.app` de ses domaines (garder `api.mazl.app`), ajouter
      `SERVE_WEBSITE=false`, redéployer ;
   b. site prod : remplacer le domaine temporaire par `mazl.app`, redéployer.
   Entre a et b, `mazl.app` ne répond pas (le site web seulement ; l'app mobile utilise
   `api.mazl.app` et n'est pas touchée). Faire b tout de suite après a.
9. Refaire les contrôles du point 4 sur `https://mazl.app` (connexion QR et message en temps réel
   compris), et `https://api.mazl.app/api/health` ×6.
10. **Retour arrière** : redonner `mazl.app` à l'application API, retirer `SERVE_WEBSITE`,
    redéployer l'API ; arrêter l'application site. L'image de l'API contient toujours `web/dist`.

### Phase 2 (après quelques jours sans incident)

Retirer de `Dockerfile` l'étape `RUN bun web/build.ts` (l'API ne sert plus le client) et lui
faire ignorer `web/` ; supprimer alors le mode par défaut `SERVE_WEBSITE` si on veut que l'API
ne serve plus jamais le site. Non fait ici : tant que le défaut est « sert le site », l'image
doit contenir `web/dist`.

## Limites connues

- **URL publique comme `API_UPSTREAM`** (stg sans réseau interne) : Traefik route par nom d'hôte,
  le site envoie donc le nom d'hôte de l'API (`Host`) et conserve l'original dans
  `X-Forwarded-Host`. Le proxy, les redirections, les en-têtes et le WebSocket se testent ; en
  revanche **la connexion web par cookie échoue** (l'API voit un `Host` qui n'est pas
  `WEB_ORIGIN`). Le réseau interne est indispensable pour valider la session web.
- Un redémarrage du conteneur de l'API coupe les WebSockets ouverts (le registre des connexions
  est en mémoire) ; ce qui change, c'est que le site reste affiché et que les requêtes HTTP
  attendent jusqu'à 5 s le nouveau conteneur au lieu d'échouer.
- `scripts/deploy/deploy.ts` ne déploie que l'API ; l'application site se déploie depuis
  Coolify (ou en ajoutant son identifiant à ce script une fois créée).

## Vérification locale de bout en bout

```
sh web/front/e2e/run.sh      # construit les deux images, démarre Postgres, l'API (site coupé),
                             # le site et un faux amont ; nettoie tout à la fin
```
