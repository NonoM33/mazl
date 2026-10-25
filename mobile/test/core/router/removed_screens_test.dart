import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/router/app_router.dart';

// Décision de Renaud du 2026-10-25 : les façades qui ne font rien (ou qui
// appellent des routes serveur inexistantes) quittent l'app. Aucun chemin du
// routeur ne doit plus y mener.
void main() {
  // Une seule fois pour tout le fichier, sans la fermer : le conteneur
  // fermerait aussi le AuthService unique de l'app.
  late final GoRouter router;

  setUpAll(() => router = ProviderContainer().read(appRouterProvider));

  bool exists(String path) =>
      !router.configuration.findMatch(Uri.parse(path)).isError;

  group('les chemins des écrans retirés ne mènent plus nulle part', () {
    const removed = {
      '/chat/3/video-call': 'appel vidéo factice',
      '/success-stories': 'succès de couples (3 routes serveur inexistantes)',
      '/visitors': 'visiteurs (route serveur inexistante)',
      '/profile/ai-shadchan': 'AI Shadchan (route serveur inexistante)',
    };
    for (final entry in removed.entries) {
      test('${entry.key} : ${entry.value}', () {
        expect(exists(entry.key), isFalse);
      });
    }
  });

  group('témoins : les écrans qui restent sont toujours là', () {
    for (final path in [
      '/discover',
      '/matches',
      '/chat',
      '/chat/3',
      '/events',
      '/likes',
      '/premium',
      '/profile/settings/shabbat',
    ]) {
      test(path, () => expect(exists(path), isTrue));
    }
  });
}
