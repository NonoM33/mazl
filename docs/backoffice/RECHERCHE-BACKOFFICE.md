# Recherche : back-office staff et modération de MAZL (état de l'art sourcé)

Date : 2026-10-24. Recherche documentaire en lecture seule. Convention : toute affirmation est suivie d'une source. La mention **[non vérifié]** signale une information issue de sources tierces ou non confirmée sur le texte officiel. Les textes DSA ont été lus via le site tiers eu-digital-services-act.com (reprise du règlement) : à recouper avec [EUR-Lex, règlement 2022/2065](https://eur-lex.europa.eu/legal-content/FR/TXT/HTML/?uri=CELEX:32022R2065) avant toute décision juridique. Ce document n'est pas un avis juridique.

---

## 1. Modération d'une application de rencontre

### 1.1 Ce que décrivent les grands acteurs
- **Match Group** : premier rapport de transparence (cadre australien volontaire) : environ 660 000 comptes supprimés ou suspendus sur l'année, dont plus de 610 000 liés aux arnaques et au spam (en majorité de faux comptes), près de 11 000 bannis pour abus ou harcèlement ; la détection automatisée est forte sur le spam et chute pour le harcèlement, Match préférant la revue humaine pour les préjudices graves ([Global Dating Insights](https://www.globaldatinginsights.com/featured/match-group-reports-660000-suspended-accounts-in-past-year/)). Chiffres issus d'un seul rapport, non recoupés avec le document primaire.
- Match avait promis un rapport de transparence en 2020 qui n'était pas publié en février 2025 ([The Markup](https://themarkup.org/investigations/2025/02/13/dating-app-tinder-hinge-cover-up)) : la transparence est un sujet de réputation, pas seulement de conformité.
- **Bumble** : chaque photo de profil est revue par des humains et par des outils automatisés ; interdits : nudité, armes, drogues, violence, symboles haineux ; sanctions : avertissement ou bannissement ([Bumble](https://bumble.com/the-buzz/bumble-safety-moderation)). Combinaison de systèmes automatiques temps réel et de modération humaine « avec le contexte approprié » pour les cas escaladés ([Bumble, Online Safety Act](https://support.bumble.com/hc/en-us/articles/28782518308509-Online-Safety-Act-Protecting-individuals-from-illegal-content)). Aucun processus d'appel public trouvé dans mes recherches.
- **Grindr** : revue de toutes les images de profil avant visibilité ; mélange automatisé et humain pour images et messages ; les signalements de mineurs sont marqués pour traitement immédiat ; signalements au NCMEC et coopération avec les forces de l'ordre ; reconnaissance qu'on ne peut pas vérifier parfaitement l'âge ([Grindr, Keeping Minors Off](https://www.grindr.com/blog/keeping-minors-off-grindr)). Estimation d'âge faciale en Australie avec repli sur pièce d'identité revue par l'équipe ([Grindr, mêmes sources](https://www.grindr.com/blog/our-commitment-to-addressing-online-harms)).
- **Hinge** : une photo de visage est analysée pour estimer la probabilité d'être majeur ; compte retiré si probablement mineur ; cas incertains envoyés à un modérateur formé ; appel par vérification d'identité ([Hinge](https://help.hinge.co/hc/en-us/articles/42464185429651-Why-Are-We-Asking-for-a-Face-Photo)).
- **Tinder** : voir 2.
- **À retenir** : le schéma dominant est « automatique pour le volume (spam, faux comptes), humain pour la gravité et l'ambiguïté ». Aucune de ces sources ne publie de grille de sanctions détaillée ; la gradation décrite ci-dessous est donc une synthèse de conception, pas un standard sourcé (hors DSA art. 17 et 23).

### 1.2 Outils du marché
- **ActiveFence** (a racheté Spectrum Labs en 2023, dont les clients incluaient Grindr) : IA contextuelle texte ; page dédiée aux risques des plateformes de rencontre (arnaques, contournement de vérification, harcèlement, images intimes non consenties) ([ActiveFence](https://www.activefence.com/?p=6392), [TechCrunch](https://techcrunch.com/2023/09/07/activefence-snaps-up-spectrum-labs-last-valued-at-137m-to-help-fight-the-harmful-content-creep/amp)). Discours commercial : allégations non vérifiées.
- **Sift** : plateforme anti-fraude (intégrité de contenu, protection des paiements, litiges) ([Expert Insights](https://expertinsights.com/reviews/sift-digital-trust-and-safety-platform)). Aucun lien sourcé avec la rencontre.
- **Hive** : rien trouvé dans mes recherches ; à documenter séparément avant tout choix. **[non vérifié]**
- Pour une petite équipe, ces outils sont des options de P2 : commencer par règles internes et signalements humains, et prévoir des points d'intégration (webhook de score de risque, file d'entrée).

### 1.3 Éléments de conception (synthèse, alignés sur le DSA)
- **File de signalements** : un signalement = notification structurée (motif normalisé, objet visé, auteur, explication). Le DSA impose des notifications « suffisamment précises et étayées », accusé de réception, décision « en temps opportun, avec diligence, de façon non arbitraire et objective » et information du notifiant sur les recours ([art. 16](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_16.html)).
- **Priorisation (sévérité × risque, SLA)** : pas de standard sourcé pour la formule ; proposer une grille interne. Les signalements « mineur » sont traités en priorité immédiate chez Grindr ([Grindr](https://www.grindr.com/blog/keeping-minors-off-grindr)) ; les menaces pour la vie ou la sécurité déclenchent l'art. 18 DSA (voir 4).
- **Contexte pour le modérateur** : conversation concernée, historique de sanctions et de signalements du membre, statut de vérification, anciens signalements du notifiant (utile à l'art. 23). Bumble évoque explicitement une revue humaine « avec le contexte » ([Bumble](https://support.bumble.com/hc/en-us/articles/28782518308509-Online-Safety-Act-Protecting-individuals-from-illegal-content)).
- **Sanctions graduées** (conception) : avertissement, retrait d'un contenu, restriction (messagerie, visibilité), suspension temporaire, bannissement. Toute restriction de visibilité, suspension ou clôture de compte fondée sur l'illégalité ou les CGU doit être motivée par un exposé des motifs ([art. 17](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_17.html)).
- **Contestation** : voir 4 (art. 20). **Journal d'audit** : voir 5.

---

## 2. Vérification

- **Tinder Face Check** : selfie vidéo court, confirme une personne réelle et présente dont le visage correspond aux photos, badge « Photo Verified », détection du même visage sur plusieurs comptes ; vidéo supprimée peu après revue, conservation d'une empreinte faciale chiffrée non réversible pour détecter fraude et doublons ; distinct de la vérification par pièce d'identité ([Match Group](https://mtch.com/?p=1143), [TechCrunch](https://techcrunch.com/2025/10/22/tinder-will-require-new-users-in-the-us-to-verify-their-identity-with-a-selfie)). Gain annoncé (plus de 60 % de baisse d'exposition aux mauvais acteurs) : chiffre de l'entreprise, non vérifié de façon indépendante.
- **Hinge / Grindr** : estimation d'âge sur photo ou visage, repli sur pièce d'identité et revue humaine ([Hinge](https://help.hinge.co/hc/en-us/articles/42464185429651-Why-Are-We-Asking-for-a-Face-Photo), [Grindr](https://www.grindr.com/blog/our-commitment-to-addressing-online-harms)).
- **Pour MAZL (conception)** : niveaux de badge distincts (e-mail/téléphone, selfie-liveness, pièce d'identité, éventuellement vérification communautaire), file de revue manuelle des cas où le score automatique est incertain, motif de rejet normalisé, possibilité de recours.
- **RGPD** : la reconnaissance faciale est un traitement de données biométriques (art. 9) ; la CNIL est réservée sur la biométrie jugée disproportionnée ([Next.ink sur ALICEM](https://next.ink/news/107883-alicem-biometrie-identite-numerique-sur-mobile-fait-tiquer-cnil.htm)). Aucune doctrine CNIL/EDPB précise sur le selfie-liveness privé n'a été trouvée : **[non vérifié]**, à demander au DPO ou à un avocat. Pistes de minimisation : supprimer la vidéo après revue, ne conserver qu'un résultat (vérifié oui/non, date, prestataire), pas de gabarit biométrique réutilisable sans base légale explicite.

---

## 3. Anti-arnaque, faux profils, mineurs

### 3.1 Romance scam : signaux
- Demande d'argent par carte cadeau, virement ou cryptomonnaie ; tentative de quitter rapidement le site ; déclarations d'amour précoces ; excuses pour ne pas se rencontrer (militaire, à l'étranger) ([FTC](https://consumer.ftc.gov/node/298459)). Les plus grosses pertes déclarées passent par la cryptomonnaie ([Cointelegraph, FTC](https://cointelegraph.com/news/ftc-warns-crypto-romance-scams)).
- Demande de passer vite sur une messagerie privée, conseils d'investissement crypto vers une plateforme désignée, petits gains initiaux pour inciter à réinvestir (type « pig butchering ») ([CFTC via Constantine Cannon](https://constantinecannon.com/?p=50199)).
- **Copier-coller de messages et incohérences IP/pays** : aucune source trouvée qui les documente ; ce sont des heuristiques de conception courantes mais **[non vérifié]**. Les signaler dans le back-office comme « signaux faibles » à cumuler, jamais comme preuve.
- Aucune des 6 sources n'est une étude de détection ; la pondération des signaux doit être calibrée sur les données réelles de MAZL.
- **Réalité du volume** : chez Match, l'immense majorité des retraits concerne arnaques et spam ([Global Dating Insights](https://www.globaldatinginsights.com/featured/match-group-reports-660000-suspended-accounts-in-past-year/)) : un tableau de bord « risque arnaque » est central.

### 3.2 Faux profils
- Détection de même visage sur plusieurs comptes via la vérification faciale ([Match Group](https://mtch.com/?p=1143)) ; revue des photos à l'upload (Bumble, Grindr, voir 1.1).

### 3.3 Mineurs
- Chez Grindr : signalement « mineur » prioritaire, bannissement prompt, signalement au NCMEC ([Grindr](https://www.grindr.com/blog/keeping-minors-off-grindr)) ; chez Hinge : estimation d'âge puis modérateur humain ([Hinge](https://help.hinge.co/hc/en-us/articles/42464185429651-Why-Are-We-Asking-for-a-Face-Photo)).
- **DSA art. 28** : mesures appropriées pour un niveau élevé de protection de la vie privée, sûreté et sécurité des mineurs ; pas d'obligation de collecter des données supplémentaires pour vérifier l'âge ([art. 28](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_28.html)). Voir 4.2 : cet article ne s'applique pas aux petites plateformes, mais l'exigence reste incontournable pour une application réservée aux adultes.

---

## 4. Juridique UE / France

### 4.1 Textes DSA : synthèse article par article
| article | contenu retenu | source |
|---|---|---|
| 15 | rapport de transparence au moins annuel, lisible par machine ; contenu : injonctions, notifications, modération d'office, réclamations, outils automatisés ; **non applicable aux micro et petites entreprises** (sauf très grandes plateformes) | [art. 15](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_15.html) |
| 16 | mécanisme de notification et d'action pour tout hébergeur | [art. 16](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_16.html) |
| 17 | exposé des motifs pour toute restriction (visibilité, suspension de compte, etc.) | [art. 17](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_17.html) |
| 18 | information rapide des autorités en cas de soupçon d'infraction pénale impliquant une menace pour la vie ou la sécurité | [art. 18](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_18.html) |
| 19 | exclusion des micro et petites entreprises de la section 3 (plateformes), sauf art. 24 §3 | [art. 19](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_19.html) |
| 20 | réclamations internes | [art. 20](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_20.html) |
| 21 | règlement extrajudiciaire | [art. 21](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_21.html) |
| 23 | suspension des utilisateurs et notifiants abusifs | [art. 23](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_23.html) |
| 24 | rapports complémentaires, nombre de destinataires actifs tous les six mois, base de données des motifs | [art. 24](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_24.html) |
| 28 | protection des mineurs | [art. 28](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_28.html) |

### 4.2 Le point décisif : le statut micro / petite entreprise
- L'art. 19 écarte de la section 3 (arts 19 à 28 : réclamations, règlement extrajudiciaire, signaleurs de confiance, mesures contre les abus, transparence des plateformes, interfaces trompeuses, publicité, recommandation, mineurs) les plateformes qui sont des micro ou petites entreprises au sens de la recommandation 2003/361/CE, **à l'exception de l'art. 24 §3** ; l'exemption se prolonge 12 mois après la perte du statut, et ne vaut pas pour les très grandes plateformes ([art. 19](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_19.html), [Presencis](https://presencis.com/regulations/dsa/article-19/)).
- Seuils : micro < 10 salariés et CA ≤ 2 M€ ; petite < 50 salariés et CA ≤ 10 M€ (source tierce, à vérifier sur la recommandation) ; l'appréciation se fait sur base consolidée du groupe **[non vérifié]** ([Presencis](https://presencis.com/regulations/dsa/article-19/)).
- **Conséquence si MAZL est une petite entreprise ET une « plateforme en ligne »** : restent applicables les obligations de la section 2 pour tout hébergeur (arts 16, 17, 18 : notification et action, exposé des motifs, signalement des infractions menaçant la vie) et les obligations générales de la section 1 (point de contact, représentant légal le cas échéant, CGU claires). Ne s'appliquent pas, en droit : art. 20 (réclamations), 21, 23, art. 15 (rapport annuel), art. 24 §1-2, art. 28 (mineurs). La publication du nombre de destinataires actifs (art. 24 §2) est en section 3 ; l'art. 24 §3 impose seulement de le communiquer sur demande au coordinateur et à la Commission ([art. 24](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_24.html)). Le considérant 57 confirme le maintien de cette demande d'information ([Presencis](https://presencis.com/regulations/dsa/article-19/)).
- **Incertitude à lever** : l'art. 17 s'applique aux hébergeurs ; la base de données des motifs (art. 24 §5) vise les plateformes en ligne ([DSA Transparency Database, API](https://transparency.dsa.ec.europa.eu/page/api-documentation), [MHC](https://mhc.ie/latest/insights/dsa-transparency-database-to-apply-to-all-online-platforms)), et l'art. 24 §5 relève de la section 3, donc, par l'art. 19, serait exclu pour une petite plateforme. L'interprétation de la Commission n'a pas été confirmée dans mes recherches : **[non vérifié]**.
- **Recommandation de conception** : même exemptée, bâtir dès le départ les mécanismes des arts 16, 17, 20 et 23, car ils sont peu coûteux et sont aussi de bonnes pratiques ; si MAZL grandit, l'exemption tombe 12 mois après la perte du statut.

### 4.3 Exigences opérationnelles par article (pour le back-office)
- **Art. 16** : formulaire de signalement avec explication motivée, localisation précise du contenu, identité du notifiant (sauf exceptions CSAM), déclaration de bonne foi ; accusé de réception ; décision notifiée avec voies de recours ; mention de l'usage de moyens automatisés ([art. 16](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_16.html)).
- **Art. 17** : l'exposé indique la nature de la décision (portée, durée), les faits retenus, si elle vient d'une notification ou d'une enquête d'office, l'usage de moyens automatisés, la base légale ou la clause des CGU, les voies de recours ; langage clair et précis ; exception si les coordonnées du destinataire sont inconnues ou en cas de contenu commercial trompeur massif ([art. 17](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_17.html)). → modèle de décision structuré avec ces champs, généré à chaque sanction.
- **Base de données DSA** : les plateformes y transmettent leurs exposés des motifs sans données personnelles, par API (jeton, bac à sable avant production) ou formulaire web pour les faibles volumes ([art. 24](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_24.html), [documentation API](https://transparency.dsa.ec.europa.eu/page/api-documentation)). → prévoir un export anonymisé des décisions, activable si MAZL y est soumis.
- **Art. 20** : contestation possible au moins 6 mois après la décision, par voie électronique, gratuite, facile d'usage ; traitement rapide, équitable, sans arbitraire ; annulation sans retard si fondée ; décision finale **non exclusivement automatisée**, sous supervision de personnel qualifié ; motivation et indication des recours dont l'art. 21 ([art. 20](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_20.html)). → file « contestations » séparée, assignée à un autre modérateur que l'auteur de la décision initiale (bonne pratique, non exigée par le texte lu).
- **Art. 21** : organes certifiés, décisions sous 90 jours (prolongeables jusqu'à 180), frais à la charge de la plateforme si le destinataire gagne ([art. 21](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_21.html)). Pour MAZL : au minimum, mentionner cette voie dans les exposés des motifs si l'art. 21 s'applique.
- **Art. 23** : suspension possible, après avertissement préalable, des utilisateurs fournissant fréquemment du contenu manifestement illégal et des notifiants soumettant fréquemment des signalements manifestement infondés ; critères : nombre absolu, proportion, gravité, intention ; la politique doit figurer dans les CGU avec exemples et durée ([art. 23](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_23.html)). → compteur de signalements abusifs par notifiant, avertissement tracé, suspension de la capacité à signaler.
- **Art. 15 / 24** : si applicable, rapport au moins annuel avec volumes, délai médian, réclamations et annulations ; plateformes : nombre de litiges 21 et de suspensions 23 en plus ([art. 15](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_15.html), [art. 24](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_24.html)). La fréquence semestrielle des rapports de plateformes n'est pas dans le texte lu pour l'art. 24 : **[non vérifié]** ; seule la publication des destinataires actifs est dite tous les six mois. → collecter dès maintenant les données de ces rapports (voir 6).
- **Art. 18** : signaler aux autorités répressives de l'État concerné (ou à l'État d'établissement, ou Europol) les informations faisant soupçonner une infraction impliquant une menace pour la vie ou la sécurité ([art. 18](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_18.html)). → bouton « escalade autorités » avec dossier figé, réservé au rôle habilité.
- **Art. 28** : voir 3.3.

### 4.4 Autorités françaises
- **Arcom** : coordinateur national des services numériques depuis la loi SREN ; travaille avec la DGCCRF et la CNIL ([Arcom](https://www.arcom.fr/en/professional-space/regulations-on-digital-services-or-dsa-obligations-and-concerned-services), [Next.ink via recherche](https://next.ink/brief-article/e-enfance-devient-le-premier-signaleur-de-confiance-en-france/)). Le statut de signaleur de confiance (art. 22) relève de l'Arcom, e-Enfance étant le premier en France.
- **PHAROS** : plateforme publique de signalement, gérée par l'OCLCTIC, qui transmet aux services d'enquête compétents ([fiche mémo académique](https://caaee.ac-versailles.fr/wp-content/uploads/sites/347/2024/09/01-fiche-memo-caaee1-pharos_1qorepeyk19.pdf)). L'hébergeur doit offrir un dispositif de signalement facilement accessible (LCEN art. 6-I) ([Assemblée nationale, question écrite](https://www.assemblee-nationale.fr/dyn/14/questions/QANR5L14QE22445.pdf)).
- **Réquisitions judiciaires** (art. 60-1 CPP) et **conservation des données d'identification** (LCEN art. 6-II) : non confirmés dans mes sources, à vérifier sur Légifrance. **[non vérifié]** → prévoir un registre des réquisitions, un point d'entrée unique, un rôle dédié.

### 4.5 RGPD
- **Art. 9** : une application juive révèle la religion par construction. Par analogie, l'autorité norvégienne a jugé que le simple usage de Grindr révèle l'orientation sexuelle, et que consentir à la politique de confidentialité pour accéder à l'appli n'est pas un consentement libre ; le consentement explicite est requis ([Next.ink](https://next.ink/brief-article/la-sanction-de-58-millions-deuros-de-la-cnil-norvegienne-contre-grindr-confirmee/), [DAC Beachcroft](https://www.dacbeachcroft.com/en/what-we-think/grindrs-consent-rules-are-no-match-for-the-gdpr)). Conséquence : le back-office manipule des données sensibles par défaut ; limiter leur exposition (moindre privilège, journalisation de chaque consultation).
- **Données biométriques** : catégorie particulière de l'art. 9, traitement interdit sauf exception ([donneespersonnelles.fr](https://donneespersonnelles.fr/donnees-biometriques-rgpd)). Voir 2.
- **AIPD (art. 35)** : la CNIL tient une liste de traitements pour lesquels elle est obligatoire (adoptée en 2018) et précise qu'un traitement hors liste peut aussi y être soumis ([CNIL, liste](https://www.cnil.fr/fr/liste-traitements-aipd-requise)). Je n'ai pas pu confirmer que la religion ou la rencontre y figurent : **[non vérifié]**. Prudence : réaliser une AIPD (traitement à grande échelle de données sensibles + biométrie + scoring de risque).
- **Journalisation** : la CNIL suggère une conservation des traces d'accès de 6 mois à 1 an, jusqu'à 3 ans pour des traitements sous contrôle interne avec risque démontré ; recommandation non prescriptive ([CNIL, recommandation](https://www.cnil.fr/fr/node/9999), via [Dalloz](https://www.dalloz-actualite.fr/document/projet-de-recommandation-relative-journalisation-23-avr-2021) ; synthèse par recherche, texte final non lu).
- **Art. 22** : décision fondée exclusivement sur un traitement automatisé avec effet significatif. Le DSA art. 20 impose déjà une décision de réclamation non exclusivement automatisée ([art. 20](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_20.html)). Conséquence : pas de bannissement 100 % automatique sans voie de revue humaine. L'article 22 n'a pas été relu dans cette recherche : **[non vérifié]**.
- **Droit d'accès, minimisation, conservation** : pas de durée sourcée pour les dossiers de modération ; à fixer (voir section 9).

---

## 5. Équipe (staff) : rôles, accès, audit, bien-être

- **RBAC / moindre privilège** : standard de conception ; aucune source dédiée consultée. Rôles proposés : modérateur (N1), vérificateur (identité/selfie), support, modérateur senior (contestations), administrateur, super-administrateur, DPO/juridique (lecture, réquisitions). Principe : séparation des tâches, p. ex. l'auteur d'une sanction ne tranche pas sa contestation.
- **MFA** : obligatoire pour tout compte staff (aucune source spécifique citée ; recommandation de sécurité générique).
- **Journal d'audit immuable** : hash-chaining, chaque entrée contient le hash de la précédente, ce qui rend détectable toute modification, suppression ou insertion ; vérification périodique ; ancrage de la tête de chaîne hors de la base pour résister à un attaquant maître de la base ; verrouillage append-only par triggers ([DEV Community](https://dev.to/137foundry/how-to-add-tamper-evidence-to-an-existing-audit-table-17f1), [C# Corner](https://www.c-sharpcorner.com/article/building-tamper-evident-audit-logs-for-ai-agent-actions/), [Knogin](https://knogin.com/en/developers/auth-tamper-evident-audit-trail), [DesignGurus](https://www.designgurus.io/answers/detail/how-do-you-design-tamperevident-audit-logs-merkle-trees-hashing)). Sources tierces ; le texte de l'OWASP Logging Cheat Sheet et d'ASVS V16 n'a pas été relu : **[non vérifié]**.
- **Accès « break-glass »** : accès exceptionnel aux données sensibles (conversation privée, pièce d'identité) avec motif obligatoire, ticket lié, limite de durée, alerte au super-administrateur, revue a posteriori. Pratique de conception, pas de source citée.
- **Bien-être des modérateurs** : Meta propose floutage ou niveaux de gris, avec peu de détails publics ([Springer, Psychological Research 2026](https://link.springer.com/article/10.1007/s00426-026-02241-5)). Résultats mitigés : le niveau de gris a un effet positif selon une étude HCOMP 2019 ([AAAI](https://ojs.aaai.org/index.php/HCOMP/article/view/5270)) ; le floutage interactif réduit l'impact sans perte de vitesse ni de précision ([Das et al. 2020](https://ischool.utexas.edu/ml/papers/das_hcomp20.pdf)) ; une étude 2026 sur modérateurs simulés ne trouve aucun bénéfice du floutage ou du niveau de gris ([Springer](https://link.springer.com/article/10.1007/s00426-026-02241-5)). Conclusion prudente : flou par défaut avec dévoilement à la demande, rotation des tâches, quotas de contenus graves, soutien psychologique.

---

## 6. Tableaux de bord et KPI

Aucune norme sourcée des KPI ; ils découlent des champs exigés par l'art. 15 et l'art. 24 :
- **Volumes** : notifications reçues, par motif, par origine (utilisateur / détection interne), nombre de mesures prises, notifications traitées automatiquement, délai médian de traitement ([art. 15](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_15.html)).
- **Réclamations** : nombre, motifs, issues, délai médian, nombre de décisions annulées (donc taux de renversement) ([art. 15](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_15.html)).
- **Litiges 21 et suspensions 23** : nombre et issues ([art. 24](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_24.html)).
- **Outils automatisés** : précision, taux d'erreur possible ([art. 15](https://www.eu-digital-services-act.com/Digital_Services_Act_Article_15.html)) → suivre faux positifs/négatifs par règle.
- **Spécifiques à une appli de rencontre** : taux de faux profils et d'arnaques bannis (cf. répartition Match, [Global Dating Insights](https://www.globaldatinginsights.com/featured/match-group-reports-660000-suspended-accounts-in-past-year/)), taux de vérification, prévalence (part de profils ou conversations actifs enfreignant les règles, estimée par échantillonnage : méthode de conception, non sourcée), signalements « mineur » et délai de premier traitement, charge par modérateur.
- **Support client** : volume, délai de première réponse, motif ; pas de source dédiée.

---

## 7. Exigences retenues pour MAZL

### P0 (avant ouverture au public)
1. File de signalements unique avec motifs normalisés, statut, assignation, SLA par priorité ; accusé de réception au notifiant (art. 16).
2. Priorité maximale « mineur présumé » et « menace pour la vie ou la sécurité » ; procédure de retrait immédiat de visibilité.
3. Fiche membre avec contexte : conversation signalée, historique des signalements/sanctions, statut de vérification, signaux d'arnaque.
4. Sanctions graduées (avertissement, restriction, suspension temporaire, bannissement) avec **exposé des motifs structuré** généré et envoyé à chaque décision (champs de l'art. 17, voies de recours).
5. Canal de contestation gratuit, électronique, ouvert au moins 6 mois, traité par une personne autre que l'auteur de la décision ; aucune décision finale automatisée (art. 20, RGPD art. 22).
6. RBAC strict (modérateur, vérificateur, support, admin, super-admin) + MFA obligatoire pour tout staff.
7. Journal d'audit append-only avec chaînage de hash de toute action staff, y compris les lectures de données sensibles.
8. Floutage par défaut des images dans les files de revue, dévoilement sur clic journalisé.
9. Registre des demandes d'autorités (réquisitions, PHAROS, art. 18) accessible à un rôle restreint.
10. AIPD et registre de traitement avant lancement de la vérification biométrique ; base légale art. 9 tranchée (section 9).

### P1 (premiers mois)
11. File de vérification manuelle (selfie/liveness, pièce d'identité) avec motifs de rejet normalisés, badges par niveau, suppression automatique des médias biométriques brutes après revue.
12. Détection des signaux d'arnaque : mots-clés (crypto, virement, carte cadeau, messagerie externe), ancienneté du compte, messages dupliqués, pays/IP incohérents, doublons de visage ; score de risque affiché, jamais décision seule.
13. Suivi des notifiants abusifs et avertissement avant suspension de la capacité de signaler (art. 23).
14. Accès « break-glass » avec motif obligatoire, durée limitée, alerte et revue a posteriori.
15. KPI : volume, délai médian, taux de contestation, taux de renversement, taux d'arnaques/faux profils, charge par modérateur ; export CSV des champs de l'art. 15.
16. Outil support client lié à la fiche membre (sans accès aux conversations par défaut).

### P2 (selon croissance)
17. Export vers la base de données DSA (API) si MAZL y est soumis ; rapport de transparence automatisé.
18. Intégration de fournisseurs (ActiveFence, Sift, estimation d'âge, vérification d'identité) via file d'entrée normalisée.
19. Vérification périodique du chaînage du journal + ancrage externe de la tête de chaîne.
20. Mesures de bien-être avancées : quotas de contenu grave, rotation, indicateurs d'exposition par modérateur.
21. Échantillonnage de prévalence, tableaux de bord de qualité (accord inter-modérateurs, revue par un pair).
22. Interface de désignation des organes de règlement extrajudiciaire (art. 21) et réception des litiges.

---

## 8. Limites de cette recherche
- Les textes DSA ont été lus sur un site miroir, pas sur EUR-Lex ; l'effet exact de l'art. 19 sur chaque article de la section 3 (en particulier art. 24 §2 et §5) doit être confirmé.
- Pas de source officielle sur : réquisitions (CPP), LCEN art. 6-II, RGPD art. 22 relu, doctrine CNIL/EDPB sur selfie-liveness, liste AIPD CNIL (religion), rapports de transparence primaires de Tinder/Hinge/Bumble, Hive.
- Chiffres de Match Group : reprises médiatiques, non recoupées.

## 9. Points juridiques à trancher par le responsable
1. **MAZL est-il une « plateforme en ligne » au sens DSA** (stockage et diffusion publique d'informations à la demande des utilisateurs : profils, photos, messages) ou seulement un hébergeur ? Les messages strictement privés peuvent être considérés comme ne constituant pas une diffusion au public ; à qualifier avec un avocat.
2. **Statut micro / petite entreprise** : effectifs, chiffre d'affaires, calcul consolidé avec le groupe ou l'ESN, suivi du seuil et de la période de grâce de 12 mois.
3. Si le statut s'applique : décider quand même d'implémenter arts 17, 20 et 23 par bonne pratique, et d'afficher la voie de l'art. 21.
4. **Base légale art. 9 RGPD** pour la religion (consentement explicite distinct, séparé des CGU, retirable) et pour la biométrie (consentement explicite ou autre exception) ; alternative sans biométrie pour qui refuse la vérification faciale.
5. **Données sensibles dans le back-office** : qui y accède, pourquoi, quelle journalisation, quelle limitation de lecture des conversations.
6. **AIPD** : obligatoire ou non, qui la rédige, nomination ou non d'un DPO.
7. **Durées de conservation** : dossiers de modération, journal d'audit (repère CNIL 6 mois à 1 an, jusqu'à 3 ans si justifié), médias de vérification (à supprimer rapidement), preuves gelées pour une procédure, données conservées pour les autorités (LCEN).
8. **Décisions automatisées** : périmètre des actions automatiques permises (masquage temporaire oui, bannissement définitif non sans revue humaine).
9. **Mineurs** : stratégie de détection de l'âge (estimation faciale ? pièce d'identité en repli ?) compatible avec la minimisation, et obligation de signalement en cas de contenu pédocriminel.
10. **Demandes d'autorités** : processus de réception des réquisitions, interlocuteur désigné, contenu transmis, signalement PHAROS ; représentant légal et point de contact DSA.
11. **Sous-traitance** : fournisseurs de vérification d'identité ou de modération (contrat de sous-traitance, localisation UE, transferts hors UE).
12. **Bien-être des modérateurs** : obligations de l'employeur et information préalable sur l'exposition à des contenus choquants.
