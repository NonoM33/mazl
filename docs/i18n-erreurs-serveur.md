# Erreurs du serveur et traductions — état des lieux et proposition

*2026-10-24, chantier i18n (branche `feat/i18n`). Proposition à valider par Renaud : rien n'est encore changé côté serveur.*

## Le constat

L'app parle désormais cinq langues (FR, EN, HE, ES, RU). Une phrase écrite par le
serveur ne peut pas suivre la langue du téléphone : **le serveur doit dire QUOI
(un code stable), l'app dit COMMENT (la phrase, dans la langue du membre).**

Ce qu'on trouve aujourd'hui dans `src/` :

- **Aucune réponse n'a de champ `code`.** Quand il y a un code, il est rangé dans `error`
  (`not_matched`, `blocked`, `too_late`, `rate_limited`…) ou dans `reason` (photos,
  vérification). Le reste du temps, `error` est une phrase.
- **Des phrases en français**, sans code :

  | route | statut | texte |
  |---|---|---|
  | `src/index.ts:191` (`/api/subscribe`) | 400 | `Email invalide` |
  | `src/index.ts:217`, `documents.routes.ts:66` | 500 | `Erreur serveur` |
  | `account.routes.ts:31` | 404 | `Compte introuvable` |
  | `account.routes.ts:39` | 500 | `La suppression a échoué, réessayez.` |
  | `documents.routes.ts` (flux web `/api/verify`) | 400/404 | `Token manquant`, `Token invalide`, `Type manquant`, `Fichier manquant`, `Fichier vide`, `Fichier trop gros (max 10MB)`, `Format non supporté (JPG/PNG/PDF)`, `Documents manquants: …` |
  | `db.ts:1234` (quota de vérification) | 429 | `Limite de tentatives atteinte (3/jour). Réessayez demain.` |
  | `admin.verification.routes.ts` | 400–500 | `Email ou mot de passe incorrect`, `Motif requis`, `Document purgé`… (tableau de bord web admin, hors app) |

- **Une centaine de phrases en anglais** (`Failed to get matches`, `Event is full`,
  `Not in a couple`, `Maximum of 3 prompts reached`…) et des messages Zod bruts
  (`"<chemin>: <message zod>"`) en 400.
- **Des textes bruts d'exception** renvoyés en 500 (`error.message`, surtout dans le
  mode couple et les photos).
- **Des enveloppes incohérentes** : `{success:false, error}` la plupart du temps, mais
  `{error}` seul pour les médias et `Forbidden` du couple ; un refus de vérification
  arrive en **HTTP 200** avec `{success:true, verified:false, reason}`.
- **Mêmes cas, statuts différents** : `Event is full` en 400 ou 500, `Couple request not
  found` en 404 ou 500.
- Les **notifications push** et les **sujets d'e-mail** sont écrits en français
  (`couple-notifier.ts`, `onesignal.ts`, `email.ts`) et envoyés tels quels, même aux
  membres réglés dans une autre langue. `src/email.ts` tutoie (« Vérifie ton profil »),
  alors que l'app vouvoie.

Le bon modèle existe déjà : **la vérification**. Ses refus portent un `reason` stable
(`no_face`, `pose_mismatch`, `document_expired`, `underage`…) que l'app traduit.

## Ce que l'app fait déjà (branche `feat/i18n`)

- `ApiResponse.httpFailure` classe chaque réponse non-2xx par son statut
  (`ApiErrorKind` : délai, réseau, 401, 403, 404, 409, 413, 429, 400/422, 5xx) et garde
  le code stable du serveur dans `ApiResponse.errorCode` (lu dans `code`, puis dans un
  `reason` ou un `error` en snake_case ; une phrase n'est pas un code).
- `apiErrorText(l10n, kind)` donne la phrase dans la langue du membre. **Le texte du
  serveur ne s'affiche plus jamais** : c'est un diagnostic pour le journal.
- Le chat, le couple, la connexion et la vérification traduisent leurs propres types
  d'erreur ; faute de code serveur, le couple reconnaît encore les phrases anglaises
  actuelles (compatibilité, à retirer quand le serveur enverra des codes).

L'app est donc déjà juste dans les 5 langues, mais avec des messages génériques
(« Cette action n'est plus possible ») là où un code permettrait une phrase précise
(« Cet événement est complet »).

## La proposition pour le serveur

### 1. Une seule enveloppe d'erreur

```json
{ "success": false, "code": "event_full", "error": "Event is full" }
```

- `code` : **obligatoire**, snake_case, stable, documenté dans l'OpenAPI (règle §10bis :
  chaque route liste ses codes d'erreur avec un exemple). C'est le seul champ que l'app lit
  pour choisir une phrase.
- `error` : phrase **en anglais**, pour les développeurs et les journaux. Jamais
  affichée, donc jamais traduite. Plus de français dans les réponses de l'API.
- Champs de contexte autorisés à côté : `retry_after`, `next_attempt_time`, `missing`,
  `max_bytes`… (des données, pas des phrases).
- Statut HTTP cohérent avec le code (un `event_full` est toujours un 409, un
  `*_not_found` toujours un 404). Plus de `error.message` brut en 500 : un 500 renvoie
  `{ code: "internal_error" }` et l'exception part dans les journaux.

Un helper unique (`src/shared/http/errors.ts`, `fail(c, status, code, devMessage, extra?)`)
et un test qui balaie la spec OpenAPI : toute réponse 4xx/5xx documentée a un `code`.

### 2. Les codes à créer en premier (ceux que l'app affiche vraiment)

| domaine | codes |
|---|---|
| commun | `validation_failed` (+ `fields: [{path, rule}]` au lieu du texte Zod), `unauthorized`, `forbidden`, `not_found`, `rate_limited`, `payload_too_large`, `internal_error` |
| couple | `not_matched`, `couple_request_required`, `already_in_couple`, `request_pending`, `request_not_pending`, `user_unavailable`, `cannot_target_self`, `not_in_couple`, `event_full` |
| profil | `prompt_limit_reached`, `prompt_not_found`, `profile_not_found` |
| photos | `image_undecodable`, `image_unsupported_format`, `image_too_large`, `image_empty`, `import_host_not_allowed`, `import_fetch_failed` (aujourd'hui dans `reason`) |
| chat | `blocked`, `not_author`, `unsend_window_closed` (aujourd'hui `too_late`), `too_many_pending`, `message_invalid` (+ `field`) |
| compte | `account_not_found`, `account_deletion_failed` |
| vérification | les `reason` actuels, inchangés ; ajouter `code` aux erreurs HTTP (`daily_limit_reached` + `next_attempt_time`) |
| événements | `event_full`, `event_not_found` |

### 3. Les textes que le serveur envoie lui-même (push, e-mails)

L'app ne peut pas les traduire : le serveur doit connaître la langue du membre.

- L'app envoie sa langue (`Accept-Language` sur chaque requête, et un champ
  `preferred_language` du profil mis à jour quand le membre change de langue dans les
  réglages).
- Les notifications OneSignal partent avec `headings`/`contents` par langue (OneSignal
  choisit selon la langue de l'appareil) ou, mieux, avec un **template** par langue.
- Les e-mails choisissent leur gabarit selon `preferred_language`, avec le français par
  défaut. Au passage, aligner le registre sur l'app (vouvoiement en français).

### 4. L'ordre proposé

1. Le helper `fail()` et l'enveloppe `{success:false, code, error}` (sans casser
   l'existant : `error` garde son texte actuel au début).
2. Les codes du couple et du chat (là où l'app devine encore à partir des phrases
   anglaises) ; l'app lit `code` en priorité, puis retire la reconnaissance des
   phrases anglaises.
3. Les phrases françaises restantes (`/api/subscribe`, compte, flux web `/api/verify`)
   passent en codes ; les pages web (`public/verify.js`) traduisent de leur côté.
4. `Accept-Language` + `preferred_language`, puis push et e-mails multilingues.

Chaque étape est indépendante, testable, et l'app reste juste pendant toute la
transition grâce au repli sur le statut HTTP.
