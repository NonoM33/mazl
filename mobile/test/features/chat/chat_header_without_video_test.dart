import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/models/conversation.dart';
import 'package:mazl/presentation/features/chat/widgets/chat_header.dart';

import '../../helpers/l10n_helpers.dart';

/// L'appel vidéo n'existait pas : un écran factice (« Sarah » en dur, boutons
/// vides). Son entrée dans l'en-tête de la conversation est retirée.
void main() {
  for (final locale in [kTestLocale, const Locale('en')]) {
    testWidgets('${locale.languageCode} : l\'en-tête n\'offre plus d\'appel '
        'vidéo', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpLocalized(
        tester,
        Scaffold(
          body: ChatHeader(
            user: ConversationUser(userId: 7, displayName: 'Jeanne Exemple'),
            isTyping: false,
            onBack: () {},
            onOpenProfile: () {},
            onOptions: () {},
          ),
        ),
        locale: locale,
      );

      expect(find.byIcon(LucideIcons.video), findsNothing);
      expect(find.bySemanticsLabel('Appel vidéo'), findsNothing);
      expect(find.bySemanticsLabel('Video call'), findsNothing);
      // Le retour et les options restent.
      expect(find.byIcon(LucideIcons.ellipsis), findsOneWidget);
      semantics.dispose();
    });
  }
}
