import 'package:flutter/foundation.dart';

import 'demo_store.dart';
import 'dev_login.dart';

/// Session fictive : vit uniquement en mémoire, rien n'est persisté.
/// Tuer l'application y met fin.
abstract final class DevSession {
  static bool _active = false;
  static final _SessionChanges _changes = _SessionChanges();

  /// Toujours `false` quand [kDevLoginAvailable] est faux.
  static bool get isActive => kDevLoginAvailable && _active;

  /// Prévient quand la session commence ou prend fin, pour relire ce qui a
  /// été lu avant (la vitrine, lue au lancement, avant toute connexion).
  static Listenable get changes => _changes;

  static void start() {
    if (!kDevLoginAvailable) {
      throw StateError('La connexion fictive est réservée au mode debug.');
    }
    DemoStore.reset();
    _active = true;
    _changes.changed();
  }

  static void stop() {
    if (!_active) return;
    _active = false;
    _changes.changed();
  }
}

class _SessionChanges extends ChangeNotifier {
  void changed() => notifyListeners();
}
