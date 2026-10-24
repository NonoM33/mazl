# ADR-W08 — Pile du front web

Date : 2026-10-24. Statut : accepté.

- React 19 + TSX, bundler Bun (`Bun.build` sur `web/index.html`), **sans Vite**.
- Pas de bibliothèque de routage ni de gestion d'état : un routeur `history` de 80 lignes et des
  hooks de données maison (`useResource`) suffisent et évitent des dépendances.
- Styles : CSS natif avec variables reprenant exactement les jetons Flutter
  (`mobile/lib/core/theme/*`) ; thème clair et sombre (`prefers-color-scheme`, réglable) ;
  `prefers-reduced-motion` respecté comme `MOUVEMENT.md` le demande.
- Polices Geist et Geist Mono servies par le site (fichiers OFL repris de `mobile/assets/fonts`).
- Icônes `lucide-react` (les mêmes que `lucide_icons_flutter`).
- QR codes : `uqr` (générateur SVG local, sans réseau). Calendrier juif : `kosher-zmanim`
  (port JavaScript de KosherJava, la même bibliothèque que `kosher_dart` sur mobile).
- Qualité : TypeScript strict (+ `noUnusedLocals`, `noUnusedParameters`), ESLint
  `typescript-eslint` strict + `react-hooks`, zéro avertissement ; tests unitaires `bun test`
  (logique pure) et e2e Playwright (Chromium déjà présent, `playwright@1.62.0`).
- Langue : français, **vouvoiement** (comme l'UI mobile actuelle et `CHAT.md`).
