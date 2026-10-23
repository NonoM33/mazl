# Conversation — règles de design « Encre & Tekhelet »

Ce document fixe l'habillage de la conversation « niveau Instagram ». La source de vérité des
couleurs est `mobile/lib/core/theme/app_colors.dart` et `app_theme.dart`. Ce qui suit dit comment
s'en servir dans le chat. Tout passe par `Theme.of(context).colorScheme` : le mode sombre est
alors gratuit. Une valeur écrite en dur dans un fichier du chat est un défaut.

## 1. Couleurs

| rôle | clair | sombre | Flutter |
|---|---|---|---|
| fond de la conversation | blanc | #0B0B0F | `scheme.surface` |
| bulle reçue | brume #F3F3F5 | #1C1C22 | `scheme.surfaceContainer` |
| texte de la bulle reçue | encre | #F4F4F5 | `scheme.onSurface` |
| bulle envoyée | tekhelet #2747F5 | #5B78FF | `scheme.primary` |
| texte de la bulle envoyée | blanc | encre | `scheme.onPrimary` (jamais `Colors.white` : 3,8:1 en sombre) |
| métadonnées (heure, « Vu ») | #6B6B76 | #A1A1AA | `scheme.onSurfaceVariant` ; dans une bulle envoyée `onPrimary` à 78 % |
| erreur (« Échec, réessayer ») | #C8281C | idem | `AppColors.error` |
| avertissement (arnaque) | #B45309 | idem | `AppColors.warning`, sur fond brume |

- Aucun dégradé, aucune ombre, aucun `Color(0x…)`, aucun `Colors.*` hors white/black/transparent.
  Le garde-fou `test/features/design/couple_design_rules_test.dart` montre comment le vérifier :
  ajoutez `lib/presentation/features/chat` à ses racines.
- Un seul accent. Le rouge n'apparaît que pour une erreur ou une action destructrice.

## 2. Bulles

- Coins de 22 px. Le coin « queue » (bas droit pour moi, bas gauche pour l'autre) passe à 6 px
  sur la DERNIÈRE bulle d'un groupe seulement. Les bulles du milieu d'un groupe ont leurs quatre
  coins à 22 px, sauf le côté collé à la marge, réduit à 8 px (empilement façon iMessage).
- Largeur maximale : 270 px, ou 75 % de l'écran au-delà de 360 px.
- Remplissage interne : 16 px horizontal, 11 px vertical. Texte : Geist 15, interligne 1,4.
- **Groupement** : même expéditeur, moins de 3 minutes d'écart, même jour. 2 px entre deux bulles
  d'un groupe, 12 px entre deux groupes. L'avatar (`ProfilePhoto`, 28 px) n'apparaît qu'à gauche de
  la dernière bulle d'un groupe reçu.
- **Heure** : plus dans chaque bulle. Elle apparaît sous la dernière bulle d'un groupe en 11 px
  `onSurfaceVariant`, et sur n'importe quelle bulle quand on la touche (révélation, 200 ms).
- **« Vu »** : sous le dernier message envoyé lu uniquement, aligné à droite : « Vu à 21:42 » en
  11 px `onSurfaceVariant`. Envoyé non lu : rien (pas de coche grise qui clignote).
- **Envoi en cours** : la bulle est à 60 % d'opacité, sans indicateur de chargement.
  **Échec** : bulle à 100 %, en dessous « Échec · Réessayer » en `AppColors.error` 12 px, la partie
  « Réessayer » est un bouton texte. Pas d'icône d'alerte rouge dans la bulle.

## 3. Séparateurs et repères

- **Date** : étiquette centrée en `AppTypography.eyebrow` (Geist Mono, majuscules espacées), couleur
  `onSurfaceVariant` : « AUJOURD'HUI », « HIER », « MAR. 21 OCT. ». Collante en haut pendant le
  défilement, sur un fond `scheme.surface` à 92 % (pas de flou ni de pastille).
- **Début de la conversation** : « MATCH · 21 OCT. » au-dessus du premier message, même style.
- **Nouveaux messages** : bouton pilule flottant au-dessus du composer, fond `scheme.onSurface`
  (encre), texte `scheme.surface`, libellé « 3 nouveaux messages » + flèche bas Lucide, 12 px
  au-dessus du composer. Il disparaît en fondu quand on arrive en bas.
- **En train d'écrire** : bulle reçue de 56 × 36 px, trois points de 6 px `onSurfaceVariant` qui
  montent l'un après l'autre (amplitude 3 px, cycle 1,2 s). Le statut de l'en-tête
  (« écrit… » en accent) reste. Animation coupée si `MediaQuery.disableAnimationsOf`.

## 4. Réactions

- **Double tap** : cœur. Un cœur Lucide plein en accent grandit au centre de la bulle (0,6 → 1,2
  → 1, 350 ms) puis disparaît. Retour haptique `HapticFeedback.lightImpact`.
- **Pastille de réaction** : sous la bulle, mordant de 8 px sur son bord inférieur, côté opposé à la
  queue. Fond `scheme.surface`, contour 2 px `scheme.surface` (elle se détache de la bulle sans
  ombre), puis `scheme.surfaceContainer` intérieur, radius 999, hauteur 22 px, émoji 13 px +
  compteur 11 px si plus d'une. Les émojis sont permis ICI SEULEMENT (c'est du contenu, pas de la
  décoration). Ma réaction : contour intérieur 1 px accent.

## 5. Appui long : menu et barre de réactions

- La bulle touchée se soulève : le reste de l'écran passe sous un voile `Colors.black` à 40 %
  (pas de flou). La bulle reste à sa place, à 100 %, échelle 1,02.
- **Barre de réactions** au-dessus de la bulle : capsule `scheme.surface`, contour 1 px
  `AppColors.hairline` (sombre : `dividerDark`), radius 999, hauteur 48 px, les six émojis 26 px
  que le serveur accepte (❤️ 😂 😮 😢 😡 👍 ; 🙏 à la place de 😡 en attente de la décision de
  Renaud). Pas de « + » : il n'y a pas de sélecteur complet dans cette version. Haptique
  `selectionClick` au survol de chaque émoji.
- **Menu** sous la bulle : carte `scheme.surface`, radius 20, contour filet, largeur 220 px, lignes
  de 48 px : icône Lucide 20 px + libellé 15 px, séparées par un filet 1 px `divider`. Ordre :
  Répondre (`reply`), Copier (`copy`), puis pour mes messages Retirer (`undo2`, en
  `AppColors.error`), pour les siens Signaler (`flag`, en `AppColors.error`). Libellés vouvoyés,
  pas de majuscules partout.
- Le menu et la barre ne passent jamais sous la barre système ni sous le composer : on décale
  la bulle si besoin.

## 6. Répondre (citation)

- **Glisser pour répondre** : la bulle suit le doigt jusqu'à 64 px. Une icône `reply` apparaît
  dans la marge et passe à l'accent au seuil, avec haptique `lightImpact`.
- **Dans le composer** : bandeau au-dessus du champ, À L'INTÉRIEUR de la capsule. Filet vertical
  3 px accent à gauche, « Réponse à Noémie » en 12 px accent, extrait sur une ligne en 13 px
  `onSurfaceVariant`, croix Lucide pour annuler.
- **Dans la bulle envoyée** : citation en haut de la bulle, fond `onPrimary` à 14 %, radius 14,
  filet 3 px `onPrimary` à 60 %. Dans une bulle reçue : fond `scheme.surface`, filet accent.
  Deux lignes au plus. La toucher fait défiler jusqu'au message cité et le surligne
  (fond accent à 12 %, 1 s).

## 7. Photos

- Une photo : radius 22, pas de remplissage autour (la bulle EST la photo), largeur 220,
  hauteur selon le format (bornée entre 160 et 300).
- Plusieurs photos : grille de 2 colonnes, 2 px d'écart, coins extérieurs à 22, au plus 4 cases.
  La 4e case affiche « +3 » sur un voile noir 45 %.
- **Photo reçue floutée** jusqu'au premier tap : `ImageFiltered` sigma 24, une pastille centrale
  `Colors.black` 45 % avec icône `eye` + « Voir la photo » en blanc 13 px.
- **Plein écran** : fond noir, barre d'état claire (`SystemUiOverlayStyle.light`), fermeture par
  croix 44 px en haut à gauche ou glissé vers le bas, pagination par points blancs. Rien d'autre.

## 8. Messages vocaux

- Bulle de la même forme. Bouton lecture rond 36 px (`onPrimary` sur moi, `scheme.onSurface` sur
  l'autre, icône inversée), onde de 32 barres de 3 px (espacement 2 px, hauteur 4 à 24 px), la
  partie lue en couleur pleine, le reste à 40 %. Durée en Geist Mono 12 px
  (`fontFeatures: [FontFeature.tabularFigures()]`). Vitesse en pilule 11 px « 1× / 1,5× / 2× »
  (virgule décimale en français).
- **Enregistrement** : maintien du micro. Le composer se transforme : point rouge
  `AppColors.error` qui pulse, chrono Geist Mono, « ‹ Glisser pour annuler » en `onSurfaceVariant`,
  et un verrou au-dessus du micro pour lâcher sans arrêter. Haptique `mediumImpact` au début et à
  l'envoi.

## 9. Aperçu de lien

- Sous le texte, dans la bulle : carte radius 16. Fond `scheme.surface` dans une bulle reçue,
  `onPrimary` à 12 % dans une bulle envoyée. Image 16:9 en haut si disponible (teinte
  `photoTints` sinon, sans icône), titre 14 px 600 deux lignes, domaine en 12 px
  `onSurfaceVariant` (ou `onPrimary` 70 %). Le lien s'ouvre hors de l'app.

## 10. Composer

- Celui qui existe (`ChatComposer`) reste la base : capsule `surfaceContainer` de 60 px minimum,
  radius 30, à 16 px des bords et au moins 12 px au-dessus de la zone système ou du clavier.
  Jamais collé à la barre.
- Le champ grandit jusqu'à 5 lignes puis défile. La capsule garde son radius (elle s'allonge).
- À droite : micro quand le champ est vide, flèche d'envoi (rond 48 px `scheme.primary`, icône
  `onPrimary`) dès qu'il y a du texte. Fondu croisé de 150 ms entre les deux.
- À gauche : « + » ouvre la feuille des pièces jointes via `showMazlSheet` (Photos, Appareil
  photo). Jamais `showModalBottomSheet` en direct (un test le refuse).

## 11. Avertissement contre les arnaques

- Carte dans le fil, pleine largeur moins 32 px, fond `scheme.surfaceContainer`, radius 20,
  icône `shieldAlert` en `AppColors.warning`, titre 14 px 600, une phrase 13 px, lien « En savoir
  plus » en accent. Pas de bandeau jaune ni de bordure colorée.
- Texte vouvoyé, factuel, sans alarmisme : « Ne transférez jamais d'argent à quelqu'un que vous
  n'avez pas rencontré. »

## 12. Mouvement et retours haptiques

- Durées : 150 ms (fondus de contrôle), 200 ms (révélation de l'heure), 250 ms (apparition d'une
  bulle : glissé de 8 px vers le haut + fondu), 350 ms (cœur du double tap). Courbe
  `Curves.easeOutCubic`.
- Toutes coupées sous `MediaQuery.disableAnimationsOf(context)`.
- Haptiques : `selectionClick` (survol des réactions), `lightImpact` (double tap, seuil de
  réponse), `mediumImpact` (début et envoi d'un vocal). Rien d'autre.

## 13. Composants à réutiliser

`ProfilePhoto` (avatars), `SectionLabel` / `AppTypography.eyebrow` (dates), `RoundIconButton`
(en-tête), `showMazlSheet` (pièces jointes, signalement), les boutons du thème. L'en-tête de
conversation actuel (`_ChatHeader`) reste : avatar 36 px, prénom 16 px 600, statut 12 px.

## 14. Ce que les tests doivent prouver

- Contraste du texte sur bulle envoyée, en clair et en sombre (comme `design_foundation_test`).
- Le composer et le bouton « nouveaux messages » ne touchent jamais le bas : écart ≥ 12 px.
- Groupement : 2 px dans un groupe, 12 px entre groupes, avatar seulement sur la dernière bulle.
- Le menu d'appui long et la feuille des pièces jointes s'ouvrent au-dessus de tout, une seule
  poignée.
- Aucun émoji hors réactions, aucun dégradé, aucune ombre dans `features/chat`.
