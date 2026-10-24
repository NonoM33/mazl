# Politique de confidentialité de MAZL

**Version du 24 octobre 2026** — projet soumis à validation juridique avant publication.

> Documents liés : [Conditions générales d'utilisation](/cgu.html) · [Conditions générales de vente](/cgv.html)

Cette politique explique quelles données personnelles MAZL traite, pourquoi, pendant combien de temps, avec qui nous les partageons et comment exercer vos droits, conformément au règlement (UE) 2016/679 (« RGPD ») et à la loi n° 78-17 du 6 janvier 1978 modifiée.

## 1. Responsable du traitement

- Responsable du traitement : [À COMPLÉTER : raison sociale de l'éditeur], [À COMPLÉTER : forme juridique et capital], [À COMPLÉTER : SIREN / RCS], [À COMPLÉTER : adresse du siège].
- Contact pour les données personnelles : [À COMPLÉTER : adresse e-mail dédiée aux demandes RGPD].
- Délégué à la protection des données (DPO) : [À COMPLÉTER : coordonnées du DPO, ou mention « aucun DPO n'a été désigné » si l'éditeur n'y est pas tenu. Compte tenu du traitement à grande échelle de données sensibles, la désignation d'un DPO est à examiner avec le conseil de l'éditeur (article 37 du RGPD).]
- Représentant dans l'Union : sans objet, le responsable est établi en France. [À COMPLÉTER : confirmer]

## 2. Données traitées

### 2.1 Compte et connexion

Vous vous connectez avec Google ou Apple. Nous recevons et conservons : l'identifiant fourni par le fournisseur (« sub »), votre adresse e-mail (pour Apple, éventuellement une adresse relais masquée), votre nom et, pour Google, l'URL de votre photo de compte (que vous pouvez choisir d'importer comme photo de profil). Nous conservons aussi les dates de création, de mise à jour et de dernière connexion du compte et son état (actif ou non). Nous ne recevons pas votre mot de passe Google ou Apple. Une fois connecté, votre appareil conserve un jeton de session valable 30 jours, dans le stockage sécurisé du téléphone.

### 2.2 Profil

Prénom ou pseudo d'affichage (50 caractères maximum), date de naissance (âge), genre (homme ou femme), ville, présentation (« bio », 1000 caractères maximum), réponses aux questions de profil (« prompts »), préférences de recherche (genre recherché, tranche d'âge, distance maximale), et vos **informations de pratique** : courant (« dénomination »), niveau de cacherout, respect du Shabbat. Vos photos de profil (6 maximum) sont ré-encodées à l'envoi et leurs métadonnées (dont la géolocalisation) supprimées.

### 2.3 Données révélant la religion et l'orientation (catégories particulières, article 9 du RGPD)

- Les informations de pratique religieuse (courant, cacherout, Shabbat) **révèlent vos convictions religieuses**. Par nature, l'usage d'un service de rencontre destiné à une communauté religieuse peut aussi révéler votre appartenance ; nous le traitons comme tel.
- L'association de votre genre et du genre que vous recherchez permet d'**inférer votre orientation sexuelle**.

Ces données ne sont traitées que sur la base de votre **consentement explicite** (article 9, paragraphe 2, a), recueilli sur le site web (case non pré-cochée, texte daté et versionné) avant leur saisie et distinct de l'acceptation des CGU. Chaque décision (accord ou retrait) est enregistrée avec sa date, la version du texte et le support utilisé (site ou application) ; l'historique est conservé pour pouvoir prouver le consentement. Elles sont facultatives dans la mesure où le Service le permet : vous pouvez les laisser vides ou les effacer depuis votre profil ; vous pouvez retirer votre consentement à tout moment (article 10), ce qui peut empêcher d'utiliser les fonctions de recherche qui en dépendent. **Le retrait efface** les informations de pratique religieuse de votre profil (courant, cacherout, Shabbat, intention) ; il est possible à tout moment dans les réglages du site. [À COMPLÉTER : l'écran de recueil existe sur le site web ; l'écran équivalent de l'application mobile reste à réaliser avant de pouvoir affirmer ce recueil pour les membres de l'application.]

### 2.4 Localisation

- Vous indiquez votre ville (recherche d'une commune) et, si vous l'autorisez, l'Application peut utiliser la position de votre téléphone.
- **La position exacte n'est jamais conservée.** Avant stockage, la position est arrondie à une grille d'environ 1 km, puis décalée d'un vecteur fixe propre à chaque membre (au plus 1 km environ). Nous ne conservons que cette position dégradée.
- La distance minimale de recherche est de 5 km. Les autres membres ne voient jamais vos coordonnées ni une distance précise.
- Nous conservons, pour limiter les abus, la date de vos mises à jour de position (au plus 10 par 24 heures).

### 2.5 Vérification d'identité et biométrie

Voir l'article 5 des CGU. Précisément :

- **Selfie vérifié (niveau 1).** Plusieurs images extraites d'une courte séquence vidéo guidée sont analysées **en mémoire** pour vérifier la présence d'une personne réelle (« preuve de vie ») et la correspondance avec vos photos de profil. **Les images ne sont pas conservées.** Est conservée uniquement une **empreinte numérique de votre visage (« gabarit »), chiffrée** (AES-256-GCM), qui sert à vérifier les photos ajoutées plus tard. Cette empreinte est une **donnée biométrique traitée pour identifier une personne de manière unique, donnée sensible au sens de l'article 9**. Elle repose sur votre consentement explicite, que vous pouvez retirer à tout moment depuis l'Application (la suppression de l'empreinte retire aussi le badge). Un journal technique des sessions de vérification (date, finalité, résultat sous forme de code) est conservé.
- **Pièce d'identité (niveau 2).** Les données de la puce de votre passeport ou carte d'identité (zone de lecture machine, photo de la puce, signature d'authenticité) sont lues par votre téléphone et envoyées à nos serveurs pour être **vérifiées en mémoire, puis oubliées**. Nous ne conservons **ni image du document, ni photo de la puce, ni votre nom, ni le numéro du document**. Nous conservons : le résultat et la méthode de vérification, la date, le **pays émetteur**, le **type de document**, sa **date d'expiration**, **votre date de naissance** (qui devient la date de naissance de votre profil, non modifiable) et une **empreinte cryptographique irréversible du document (HMAC)**, qui garantit qu'un document n'ouvre qu'un seul compte et que le document d'un membre définitivement exclu ne puisse servir à se réinscrire. La photo de la puce est comparée en mémoire à votre selfie.
- **Relecture manuelle (repli).** Si vous transmettez des documents (pièce d'identité recto/verso, selfie avec pièce) par le parcours de vérification web, ils sont stockés **chiffrés** et vus par un modérateur habilité, puis **supprimés dès la décision** (acceptation ou refus). Un document non examiné est supprimé au bout de 30 jours.

Aucune décision de modération ou d'exclusion n'est prise **exclusivement** par un traitement automatisé : le refus d'une vérification peut être contesté auprès de l'équipe (article 11).

### 2.6 Activité et échanges

Likes, Super Likes et « Passer » (swipes), matchs, messages (texte), photos et messages vocaux envoyés dans une conversation (stockés chiffrés en transit et servis par des liens signés de courte durée), réactions, accusés de lecture, aperçus de liens (si vous partagez un lien, nos serveurs le consultent pour en tirer un titre et une image, avec une mise en cache de 24 heures), participation aux événements, Boosts activés.

### 2.7 Mode couple

Demandes et statut de couple, date de début, statut de relation, et les contenus de l'espace commun (réponses aux questions du jour, souvenirs, dates, liste d'envies, jalons, activités sauvegardées et réservations). Ils sont visibles par les deux membres du couple.

### 2.8 Sécurité et modération

Signalements (motif, précisions, message visé, auteur du signalement), blocages entre membres, sanctions et bannissements, notes internes de modération, journal d'actions des modérateurs, traces d'accès techniques (adresse IP, date, erreurs) utilisées pour la sécurité et le fonctionnement. Les journaux de fonctionnement n'enregistrent ni jeton, ni image, ni contenu de message.

### 2.9 Achats

Statut de l'abonnement mazl+ (formule, dates de début et d'expiration, statut), identifiants de transaction Apple, produits achetés, soldes et historique d'usage des Boosts et Super Likes. Pour un achat fait sur le site, nous conservons aussi votre identifiant client Stripe, l'identifiant de l'abonnement, l'historique de vos paiements et la preuve de votre renoncement au droit de rétractation (date, offre, version du texte). **Nous ne recevons ni votre numéro de carte, ni vos coordonnées bancaires** : ils restent chez Apple ou chez Stripe.

### 2.10 Notifications, e-mails et liste d'attente

- **Notifications push** : un identifiant technique d'appareil et un identifiant de membre (de la forme « user_… ») sont transmis à OneSignal pour vous adresser les notifications (nouveau match, message, demande de couple, etc.). Vous pouvez les désactiver dans les réglages de votre téléphone.
- **E-mails** : e-mails de service (vérification, documents à renvoyer, profil vérifié) et, le cas échéant, e-mails d'information ou de campagne, envoyés via Resend. Chaque message d'information comporte un lien de désinscription ; la liste des adresses désinscrites est conservée pour respecter votre choix.
- **Liste d'attente (site)** : adresse e-mail, système d'exploitation déclaré, état de la vérification et dates d'étapes.

### 2.11 Raison de départ

Si vous la renseignez à la suppression de votre compte, la raison est conservée **sans aucun identifiant** (ni numéro de membre, ni e-mail).

## 3. Finalités et bases légales

| Finalité | Données principales | Base légale |
|---|---|---|
| Créer et gérer votre compte, authentifier, fournir le Service de rencontre (profil, découverte, matchs, messagerie, événements) | compte, profil, activité, échanges | Exécution du contrat (art. 6.1.b) |
| Mettre en relation selon votre pratique religieuse et vos préférences | pratique religieuse, genre recherché | Consentement explicite (art. 9.2.a) |
| Vérifier par selfie que vos photos sont les vôtres et empêcher les faux profils | empreinte du visage, résultats | Consentement explicite (art. 9.2.a), retirable |
| Vérifier votre identité et votre majorité, empêcher les doublons et le retour des membres exclus | résultat de lecture de puce, empreinte HMAC du document, date de naissance | Consentement explicite pour la vérification ; intérêt légitime (art. 6.1.f) pour la prévention de la fraude et la protection des membres ; obligation de protéger les mineurs. [À COMPLÉTER : base à confirmer par le conseil de l'éditeur pour la conservation de l'empreinte d'un membre exclu] |
| Géolocalisation dégradée pour la proximité | position floutée | Exécution du contrat ; consentement pour l'accès à la position de l'appareil |
| Modération, signalements, lutte contre le harcèlement et les abus, sécurité des systèmes | signalements, blocages, sanctions, journaux | Intérêt légitime (art. 6.1.f) ; obligation légale (LCEN, règlement (UE) 2022/2065) |
| Gérer les achats, abonnements et crédits, les remboursements et les révocations | données d'abonnement et de transactions | Exécution du contrat ; obligation légale |
| Notifications push d'usage | identifiant d'appareil, identifiant de membre | Exécution du contrat (notifications de service) ; consentement (autorisation système) |
| E-mails de service | adresse e-mail | Exécution du contrat |
| Informations et campagnes commerciales | adresse e-mail | Consentement ou intérêt légitime selon la règle applicable à la prospection électronique ; opposition à tout moment. [À COMPLÉTER : régime retenu par l'éditeur] |
| Améliorer le Service, statistiques agrégées | données d'usage agrégées | Intérêt légitime (art. 6.1.f). [À COMPLÉTER : confirmer l'absence d'outil de mesure d'audience] |
| Répondre aux demandes des autorités, exercer ou défendre des droits en justice | données utiles | Obligation légale ; intérêt légitime |

Nous ne vendons pas vos données et ne les utilisons pas pour de la publicité ciblée.

## 4. Durées de conservation

| Donnée | Durée |
|---|---|
| Compte, profil, photos, swipes, matchs, messages et médias, participations aux événements, contenus du mode couple | Jusqu'à la suppression du compte (article 10 de cette politique). La suppression est immédiate et définitive. |
| Photos de profil et fichiers de conversation (images, vocaux) sur nos serveurs | Effacés avec le compte, ou dès que vous retirez la photo ou le message |
| Messages supprimés par leur auteur (« retirer ») | Effacés à la demande de l'auteur |
| Aperçus de liens | 24 heures (cache) |
| Images et vidéo du selfie, fichiers de la puce du document, photo de la puce | **Non conservés** (traitement en mémoire) |
| Empreinte chiffrée du visage | Jusqu'au retrait du consentement ou à la suppression du compte |
| Résultat de la vérification d'identité (pays, type, expiration, date de naissance, empreinte HMAC du document) | Jusqu'à la suppression du compte |
| Empreinte HMAC d'un document d'un membre **définitivement banni** | Conservée après la suppression du compte, aux seules fins d'empêcher la réinscription. [À COMPLÉTER : durée maximale à fixer par l'éditeur ; le code actuel ne prévoit pas d'expiration, ce qui est à justifier ou à borner] |
| Documents transmis pour relecture manuelle | Supprimés dès la décision, et au plus tard après 30 jours sans décision |
| Position (floutée) | Jusqu'à la suppression du compte ; la position exacte n'est pas stockée |
| Historique des mises à jour de position (dates uniquement) | Jusqu'à la suppression du compte. [À COMPLÉTER : durée de purge à fixer] |
| Journal des sessions de vérification (résultat, date) | Jusqu'à la suppression du compte. [À COMPLÉTER : durée de purge à fixer] |
| Signalements que vous avez émis | Conservés après la suppression de votre compte sans lien avec vous (l'auteur est détaché), pour le traitement de la modération. Les signalements visant un membre supprimé sont effacés avec son compte. |
| Blocages, sanctions et notes de modération concernant le compte | Effacés avec le compte |
| Journal des actions de modération (action, date, numéro interne du compte, sans le contenu) | [À COMPLÉTER : durée à fixer, par exemple 1 an à 5 ans selon la finalité] |
| Abonnement, solde et historique de crédits tenus par MAZL | Effacés avec le compte. Les justificatifs de paiement et obligations comptables sont tenus par Apple (ou Google) ; l'éditeur conserve les pièces comptables exigées par la loi pendant 10 ans. [À COMPLÉTER : confirmer] |
| Adresse de la liste d'attente | Jusqu'à la suppression du compte correspondant ou à la désinscription ; l'adresse désinscrite est conservée dans la liste d'opposition |
| Raison de départ anonyme | Sans limite de durée (non personnelle) |
| Journaux techniques (adresse IP, erreurs) | [À COMPLÉTER : durée, 12 mois au plus recommandés pour les journaux de connexion exigés par la LCEN] |
| Données exigées par la loi ou une réquisition judiciaire | Le temps exigé par la loi |

Lorsque vous supprimez votre compte, les sauvegardes techniques de la base de données peuvent contenir vos données pendant une durée limitée, après quoi elles sont écrasées. [À COMPLÉTER : durée de rotation des sauvegardes]

## 5. Destinataires

Vos données sont accessibles :

- aux **autres membres**, dans la limite de ce que vous publiez sur votre profil (prénom, âge, photos, ville approximative, bio, pratique religieuse si renseignée, badges de vérification) ; pas de coordonnées ni d'adresse e-mail ;
- au **personnel habilité** de MAZL (modération, support, administration technique) dans la limite de ce qui est nécessaire ;
- à nos **sous-traitants** (article 6) ;
- aux **autorités** (judiciaires, administratives) sur réquisition ou obligation légale.

## 6. Sous-traitants et services tiers

| Prestataire | Rôle | Données concernées | Localisation / transfert |
|---|---|---|---|
| Hetzner Online GmbH (via la plateforme Coolify) | Hébergement des serveurs, de la base de données et des fichiers | Toutes les données du Service | Allemagne / UE. [À COMPLÉTER : confirmer le centre de données] |
| Resend | Envoi des e-mails de service et de campagnes | Adresse e-mail, nom, contenu du message | États-Unis : transfert encadré par [À COMPLÉTER : mécanisme, par exemple clauses contractuelles types et/ou Data Privacy Framework] |
| OneSignal | Notifications push | Identifiant d'appareil, identifiant de membre, contenu de la notification | États-Unis : transfert encadré par [À COMPLÉTER : mécanisme] |
| Google (Sign-In) | Authentification par compte Google ; polices Google Fonts du site | Identifiant, e-mail, nom, photo du compte ; adresse IP lors du chargement des polices | États-Unis / monde : [À COMPLÉTER : mécanisme de transfert] |
| Apple (Sign in with Apple, App Store, notifications du serveur App Store) | Authentification ; vente et facturation ; vérification des transactions | Identifiant Apple, adresse (éventuellement masquée), transactions | Apple, selon sa politique et ses mécanismes de transfert |
| Stripe Payments Europe, Ltd (groupe Stripe) | Encaissement des paiements par carte sur le site, gestion des abonnements web, émission des factures, portail de gestion | Identifiant client Stripe, adresse e-mail, historique des paiements et des factures, identifiant de l'abonnement ; le numéro de carte est saisi chez Stripe et n'est jamais transmis à MAZL. Stripe agit pour MAZL comme sous-traitant et, pour ses propres obligations (lutte contre la fraude et le blanchiment, réglementation financière), comme responsable de traitement | Irlande / UE, avec des transferts possibles vers les États-Unis : encadrés par [À COMPLÉTER : mécanisme, par exemple clauses contractuelles types et/ou Data Privacy Framework] |
| Institut national de l'information géographique et forestière (IGN) — Géoplateforme (data.geopf.fr) | Recherche de commune à la saisie de la ville | Texte saisi pour la recherche de commune, adresse IP | France |
| Sites web que vous partagez dans un message | Aperçu de lien | Notre serveur consulte l'adresse partagée (le site visité voit l'adresse IP du serveur, pas la vôtre) | Variable |

Les modèles de reconnaissance faciale et de lecture de puce s'exécutent sur nos propres serveurs : **aucune donnée biométrique, aucune image et aucune donnée de pièce d'identité n'est envoyée à un prestataire tiers de reconnaissance**. Les modèles utilisés (OpenCV Zoo) sont des logiciels libres exécutés en local.

Nous concluons avec nos sous-traitants les accords exigés par l'article 28 du RGPD. [À COMPLÉTER : liste à tenir à jour par l'éditeur ; confirmer la conclusion des accords de sous-traitance avec chacun]

## 7. Transferts hors de l'Union européenne

Certains prestataires (Resend, OneSignal, Google, Apple, Stripe) peuvent traiter des données aux États-Unis ou dans d'autres pays hors Union européenne. Ces transferts sont fondés sur une décision d'adéquation (cadre de protection des données UE-États-Unis, pour les entreprises certifiées) ou sur des clauses contractuelles types de la Commission européenne, complétées au besoin de mesures supplémentaires. [À COMPLÉTER : confirmer, prestataire par prestataire, la base retenue]. Vous pouvez en demander une copie à l'adresse indiquée à l'article 1.

## 8. Sécurité

Chiffrement des pièces d'identité transmises à la relecture manuelle et des empreintes faciales au repos (AES-256-GCM, avec liaison au contexte), empreinte HMAC des documents, URL de photos signées et de courte durée, limitation de débit contre l'aspiration des profils, traitement en mémoire des images de vérification, accès administrateur restreint et journalisé, communications chiffrées (HTTPS). Aucun système n'étant infaillible, nous vous informerons, ainsi que la CNIL le cas échéant, des violations de données dans les conditions des articles 33 et 34 du RGPD.

## 9. Données de mineurs

MAZL est interdit aux moins de 18 ans. Si nous apprenons qu'un compte est celui d'un mineur, nous le supprimons. Vous pouvez signaler un profil qui vous semble appartenir à un mineur (motif « personne mineure »).

## 10. Vos droits

Vous disposez des droits suivants : **accès** (copie de vos données), **rectification**, **effacement**, **limitation**, **opposition** (notamment à la prospection et aux traitements fondés sur l'intérêt légitime), **portabilité** des données que vous nous avez fournies, **retrait du consentement à tout moment** (sans effet sur la licéité des traitements passés), et droit de définir des **directives relatives au sort de vos données après votre décès**.

- **Supprimer votre compte** : directement dans l'Application (réglages du compte), ou par la route `DELETE /api/users/me` de l'API pour les clients autorisés. L'effacement est immédiat.
- **Retirer votre consentement à la reconnaissance faciale** : dans l'écran de vérification de l'Application (suppression de l'empreinte, retrait du badge).
- **Retirer votre consentement aux données de pratique religieuse** : dans les réglages du site (le retrait efface les informations concernées de votre profil), bientôt dans l'Application, en vidant les champs correspondants de votre profil, ou en nous écrivant.
- **Obtenir une copie de vos données (accès et portabilité)** : le bouton d'export des réglages du site (bientôt dans l'Application) produit un fichier JSON lisible par une machine : compte, profil, photos (informations seulement, sans les fichiers), réponses aux questions, préférences, likes et passes donnés, matchs, messages que vous avez envoyés, blocages et signalements émis, abonnement, crédits, couple, événements, consentements, sessions du site. Les messages reçus ne sont pas inclus : ils appartiennent à leurs auteurs. Aucun secret (mot de passe, jeton, empreinte) n'y figure. L'export est limité à trois par jour.
- **Autres demandes** : à [À COMPLÉTER : adresse e-mail dédiée aux demandes RGPD]. Nous pouvons vous demander de justifier de votre identité par un moyen proportionné. Nous répondons dans un délai d'un mois (prorogeable de deux mois pour les demandes complexes).
- **Réclamation** : vous pouvez saisir la CNIL (Commission nationale de l'informatique et des libertés, 3 place de Fontenoy, TSA 80715, 75334 Paris Cedex 07, www.cnil.fr) ou l'autorité de contrôle de votre pays de résidence, sans préjudice de tout recours juridictionnel.

## 11. Décisions automatisées

La vérification de votre visage et de votre document est réalisée par un traitement automatisé (comparaison faciale, vérification de signature). Un échec ne vous exclut pas automatiquement du Service. Vous pouvez demander l'intervention d'une personne, exprimer votre point de vue et contester la décision en écrivant à l'adresse de l'article 10. Les sanctions de modération sont décidées par des personnes.

## 12. Cookies et traceurs

**Site https://mazl.app.** Les pages du site vitrine, de la liste d'attente et des mentions légales **ne déposent pas de cookie et n'utilisent pas d'outil de mesure d'audience ni de publicité**. Le chargement des polices du site peut cependant solliciter Google Fonts (les polices sont servies par Google, qui reçoit alors votre adresse IP) ; les pages juridiques n'utilisent aucune police externe. La console d'administration (réservée à l'équipe) mémorise une session dans le stockage local du navigateur. L'espace membre du site (après connexion) ne contient **aucun pixel publicitaire, aucune mesure d'audience et aucun script tiers** ; seule la page de connexion charge le script du fournisseur de connexion que vous choisissez (Google, et Apple si activé), nécessaire à cette connexion. Si nous ajoutons un jour un traceur soumis à consentement, un bandeau vous permettra de l'accepter ou de le refuser avant tout dépôt. [À COMPLÉTER : confirmer l'absence de tout traceur sur le site à la date de publication]

**Application mobile.** Elle utilise le stockage sécurisé de l'appareil pour votre jeton de session et des préférences locales strictement nécessaires au fonctionnement. Elle demande les autorisations suivantes, que vous pouvez refuser ou retirer dans les réglages de votre téléphone : appareil photo (photos, selfie), photothèque, localisation, notifications, microphone (messages vocaux) et NFC (lecture de la puce du document). Elle n'intègre pas de publicité ni d'outil de mesure d'audience tiers. [À COMPLÉTER : confirmer avant publication, notamment pour la déclaration « confidentialité des données » de l'App Store]

## 13. Évaluation d'impact

Les traitements portant sur des données biométriques et sur des données révélant la religion, à grande échelle, sont susceptibles d'engendrer un risque élevé : l'éditeur doit conduire et tenir à jour une analyse d'impact relative à la protection des données (AIPD, article 35 du RGPD). [À COMPLÉTER : date de réalisation de l'AIPD, et, le cas échéant, consultation de la CNIL]

## 14. Modifications

Nous pouvons modifier cette politique. La date de version figure en tête du document. Les changements substantiels vous seront signalés dans l'Application ou par e-mail ; lorsque votre consentement est requis pour un nouveau traitement, il vous sera demandé de nouveau.

---

*Document en projet : il doit être relu et validé par un conseil juridique avant publication. Les mentions entre crochets doivent être complétées par l'éditeur (voir `docs/legal/A_COMPLETER.md`).*
