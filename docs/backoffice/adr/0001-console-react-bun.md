# ADR 0001 — Console staff en React, bundlée par Bun, servie par Hono

- Statut : accepté — 2026-10-24
- Contexte : `public/admin.html` (80 Ko de HTML et JS inline, sans test, hors charte) ne peut pas porter
  les nouveaux écrans (file priorisée, panneaux de détail, curseurs avec aperçu en direct, comparaison A/B).

## Options examinées

1. **Continuer en HTML/JS inline** dans `public/` : zéro dépendance, mais pas de typage, pas de composants,
   l'état d'un écran comme le réglage de l'algorithme devient vite ingérable ; c'est l'état actuel.
2. **SPA Vite + React** : écarté, le `CLAUDE.md` du dépôt interdit Vite.
3. **React + TSX bundlé par Bun** (HTML import, autorisé et recommandé par le `CLAUDE.md` du dépôt).
4. **Flutter Web** (réutiliser le thème de l'app) : bundle lourd, rendu canvas peu accessible, mauvais outil
   pour des tableaux denses sur ordinateur.

## Décision

Option 3. Le point d'entrée `console/index.html` importe `console/src/main.tsx` ; au démarrage, le serveur
appelle `Bun.build` sur ce HTML et garde le résultat **en mémoire** ; Hono sert `/console` et ses fichiers
hachés, avec les en-têtes de sécurité existants (CSP `script-src 'self'`, `frame-ancestors 'none'`).
En développement, le bundle est reconstruit à chaque chargement de page.

Pourquoi pas `Bun.serve({ routes: { "/console": html } })` directement : ces routes contournent Hono, donc
la CSP et les en-têtes de sécurité, et le serveur actuel passe tout par `app.fetch`. Construire au
démarrage garde un seul chemin de requête, sans étape de build dans le Dockerfile.

- Pas de framework CSS : un fichier de jetons (`tokens.css`) qui reprend la charte « Encre & Tekhelet »
  (`mobile/lib/core/theme/app_colors.dart`, `app_typography.dart`) : encre `#0B0B0F`, papier, un seul
  accent tekhelet `#2747F5`, Geist / Geist Mono **auto-hébergées** (aucune requête vers Google Fonts : pas
  de fuite d'adresse IP du staff, RGPD).
- Pas de routeur ni de gestionnaire d'état externes : `react`, `react-dom` seulement ; navigation par le
  hash, état local et un petit client d'API typé par les DTO du serveur (`src/features/*/presentation/dto.ts`,
  imports de types uniquement).
- Jeton de session en `sessionStorage` (fermé avec l'onglet), envoyé en `Authorization: Bearer`.
- Accessibilité : contrastes de la charte (≥ 4,5:1), navigation clavier, `aria-*` sur les panneaux,
  respect de `prefers-reduced-motion`, thème sombre via `prefers-color-scheme`.

## Conséquences

- Deux dépendances d'exécution (`react`, `react-dom`) et leurs types en développement.
- Un `tsconfig` dédié à la console (bibliothèque DOM) ; `bun run typecheck` vérifie les deux.
- L'ancienne console reste servie le temps de migrer événements, campagnes et abonnements.
