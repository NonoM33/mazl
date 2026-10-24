# ADR-W03 — Connexion : QR code depuis l'app, Google, Apple ; comptes existants seulement ; anti-bot sans tiers

Date : 2026-10-24. Statut : accepté.

## Décision
1. **QR code (méthode principale, façon WhatsApp Web).**
   - Le navigateur demande un appairage : il reçoit `pairing_id`, un `code` (affiché en QR,
     `mazl-web:<code>`, compris par le seul lecteur de l'app) et un `browser_secret` qui ne
     quitte jamais le navigateur. Durée : 120 s, usage unique.
   - L'app (membre connecté, JWT mobile) envoie le code (`/api/web/pairings/scan`), voit le
     navigateur et son système, puis **approuve ou refuse**. Le refus et l'expiration sont
     visibles du navigateur, qui interroge toutes les 2 s avec son `browser_secret`.
   - Contre le relais de QR (hameçonnage) : l'app montre « Chrome sur macOS, demandé à 14:02 »
     et demande une confirmation explicite ; une session web ne peut pas approuver.
2. **Google** (Google Identity Services) et **Apple** (Sign in with Apple JS, si
   `APPLE_WEB_SERVICES_ID` est configuré) avec vérification serveur du jeton, comme le mobile.
3. **Comptes existants uniquement.** Le web n'ouvre pas de compte : l'inscription suppose le
   parcours mobile (profil, consentements, vérification selfie). Un compte inconnu reçoit
   `404 account_not_found` et le site affiche un QR vers l'App Store.
4. **Anti-bot sans service tiers** : preuve de travail SHA-256 (défi signé HMAC, 2 min, usage
   unique, difficulté 18 bits ≈ 0,3 à 1 s dans un navigateur) exigée pour ouvrir un appairage
   et pour la connexion Google ou Apple, plus des limites par adresse IP (30 / 15 min, comme
   le mobile). Pas de reCAPTCHA ni de Turnstile : aucun traceur, aucun transfert hors UE.
