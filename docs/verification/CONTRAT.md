# Contrat — vérification des membres et socle de sécurité

> Source de vérité pour le socle, le niveau 1 (selfie vérifié) et le niveau 2
> (puce du passeport ou de la CNI). Types : `src/features/verification/domain/types.ts`,
> ports : `src/features/verification/application/ports.ts`. Un changement ici
> change l'API : il se fait dans ce fichier d'abord.

## 0. Règles qui ne se négocient pas

1. **Aucune image de vérification ne touche le disque.** Les selfies, les fichiers
   de la puce (DG1, DG2, SOD) et la photo de la puce sont traités en mémoire puis
   oubliés. Les journaux ne contiennent ni image, ni nom, ni numéro de document,
   ni score : seulement un code de refus (`FaceRejection`, `IdentityRejection`).
2. **On ne garde que des résultats** : niveau obtenu, méthode, date, pays
   émetteur, type de document, date de naissance (qui fixe l'âge du profil),
   l'empreinte HMAC du document, et l'empreinte du visage chiffrée (§3).
3. **Les noms du document ne sont jamais stockés.**
4. **Chiffrement au repos** : `src/shared/crypto/secret-box.ts` (AES-256-GCM,
   contexte lié). **Signatures et empreintes** : `src/shared/crypto/signer.ts`.
   Pas d'autre primitive maison ailleurs.
5. **En production, une clé absente arrête le démarrage**
   (`assertKeysConfigured()` au boot).

## 1. Variables d'environnement

| variable | rôle | défaut hors production |
|---|---|---|
| `DATA_ENCRYPTION_KEY` | AES-256-GCM des pièces d'identité et empreintes de visage | clé de dev dérivée |
| `MEDIA_SIGNING_KEY` | URLs de photos signées | clé de dev dérivée |
| `DOC_FINGERPRINT_KEY` | empreinte HMAC des documents | clé de dev dérivée |
| `FACE_MODELS_DIR` | dossier des modèles ONNX | `models/` |
| `CSCA_BUNDLE_PATH` | certificats racines des États (PEM concaténés) | `data/csca/csca.pem` |
| `OPJ_DECOMPRESS` | binaire OpenJPEG pour le JPEG 2000 du DG2 | `opj_decompress` |
| `FACE_MATCH_THRESHOLD` | cosinus SFace minimal, même personne | `0.363` (valeur publiée par OpenCV) |
| `FACE_CONSISTENCY_THRESHOLD` | cosinus minimal entre les images d'une même session | `0.363` (une tête tournée fait baisser le cosinus : 0,39 mesuré à 60°) |

Modèles : `bun run models:fetch` (script `scripts/fetch-face-models.ts`, empreintes
SHA-256 figées). YuNet 2023mar (MIT) et SFace 2021dec (Apache 2.0), OpenCV Zoo.
**Jamais InsightFace/ArcFace : licence non commerciale.**

## 2. Socle

### 2.1 Photos de profil (`src/features/media/`)
- Téléversement : **ré-encodage systématique** en JPEG (sharp), orientation EXIF
  appliquée puis **toutes les métadonnées supprimées** (GPS compris), côté long
  ≤ 1600 px, nom de fichier `crypto.randomUUID()`, extension jamais lue du client.
  Refus si sharp ne sait pas décoder.
- **Plus aucune URL externe** dans `POST /api/profile/photos` (JSON). Seule
  exception : `{"import_oauth_picture": true}`, qui télécharge côté serveur
  `users.picture` si son hôte est dans une liste blanche (`lh3.googleusercontent.com`),
  puis la traite comme un téléversement.
- **Service des photos** : `GET /media/photos/:photoId?exp=<unix>&sig=<b64url>`.
  `sig = HMAC(MEDIA_SIGNING_KEY, "photo:<photoId>:<exp>")`, durée 1 h,
  `Cache-Control: private, max-age=3600`, `Content-Type: image/jpeg`,
  `X-Content-Type-Options: nosniff`. Signature fausse ou expirée → 404.
- Toutes les réponses d'API qui contiennent des photos (discover, profil,
  likes, matchs, daily picks, conversations, visiteurs) renvoient des **URLs
  signées**, absolues si `PUBLIC_BASE_URL` est défini, relatives sinon. La
  colonne `profile_photos.url` reste la clé de stockage.
- Après stockage, appel du port `PhotoFaceChecker.checkStoredPhoto` (no-op par
  défaut, implémenté par le niveau 1).

### 2.2 Position
- À l'écriture (`PUT /api/profile`), la position est **floutée avant stockage** :
  arrondie à une grille de ~1 km, puis décalée d'un vecteur fixe par
  utilisateur (≤ 1 km, dérivé de `HMAC(MEDIA_SIGNING_KEY, "geo:<userId>")`).
  La position exacte n'est jamais stockée.
- `distance_max` minimal : 5 km (une valeur plus petite est ramenée à 5).
- Au plus 10 changements de position par 24 h et par utilisateur ; au-delà, la
  mise à jour de la position est ignorée (le reste du profil passe).
- Aucune réponse ne contient de coordonnées ni de distance précise d'un autre
  membre.

### 2.3 Anti-aspiration
- Limiteur en mémoire par utilisateur : `GET /api/profile/:userId` ≤ 120/h,
  `GET /api/discover` et `/api/daily-picks` ≤ 300/h. Au-delà : 429
  `{ success: false, error: "rate_limited", retry_after: <s> }`.

### 2.4 Pièces d'identité du parcours web existant (`/api/verify/*`)
- Fichiers **chiffrés** (`seal`, contexte `"document:<documentId>"`), écrits en
  `.enc`, l'admin les déchiffre à la volée.
- **Purge** : à l'approbation ou au refus, le fichier est effacé et
  `documents.filename` vaut `NULL`, `purged_at = NOW()`. Un fichier jamais
  décidé est purgé à 30 jours (tâche au démarrage puis toutes les 6 h).
- Script de migration unique `scripts/encrypt-existing-documents.ts` : chiffre
  les fichiers en clair restants, efface les originaux, purge ceux déjà décidés.

## 3. Niveau 1 — selfie vérifié

### `POST /api/verification/face/session`
Corps `{ "purpose": "photo" | "identity" }`.
- 200 `{ success: true, session_id: "<uuid>", challenges: ["front","left","right"], expires_at: "<ISO>" }`
  — `challenges` commence toujours par `"front"`, puis `"left"` et `"right"` dans
  un ordre tiré au hasard, éventuellement suivis d'un second `"front"` (3 ou 4 étapes).
  Expiration 120 s, usage unique.
- 429 `{ success: false, error: "daily_limit_reached", next_attempt_time }` :
  3 sessions par jour et par objectif.

### `POST /api/verification/face/submit` (multipart)
Champs : `session_id`, `frame_0` … `frame_{n-1}` (JPEG, ≤ 2 Mo chacun, une
image par étape, dans l'ordre des `challenges`).
Contrôles serveur, dans l'ordre :
1. session existante, à l'utilisateur, non expirée, non utilisée (elle est
   consommée même en cas d'échec) ;
2. nombre d'images = nombre d'étapes ;
3. chaque image : décodable, **exactement un visage**, distance entre les yeux
   ≥ 60 px ;
4. pose : `yaw = (nez.x − milieu_des_yeux.x) / distance_des_yeux` ;
   `front` : |yaw| < 0.12 ; `left`/`right` : |yaw| > 0.22 et **signes opposés**
   entre `left` et `right` ;
5. images non identiques (différence moyenne des pixels sur 32×32 en niveaux
   de gris > 2/255 entre deux images) ;
6. même personne sur toutes les images : cosinus ≥ `FACE_CONSISTENCY_THRESHOLD` ;
7. purpose `photo` : la première image `front` est comparée à **chaque photo du
   profil** ; il faut que la photo principale corresponde (≥ `FACE_MATCH_THRESHOLD`).
   Pas de photo avec visage → `no_profile_photo`.

Réponse 200 :
```json
{ "success": true, "verified": true,
  "photo_matches": [{ "photo_id": 12, "match": true }, { "photo_id": 13, "match": false }] }
```
ou `{ "success": true, "verified": false, "reason": "<FaceRejection>" }`.

En cas de succès (purpose `photo`) : `profiles.photo_verified_at = NOW()`,
`profile_photos.face_match` renseigné, et **l'empreinte du visage de la première
image `front` est conservée chiffrée** dans `face_references` (contexte
`"face-reference:<userId>"`). Elle sert à vérifier les photos ajoutées plus tard
et à rien d'autre ; elle est effacée avec le compte ou si l'utilisateur retire
son consentement (`DELETE /api/verification/face/reference`, qui retire aussi
le badge).

### Badge
`is_verified` (déjà lu par l'app) = `photo_verified` OU `identity_verified`.
`photo_verified` = `photo_verified_at` non nul ET photo principale avec
`face_match = true`. Les réponses de profil exposent `photo_verified` et
`identity_verified` en plus.

### Ancien parcours
`POST /api/verification/submit` **ne vérifie plus personne** : il répond
`{ success: true, verified: false, reason: "app_update_required" }`. Le test qui
exigeait `verified: true` pour un base64 quelconque est remplacé par un test de
non-régression qui exige le refus.

## 4. Niveau 2 — puce du document

### Côté app
MRZ lue à la caméra (ML Kit, contrôle des chiffres de contrôle), puis lecture
NFC (`dmrtd`, PACE d'abord, BAC en repli) de DG1, DG2 et EF.SOD, puis une
session de selfie `purpose: "identity"`.

### `POST /api/verification/identity` (multipart)
Champs : `session_id` (session `identity`), `frame_*` comme au niveau 1,
`dg1`, `dg2`, `sod` (binaire brut tel que lu sur la puce).
Contrôles :
1. liveness du niveau 1 (étapes 1 à 6) ;
2. `ChipVerifier.verify` : authentification passive ICAO 9303
   (CMS SignedData de l'EF.SOD, certificat DSC chaîné à un CSCA de
   `CSCA_BUNDLE_PATH`, hachés de DG1 et DG2 égaux à ceux signés). RSA PKCS#1
   v1.5, RSA-PSS, ECDSA courbes nommées **et paramètres explicites**
   (brainpool compris : vérification ECDSA maison en BigInt, BoringSSL de Bun
   ne connaît pas brainpool) ;
3. document non expiré, âge ≥ 18 ans ;
4. empreinte `HMAC(DOC_FINGERPRINT_KEY, "<État>|<numéro>|<naissance>")` :
   déjà utilisée par un autre compte → `document_already_used` ; présente dans
   `banned_document_fingerprints` → `document_banned` ;
5. photo de la puce (JPEG ou JPEG 2000) vs première image `front` :
   ≥ `FACE_MATCH_THRESHOLD`, sinon `document_face_mismatch`.

Succès : ligne `identity_verifications`, `profiles.birthdate` remplacée par
celle du document et verrouillée (`birthdate_locked = true`, plus modifiable
par `PUT /api/profile`), `verification_level = 'identity'`.
Réponse `{ success: true, verified: true }` ou
`{ success: true, verified: false, reason: "<IdentityRejection>" }`.
Quota : celui des sessions `identity` (3 par jour).

Au bannissement d'un compte (route admin existante), son empreinte est copiée
dans `banned_document_fingerprints`.

Repli sans NFC : le parcours web existant (relecture manuelle), chiffré et purgé (§2.4).

### `GET /api/verification/status`
```json
{ "success": true,
  "photo": { "verified": true, "verified_at": "<ISO>|null", "attempts_today": 1 },
  "identity": { "verified": false, "verified_at": null, "attempts_today": 0 },
  "level": "none" | "photo" | "identity",
  "is_verified": true, "attempts_today": 1, "next_attempt_time": null }
```
(`is_verified`, `attempts_today` et `next_attempt_time` restent pour les
anciennes versions de l'app.)

## 5. Schéma (chaque feature crée ses tables dans son `infra/schema.ts`)

```sql
-- media
ALTER TABLE profile_photos ADD COLUMN IF NOT EXISTS face_match BOOLEAN;
ALTER TABLE profile_photos ADD COLUMN IF NOT EXISTS face_checked_at TIMESTAMP;
CREATE TABLE IF NOT EXISTS location_updates (user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE, created_at TIMESTAMP NOT NULL DEFAULT NOW());
-- documents (parcours web)
ALTER TABLE documents ALTER COLUMN filename DROP NOT NULL;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS encrypted BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS purged_at TIMESTAMP;
-- niveau 1
CREATE TABLE IF NOT EXISTS face_verification_sessions (
  id UUID PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  purpose VARCHAR(10) NOT NULL, challenges JSONB NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(), expires_at TIMESTAMP NOT NULL,
  consumed_at TIMESTAMP, outcome VARCHAR(40));
CREATE TABLE IF NOT EXISTS face_references (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  embedding_sealed BYTEA NOT NULL, model VARCHAR(40) NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS photo_verified_at TIMESTAMP;
-- niveau 2
CREATE TABLE IF NOT EXISTS identity_verifications (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  method VARCHAR(20) NOT NULL,            -- 'nfc_passive_auth' | 'manual_review'
  issuing_state CHAR(3) NOT NULL, document_type VARCHAR(2) NOT NULL,
  doc_fingerprint CHAR(64) NOT NULL UNIQUE, document_expiry DATE NOT NULL,
  verified_at TIMESTAMP NOT NULL DEFAULT NOW());
CREATE TABLE IF NOT EXISTS banned_document_fingerprints (
  doc_fingerprint CHAR(64) PRIMARY KEY, banned_at TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS identity_verified_at TIMESTAMP;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS birthdate_locked BOOLEAN NOT NULL DEFAULT false;
```

## 6. Tests

- Unitaires, sans serveur : `bun test tests/unit`.
- Intégration : serveur + Postgres lancés, `TEST_API_URL=… bun test tests/*.test.ts`.
- Les jeux d'essai de la puce sont **fabriqués par `openssl cms -sign`** (script
  `tests/fixtures/chip/make-fixtures.sh`), jamais par notre code : un vérificateur
  testé contre son propre encodeur ne prouve rien.
- Les images de visage de test sont des portraits du **domaine public** (sources
  notées dans `tests/fixtures/faces/SOURCES.md`).
