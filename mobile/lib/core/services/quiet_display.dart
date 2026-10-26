import 'package:flutter/foundation.dart';

/// Whether the Shabbat display is on. While it is, nothing the app does may
/// light, sound or move the phone: the push provider shows no banner, the
/// couple flow keeps its dialogs and its redirects for later.
///
/// The system itself is out of reach of the app: a notification of another
/// app, a call, an alarm. Focus ("Do Not Disturb") is the member's to set.
class QuietDisplay {
  QuietDisplay();

  /// The one the app shares.
  static final QuietDisplay instance = QuietDisplay();

  final ValueNotifier<bool> _on = ValueNotifier<bool>(false);

  ValueListenable<bool> get listenable => _on;

  bool get isOn => _on.value;

  void enter() => _on.value = true;

  void leave() => _on.value = false;
}
