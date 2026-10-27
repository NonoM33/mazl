import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/theme/app_theme.dart';

import '../../features/chat/chat_test_support.dart';
import '../../helpers/l10n_helpers.dart';
import '../../support/dark_theme_audit.dart';

// WCAG AA, en thème clair ET sombre : 4,5:1 pour le texte normal, 3:1 pour le
// grand texte. Vu sur iPhone : mes bulles étaient bleu moyen avec un texte
// presque noir, peu lisible.

final _themes = {
  Brightness.light: AppTheme.lightTheme,
  Brightness.dark: AppTheme.darkTheme,
};

void main() {
  setUpAll(loadChatFonts);

  for (final entry in _themes.entries) {
    final name = entry.key.name;
    final scheme = entry.value.colorScheme;

    group('couleurs du thème $name', () {
      final pairs = <String, (Color, Color)>{
        'texte sur page': (scheme.onSurface, scheme.surface),
        'texte sur carte': (scheme.onSurface, scheme.surfaceContainer),
        'texte d\'aide sur page': (scheme.onSurfaceVariant, scheme.surface),
        'texte d\'aide sur carte': (
          scheme.onSurfaceVariant,
          scheme.surfaceContainer,
        ),
        'accent (lien, icône) sur page': (scheme.primary, scheme.surface),
        'accent sur carte': (scheme.primary, scheme.surfaceContainer),
        'erreur sur page': (scheme.error, scheme.surface),
        'erreur sur carte': (scheme.error, scheme.surfaceContainer),
        'ma bulle': (scheme.onPrimaryContainer, scheme.primaryContainer),
        'bulle de l\'autre': (scheme.onSurface, scheme.surfaceContainer),
        'heure dans ma bulle': (
          scheme.onPrimaryContainer.withValues(alpha: 0.85),
          scheme.primaryContainer,
        ),
        'heure sous la bulle': (scheme.onSurfaceVariant, scheme.surface),
      };
      pairs.forEach((label, pair) {
        test('$label : au moins 4,5:1', () {
          final (fg, bg) = pair;
          final ratio = contrastRatio(Color.alphaBlend(fg, bg), bg);
          expect(ratio, greaterThanOrEqualTo(4.5), reason: '$label $ratio');
        });
      });
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('boutons, puces et cartes lisibles (${brightness.name})', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FilledButton(onPressed: () {}, child: const Text('Continuer')),
                ElevatedButton(onPressed: () {}, child: const Text('Valider')),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Plus tard'),
                ),
                TextButton(onPressed: () {}, child: const Text('Annuler')),
                FilterChip(
                  label: const Text('Mariage'),
                  selected: true,
                  onSelected: (_) {},
                ),
                FilterChip(
                  label: const Text('Amitié'),
                  selected: false,
                  onSelected: (_) {},
                ),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Une carte'),
                  ),
                ),
              ],
            ),
          ),
        ),
        brightness: brightness,
      );
      expect(lowContrastTexts(tester), isEmpty);
    });

    testWidgets(
      'conversation : bulles, heures et « Lu à » (${brightness.name})',
      (tester) async {
        final messages = [
          msg(1, other, 'Salut, tu es libre ce soir ?', at: today(10, 0)),
          msg(2, me, 'Oui, vers 19 h.', at: today(10, 1), readAt: today(10, 2)),
          msg(3, me, 'On se retrouve où ?', at: today(10, 3)),
        ];
        await ChatHarness(
          initial: chatState(messages),
        ).pump(tester, brightness: brightness);
        expect(find.text('Oui, vers 19 h.'), findsOneWidget);
        expect(lowContrastTexts(tester), isEmpty);
      },
    );
  }
}
