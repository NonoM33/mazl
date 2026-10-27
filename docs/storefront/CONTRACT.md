# Vitrine : offres, prix et campagnes saisonnières — contrat commun

Décidé par Renaud le 2026-10-27 : « gérer les prix des abonnements, des offres… depuis le
back-office, et l'app se met à jour dynamiquement », plus des campagnes pour les fêtes
françaises, juives et internationales (Saint-Valentin, Noël…), chacune avec son icône
d'app et son gabarit minimaliste, programmées à l'avance, « sans MAJ ».

Ce fichier est le contrat entre le serveur (`src/features/storefront/`), le back-office
(`console/src/storefront/`) et l'app (`mobile/lib/.../storefront/`). Une modification du
contrat passe par l'orchestrateur.

## 1. Ce qu'Apple permet (et ce qu'il interdit)

- **Le prix affiché sur iPhone vient TOUJOURS de StoreKit** (localisé par pays). Le serveur
  ne transmet jamais un prix à afficher pour iOS : il dit QUOI montrer, dans quel ordre, avec
  quelle mise en avant et quelle campagne.
- **Prix de base d'un abonnement** : modifiable par l'API App Store Connect (prix de la France,
  puis chaque pays par les « equalizations » d'Apple). Une hausse s'applique aux abonnés
  existants seulement s'ils l'acceptent : `preserveCurrentPrice: true` par défaut (les abonnés
  gardent leur prix). Une baisse s'applique à tous au renouvellement. Délai : Apple applique
  à la date demandée (au plus tôt aujourd'hui), propagation de quelques heures.
- **Réduction de campagne sur un abonnement = code d'offre Apple** (`subscriptionOfferCodes`
  + un code personnalisé, ex. `VALENTIN27`), jamais une baisse du prix de base. Éligibilité :
  nouveaux, anciens et actuels abonnés. L'app l'ouvre par
  `https://apps.apple.com/redeem?ctx=offercodes&id=6758543555&code=<CODE>` (code pré-rempli).
- **Consommables** : prix temporaire par le calendrier de prix d'Apple (`inAppPurchasePriceSchedules`,
  `startDate`/`endDate`). Les 4 consommables sont encore `MISSING_METADATA` chez Apple : prévu
  par l'API, sans effet tant qu'ils ne sont pas validés.
- **Web (Stripe)** : un prix Stripe est immuable → nouveau prix créé, son id rangé dans le
  catalogue (il remplace la variable `STRIPE_PRICE_*`). Réduction de campagne = coupon
  (`percent_off`, `redeem_by` = fin) + code promo, appliqué d'office au paiement pendant la
  campagne.
- **Icône de l'app** : seules les icônes PRÉSENTES dans le bundle peuvent être posées
  (`setAlternateIconName`). Toutes les icônes de `themes.json` partent dans la prochaine
  build ; ensuite le serveur choisit laquelle, sans mise à jour. iOS affiche une alerte
  système « Vous avez modifié l'icône » à chaque changement (imposé par Apple), et le
  changement n'a lieu que quand l'app est au premier plan (ouverture ou retour).

## 2. Thèmes (`docs/storefront/themes.json`)

Un thème = un événement, une icône d'app, un glyphe, une couleur d'accent, une règle de date.
Ids figés : `valentine, tu_bav, rosh_hashana, hanukkah, christmas, new_year, purim,
passover, mothers_day, summer, black_friday`. Le thème `default` n'existe pas : pas de
campagne = icône et vitrine normales.

- Glyphes : `heart, two_hearts, pomegranate, flame, fir, sparkle, mask, matzah, flower, sun,
  bolt`, dessinés UNE fois en SVG (viewBox `0 0 24 24`, traits 1.75, `currentColor`) dans
  `mobile/assets/storefront/glyphs/<glyph>.svg`, copiés tels quels dans
  `console/src/storefront/glyphs/` par `mobile/tool/app_icon/make_app_icon.py`.
- Icônes iOS : jeux `AppIcon-<themeId>` dans `Runner/Assets.xcassets` (clair, sombre,
  teinté), le point tekhelet du logo remplacé par le glyphe dans la couleur d'accent ; nom
  passé à `setAlternateIconName` : `AppIcon-<themeId>`.
- Règles de date (`rule.type`) : `fixed` (jour/mois), `hebrew` (jour d'un mois hébreu, calculé
  avec `kosher-zmanim`, `adar` = Adar II les années embolismiques), `fr_mothers_day`
  (dernier dimanche de mai, ou premier dimanche de juin si c'est la Pentecôte),
  `black_friday` (4e vendredi de novembre). `days` = durée de la fête (défaut 1).
  `window` = [jours avant le premier jour, jours après le dernier jour]. Fête juive : la
  fenêtre commence la veille au soir, donc un jour de plus avant.

## 3. Données (Postgres, `src/features/storefront/infra/schema.ts`)

- `storefront_products` : `product_id` (pk, ids de `billing-web/domain/offers.ts`),
  `visible` bool, `sort_order` int, `featured` bool, `highlight` jsonb (`{fr,en,he,es,ru}`
  ou null), `stripe_price_id` text null (null = variable d'environnement), `updated_at`,
  `updated_by`.
- `storefront_campaigns` : `id` serial, `theme_id`, `name` (interne), `starts_at`,
  `ends_at` (timestamptz), `texts` jsonb `{title,subtitle,cta}` × 5 langues, `targets`
  jsonb `[{productId, discountPercent (5..90)}]`, `change_app_icon` bool (défaut true),
  `status` `draft | scheduled | cancelled`, `apple` jsonb (ids des codes d'offre créés,
  code personnalisé, erreur éventuelle), `stripe` jsonb (coupon, code promo), `created_by`,
  `created_at`, `updated_at`. État affiché calculé : `draft`, `scheduled` (avant
  `starts_at`), `live`, `ended`, `cancelled`.
- `storefront_price_changes` : journal de chaque écriture de prix (qui, produit, plateforme,
  pays, ancien, nouveau, date d'effet, résultat). Toute écriture passe aussi par l'audit
  staff existant (`src/features/audit`).

Règles : deux campagnes `scheduled` ne se chevauchent jamais (409 `campaign_overlap`) ;
`ends_at > starts_at`, durée ≤ 45 jours ; une campagne `live` ne se modifie que pour la
terminer plus tôt ou l'annuler.

## 4. API publique : `GET /api/storefront` (sans authentification, cache 60 s)

```json
{ "success": true, "data": {
  "serverTime": "2027-02-10T09:00:00Z",
  "products": [ { "productId": "com.mazl.app.plus.3m", "visible": true, "sortOrder": 0,
                  "featured": true, "highlight": "Le plus choisi" } ],
  "campaign": null | { "id": 12, "themeId": "valentine", "accent": "#E5484D", "glyph": "heart",
     "startsAt": "...", "endsAt": "...", "title": "...", "subtitle": "...", "cta": "...",
     "targets": [ { "productId": "com.mazl.app.plus.3m", "discountPercent": 30,
                    "iosOfferCode": "VALENTIN27", "webPromotion": true } ] },
  "appIcon": null | "AppIcon-valentine",
  "nextChangeAt": "2027-02-15T00:00:00+01:00" | null
} }
```
Textes et `highlight` dans la langue de `Accept-Language` (fr par défaut, repli fr).
`appIcon` est null hors campagne ou si `change_app_icon` est faux. `iosOfferCode` n'est
présent que si le code a bien été créé chez Apple.

## 5. API du back-office (`/api/admin/storefront/...`, session staff, cf. matching-admin)

| route | rôle | effet |
|---|---|---|
| `GET products` | admin | catalogue + prix réels : Apple (France + 4 pays témoins US, GB, IL, CA) et Stripe |
| `PATCH products/:productId` | admin | visible, ordre, mise en avant, texte |
| `GET products/:productId/apple-price-points?territory=FRA` | admin | paliers Apple disponibles |
| `POST products/:productId/apple-price` | super-admin | `{pricePointId, startDate, preserveCurrentPrice}` ; `dryRun` d'abord (renvoie ce qui changera pays par pays) |
| `POST products/:productId/web-price` | super-admin | `{amountCents, currency}` → nouveau prix Stripe, rangé dans le catalogue |
| `GET campaigns?year=` / `POST campaigns` / `PATCH campaigns/:id` | admin | CRUD |
| `GET campaigns/presets?year=` | admin | une proposition par thème avec ses dates calculées, conflits signalés |
| `POST campaigns/:id/publish` | super-admin | crée codes d'offre Apple + coupon Stripe, passe `scheduled` ; échec Apple = reste `draft` avec l'erreur |
| `POST campaigns/:id/cancel` | super-admin | désactive codes Apple et code promo Stripe |

Chaque route : OpenAPI complet (§10bis du CLAUDE.md global : exemples synthétiques, erreurs
réelles), validation zod, isolation par rôle testée.

## 6. Ports vers Apple et Stripe (`src/features/storefront/application/ports.ts`)

Le domaine ne connaît que ces interfaces ; les adaptateurs vivent dans
`infra/app-store-connect/` et `infra/stripe/` ; les tests utilisent des faux.

## 7. App (Flutter)

- Lit `/api/storefront` au démarrage, au retour au premier plan et à `nextChangeAt` ;
  garde la dernière réponse (repli : catalogue par défaut actuel, aucune campagne).
- Écran mazl+ : ordre, mise en avant et textes du serveur ; prix StoreKit inchangés ;
  campagne = gabarit du thème (glyphe, accent, titre, sous-titre, fin « jusqu'au 14 février »,
  badge « −30 % » sur les produits ciblés, bouton qui ouvre le code d'offre). Bandeau discret
  de la campagne sur la carte « Passer à mazl+ » des réglages. 100 % Duo (7 poses, deux pages
  en livre), clair et sombre, 5 langues.
- Icône : si `appIcon` ≠ icône actuelle et que le réglage « Icône des fêtes » (activé par
  défaut) le permet, `setAlternateIconName(appIcon)` (null = icône normale), par un canal
  natif `mazl/app_icon`. Jamais plus d'un changement par ouverture.
