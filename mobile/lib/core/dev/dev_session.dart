import 'demo_store.dart';
import 'dev_login.dart';

/// Session fictive : vit uniquement en mémoire, rien n'est persisté.
/// Tuer l'application y met fin.
abstract final class DevSession {
  static bool _active = false;

  /// Toujours `false` quand [kDevLoginAvailable] est faux.
  static bool get isActive => kDevLoginAvailable && _active;

  static void start() {
    if (!kDevLoginAvailable) {
      throw StateError('La connexion fictive est réservée au mode debug.');
    }
    DemoStore.reset();
    _active = true;
  }

  static void stop() {
    _active = false;
  }
}
