# Mouvement — règles des gestes « Encre & Tekhelet »

Décidé par Renaud le 2026-10-24 : pastille d'intention dans le coin, seuil à 30 %, photos qui
se rejoignent au match. La démonstration de référence est `docs/design/balayages-proposition.html`.

**Les valeurs vivent dans le code, une seule fois** : `mobile/lib/core/motion/mazl_motion.dart`
(`MazlMotion`). Ce document dit ce que ces valeurs veulent dire et comment s'en servir ; il ne les
recopie que pour être lu. En cas d'écart, c'est `MazlMotion` qui fait foi, et l'écart est un défaut
à corriger des deux côtés. Un geste qui écrit une durée, un seuil ou un ressort en dur est refusé
(test de balayage des sources).

## 1. Principes

- **Le doigt mène.** Pendant le geste, l'élément suit le doigt 1:1, sans retard ni lissage.
- **Une seule récompense par geste**, au moment où il est acquis : un retour haptique et, au plus,
  un petit rebond. Jamais de confettis, de tampon géant, de son ou de pluie de cœurs.
- **L'élan compte.** Un geste acquis part dans la direction et à la vitesse du lancer. Un geste non
  acquis revient en ressort, jamais en ligne droite.
- **Un refus revient d'où il est parti.** Ce que le serveur refuse (limite gratuite, super like
  sans crédit) revient en ressort, puis la raison s'affiche (fenêtre mazl+). Rien ne sort pour
  réapparaître d'un saut.
- **Réduire les animations** (`MazlMotion.reduced(context)`, ou `MediaQuery.disableAnimationsOf`) :
  ni rotation, ni ressort, ni rebond, ni flou. Un geste acquis s'efface en fondu de 150 ms
  (`reducedFade`) ; un geste non acquis revient en 120 ms (`reducedReturn`).
- **Le réglage de l'iPhone passe par la racine.** Sur iOS, « Réduire les animations » arrive dans
  `accessibilityFeatures.reduceMotion` et ne touche pas `MediaQuery.disableAnimations` (qui ne
  reflète que « Supprimer les animations » d'Android). `ReduceMotionScope`, posé dans
  `MaterialApp.builder`, verse `reduceMotion` dans `disableAnimations` pour tous les écrans,
  feuilles et surcouches, et suit le réglage s'il change pendant que l'app tourne. Un test vérifie
  qu'il est bien en place dans `app.dart`. Les `AnimationController` de Flutter lisent le drapeau
  du moteur, pas `MediaQuery` : nos animations doivent donc décider elles-mêmes, en lisant
  `disableAnimationsOf`.
- **Tests** : un test qui parle du réglage de l'iPhone pose `reduceMotion` (allumé, éteint, changé
  en cours de route), jamais seulement `disableAnimations`. Chaque geste a son test animations
  réduites.

## 2. Valeurs communes

| rôle | valeur | `MazlMotion` |
|---|---|---|
| retour en ressort | amortissement 0,7, léger dépassement, ≈ 350 ms | `spring` |
| filet de fin de ressort | `springTolerance` | `springTolerance` |
| retour, animations réduites (courbe) | `reducedReturnCurve` | `reducedReturnCurve` |
| rebond « c'est acquis » | 1 → 1,15 → 1 en 220 ms | `popDuration`, `popScale` |
| apparition d'une pastille de réaction | 0,5 → 1,15 → 1 en 220 ms | `reactionPopFrom`, `popScale`, `popDuration` |
| fondu, animations réduites | 150 ms | `reducedFade` |
| retour, animations réduites | 120 ms | `reducedReturn` |

Retours haptiques autorisés, et seulement eux :

| moment | haptique |
|---|---|
| franchissement d'un seuil (aimer, passer, fermer une photo, survol d'une réaction, tirer pour actualiser) | `HapticFeedback.selectionClick` |
| seuil de la réponse glissée, double tap sur une bulle, éclosion de l'étoile d'actualisation | `HapticFeedback.lightImpact` |
| super like acquis, match, début et envoi d'un message vocal | `HapticFeedback.mediumImpact` |

Rien au départ de la carte, rien sur les boutons, rien en continu pendant un geste. Revenir en
deçà d'un seuil ne redéclenche pas d'haptique.

## 3. Paquet de cartes (Découvrir, activités du couple)

- **Pendant** : la carte suit le doigt. Rotation jusqu'à 8° (`deckMaxRotationDegrees`) pour une
  largeur de carte, avec le pivot au point saisi : une carte tenue par le bas tourne dans l'autre
  sens (la moitié basse se décide à `deckGrabLowerHalf`, 0,5 de la hauteur). La carte de dessous
  passe de 0,96 à 1 (`deckBackScale`) et remonte de 8 px (`deckBackOffset`) en proportion du geste.
- **Intention** : une pastille ronde blanche de 56 px (`intentDiscSize`) apparaît dans le coin
  haut opposé au geste, à 20 px des bords (`intentDiscInset`). Elle porte un cœur accent pour aimer, une croix `AppColors.muted` pour
  passer, et une étoile accent au centre pour un geste vers le haut. Son opacité et son échelle
  (de 0,8 à 1, `intentDiscMinScale`) suivent la progression vers le seuil. Le bouton correspondant
  sous la carte grossit jusqu'à 1,1 (`deckButtonMaxScale`) et se remplit d'accent côté « aimer ».
  Il n'y a plus d'étiquette J'AIME / PASSER, ni de tampon PASSER / GARDER dans le couple.
- **Seuil** : 30 % de la largeur (`deckThreshold`) à gauche ou à droite, 25 % de la hauteur
  (`deckUpThreshold`) vers le haut. Un lancer est acquis sous le seuil s'il dépasse 800 px/s
  (`deckFlingVelocity`), parcourt au moins 48 px (`deckFlingMinDistance`) et reste nettement
  horizontal : |dx| > 1,2 × |dy| (`deckFlingHorizontalRatio`). Au franchissement :
  `selectionClick`, et la pastille fait le rebond commun.
- **Relâcher** : un geste acquis fait partir la carte selon son élan en 240 ms (`deckExit`,
  `deckExitCurve`), jusqu'à 1,6 largeur de carte (`deckExitDistance`), en gardant 18 % de la
  vitesse du doigt (`deckExitVelocityCarry`) et 80 % de rotation en plus (`deckExitExtraRotationShare`). Un geste non acquis la ramène en ressort (`spring`).
- **Vers le haut** : super like dans Découvrir, « garder » dans le couple. `mediumImpact` quand
  c'est acquis. Super like sans crédit : même règle que le like refusé.
- **Vers le bas** : sans effet. La carte cède à 20 % du geste (`deckBlockedResistance`) puis
  revient en ressort. Un blocage sec ressemble à un bug, et la carte ne disparaît jamais.
- **Boutons** : ils lancent la carte avec le même départ que le balayage. Jamais un simple
  effacement, et pas d'haptique.
- **Galerie de photos dans la carte** : on change de photo en touchant la moitié gauche ou droite,
  jamais en balayant. Le balayage horizontal appartient à la carte. L'indicateur de position glisse
  d'une photo à l'autre au lieu de sauter, en 200 ms (`photoIndicatorSlide`, `photoIndicatorCurve`) ;
  animations réduites : il est en place tout de suite.
- **Retour en arrière** (mazl+) : la carte revient du côté où elle était partie, en ressort.

## 4. Match

Le match ne s'affiche plus dans une boîte de dialogue système. Il s'ouvre dans une feuille
`showMazlSheet` sur fond papier. Ce n'est pas l'écran plein du Mazal Tov, qui reste la célébration
du couple.

- Les deux photos (`PairedAvatars`, la paire de cercles de Mazal Tov) partent à 28 px de part et
  d'autre (`matchApartOffset`), attendent que la feuille ait fini de monter, puis se rejoignent en
  420 ms (`matchMeet`, `matchMeetCurve`). Chaque photo porte un anneau papier de 3 px, qui les
  sépare là où elles se touchent. La pastille cœur accent se pose sur le point de contact
  (`PairBadgePlacement.overlay`) ; dans Mazal Tov, elle reste entre les deux photos.
- Au contact, un seul anneau accent en forme de pilule autour de la paire grandit jusqu'à 1,3 et
  s'efface, en 600 ms, une seule fois (`matchPulse`, `matchPulseCurve`, `matchPulseMaxScale`).
  `mediumImpact` une fois, au contact.
- Titre « C'est un match », la phrase « Myriam et vous vous êtes plu. », puis les deux actions :
  « Envoyer un message » (bouton principal ENCRE, `ElevatedButton` du thème, qui ouvre la
  conversation) et « Continuer à découvrir » (bouton texte).
- Animations réduites : les photos sont déjà en place, sans pulsation.

## 5. Réponse glissée (chat)

- Suit le doigt 1:1 jusqu'à 64 px (`replyThreshold`). Au-delà, élastique à 35 %
  (`replyResistance`), butée à 110 px (`replyMaxOffset`). La flèche « répondre » passe de 0,6 à 1
  en taille et de 0 à 1 en opacité.
- Au seuil : `lightImpact`, la flèche prend l'accent et fait le rebond commun.
- Relâcher : retour en ressort (`spring`). La citation glisse dans le composer par le bas.
- Le reste de la conversation (réactions, appui long, flou) : `docs/design/CHAT.md` §4 et §5.

## 6. Photo en plein écran : tirer pour fermer

- Ouverture en 200 ms (`viewerOpen`).

- La photo suit le doigt dans les deux axes. Sur 300 px de course (`viewerProgressDistance`), elle
  rétrécit jusqu'à 0,85 (`viewerMinScale`) et le fond perd jusqu'à 70 % de son opacité
  (`viewerMaxFade`).
- Seuil : 120 px vers le bas (`viewerDismissDistance`) ou un lancer à plus de 600 px/s
  (`viewerDismissVelocity`) ; `selectionClick` au franchissement.
- Relâcher : un geste acquis fait revoler la photo vers sa vignette en 260 ms
  (`viewerReturnToThumbnail`) ; un geste non acquis la ramène au centre en ressort. Elle ne saute
  jamais à sa place.
- Tirée au-delà du seuil puis relancée vers le haut (plus de 600 px/s), elle reste ouverte et
  revient au centre : la personne a changé d'avis.

## 7. Feuilles du bas, pages qui défilent

- **Feuilles** (`showMazlSheet`) : élastique quand on les tire vers le haut ; la fermeture dépend
  de la vitesse du geste autant que de la distance. Pas d'haptique.
- **Pages et listes** : défilement natif de la plateforme, jamais réécrit. Seul un indicateur de
  page glisse au lieu de sauter. Exception : une liste qu'on peut actualiser rebondit partout
  (Android compris), pour que l'étoile du §7bis s'ouvre de la même façon.
- **Barre d'onglets repliée** : déjà en ressort, inchangée.

## 7bis. Tirer pour actualiser : l'étoile « Le trait »

Choisie par Renaud le 2026-10-27 (variante A de `docs/design/pull-refresh-proposition.html`, où les
quatre propositions restent jouables). Widget unique : `StarRefresh`
(`mobile/lib/presentation/common/widgets/star_refresh/`), à la place de `RefreshIndicator`, qui est
refusé dans `lib/` par `test/core/motion_single_source_test.dart`.

- **Pendant** : la liste suit le doigt et rebondit. L'étoile se construit dans l'espace ouvert :
  le triangle pointe en haut se trace, puis le triangle pointe en bas, pendant qu'elle se redresse
  d'un quart de tour et grandit de 0,6 à 1. Elle apparaît en fondu sur les 26 premiers points
  (`refreshFadeInGap`).
- **Seuil** : 64 points (`refreshThreshold`), `selectionClick` en le franchissant (une fois ;
  revenir en deçà ne redéclenche rien). On actualise en **lâchant** au-delà du seuil.
- **Chargement** : la liste reste baissée de 60 points (`refreshHold`) ; les deux tracés deviennent
  deux comètes de 55 % de leur triangle (`refreshCometShare`, en 300 ms `refreshCometShrink`) qui
  font le tour pendant que l'étoile tourne d'un tiers par tour de 800 ms (`refreshCycle`). Le
  chargement finit **toujours sur un tour entier**, donc sur une étoile droite, et dure au moins
  un tour (`refreshMinCycles`) même si la réponse est instantanée.
- **Éclosion** : les comètes se referment, l'étoile gonfle jusqu'à 1,4 (`refreshBloomScale`) et se
  remplit de tekhelet, puis revient, en 600 ms (`refreshBloom`) ; `lightImpact`. La liste remonte
  ensuite en ressort (`spring`).
- **Où** : au-dessus du milieu de la liste tirée (la page tirée quand le Duo est tenu en livre),
  jamais dans le pli ; une liste qui traverse le pli met l'étoile du côté le plus large.
- **Hanoucca** : pendant les huit soirs, une hanoukia remplace l'étoile (`hanukkahNight`, calcul
  hébraïque de `kosher_dart`, hors d'Israël). Le soir commence à 17 h (`kHanukkahEveningHour`) : la
  première bougie brûle dès le soir qui précède le 25 kislev. Même geste que l'étoile : le corps se
  trace sur la première moitié du tirage, puis le shamash s'allume, et les bougies du soir — posées
  de droite à gauche, une de plus chaque soir — s'allument de la plus récente (la plus à gauche)
  vers la droite. Pendant le chargement les flammes scintillent (`refreshFlameFlicker`, 15 %) et
  reviennent à leur taille à chaque tour entier ; à l'éclosion ce sont les flammes qui gonflent.
  Corps en tekhelet, flammes dans l'ambre du thème `hanukkah` de la vitrine. Animations réduites :
  flammes immobiles.
- **Animations réduites** : l'étoile se construit toujours sous le doigt, mais ne tourne pas et ne
  gonfle pas ; elle reste entière pendant le chargement, son remplissage s'efface en 150 ms
  (`reducedFade`) et la liste remonte en 120 ms (`reducedReturn`).

## 7ter. Chargements : le fil qui passe

Depuis le 2026-10-27, les squelettes de chargement (`mobile/lib/presentation/widgets/skeletons.dart`)
n'utilisent plus le reflet gris du paquet `shimmer`, retiré du projet. Les blocs sont des aplats
`surfaceContainer`. Un seul fil d'accent de 2 points (`loadingThreadWidth`) les traverse dans le sens
de lecture (de droite à gauche en hébreu), en 2,4 s (`loadingThreadPeriod`, `loadingThreadCurve`),
estompé à ses extrémités et aux bords de sa course. Il n'apparaît que sur les blocs
(`LoadingThread`). Il n'y a qu'un fil par liste, donc un seul ticker. Animations réduites : ni fil, ni
ticker. En pose livre, le squelette des événements tient dans la première page.

## 7quater. Aimer : le cœur qui se remplit depuis le doigt

Depuis le 2026-10-27, les boutons « aimer » (carte de Découvrir, « aimer en retour » des Likes, barre
« J'aime » du profil) se remplissent depuis le point exact du toucher (`LikeFill`) :
- **Pendant l'appui** : un disque grandit depuis le doigt, découpé à la forme du bouton, jusqu'à 65 % du
  bouton (`likeFillPreview`, en 360 ms : `likeFillDuration`, `likeFillCurve`).
- **Tap validé** : le disque couvre le bouton (`likeFillFinish`, 140 ms au plus), puis le rebond
  commun (`popDuration`, `popScale`).
- **Tap annulé** (le doigt sort) : le disque se vide (`likeFillCancel`) et rien n'est envoyé.
- **Après le rebond** : le bouton revient au repos (`likeFillRelease`).
- **Couleurs** : sur le bouton accent, le disque est un tekhelet plus profond et le cœur reste blanc. Sur
  la barre encre du profil, le disque est tekhelet et le texte passe au blanc.
- **Haptique** : aucune, comme pour tous les boutons.
- **Animations réduites** : ni disque partiel ni rebond, un fondu de 150 ms.

## 8. Ce que les tests doivent prouver

- Chaque geste (paquet de Découvrir, paquet du couple, visionneuse, réponse glissée) lit ses valeurs
  dans `MazlMotion`. Le balayage des sources refuse tout `Duration(` et tout seuil écrit en dur dans
  ces fichiers.
- Paquet de cartes :
  - un lancer court, vertical ou lent n'est pas acquis ;
  - un balayage vers le bas ne retire pas la carte ;
  - un like refusé ramène la carte, puis ouvre la fenêtre mazl+ ;
  - le seuil déclenche un seul `selectionClick`.
- Sous `disableAnimations` : aucune rotation, aucun ressort, des fondus de 150 ms.
- Hors des gestes aussi : tout fichier de `mobile/lib/` qui lance une animation (`AnimationController`,
  `.animate(`, `animateTo`, `animateToPage`, `elasticOut`) lit le réglage, sinon
  `test/core/reduce_motion_guard_test.dart` échoue. Transitions de pages : un simple fondu.
- Match : la feuille s'ouvre au-dessus de la barre d'onglets avec une seule poignée, et ses deux
  actions mènent où elles doivent.
