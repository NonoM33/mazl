# ADR-W05 — Règles de l'App Store et paiement web

Date : 2026-10-24. Statut : accepté. Source : App Store Review Guidelines, §3.1.1, 3.1.1(a),
3.1.2, 3.1.3 et 3.1.3(b), lues le 2026-10-24 sur developer.apple.com/app-store/review/guidelines/.

## Ce que disent les règles
- 3.1.1 : débloquer une fonction (abonnement, crédits) dans l'app passe par l'achat intégré.
- 3.1.3(b) « Multiplatform Services » : l'app **peut** donner accès à un abonnement ou à des
  consommables achetés sur le site, **à condition** qu'ils soient aussi vendus en achat intégré
  dans l'app. C'est le cas de mazl+ et des quatre packs.
- 3.1.1(a) et préambule de 3.1.3 : hors vitrine des États-Unis, l'app et ses métadonnées
  **ne doivent contenir ni bouton, ni lien, ni incitation** vers un autre moyen d'achat, sauf
  droit « StoreKit External Purchase Link » accordé par Apple pour certaines vitrines (UE au
  titre du DMA, avec commission et écran d'avertissement imposés).
- 3.1.2 : un abonnement doit fonctionner sur tous les appareils du membre où l'app existe.
- Communiquer hors de l'app (e-mail, site) sur les autres moyens d'achat est permis.

## Décision
- L'app iOS **n'affiche aucun lien ni aucune mention incitant à payer sur le web**, sur toutes
  les vitrines (MAZL vise la France et Israël d'abord) ; pas de demande du droit External
  Purchase Link pour l'instant.
- L'app **reconnaît** un mazl+ ou des crédits achetés sur le web (même ligne `subscriptions`,
  mêmes soldes) : c'est permis par 3.1.3(b).
- Un abonnement Stripe se gère **sur le web** ; l'app peut écrire, sans lien ni bouton,
  « Abonnement géré sur le site MAZL » (à faire valider par la revue Apple, décision de
  Renaud ; non codé dans ce chantier).
- Le site peut parler de l'app et de ses achats ; le QR code « ouvrir l'app » ne mène pas à un
  achat.
