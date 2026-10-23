# mazl

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Connexion fictive (dev)

Pour parcourir tous les écrans dans le simulateur sans compte ni serveur : sur
l'écran de connexion, le bouton discret « Connexion fictive (dev) » ouvre une
session de démonstration (« Léa (démo) ») et envoie sur la découverte.

- **Builds debug uniquement.** Tout est gardé par `kDevLoginAvailable`
  (`lib/core/dev/dev_login.dart`), égal à `kDebugMode`, constante de
  compilation fausse en profile et en release : le bouton et le code de démo
  n'existent pas dans les builds TestFlight / App Store.
- **Ne joint jamais le serveur.** Pendant la session, `DemoHttpClient` répond
  depuis des données synthétiques (`lib/core/dev/demo_fixtures.dart`) ; une
  route inconnue renvoie un 503 « Mode démo : indisponible ».
- **Rien n'est persisté** (ni stockage sécurisé, ni préférences), pas de JWT,
  pas de RevenueCat, pas de notifications push. Se déconnecter ou tuer
  l'application met fin à la session.
- Pour ajouter une route de démo : `lib/core/dev/demo_routes.dart`, puis la
  vérifier dans `test/core/dev/demo_api_shapes_test.dart` avec le vrai
  `ApiService`.
