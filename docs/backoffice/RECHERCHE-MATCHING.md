# Recherche documentaire : moteur de matching explicable pour MAZL

Date : 2026-10-24. Recherche en lecture seule (web). Chaque affirmation importante porte son URL. Les sources secondaires (presse, blogs) sont signalées comme telles ; les pages primaires de Tinder (Medium/blog.gotinder.com) n'ont pas pu être ouvertes (HTTP 403), donc le contenu du billet de 2019 est rapporté via la presse.

Principe de lecture : aucun chiffre n'est inventé. Les valeurs numériques proposées dans la dernière partie sont des **points de départ à calibrer**, pas des résultats de la littérature.

---

## 1. Tinder : de l'Elo à un système « multi-signaux »

**L'ancien score Elo / « desirability ».** Fast Company (Austin Carr, 2016) a révélé que Tinder classait ses utilisateurs par un score interne appelé « Elo », d'après le classement des échecs. Chaque balayage à droite est un « vote » ; le score monte davantage quand le vote vient d'un profil lui-même bien classé, et les profils de score voisin se voient entre eux. Le journaliste y lit son propre score (946, « plutôt haut de la moyenne »). Le PDG Sean Rad affirmait que « ce n'est pas seulement le nombre de swipes à droite », sans détailler. Sources (secondaires, relayant l'article) : [Digital Trends](https://www.digitaltrends.com/phones/tinder-rank-elo-score/), [Global Dating Insights](https://www.globaldatinginsights.com/news/12012016-tinder-uses-complex-algorithm-secretly-ranks-users/), [Stylist](https://www.stylist.co.uk/life/tinder-rating-attractive-desirable-hot-or-not-elo-score-sean-rad-fast-company/63204).

**L'abandon (2019).** Le billet « Powering Tinder : the method behind our matching » (mars 2019, [blog.gotinder.com](https://blog.gotinder.com/powering-tinder-r-the-method-behind-our-matching/), non ouvert) indique que Tinder ne s'appuie plus sur l'Elo. D'après [Engadget](https://www.engadget.com/2019-03-18-tinder-dumps-desirability-scores.html) et [Global Dating Insights](https://www.globaldatinginsights.com/featured/tinder-changes-algorithms-and-removes-elo-scores/), le système ajuste les propositions à chaque Like/Nope reçu, et le paramètre le plus important est l'**activité** (combien on utilise l'app). Selon [Tecnoblog](https://tecnoblog.net/289506/como-funciona-o-powering-tinder-o-algoritmo-por-tras-dos-matches/), les facteurs cités sont l'activité, la localisation/distance, les préférences de genre, et les likes/passes servant à trouver des centres d'intérêt communs. [Metro.pr](https://www.metro.pr/noticias/2019/03/20/tinder-elo-matches) ajoute que peu de données sont requises au départ (genre, lieu, âge, distance).

**Embeddings (TinVec).** Le chief scientist de Tinder a présenté en 2017 « TinVec », approche de recommandation personnalisée qui encode les préférences de chaque utilisateur en vecteurs à partir de l'immense volume de swipes ([résumé MLconf](https://mlconf.com/?p=8768)). Le détail du modèle (type word2vec sur séquences de swipes) n'est **pas confirmé** par une source primaire consultée : incertitude.

**Critiques.**
- Opacité : l'utilisateur ne voit ni ne contrôle son score ; Tinder n'a jamais détaillé la décomposition ([Fast Company via Global Dating Insights](https://www.globaldatinginsights.com/news/12012016-tinder-uses-complex-algorithm-secretly-ranks-users/), [Engadget](https://www.engadget.com/2019-03-18-tinder-dumps-desirability-scores.html)).
- Un score unique de « désirabilité » enferme chacun dans un étage de la hiérarchie et encode des biais de popularité (voir §4 et §5). Cette lecture est une inférence de l'état de l'art, non une citation de Tinder.
- Ce que MAZL en retient : le score global opaque est à éviter ; l'activité récente et la proximité sont des signaux admis par l'industrie ; l'explicabilité est un avantage concurrentiel (voir §7).

---

## 2. Hinge : « Most Compatible » et « Standouts »

**Most Compatible (2018).** Hinge a présenté une variante du célèbre algorithme de Gale-Shapley (problème des mariages stables) qui apprend des likes et des passes et propose chaque jour la personne dont les préférences s'alignent le mieux. Hinge a rapporté, sur des tests internes, que les couples « Most Compatible » avaient 8 fois plus de chances de mener à un échange de numéros (chiffre de l'entreprise, non indépendant). Sources : [TechCrunch](https://techcrunch.com/?p=1668547), [9to5Google](https://9to5google.com/2018/07/12/ai-dating-app-hinge/), [The Hustle](https://thehustle.co/hinge-machine-learning-algorithm). Le Gale-Shapley classique suppose deux groupes distincts ; TechCrunch évoque une variante de type « stable roommates » pour un pool unique, tandis qu'un [blog Cornell](https://blogs.cornell.edu/info2040/2019/09/23/44308) décrit un pool sans division par genre. Détails d'implémentation actuels : **inconnus**.

**Standouts.** Selon l'[aide Hinge](https://help.hinge.co/hc/en-us/articles/360057625534), Standouts est un flux quotidien de profils qui reçoivent le plus d'attention, filtré selon vos préférences et votre activité. On ne peut pas y envoyer un Like simple mais une **Rose** (denrée rare : une gratuite par semaine selon certaines sources, achats possibles) qui place votre profil en haut des « Likes reçus » du destinataire ([aide Hinge](https://help.hinge.co/hc/en-us/articles/360057625534), [SwipeStats](https://www.swipestats.io/blog/hinge-standouts)). Hinge affirme qu'une Rose est deux fois plus susceptible de mener à un rendez-vous (revendication de l'entreprise, [Global Dating Insights](https://www.globaldatinginsights.com/news/hinge-reveals-standouts-and-roses/)). L'aide Hinge note elle-même que ces profils très sollicités ne cherchent peut-être plus.

**Leçon pour MAZL.** Hinge sépare deux produits : la recommandation de compatibilité (appariement) et la visibilité de profils très demandés, avec un signal d'intention payant mais rare (la Rose), proche de nos super likes et boosts.

---

## 3. Réciprocité : les systèmes de recommandation réciproques

**Principe.** Dans la rencontre, une recommandation n'est bonne que si **les deux** parties sont susceptibles de s'apprécier ; recommander uniquement ce que A aime produit des rejets et de la congestion. La littérature parle de *reciprocal recommender systems* (RRS).

- **RECON** (Pizzato, Rej, Chung, Koprinska, Kay, RecSys 2010) : recommandeur réciproque basé sur le contenu, qui apprend les préférences des deux côtés à partir des profils et du comportement de messages, et mesure le taux de succès plutôt que la seule pertinence. Voir [Reciprocal Recommenders (UMAP-ITWP 2010)](https://ls13-www.cs.tu-dortmund.de/homepage/ITWP2010/papers/ReciprocalRecommender.pdf) et la suite « Finding someone you will like and who won't reject you » ([Springer, 2011](https://www.springerprofessional.de/finding-someone-you-will-like-and-who-won-t-reject-you/3687718)).
- **Synthèse de référence** : Palomares, Porcel, Pizzato, Guy, Herrera-Viedma, *Reciprocal Recommender Systems: Analysis of State-of-Art Literature, Challenges and Opportunities towards Social Recommendation*, Information Fusion 69 (2021), [arXiv 2007.16120](https://arxiv.org/abs/2007.16120). Le papier met l'accent sur les **stratégies de fusion** des préférences dans les deux sens.
- **Agrégation.** Le tutoriel SIGIR 2020 de Palomares ([diapositives](https://www.slideshare.net/slideshow/acm-sigir-2020-tutorial-reciprocal-recommendation-matching-users-with-the-right-users/237244623)) traite de la fusion des préférences. Je n'ai pas pu relire le texte intégral pour citer précisément quelles fonctions (moyenne harmonique, géométrique, minimum) y sont comparées : **vérifier avant de citer**. Propriété mathématique générale (non sourcée à un papier précis) : la moyenne harmonique et la moyenne géométrique sont dominées par le plus petit des deux scores, donc un fort score unilatéral ne compense pas un faible score de l'autre côté ; la moyenne arithmétique, elle, le permet.

**À retenir.** Scorer chaque paire dans les deux sens, puis fusionner par une fonction qui pénalise l'asymétrie.

---

## 4. Fraîcheur, distance, préférences, diversité, congestion, nouveauté, boosts, signaux négatifs

**Activité et fraîcheur.** L'activité récente est le signal n°1 cité par Tinder après l'abandon de l'Elo ([Engadget](https://www.engadget.com/2019-03-18-tinder-dumps-desirability-scores.html), [Tecnoblog](https://tecnoblog.net/289506/como-funciona-o-powering-tinder-o-algoritmo-por-tras-dos-matches/)). Hinge note aussi que des profils très sollicités peuvent ne plus chercher ([aide Hinge](https://help.hinge.co/hc/en-us/articles/360057625534)). Il n'y a pas de formule publique de décroissance : le choix (exponentielle, demi-vie) est de notre ressort.

**Distance.** Tinder cite la proximité comme facteur ([Tecnoblog](https://tecnoblog.net/289506/como-funciona-o-powering-tinder-o-algoritmo-por-tras-dos-matches/)). La forme de décroissance n'est pas publiée ; incertitude, à calibrer sur les données MAZL.

**Préférences dures vs souples.** Les préférences déclarées (âge, distance, genre recherché) sont des filtres explicites chez Tinder/Hinge. Mais les préférences **révélées** (ce qu'on like vraiment) divergent parfois des préférences déclarées : [Hitsch, Hortaçsu et Ariely, *What makes you click*, QME 2010](https://scholars.duke.edu/publication/859289) estiment les préférences à partir des choix de contact et trouvent une forte tendance à la similarité sur de nombreux attributs ; leur travail compagnon [*Matching and Sorting in Online Dating*, AER 2010](https://dukespace.lib.duke.edu/items/847881be-8cb3-4df6-ab3d-c2b839aadcfa) montre que les préférences suffisent à expliquer une grande part du tri observé. Conséquence : traiter comme dur ce que l'utilisateur déclare absolu, et comme souple (appris) le reste.

**Congestion et surexposition.** Sur ces plateformes, un coût de contact très bas crée de la congestion : trop de demandes vers les mêmes profils ([Columbia Business School](https://business.columbia.edu/insights/chazen-global-insights/cant-meet-anyone-online-its-not-all-your-fault)). Kanoria & Saban (« Facilitating the Search for Partners on Matching Platforms », [PDF SSRN](https://business.columbia.edu/sites/default/files-efs/citation_file_upload/ssrn-2427960.pdf)) montrent que des restrictions de la plateforme (faire initier le côté minoritaire, masquer certaines informations) améliorent le bien-être ; Arnosti, Johari, Kanoria (*Managing Congestion in Matching Markets*, MSOM 2021, [arXiv 2102.09017](https://arxiv.org/pdf/2102.09017) pour une version voisine sur la conception de recherche) étudient des leviers opérationnels. Application : plafonner l'exposition d'un profil par jour est une réponse documentée à la congestion. Chiffres de plafond : aucun dans la littérature consultée.

**Équité d'exposition.** Singh & Joachims (KDD 2018, [arXiv 1802.07281](https://arxiv.org/pdf/1802.07281)) formalisent l'exposition comme ressource à répartir et expriment des contraintes d'équité (parité démographique, etc.) dans un cadre d'optimisation ; l'effet de position (un rang bas reçoit bien moins de regards) justifie de gérer l'exposition, pas seulement le rang. Utile pour limiter le « winner takes all ».

**Diversité et exploration (bandits).** Les bandits (epsilon-greedy, UCB, Thompson sampling, LinUCB) servent à équilibrer exploitation et exploration, notamment pour le démarrage à froid : [Li et al., cold-start via bandits contextuels](https://arxiv.org/pdf/1405.7544), [survey des applications pratiques](https://arxiv.org/pdf/1904.10040), [Eugene Yan](https://eugeneyan.com/writing/bandits/) (conseille de restreindre l'exploration à un ensemble de candidats déjà pertinents pour protéger l'expérience). Les gains rapportés sont sur MovieLens/Netflix/Yahoo, pas sur la rencontre : transfert à valider.

**Démarrage à froid / nouveauté.** Un nouveau profil n'a pas d'historique ; la littérature bandit propose une exploration forcée contrôlée ([arXiv 1405.7544](https://arxiv.org/pdf/1405.7544)). Tinder dit n'avoir besoin que du genre, de la localisation, de l'âge et de la distance au départ ([Metro.pr](https://www.metro.pr/noticias/2019/03/20/tinder-elo-matches)).

**Boosts payants.** Hinge insère l'argent via un signal d'intention rare (Rose) qui remonte dans la file du destinataire plutôt que de modifier un score global ([aide Hinge](https://help.hinge.co/hc/en-us/articles/360057625534), [SwipeStats](https://www.swipestats.io/blog/hinge-standouts)). Aucune source consultée ne décrit le mécanisme interne d'un « boost » de visibilité de Tinder : **incertitude**. Choix de conception : le boost doit être borné et ne jamais surpasser les filtres durs ni la réciprocité.

**Signaux négatifs (blocages, signalements, ghosting).** Je n'ai trouvé aucune publication de plateforme décrivant en détail la pondération des signalements dans le classement. À traiter comme une décision de produit/modération (voir §7), sans autorité de source.

---

## 5. Équité et biais

- **Biais raciaux documentés.** L'analyse « Race and Attraction, 2009-2014 » d'OkCupid (Christian Rudder) rapporte des préférences raciales marquées dans les messages (par ex. pénalité envers les femmes noires et les hommes asiatiques et noirs selon les groupes) : [Gwern (archive de l'article)](https://gwern.net/doc/psychology/okcupid/raceandattraction20092014.html), [Global Dating Insights](https://www.globaldatinginsights.com/from-the-web/christian-rudder-reveals-okcupid-data-on-race-and-attraction/). Critique méthodologique : [Cathy O'Neil / MathBabe](https://mathbabe.org/2014/09/16/christian-rudders-dataclysm). Hitsch et al. trouvent aussi une forte préférence pour la même origine ([Duke](https://scholars.duke.edu/publication/859289)).
- **Recommandations éthiques.** Hutson, Taft, Barocas, Levy, *Debiasing Desire* (CSCW 2018, [arXiv 1809.01563](https://arxiv.org/abs/1809.01563)) : ne pas coder les préférences ethniques dans les algorithmes, proposer des catégories d'auto-description plus riches, et décourager la discrimination. Le [résumé Cornell](https://news.cornell.edu/node/303801) cite aussi le cas de CoffeeMeetsBagel montrant des profils de même ethnicité malgré « pas de préférence » (rapport d'un journaliste, non vérifié à la source).
- **Boucles de rétroaction.** Un score appris sur les swipes reproduit les préférences biaisées (inférence de la littérature citée). Un moteur à poids explicites rend le biais visible et auditable.
- **Pour MAZL (obligations RGPD).** Le judaïsme est une donnée sensible au sens de l'article 9 du RGPD (opinions religieuses). Le courant, la cashrout et le chabbat sont donc traités avec consentement explicite ; à faire valider juridiquement (non traité par cette recherche).

---

## 6. Spécifique religieux : apps juives et compatibilité ordinale

**Apps existantes.**
- **JSwipe / JDate.** JSwipe propose à l'inscription des courants (Orthodox, Conservative, Reform, « Just Jewish », « Willing to Convert », « Other »), et demande si l'on mange casher ([CJN](https://thecjn.ca/?p=232545), [Daily Beast](https://www.thedailybeast.com/my-week-on-jewish-tinder/)) ; un blog affirme un filtre par courant ([DoULike](https://www.doulike.com/blog/?p=3787), source commerciale). JDate demande le courant à l'inscription et ses filtres avancés (casher, assiduité à la synagogue, tabac, alcool) sont réservés aux abonnés ([Tawkify](https://tawkify.com/blog/dating-methods/best-jewish-dating-apps-sites-websites), blog commercial). Filtre chabbat et champ explicite d'intention de mariage : **non confirmés** dans les résultats.
- **Lox Club.** Appli sélective : candidature, validation par un comité de bénévoles, compte Instagram exigé, nombre de swipes limité (environ une demi-douzaine toutes les six heures selon [DatingNews](https://www.datingnews.com/apps-and-sites/the-lox-club-connects-jewish-singles-who-are-ready-for-love/) et [Wikipedia](https://en.wikipedia.org/wiki/Lox_Club)). Critique : le tri par statut peut être perçu comme élitiste ([Heyalma](https://www.heyalma.com/i-applied-to-the-lox-club-to-see-what-this-elite-jewish-dating-app-is-all-about/)). Intérêt pour MAZL : la **rareté des actions** comme réponse à la congestion (cohérent avec Kanoria & Saban).
- Aucune de ces apps ne publie de formule de compatibilité religieuse : tout ce qui suit relève de la conception, pas d'un état de l'art.

**Les courants sont ordonnés, pas binaires.** À titre de repère de population, Pew (*Jewish Americans in 2020*) montre un gradient net : parmi les juifs américains, 95 % des orthodoxes tiennent casher à la maison, contre environ 24 % des massorti/conservative, 5 % des réformés et 6 % des sans-courant ([Pew, pratiques juives](https://www.pewresearch.org/religious-landscape-study/2021/05/11/jewish-practices-and-customs/) ; synthèse : [Pew](https://www.pewresearch.org/short-reads/2021/05/13/jews-in-u-s-are-far-less-religious-than-christians-and-americans-overall-at-least-by-traditional-measures/)). Cela justifie une échelle **ordinale** (distance entre niveaux) plutôt qu'une égalité stricte. Limite : données américaines, dénominations anglo-saxonnes ; la catégorisation française de MAZL (texte libre : orthodoxe, massorti, libéral, traditionaliste…) devra être normalisée par la table de correspondance décrite ci-dessous. Pew ne fournit pas de chiffres chabbat dans les pages consultées.

**Compatibilité ordinale.** Aucune source consultée ne propose de formule pour ce cas ; la proposition ci-dessous (similarité décroissante avec la distance entre rangs, tolérance asymétrique, préférence « plus pratiquant ») est donc une **hypothèse de conception à valider** avec des utilisateurs et des rabbins ou conseillers communautaires.

---

## 7. Proposition de moteur pour MAZL

Architecture en six étages, chacun lisible et paramétrable :

```
candidats -> filtres durs -> sous-scores souples s_k(A,B) in [0,1]
  -> S(A->B) = somme_k w_k * s_k   (par sens)
  -> réciprocité R = fusion(S(A->B), S(B->A))
  -> multiplicateurs m_i -> score final -> exploration -> classement + explication
```

### 7.1 Filtres durs (éliminatoires, jamais compensés)

| Filtre | Règle | Inspiration |
|---|---|---|
| Genre / « recherche » | réciproque : A cherche le genre de B et B cherche celui de A | préférences explicites Tinder ([Tecnoblog](https://tecnoblog.net/289506/como-funciona-o-powering-tinder-o-algoritmo-por-tras-dos-matches/)) |
| Tranche d'âge | l'âge de B dans la tranche de A **et** inversement | idem ; RRS : les deux sens ([Palomares 2021](https://arxiv.org/abs/2007.16120)) |
| Distance max | distance <= max de A et max de B (le plus petit des deux) | idem |
| Blocages / signalements actifs | exclusion dans les deux sens, y compris profils signalés par A | décision produit, pas de source |
| Profils non éligibles | compte suspendu, sans photo, etc. | décision produit |
| Éventuellement « jamais » religieux | uniquement si l'utilisateur coche explicitement un critère rédhibitoire | principe de préférences dures déclarées ([Hitsch et al.](https://scholars.duke.edu/publication/859289)) ; éviter tout filtre ethnique ([Hutson et al.](https://arxiv.org/abs/1809.01563)) |

Règle d'or : un filtre dur ne s'affiche que si l'utilisateur l'a lui-même posé ; tout le reste est souple.

### 7.2 Sous-scores souples (0..1), formules suggérées

Notation : `A` = demandeur, `B` = candidat. Tous les sous-scores sont calculés du point de vue de A sur B, puis de B sur A.

1. **Courant** `s_courant`. Normaliser le texte libre vers un rang ordinal `r` (par exemple 1 = libéral à 5 = orthodoxe strict) via une table de correspondance versionnée, avec une catégorie « inconnu » pour les valeurs non reconnues. Formule suggérée : `s = max(0, 1 - |r_A - r_B| / D)` où `D` est l'écart maximal toléré (paramètre), avec une tolérance asymétrique (par exemple, pénalité moindre si B est plus pratiquant que A que l'inverse, à valider). Inspiration : gradient ordinal de [Pew](https://www.pewresearch.org/religious-landscape-study/2021/05/11/jewish-practices-and-customs/) ; similarité comme tendance dominante dans [Hitsch et al.](https://scholars.duke.edu/publication/859289). Hypothèse de conception.
2. **Cashrout** `s_cashrout` et 3. **Chabbat** `s_chabbat`. Même forme ordinale sur leur propre échelle (niveaux déclarés). Les trois critères religieux peuvent être fusionnés en un sous-score `s_religieux` (moyenne pondérée) pour l'affichage. Inspiration : champs de JSwipe/JDate ([CJN](https://thecjn.ca/?p=232545), [Tawkify](https://tawkify.com/blog/dating-methods/best-jewish-dating-apps-sites-websites)). Corrélation entre ces trois critères : mesurer sur les données MAZL avant de leur donner des poids indépendants (sinon double comptage).
4. **Âge** `s_age`. Position dans la tranche de A : 1 au centre de la tranche préférée, décroissance douce vers les bords (par exemple linéaire ou gaussienne tronquée). Le filtre dur couvre l'extérieur de la tranche.
5. **Distance** `s_dist = exp(-d / d0)` ou `1 / (1 + (d/d0)^p)`, avec `d0` paramétrable par densité urbaine. Forme non publiée par les plateformes : à calibrer.
6. **Profil** `s_profil` : complétude (photos, bio, prompts) et niveau de vérification (none < selfie < identité). Formule : moyenne pondérée de signaux binaires ou bornés. Raison : un profil complet et vérifié inspire davantage confiance ; décision produit, sans source directe.
7. **Intention** (si disponible) : sérieux de la démarche (mariage), apprise plus tard. Les sources n'établissent pas de champ explicite chez JSwipe.
8. **Affinité apprise** `s_appris` (phase 2) : préférences révélées de A à partir des likes (embeddings à la TinVec, [MLconf](https://mlconf.com/?p=8768)) ou modèle de RECON ([Pizzato et al.](https://ls13-www.cs.tu-dortmund.de/homepage/ITWP2010/papers/ReciprocalRecommender.pdf)). À introduire seulement avec un volume de données suffisant et un audit de biais.

Poids `w_k` : stockés en base, versionnés, modifiables au back-office, somme normalisée à 1. Pas de valeurs recommandées par la littérature ; commencer avec des poids experts puis ajuster par A/B test.

### 7.3 Combinaison

- **Par sens** : `S(A->B) = sum_k w_k * s_k(A,B)`, normalisé dans [0,1].
- **Réciprocité** : `R = 2 * S(A->B) * S(B->A) / (S(A->B) + S(B->A))` (moyenne harmonique) ; alternative : moyenne géométrique `sqrt(S(A->B) * S(B->A))`. Les deux sont dominées par le plus faible des deux sens et évitent les recommandations unilatérales. Source : principe de fusion réciproque de [Palomares et al. 2021](https://arxiv.org/abs/2007.16120) et [RECON](https://ls13-www.cs.tu-dortmund.de/homepage/ITWP2010/papers/ReciprocalRecommender.pdf) ; le choix précis harmonique contre géométrique est à trancher par test (aucune source consultée ne le tranche).
- Pour la phase 2 avec un modèle de probabilité de like `P(B aime A)`, remplacer `S(B->A)` par cette probabilité (idée de [RECON](https://ls13-www.cs.tu-dortmund.de/homepage/ITWP2010/papers/ReciprocalRecommender.pdf) : maximiser les chances de succès des deux côtés).

### 7.4 Multiplicateurs (appliqués après la réciprocité, bornés)

`score = R * m_fraicheur * m_nouveaute * m_boost * m_surexposition * m_signalements`

| Multiplicateur | Formule suggérée | Inspiration |
|---|---|---|
| Fraîcheur / activité | `m = max(m_min, 2^(-delta_jours / demi_vie))` selon la dernière connexion de B | activité = signal n°1 ([Engadget](https://www.engadget.com/2019-03-18-tinder-dumps-desirability-scores.html)) ; forme exponentielle = choix MAZL |
| Nouveauté | bonus `1 + b` décroissant sur les N premiers jours ou les N premières impressions de B (par impressions plutôt que par durée pour éviter l'injustice) | cold start par exploration ([arXiv 1405.7544](https://arxiv.org/pdf/1405.7544)) |
| Boost payant | `m = 1 + min(boost, plafond)` avec plafond **strict** ; ne contourne jamais les filtres durs ni un seuil minimal de réciprocité ; durée limitée | signal d'intention rare, type Rose ([aide Hinge](https://help.hinge.co/hc/en-us/articles/360057625534)) ; mécanisme interne des boosts concurrents inconnu |
| Super like | priorité dans la file du destinataire, pas dans le score général | idem Rose Hinge |
| Surexposition | `m = 1 / (1 + max(0, impressions_24h / plafond - 1))` ou coupure dure à `plafond` impressions par jour ; plafond calibré sur la distribution réelle | congestion ([Kanoria & Saban](https://business.columbia.edu/sites/default/files-efs/citation_file_upload/ssrn-2427960.pdf), [Columbia](https://business.columbia.edu/insights/chazen-global-insights/cant-meet-anyone-online-its-not-all-your-fault)) ; équité d'exposition ([Singh & Joachims](https://arxiv.org/pdf/1802.07281)) |
| Signalements | `m = (1 - p)^n` avec `n` signalements pondérés par la fiabilité du signaleur et jamais appliqué automatiquement sans revue humaine au-delà d'un seuil | aucune source ; décision produit et modération |

Garde-fou de transparence : un boost est toujours affiché comme tel et son impact est plafonné et mesuré.

### 7.5 Exploration

- Réserver une fraction `epsilon` des emplacements (paramétrable) à des candidats **hors top** mais éligibles (filtres durs respectés), tirés par epsilon-greedy ; évolution possible vers Thompson sampling ou UCB quand le volume le permet ([survey bandits](https://arxiv.org/pdf/1904.10040), [Eugene Yan](https://eugeneyan.com/writing/bandits/)).
- Restreindre l'exploration aux candidats déjà plausibles pour protéger l'expérience ([Eugene Yan](https://eugeneyan.com/writing/bandits/)).
- Diversité : pénaliser légèrement la similarité excessive dans une même session. Incertitude : aucune source rencontrée ne mesure l'effet de la diversité sur la rencontre.
- Valeur de `epsilon` : non fournie par la littérature ; démarrer faible et mesurer.

### 7.6 Explicabilité

- **Décomposition stockée par paire** : pour chaque recommandation, enregistrer les `s_k`, les `w_k` de la version utilisée, `R`, chaque `m_i` et la version de la configuration. Un administrateur peut ainsi répondre à « pourquoi A voit B ? ».
- **Raisons affichées à l'utilisateur** : n'afficher que les 2-3 contributions positives les plus fortes (par exemple « même sensibilité religieuse », « proche de chez vous ») ; ne jamais exposer les sous-scores de l'autre personne ni les pénalités (signalements) ni un « score de désirabilité » (leçon de l'Elo : [Fast Company via GDI](https://www.globaldatinginsights.com/news/12012016-tinder-uses-complex-algorithm-secretly-ranks-users/)).
- **Back-office** : écran de simulation (« que se passe-t-il si w_courant passe de x à y ? »), journal des changements de poids, comparaison de deux configurations hors ligne.
- **Audit d'équité** : tableaux de bord d'exposition par segment d'âge, ville et courant (pas d'ethnicité, voir [Hutson et al.](https://arxiv.org/abs/1809.01563)) ; contrôle que le boost payant et la fraîcheur ne créent pas d'écarts imprévus ([Singh & Joachims](https://arxiv.org/pdf/1802.07281)).
- **Mesure du succès** : mesurer les conversations réelles et les matches mutuels, non seulement les likes, comme RECON qui évalue un taux de succès ([UMAP-ITWP 2010](https://ls13-www.cs.tu-dortmund.de/homepage/ITWP2010/papers/ReciprocalRecommender.pdf)).

### 7.7 Points d'incertitude à lever avant mise en production

1. Texte intégral des pages primaires de Tinder (billet 2019) et du papier de Palomares : à relire pour confirmer les fonctions d'agrégation citées.
2. Formes de décroissance (distance, fraîcheur) et plafonds de surexposition : **aucune valeur publiée**, à calibrer sur les données MAZL.
3. Table de correspondance « courant » en texte libre vers rang ordinal : à construire avec des conseillers communautaires ; tolérance asymétrique à valider.
4. Poids initiaux : décision d'experts, puis A/B test.
5. Traitement des données religieuses (RGPD art. 9) et pondération des signalements : validation juridique et modération.
6. Chiffres d'efficacité cités (Hinge : 8x ; Rose : 2x) : revendications d'entreprise non vérifiées de façon indépendante.

---

## Index des sources principales

- Tinder : [Digital Trends](https://www.digitaltrends.com/phones/tinder-rank-elo-score/), [Engadget 2019](https://www.engadget.com/2019-03-18-tinder-dumps-desirability-scores.html), [Global Dating Insights 2019](https://www.globaldatinginsights.com/featured/tinder-changes-algorithms-and-removes-elo-scores/), [Tecnoblog](https://tecnoblog.net/289506/como-funciona-o-powering-tinder-o-algoritmo-por-tras-dos-matches/), [MLconf TinVec](https://mlconf.com/?p=8768)
- Hinge : [TechCrunch](https://techcrunch.com/?p=1668547), [The Hustle](https://thehustle.co/hinge-machine-learning-algorithm), [aide Standouts](https://help.hinge.co/hc/en-us/articles/360057625534)
- Réciprocité : [RECON/Reciprocal Recommenders](https://ls13-www.cs.tu-dortmund.de/homepage/ITWP2010/papers/ReciprocalRecommender.pdf), [Palomares et al. 2021](https://arxiv.org/abs/2007.16120)
- Marchés et équité : [Kanoria & Saban](https://business.columbia.edu/sites/default/files-efs/citation_file_upload/ssrn-2427960.pdf), [Singh & Joachims](https://arxiv.org/pdf/1802.07281), [Hitsch et al.](https://scholars.duke.edu/publication/859289), [Hutson et al.](https://arxiv.org/abs/1809.01563)
- Bandits : [cold-start bandits](https://arxiv.org/pdf/1405.7544), [survey](https://arxiv.org/pdf/1904.10040)
- Judaïsme et apps : [Pew](https://www.pewresearch.org/religious-landscape-study/2021/05/11/jewish-practices-and-customs/), [CJN JSwipe](https://thecjn.ca/?p=232545), [Tawkify](https://tawkify.com/blog/dating-methods/best-jewish-dating-apps-sites-websites), [Lox Club](https://en.wikipedia.org/wiki/Lox_Club)
