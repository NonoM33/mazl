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
- **Réduire les animations** (`MazlMotion.reduced(context)`) : ni rotation, ni ressort, ni rebond,
  ni flou. Un geste acquis s'efface en fondu de 150 ms (`reducedFade`) ; un geste non acquis revient
  en 120 ms (`reducedReturn`). Chaque geste a son test sous `disableAnimations`.

## 2. Valeurs communes

| rôle | valeur | `MazlMotion` |
|---|---|---|
| retour en ressort | amortissement 0,7, léger dépassement, ≈ 350 ms | `spring` |
| rebond « c'est acquis » | 1 → 1,15 → 1 en 220 ms | `popDuration`, `popScale` |
| fondu, animations réduites | 150 ms | `reducedFade` |
| retour, animations réduites | 120 ms | `reducedReturn` |

Retours haptiques autorisés, et seulement eux :

| moment | haptique |
|---|---|
| franchissement d'un seuil (aimer, passer, fermer une photo, survol d'une réaction) | `HapticFeedback.selectionClick` |
| seuil de la réponse glissée, double tap sur une bulle | `HapticFeedback.lightImpact` |
| super like acquis, match, début et envoi d'un message vocal | `HapticFeedback.mediumImpact` |

Rien au départ de la carte, rien sur les boutons, rien en continu pendant un geste. Revenir en
deçà d'un seuil ne redéclenche pas d'haptique.

## 3. Paquet de cartes (Découvrir, activités du couple)

- **Pendant** : la carte suit le doigt. Rotation jusqu'à 8° (`deckMaxRotationDegrees`) pour une
  largeur de carte, avec le pivot au point saisi : une carte tenue par le bas tourne dans l'autre
  sens. La carte de dessous passe de 0,96 à 1 (`deckBackScale`) et remonte de 8 px
  (`deckBackOffset`) en proportion du geste.
- **Intention** : une pastille ronde blanche de 56 px (`intentDiscSize`) apparaît dans le coin
  haut opposé au geste. Elle porte un cœur accent pour aimer, une croix `AppColors.muted` pour
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
  `deckExitCurve`). Un geste non acquis la ramène en ressort (`spring`).
- **Vers le haut** : super like dans Découvrir, « garder » dans le couple. `mediumImpact` quand
  c'est acquis. Super like sans crédit : même règle que le like refusé.
- **Vers le bas** : sans effet. La carte cède à 20 % du geste (`deckBlockedResistance`) puis
  revient en ressort. Un blocage sec ressemble à un bug, et la carte ne disparaît jamais.
- **Boutons** : ils lancent la carte avec le même départ que le balayage. Jamais un simple
  effacement, et pas d'haptique.
- **Galerie de photos dans la carte** : on change de photo en touchant la moitié gauche ou droite,
  jamais en balayant. Le balayage horizontal appartient à la carte. L'indicateur de position glisse
  d'une photo à l'autre au lieu de sauter.
- **Retour en arrière** (mazl+) : la carte revient du côté où elle était partie, en ressort.

## 4. Match

Le match ne s'affiche plus dans une boîte de dialogue système. Il s'ouvre dans une feuille
`showMazlSheet` sur fond papier. Ce n'est pas l'écran plein du Mazal Tov, qui reste la célébration
du couple.

- Les deux photos (cercles à filet, composition des avatars de Mazal Tov) glissent l'une vers
  l'autre et se touchent, puis un seul anneau accent pulse une fois autour de la pastille cœur.
  `mediumImpact` au contact.
- Titre « C'est un match », une phrase, puis les deux actions : « Envoyer un message » (bouton
  principal encre, ouvre la conversation) et « Continuer à découvrir » (bouton texte).
- Animations réduites : les photos sont déjà en place, sans pulsation.

## 5. Réponse glissée (chat)

- Suit le doigt 1:1 jusqu'à 64 px (`replyThreshold`). Au-delà, élastique à 35 %
  (`replyResistance`), butée à 110 px (`replyMaxOffset`). La flèche « répondre » passe de 0,6 à 1
  en taille et de 0 à 1 en opacité.
- Au seuil : `lightImpact`, la flèche prend l'accent et fait le rebond commun.
- Relâcher : retour en ressort (`spring`). La citation glisse dans le composer par le bas.
- Le reste de la conversation (réactions, appui long, flou) : `docs/design/CHAT.md` §4 et §5.

## 6. Photo en plein écran : tirer pour fermer

- La photo suit le doigt dans les deux axes. Sur 300 px de course (`viewerProgressDistance`), elle
  rétrécit jusqu'à 0,85 (`viewerMinScale`) et le fond perd jusqu'à 70 % de son opacité
  (`viewerMaxFade`).
- Seuil : 120 px vers le bas (`viewerDismissDistance`) ou un lancer à plus de 600 px/s
  (`viewerDismissVelocity`) ; `selectionClick` au franchissement.
- Relâcher : un geste acquis fait revoler la photo vers sa vignette en 260 ms
  (`viewerReturnToThumbnail`) ; un geste non acquis la ramène au centre en ressort. Elle ne saute
  jamais à sa place.

## 7. Feuilles du bas, pages qui défilent

- **Feuilles** (`showMazlSheet`) : élastique quand on les tire vers le haut ; la fermeture dépend
  de la vitesse du geste autant que de la distance. Pas d'haptique.
- **Pages et listes** : défilement natif de la plateforme, jamais réécrit. Seul un indicateur de
  page glisse au lieu de sauter.
- **Barre d'onglets repliée** : déjà en ressort, inchangée.

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
- Match : la feuille s'ouvre au-dessus de la barre d'onglets avec une seule poignée, et ses deux
  actions mènent où elles doivent.
