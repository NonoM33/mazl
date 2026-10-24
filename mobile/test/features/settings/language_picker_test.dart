import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/l10n/app_language_controller.dart';
import 'package:mazl/presentation/features/settings/widgets/language_picker_sheet.dart';

import '../../helpers/l10n_helpers.dart';

class _MemoryStore implements LanguagePreferenceStore {
  String? saved;

  @override
  Future<String?> read() async => saved;

  @override
  Future<void> write(String? code) async => saved = code;
}

/// The real app wiring: MaterialApp's locale follows appLanguageProvider.
class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: language?.locale ?? kTestLocale,
      home: const Scaffold(body: LanguagePickerSheet()),
    );
  }
}

void main() {
  late _MemoryStore store;

  Future<void> pump(WidgetTester tester) async {
    store = _MemoryStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [languagePreferenceStoreProvider.overrideWithValue(store)],
        child: const _App(),
      ),
    );
  }

  testWidgets('propose la langue du téléphone puis chaque langue par son nom', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Langue du téléphone'), findsOneWidget);
    for (final language in AppLanguage.values) {
      expect(find.text(language.autonym), findsOneWidget);
    }
  });

  testWidgets(
    'choisir עברית passe toute l\'app en hébreu, de droite à gauche',
    (tester) async {
      await pump(tester);

      await tester.tap(find.text('עברית'));
      await tester.pumpAndSettle();

      expect(store.saved, 'he');
      expect(find.text('שפת הטלפון'), findsOneWidget);
      final direction = Directionality.of(tester.element(find.text('עברית')));
      expect(direction, TextDirection.rtl);
    },
  );

  testWidgets('la langue en cours est cochée', (tester) async {
    await pump(tester);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    final tile = find.ancestor(
      of: find.text('English'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(
        of: tile,
        matching: find.byKey(LanguagePickerSheet.checkKey),
      ),
      findsOneWidget,
    );
  });
}
