import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/l10n/app_language.dart';
import 'package:mazl/core/l10n/app_language_controller.dart';

class _MemoryStore implements LanguagePreferenceStore {
  _MemoryStore([this.saved]);
  String? saved;
  int writes = 0;

  @override
  Future<String?> read() async => saved;

  @override
  Future<void> write(String? code) async {
    writes++;
    saved = code;
  }
}

void main() {
  ProviderContainer containerWith(_MemoryStore store, {AppLanguage? saved}) {
    final container = ProviderContainer(
      overrides: [
        languagePreferenceStoreProvider.overrideWithValue(store),
        savedLanguageProvider.overrideWithValue(saved),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('par défaut, aucun choix : la langue du téléphone s\'applique', () {
    final container = containerWith(_MemoryStore());
    expect(container.read(appLanguageProvider), isNull);
  });

  test('la langue lue au démarrage est appliquée dès la première image', () {
    final container = containerWith(_MemoryStore('he'), saved: AppLanguage.he);
    expect(container.read(appLanguageProvider), AppLanguage.he);
  });

  test('choisir une langue l\'applique et la retient', () async {
    final store = _MemoryStore();
    final container = containerWith(store);

    await container.read(appLanguageProvider.notifier).choose(AppLanguage.en);

    expect(container.read(appLanguageProvider), AppLanguage.en);
    expect(store.saved, 'en');
  });

  test('revenir à « langue du téléphone » efface le choix retenu', () async {
    final store = _MemoryStore('he');
    final container = containerWith(store, saved: AppLanguage.he);

    await container.read(appLanguageProvider.notifier).choose(null);

    expect(container.read(appLanguageProvider), isNull);
    expect(store.saved, isNull);
  });

  test(
    'loadSavedLanguage relit le code retenu, ignore un code inconnu',
    () async {
      expect(await loadSavedLanguage(_MemoryStore('he')), AppLanguage.he);
      expect(await loadSavedLanguage(_MemoryStore('xx')), isNull);
      expect(await loadSavedLanguage(_MemoryStore()), isNull);
    },
  );
}
