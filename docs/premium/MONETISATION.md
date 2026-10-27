# Contrat — fonctionnalités qui rapportent (lot du 2026-10-27)

> Renaud, 2026-10-27 : « la feature des photos floues des likes que l'on reçoit si on n'est pas
> abonné… tous les trucs d'app de rencontre qui rapportent de l'argent, et si tu as d'autres
> idées, go ». Règles : pas de dark pattern (rien de caché sur le prix, résiliation simple, aucun
> faux like, aucun faux compteur), données sensibles protégées, et **le serveur décide toujours** :
> une donnée réservée aux abonnés n'est jamais envoyée en clair à un non-abonné.

## 1. Likes reçus floutés (non-abonnés)

- Le serveur ajoute à l'aperçu d'un like reçu (`domain/teaser.ts`) un `blurredPhotoUrl` : une
  URL signée vers une **variante floue générée côté serveur** (`GET /media/photos/:id/blur?exp&sig`),
  48 px de large, flou gaussien fort (sharp), JPEG ~2 Ko, impossible à « déflouter ». Jamais
  l'URL de la vraie photo, jamais l'id du membre, jamais l'âge (inchangé).
- L'app affiche une grille de photos floues avec le prénom masqué (« Quelqu'un »), le badge vérifié
  et « il y a 2 h » ; un appui ouvre mazl+. En-tête : « 12 personnes vous ont aimé » (le vrai
  nombre).
- Test de sécurité : la réponse d'un non-abonné ne contient aucune URL `/media/photos/<id>` non
  floue ni aucun `user_id`.

## 2. Passeport (mazl+)

Choisir une autre ville pour Découvrir (voyage, alyah : Tel-Aviv, Jérusalem, New York, Londres,
Montréal… ou n'importe quelle ville géocodée), sans changer sa ville affichée. `PUT
/api/discover/passport { city, latitude, longitude } | null` ; Découvrir l'utilise si actif ;
non-abonné → 402 `mazl_plus_required`. Le profil du membre en passeport affiche « De passage à X »
aux autres.

## 3. Mode discret (mazl+)

Seules les personnes que vous avez aimées vous voient dans Découvrir. `PUT
/api/profile/incognito { enabled }` ; filtre côté candidats ; 402 sinon.

## 4. Confirmations de lecture (mazl+)

`read_at` des messages renvoyé à l'expéditeur seulement s'il est abonné (et si le destinataire n'a
pas désactivé « Envoyer les confirmations de lecture », réglage par défaut activé). Affichage « Lu à
21 h 04 » sous le dernier message.

## 5. Super Like avec un mot

Un Super Like peut porter un message de 140 caractères (`POST /api/swipe` `{ ..., note }`),
modéré comme un message (filtre existant), affiché sur la carte du destinataire. Coûte un Super
Like comme aujourd'hui.

## 6. Likes prioritaires (mazl+)

Les likes d'un abonné sont présentés en premier dans la pile de Découvrir du destinataire (tri
côté serveur, sans fausser le reste du classement).

## 7. Retour arrière

Annuler le dernier passage : 1 par jour sans abonnement, illimité avec mazl+ (`POST
/api/swipe/undo`, 402 `undo_limit_reached` au-delà). L'app a déjà `SwipeDeck.undo` : le brancher sur
le serveur.

## 8. Boost au bon moment

Le serveur connaît les heures d'affluence par ville (nombre de sessions actives, agrégé, sans
donnée personnelle) ; l'écran Boost indique « Meilleur moment : samedi 21 h, après Shabbat » et
propose de programmer le Boost (`POST /api/boost/schedule { at }`, déclenché par la tâche à 60 s
existante). Push à l'heure dite.

## 9. Moments d'achat contextuels (sans harcèlement)

L'app montre l'offre mazl+ au bon moment, au plus une fois par jour et par moment : limite de likes
atteinte (déjà), 3ᵉ like reçu, retour arrière refusé, passeport tenté, premier match. Chaque
moment est un événement de mesure d'audience (OpenPanel, consentement d'abord) pour savoir lequel
convertit. Toujours un bouton « Plus tard » visible, jamais de compte à rebours factice.

## 10. Événements : tarif membre

Les événements payants affichent un tarif réduit pour les abonnés (`member_price_cents` par
événement, géré dans le back-office des événements) — la réduction pousse l'abonnement.
