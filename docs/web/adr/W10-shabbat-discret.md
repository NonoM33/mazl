# ADR-W10 — Pause Shabbat et fêtes ; mode discret

Date : 2026-10-24. Statut : accepté.

## Pause Shabbat
- Même calcul que le mobile (`jewish_calendar_service.dart`) : `kosher-zmanim`, diaspora,
  allumage 18 min avant le coucher du soleil, sortie à la tombée de la nuit (8,5°), fêtes de
  Yom Tov incluses si l'option est cochée, marge réglable 0 à 30 min par pas de 5.
- Position : la dernière position enregistrée par le mobile (profil, floutée à ~1 km, ce qui
  suffit aux zmanim), sinon Paris comme le mobile.
- Effet sur le web, activé par défaut, réglage gardé dans le navigateur (préférence de confort,
  sans envoi au serveur) : pendant Shabbat ou Yom Tov, un écran « Chabbat Chalom » remplace
  l'espace connecté, indique l'heure de sortie, n'émet aucun son ni titre clignotant ; le membre
  peut continuer s'il le choisit. Aucun statut n'est poussé au serveur (le mobile ne le fait pas
  non plus).

## Mode discret
- **Échap deux fois** (en moins de 400 ms) ou le bouton de la barre latérale : écran neutre
  (« Notes », feuille vide), titre d'onglet « Notes » et favicon neutre ; toutes les images
  sont retirées du DOM, la socket reste ouverte mais rien ne s'affiche. Retour : même raccourci
  ou bouton « Reprendre ».
- Ce n'est pas une protection contre les captures d'écran (impossibles à empêcher sur le web),
  seulement contre un regard par-dessus l'épaule. Le site le dit.
