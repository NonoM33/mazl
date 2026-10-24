# mazl+ dans App Store Connect

App id 6758543555, bundle `com.mazl.app`. Ces textes sont ceux saisis dans App Store
Connect ; l'app doit employer les mêmes noms. Limites Apple : nom 35 caractères,
description 55.

Langues localisées sur App Store Connect : français (France), anglais (États-Unis),
hébreu, espagnol (Espagne), russe.

## Groupe d'abonnements

Nom de référence et nom affiché : **mazl+** (identique dans toutes les langues).

Groupe 22508803. Prix de base : la France ; Israël et les autres pays suivent la
conversion d'Apple. Disponibles dans les 175 pays.

## Abonnements

| produit | id Apple | niveau | durée | prix FR / US / UK |
|---|---|---|---|---|
| `com.mazl.app.plus.12m` | 6826540839 | 1 | 1 an (payé d'avance) | 99,99 € / 119,99 $ / 89,99 £ |
| `com.mazl.app.plus.6m` | 6826539502 | 2 | 6 mois | 69,99 € / 79,99 $ / 64,99 £ |
| `com.mazl.app.plus.3m` | 6826538779 | 3 | 3 mois | 44,99 € / 49,99 $ / 39,99 £ (mis en avant) |
| `com.mazl.app.plus.1m` | 6826448080 | 4 | 1 mois | 19,99 € / 19,99 $ / 17,99 £ |

Niveaux : la plus longue durée en haut. Passer à une durée plus longue est une montée
de gamme, immédiate ; passer à une durée plus courte prend effet au renouvellement.

Offre de bienvenue sur `plus.1m` : paiement au fur et à mesure, premier mois à
9,99 € / 9,99 $ / 8,99 £, dans les 175 pays, du 2026-10-24 sans date de fin. Apple ne
l'accorde qu'aux nouveaux abonnés du groupe.

Non activé : la « facturation mensuelle avec engagement de 12 mois » que propose
Apple sur `plus.12m` (iOS 26.4+ et SDK 26.5+).

Noms affichés :

| langue | 1m | 3m | 6m | 12m |
|---|---|---|---|---|
| fr | mazl+ 1 mois | mazl+ 3 mois | mazl+ 6 mois | mazl+ 12 mois |
| en | mazl+ 1 month | mazl+ 3 months | mazl+ 6 months | mazl+ 12 months |
| he | mazl+ חודש אחד | mazl+ 3 חודשים | mazl+ 6 חודשים | mazl+ 12 חודשים |
| es | mazl+ 1 mes | mazl+ 3 meses | mazl+ 6 meses | mazl+ 12 meses |
| ru | mazl+ 1 месяц | mazl+ 3 месяца | mazl+ 6 месяцев | mazl+ 12 месяцев |

Description, la même pour les quatre durées :

| langue | description |
|---|---|
| fr | Likes illimités, voir qui vous a aimé, Boost quotidien |
| en | Unlimited likes, see who liked you, a daily Boost |
| he | לייקים ללא הגבלה, לראות מי אהב אותך, בוסט יומי |
| es | Likes ilimitados, ve a quién le gustas, Boost diario |
| ru | Безлимитные лайки, кто вас лайкнул, ежедневный буст |

## Achats à l'unité (consommables)

| produit | prix | fr | en |
|---|---|---|---|
| `com.mazl.app.boost.1` | 7,99 € | 1 Boost — En tête de pile pendant 30 minutes | 1 Boost — Top of the stack for 30 minutes |
| `com.mazl.app.boost.3` | 19,99 € | 3 Boosts — En tête de pile pendant 30 minutes | 3 Boosts — Top of the stack for 30 minutes |
| `com.mazl.app.superlikes.5` | 4,99 € | 5 Super Likes — Pour qu'on vous remarque d'abord | 5 Super Likes — Get noticed first |
| `com.mazl.app.superlikes.15` | 11,99 € | 15 Super Likes — Pour qu'on vous remarque d'abord | 15 Super Likes — Get noticed first |

Prix de base : la France ; tous les autres pays suivent la conversion d'Apple (par
exemple 6,99 $ pour `boost.1`). Disponibles dans les 175 pays. Les consommables sont
localisés en fr et en d'abord ; he, es et ru suivront la traduction de l'app.

## Sandbox Apple : `APPLE_ALLOW_SANDBOX`

Le serveur vérifie la signature Apple d'une transaction, pas l'argent réellement
encaissé. Une transaction signée `environment: "Sandbox"` est une vraie signature
d'Apple, obtenue sans payer (testeurs TestFlight, comptes Sandbox). Acceptée en
production, elle donnerait mazl+ ou des crédits gratuitement.

| valeur | effet |
|---|---|
| `true` (défaut, variable absente ou vide) | les transactions Sandbox sont acceptées, abonnements et consommables |
| `false` | toute transaction Sandbox est refusée (422 `invalid_transaction`, raison `sandbox_not_allowed` dans les journaux), pour les achats, les restaurations, les consommables et les notifications |
| autre valeur (`flase`...) | le serveur ne démarre pas : une faute de frappe ne doit pas laisser la porte ouverte |

Compromis : **l'équipe App Review achète en Sandbox contre le serveur de production**.
Avec `false`, la soumission est refusée (ses achats échouent). Donc :

1. Garder `true` (défaut) pendant la soumission et la revue d'une version qui ajoute
   ou modifie un produit.
2. Passer à `false` quand aucune revue n'est en cours, puis repasser à `true` avant
   la soumission suivante.
3. À terme, la sortie propre est de séparer l'environnement : le serveur de
   production refuse le Sandbox, un serveur dédié le reçoit, et l'URL des notifications
   « Sandbox » d'App Store Connect pointe vers lui.

Tant que la valeur reste `true`, la protection repose sur l'accès aux comptes
TestFlight : ne les ouvrir qu'à des testeurs de confiance (pas de lien public).

## Reste à faire avant la soumission

- Une capture d'écran de l'écran d'achat pour l'équipe de vérification, sur chaque
  produit.
- Soumettre les produits avec la prochaine version de l'app (Apple l'exige pour le
  premier abonnement et le premier consommable).
