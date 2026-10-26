# Console staff MAZL

React + TSX bundlé par Bun (ADR `docs/backoffice/adr/0001-console-react-bun.md`). Aucune requête externe : polices Geist auto-hébergées (`console/fonts/`).

- Maquette sans backend : `bun run console:mock` puis http://localhost:3470/console (comptes `admin@example.com`, `moderation@example.com`, `support@example.com`, `analyste@example.com` (Algorithme en lecture seule), `nouveau@example.com` — mot de passe `demo`, code à 6 chiffres quelconque sauf `000000`).
- Captures : `bun run console:mock` dans un terminal, `bun run console:screenshots` dans un autre → `docs/backoffice/captures/maquette-*.png`.
- Typage : `bun run typecheck` (racine puis `console/tsconfig.json`). Tests : `bun test tests/unit`.
- Connexion Google : Google Identity Services n'est pas chargé dans ce lot. Le bouton « Continuer avec Google » ouvre un champ où coller un ID token (POST `/auth/google`). L'emplacement du futur bouton officiel est `#google-signin-slot` (`console/src/auth/LoginScreen.tsx`).
- Écran « Algorithme » (`console/src/matching/`) : Comprendre / Régler / Historique, sur `/api/backoffice/matching`. La maquette (`console/dev/mock-matching.ts`) valide les réglages et calcule les classements avec le vrai moteur sur la population fictive du serveur ; l'état (versions, test A/B) est en mémoire.
