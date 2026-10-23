# Contrat — messagerie (niveau Instagram)

> Source de vérité du chat : API, temps réel, état dans l'app. Un changement ici
> change l'API : il se fait dans ce fichier d'abord. Le rendu suit la DA
> (règles fournies par la session design, `docs/chat/DA.md` quand elle existe).

## 0. Règles qui ne se négocient pas

1. **Seuls les deux membres d'une conversation** lisent, écrivent, réagissent ;
   tout autre appel → 404 (pas 403 : on ne confirme pas qu'elle existe).
2. **Les médias passent par le même tuyau que les photos de profil** : photo
   ré-encodée (EXIF/GPS supprimés), URL signée 1 h ; audio vérifié par ses
   octets, jamais par l'extension. Rien n'est servi sans signature.
3. **Aucun contenu de message dans les journaux** (ni texte, ni URL, ni nom).
4. **L'analyse anti-arnaque se fait dans l'app**, sur les messages reçus, sans
   rien envoyer nulle part. Elle avertit, elle ne bloque jamais.
5. **Aperçu de lien côté serveur, sans SSRF** : http/https seulement, ports 80
   et 443, résolution DNS puis refus de toute IP privée, locale, de lien local
   ou réservée (IPv4 et IPv6), pas de redirection suivie, 5 s, 512 Ko lus au
   plus, seulement `text/html`. Résultat mis en cache 24 h par URL.

## 1. Forme d'un message

```json
{ "id": 812, "conversation_id": 40, "sender_id": 7,
  "client_id": "c-5f2a…",              // id choisi par l'app à l'envoi (idempotence)
  "type": "text" | "photo" | "voice",
  "content": "Salut !",                // texte ; légende pour une photo ; "" pour un vocal
  "media": [ { "id": 31, "kind": "photo", "url": "<signée>", "width": 1200, "height": 1600 } ],
  "voice": { "id": 32, "url": "<signée>", "duration_ms": 8300, "waveform": [0,12,40,…] } | null,
  "reply_to": { "id": 799, "sender_id": 45, "type": "text", "preview": "On se voit jeudi ?" } | null,
  "reactions": [ { "emoji": "❤️", "user_ids": [45] } ],
  "link_preview": { "url": "…", "title": "…", "description": "…", "image_url": "<signée ou null>", "site_name": "…" } | null,
  "created_at": "<ISO>", "read_at": "<ISO> | null",
  "unsent": false }
```
- `unsent: true` : `content` vide, `media`/`voice`/`link_preview` à null ;
  l'app affiche « Message retiré ».
- `reply_to.preview` : 80 caractères au plus, « Photo », « Message vocal » ou
  « Message retiré » selon le cas.
- `waveform` : 48 valeurs entières 0–100, calculées par l'app à l'enregistrement.
- Réactions permises : `❤️ 😂 😮 😢 😡 👍` (une par membre et par message ;
  la même deux fois la retire).

## 2. Routes

| route | comportement |
|---|---|
| `GET /api/conversations/:id/messages?before=<id>&limit=30` | pagination par curseur, du plus récent au plus ancien ; `{ success, messages: [§1], has_more }` |
| `POST /api/conversations/:id/media` (multipart `file`, `kind`=`photo`\|`voice`, `duration_ms`, `waveform` JSON) | photo : JPEG/PNG/HEIC ≤ 10 Mo → ré-encodée ; vocal : AAC/M4A (`ftyp`) ≤ 3 Mo et ≤ 120 s → `{ success, media: { id, kind, url, … } }`. Le média n'est rattaché à rien tant qu'un message ne l'utilise pas ; purgé après 24 h s'il reste orphelin. |
| `POST /api/conversations/:id/messages` `{ client_id, type, content?, media_ids?, reply_to_id? }` | crée ; **idempotent sur `client_id`** (un second envoi rend le même message, 200) ; ≤ 10 photos ; `reply_to_id` doit appartenir à la même conversation. Lance l'aperçu de lien en tâche de fond pour le premier lien du texte. → `{ success, message: §1 }` |
| `POST /api/messages/:id/reactions` `{ emoji }` | bascule la réaction de l'appelant → `{ success, reactions }` |
| `POST /api/messages/:id/unsend` | l'auteur seulement, dans les 15 min → message en `unsent` ; les médias sont effacés du disque |
| `PUT /api/conversations/:id/read` `{ up_to_id }` | marque lu jusqu'à ce message |
| `POST /api/messages/:id/report` `{ reason }` | réutilise la modération existante (`reports`), avec le lien vers le message |

L'ancien `POST …/messages { content }` (sans `client_id`) reste accepté
(texte seul) pour les versions de l'app déjà installées.

## 3. Temps réel (enveloppe `{ type, payload }`, à l'autre membre et à l'auteur)

| type | payload |
|---|---|
| `chat:message` | `{ message: §1 }` |
| `chat:updated` | `{ message: §1 }` (aperçu de lien arrivé, retrait, réactions) |
| `chat:typing` | `{ conversation_id, user_id, is_typing }` (existant) |
| `chat:read` | `{ conversation_id, user_id, up_to_id, read_at }` |

## 4. Dans l'app

- **État** (`ChatController` par conversation, Riverpod) : liste de messages
  (serveur + envois en cours), pagination vers le haut, saisie en cours,
  « Vu ». Envoi **optimiste** : la bulle apparaît tout de suite avec
  `client_id` ; état `envoi` → `envoyé` → `vu`, ou `échec` avec
  « Réessayer ». Les envois en échec survivent à un redémarrage de l'écran,
  pas de l'app.
- **Gestes** : appui long → barre de réactions + menu (Répondre, Copier,
  Retirer si à moi et < 15 min, Signaler si pas à moi) ; glisser vers la droite
  → répondre (seuil 64 px, retour haptique) ; double tap → ❤️ (animation).
- **Rendu** : regroupement par auteur (< 2 min d'écart = même groupe),
  séparateurs de date collants, « Vu à 20:47 » sous le dernier message lu
  envoyé, indicateur de saisie animé, bouton « ↓ N nouveaux » quand on est
  remonté.
- **Photos** : jusqu'à 10 par message, grille ; visionneuse plein écran
  (pincer, balayer, fermer en glissant vers le bas). **Photos reçues floutées**
  jusqu'au premier tap (« Afficher la photo »).
- **Vocal** : appui maintenu sur le micro pour enregistrer (glisser à gauche
  pour annuler, relâcher pour envoyer), 120 s max, forme d'onde ; lecture avec
  vitesse ×1 / ×1,5 / ×2. AAC 64 kbit/s mono.
- **Arnaques** : sur un message reçu qui parle d'argent, de crypto, de
  virement, de carte cadeau, ou qui pousse vers WhatsApp/Telegram/Signal dans
  les premiers échanges → bandeau discret « Ne versez jamais d'argent à
  quelqu'un rencontré ici » + lien « Signaler ». Règles dans un module pur,
  testé, en français et en anglais.
- Les feuilles du bas passent par `showMazlSheet`, les menus par la racine
  (`sheet_rules_test`).

## 5. Démo

Toutes les routes ci-dessus répondent en démo avec les vraies formes ; le
correspondant fictif répond parfois (« Haha », une réaction) quelques secondes
après un envoi, pour que l'indicateur de saisie, le « Vu » et les réactions se
voient sans serveur.
