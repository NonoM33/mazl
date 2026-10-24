# ADR-W04 — Paiement web Stripe et réconciliation du droit mazl+

Date : 2026-10-24. Statut : accepté. Mode TEST uniquement dans ce chantier.

## Décision
- **Stripe Checkout** hébergé (aucun script Stripe dans le site, aucune donnée de carte chez
  MAZL) : abonnement mazl+ 1, 3, 6, 12 mois (`mode: subscription`) et packs de crédits
  (`mode: payment`, Boost 1 et 3, Super Likes 5 et 15). **Customer Portal** pour changer de
  formule, mettre à jour le moyen de paiement, télécharger les factures et résilier.
- **Prix TTC** : les `Price` Stripe sont créés avec `tax_behavior: inclusive` ; le site lit le
  montant chez Stripe (cache 10 min) et l'affiche TTC, jamais un prix codé en dur.
- **Renoncement au droit de rétractation (L221-28 13°)** : case obligatoire, non pré-cochée ;
  sans elle, `400 withdrawal_waiver_required`. La preuve (membre, offre, version et empreinte
  SHA-256 du texte, horodatage serveur, identifiant de la session Checkout) est stockée dans
  `billing_withdrawal_waivers`, conservée en cas de suppression du compte (`user_id` mis à
  NULL) pour la durée de prescription : base légale = preuve d'une obligation légale.
- **Factures** : émises par Stripe (abonnements : natif ; paiements : `invoice_creation`).
- **Webhook** `POST /api/billing/stripe/webhook` : signature vérifiée avec la fonction
  officielle `stripe.webhooks.constructEventAsync` sur le corps brut ; idempotence par la table
  `stripe_events` (identifiant d'événement) ; état relu chez Stripe (`subscriptions.retrieve`)
  avant toute projection, ce qui rend l'ordre d'arrivée sans importance. Événements traités :
  `checkout.session.completed`, `checkout.session.async_payment_succeeded`,
  `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_failed`,
  `charge.refunded`.
- **Un seul droit mazl+ par membre**, quelle que soit la source : la ligne unique
  `subscriptions` (lue par `PgPlusStatus`) reste la projection du droit. Stripe y écrit avec
  `store = 'stripe'` et `original_transaction_id = sub_…`. L'état complet Stripe vit dans
  `stripe_subscriptions`.
  - Checkout d'abonnement refusé (`409 already_subscribed`, `source: apple|stripe`) si un
    droit actif existe déjà.
  - Une projection Stripe n'écrase jamais une ligne Apple active et plus longue.
  - Deux onglets (relecture de sécurité M2) : un nouveau Checkout d'abonnement fait d'abord
    expirer les Checkout d'abonnement encore ouverts du client, et les créations d'un même
    membre sont sérialisées. Si un second abonnement est payé quand même (Stripe plus récent
    qu'un autre Stripe vivant, ou Stripe nouveau alors qu'un mazl+ App Store est vivant), le
    webhook l'annule et rembourse sa dernière facture ; le plus ancien est gardé quel que soit
    l'ordre des événements.
  - Si l'App Store active un abonnement alors qu'un abonnement Stripe est actif (achat fait sur
    l'iPhone après le web), la ligne passe à Apple ; `GET /api/billing/status` signale
    `conflict: "double_subscription"` et le site explique comment résilier l'un des deux
    (Stripe : portail ; Apple : Réglages de l'iPhone). Quand l'un expire, l'autre est
    reprojeté (`GET /api/billing/status` et chaque événement Stripe relancent la projection).
- **Crédits** : `checkout.session.completed` payé → `CreditsRepository.recordPurchase` avec
  l'identifiant du PaymentIntent (`pi_…`), donc la même idempotence, le même verrou et la même
  table de révocations que les achats Apple : pas de double crédit, pas de double dépense.
  `charge.refunded` → `refundPurchase` (le solde peut devenir négatif, comme pour Apple).
- **Suppression du compte** : l'abonnement Stripe est résilié immédiatement (`subscriptions.cancel`)
  avant l'effacement ; le client Stripe est conservé chez Stripe pour les factures (obligation
  comptable de 10 ans), détaché de MAZL.

## Variables
`STRIPE_SECRET_KEY` (`sk_test_…` ; une clé `sk_live_…` fait échouer le démarrage tant que
`STRIPE_ALLOW_LIVE` n'est pas `true`), `STRIPE_WEBHOOK_SECRET` (`whsec_…`),
`STRIPE_PRICE_PLUS_1M`, `STRIPE_PRICE_PLUS_3M`, `STRIPE_PRICE_PLUS_6M`, `STRIPE_PRICE_PLUS_12M`,
`STRIPE_PRICE_BOOST_1`, `STRIPE_PRICE_BOOST_3`, `STRIPE_PRICE_SUPERLIKES_5`,
`STRIPE_PRICE_SUPERLIKES_15`, `STRIPE_PORTAL_CONFIGURATION` (facultatif). Sans
`STRIPE_SECRET_KEY`, les routes de paiement répondent `503 billing_unavailable` et le site
le dit.
