import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/conversation.dart';
import 'package:mazl/presentation/features/chat/widgets/chat_header.dart';

import '../../helpers/l10n_helpers.dart';

/// Le serveur ne publie aucune présence : l'en-tête affichait « En ligne » en
/// dur sous le nom de tout le monde. Il ne dit plus rien d'autre que « écrit… »
/// (la saisie, elle, arrive réellement par la WebSocket).
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool isTyping,
    required Locale locale,
  }) => pumpLocalized(
    tester,
    Scaffold(
      body: ChatHeader(
        user: ConversationUser(userId: 7, displayName: 'Jeanne Exemple'),
        isTyping: isTyping,
        onBack: () {},
        onOpenProfile: () {},
        onOptions: () {},
      ),
    ),
    locale: locale,
  );

  for (final language in AppLanguage.values) {
    final locale = Locale(language.code);

    testWidgets('${language.code} : au repos, seul le nom est écrit', (
      tester,
    ) async {
      await pump(tester, isTyping: false, locale: locale);

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .toList();
      expect(texts, ['Jeanne Exemple']);
    });

    testWidgets('${language.code} : pendant la saisie, la saisie est dite', (
      tester,
    ) async {
      await pump(tester, isTyping: true, locale: locale);

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .toList();
      expect(texts.length, 2);
      expect(texts.first, 'Jeanne Exemple');
    });
  }
}
