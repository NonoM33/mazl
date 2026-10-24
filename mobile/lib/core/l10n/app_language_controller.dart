import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';

/// Où le choix de langue des réglages est retenu entre deux lancements.
abstract interface class LanguagePreferenceStore {
  Future<String?> read();

  /// `null` efface le choix : la langue du téléphone reprend la main.
  Future<void> write(String? code);
}

class SharedPreferencesLanguageStore implements LanguagePreferenceStore {
  static const _key = 'app_language';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> write(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, code);
    }
  }
}

/// La langue retenue, lue avant `runApp` pour que la première image soit
/// déjà dans la bonne langue.
Future<AppLanguage?> loadSavedLanguage(LanguagePreferenceStore store) async =>
    AppLanguage.fromCode(await store.read());

/// Le choix fait dans les réglages ; `null` = suivre le téléphone.
class AppLanguageController extends StateNotifier<AppLanguage?> {
  AppLanguageController(this._store, {AppLanguage? initial}) : super(initial);

  final LanguagePreferenceStore _store;

  Future<void> choose(AppLanguage? language) async {
    state = language;
    await _store.write(language?.code);
  }
}

final languagePreferenceStoreProvider = Provider<LanguagePreferenceStore>(
  (ref) => SharedPreferencesLanguageStore(),
);

/// Remplacé dans `main` par la valeur de [loadSavedLanguage].
final savedLanguageProvider = Provider<AppLanguage?>((ref) => null);

final appLanguageProvider =
    StateNotifierProvider<AppLanguageController, AppLanguage?>(
      (ref) => AppLanguageController(
        ref.watch(languagePreferenceStoreProvider),
        initial: ref.watch(savedLanguageProvider),
      ),
    );
