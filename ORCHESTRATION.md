# ORCHESTRATION — Remédiation MAZL (audit 2026-07-02)
> Généré par Fable (chef d'orchestre). Exécutant : Opus 4.8 + agents parallèles.
> Base : audit 8 axes. Tous les fichier:ligne ci-dessous ont été vérifiés dans le code.

## 🎯 Objectif & Definition of Done
Rendre MAZL sûr et cohérent UI↔backend, sans régresser le build.
DoD final (toutes doivent passer) :
- `cd mobile && dart analyze` → "No issues found!"
- `cd mobile && flutter test` → tous verts
- `bunx tsc --noEmit` → 0 erreur
- `bun test` (backend, serveur+DB de test) → suites sécurité/contrat vertes
- 0 endpoint mobile appelant une route inexistante (script de contrôle vague 2)

## 🧭 Règles COORDINATEUR (Opus)
- Vague par vague. Barrière : ne pas démarrer N+1 tant que N n'est pas ✅ vérifiée.
- Dans une vague, spawner toutes les tâches EN PARALLÈLE (1 message, N Agent), sauf `séquentiel`.
- JAMAIS deux agents sur le même fichier en parallèle (déjà pré-groupé ci-dessous).
- `src/index.ts` (4053 l.) et `src/db.ts` (3512 l.) sont des MONOLITHES : un seul agent à la
  fois par fichier → streams séquentiels dédiés (voir Notes).
- Les agents n'exécutent AUCUN `git` (races). Le coordinateur commite après chaque gate.
- Après chaque tâche : commande **Vérifier**. Échec → relancer l'agent avec l'erreur.

## 🧍 Actions humaines (bloquantes, hors agents)
- [ ] Révoquer le credential Jenkins `renaud:24536Tetr@` (exposé `Jenkinsfile:235`) + purger l'historique git.
- [ ] Régénérer le mot de passe keychain CI `ci2026` (`Jenkinsfile:75`).
- [ ] Provisionner en prod (Coolify) : `JWT_SECRET`, `ADMIN_JWT_SECRET`, vraies clés RevenueCat `appl_`/`goog_`, `ADMIN_EMAILS`.
- [ ] Décider produit : `profile_setup_screen.dart` → implémenter ou supprimer.

---

## 🌊 VAGUE 1 — Sécurité backend (parallèle : fichiers disjoints)

### Tâche 1.1 — Vrai JWT HMAC + vérif Apple + fail-fast  `owner: src/auth.ts`
`signHS256` (auth.ts:215-228) n'est pas un HMAC → tokens forgeables ; Apple non vérifié (auth.ts:~116) ; `JWT_SECRET` fallback en dur (auth.ts:7). → HMAC-SHA256 réel + timingSafeEqual, vérif signature Apple via JWKS, fail-fast si secret absent. Ne pas : any/ts-ignore, changer la forme des tokens.
**Vérifier** : `bunx tsc --noEmit 2>&1 | grep 'src/auth.ts' || echo OK`

### Tâche 1.2 — Fermer backdoors + durcir index  `owner: src/index.ts`  `séquentiel`
Gater `/api/dev/*` (index.ts:2026-2264) derrière NODE_ENV≠production ; retirer admin via `?password=` ; fail-fast `ADMIN_JWT_SECRET` (index.ts:186) ; CORS allowlist (index.ts:157) ; vérif appartenance couple sur `:coupleId` (index.ts:2410,2431). Ne pas : toucher db.ts.
**Vérifier** : `bunx tsc --noEmit 2>&1 | grep 'src/index.ts' || echo OK`

### Tâche 1.3 — CI honnête + secrets  `owner: Jenkinsfile`
withCredentials (retirer `renaud:...` l.235) ; `dart analyze` bloquant (retirer `|| true`) ; stage backend bloquant (`tsc --noEmit && bun test`) ; retirer `catchError('SUCCESS')` des deploys.
**Vérifier** : `grep -nE '24536|\|\| true|--no-fatal' Jenkinsfile || echo OK`

### Tâche 1.4 — Durcir Docker  `owner: Dockerfile, .dockerignore`
`.dockerignore` (.env, mobile/, uploads/, .git) ; user non-root ; `--frozen-lockfile` ; HEALTHCHECK.
**Vérifier** : `test -f .dockerignore && grep -q frozen-lockfile Dockerfile && echo OK`

## ✅ Gate Vague 1
`bunx tsc --noEmit && cd mobile && dart analyze`

---

## 🌊 VAGUE 2 — Combler le contrat API (endpoints manquants + WS + discover)
> Goulet : `src/index.ts` + `src/db.ts` = 2 streams séquentiels (2.A, 2.B). Les tâches mobiles (2.M*) en parallèle, fichiers disjoints.

### Stream 2.A — Backend endpoints  `owner: src/index.ts`  `deps: 1.2`  `séquentiel`
Ajouter routes absentes : block/unblock/blocked + exclusion partout ; report (aligner chemin+payload sur api_service.dart:1011) ; likes/received(+count) ; boost status/activate ; prompts CRUD ; verification start/submit/status (limite 3/j serveur) ; couple request/requests/check. **Fix WS** : lire `data.payload.*` (index.ts:3950), émettre `match:new`, relayer `isTyping` réel (index.ts:~3998).
**Vérifier** : `bunx tsc --noEmit 2>&1 | grep 'src/index.ts' || echo OK`

### Stream 2.B — Backend data + discover  `owner: src/db.ts`  `séquentiel`
Fonctions data pour les endpoints ci-dessus ; **`getDiscoverProfiles` (db.ts:1088)** : filtres genre/looking_for/âge/distance + scoring religieux (colonnes db.ts:77-79) ; **index** manquants (swipes, messages, matches, profiles.user_id, event_rsvps, couples.user1/2_id). Ne pas : toucher index.ts, concaténer du SQL.
**Vérifier** : `bunx tsc --noEmit 2>&1 | grep 'src/db.ts' || echo OK`

### Mobiles parallèles
- **2.M1** `chat_screen.dart` — brancher les 4 actions mortes du menu conversation + erreur si sendMessage échoue.
- **2.M2** `profile_view_screen.dart` — vrai score de compatibilité (retirer 87% hardcodé).
- **2.M3** `couple_service.dart` — dé-commenter activation (l.286), retirer auto-effacement (l.250). `deps: 2.A`.
- **2.M4** `jewish_calendar_service.dart` — utiliser `kosher_dart` au lieu des fêtes 2025 hardcodées.

## ✅ Gate Vague 2
`bunx tsc --noEmit && cd mobile && dart analyze && flutter test`

---

## 🌊 VAGUE 3 — Monétisation défendable (parallèle)
- **3.1** `src/index.ts (stream)` — webhook RevenueCat signé (index.ts:1846), vérif premium serveur, mapper tous les plans. `deps: fin vague 2`.
- **3.2** `revenuecat_service.dart` — annulation d'achat (PlatformException), init non-bloquant au boot.
- **3.3** `premium_gate.dart` — persister quotas (likes/super/boost), aligner sur enforcement serveur.

## ✅ Gate Vague 3
`bunx tsc --noEmit && cd mobile && dart analyze && flutter test`

---

## 🌊 VAGUE 4 — Tests de non-régression (parallèle, nouveaux fichiers)
Prérequis : exporter `app` depuis `src/index.ts` (test via `app.fetch()` sans réseau).
- **4.1** `tests/auth-security.test.ts` — JWT forgé rejeté ; `/api/dev/*` → 404 en prod ; boot refusé sans secret.
- **4.2** `tests/subscription-webhook.test.ts` — webhook sans signature rejeté ; plan correct.
- **4.3** `tests/blocking.test.ts` — bloqué hors discover/matches, ne peut plus écrire (REST + WS).
- **4.4** `tests/matching-chat.test.ts` — swipe→match réciproque ; contrôle d'accès conversation.
- **4.5** `mobile/test/core/services/api_service_test.dart` — parsing/erreurs 401/404/500, header Auth.

## ✅ Gate Vague 4
`bun test && cd mobile && flutter test`

---

## 🌊 VAGUE 5 — Refactor archi incrémental (par feature, plus tard)
- Backend : `src/features/<feature>/{domain,application,infra,presentation}`, middleware auth unique (remplace 56 copier-collés), validation zod, migrations versionnées + runner. Ordre : auth → couples → chat → events → admin.
- Mobile : `AuthService`/`CoupleService` → `AsyncNotifier` Riverpod, éclater `api_service.dart` (2424 l.) en repositories typés (freezed), `ApiClient` Dio (timeouts/erreurs typées/flavors --dart-define), supprimer `DataPrefetchService`.
- Chaque feature migrée = 1 vague dédiée + ses tests.

## 📌 Notes de parallélisation
- Vague 1 : 4 agents simultanés (auth.ts, index.ts, Jenkinsfile, Dockerfile).
- Vague 2 : débit limité par 2 monolithes (2 streams séquentiels) + 4 agents mobiles en parallèle.
- Goulet structurel : tant que index.ts/db.ts ne sont pas éclatés (vague 5), tout ajout backend se sérialise → argument pour prioriser le refactor auth/couples tôt.
