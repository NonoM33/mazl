import 'package:shared_preferences/shared_preferences.dart';

/// Se souvient que le tutoriel de l'iPhone Duo a déjà été montré.
abstract interface class DuoTutorialStore {
  Future<bool> hasBeenSeen();
  Future<void> markSeen();
}

class SharedPreferencesDuoTutorialStore implements DuoTutorialStore {
  static const _key = 'duo_tutorial_seen';

  @override
  Future<bool> hasBeenSeen() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  @override
  Future<void> markSeen() async =>
      (await SharedPreferences.getInstance()).setBool(_key, true);
}
