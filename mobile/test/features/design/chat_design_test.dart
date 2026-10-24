import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/conversation.dart';
import 'package:mazl/core/theme/app_colors.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/chat/screens/conversations_screen.dart';
import '../../helpers/l10n_helpers.dart';

Conversation _conversation({int unread = 0}) => Conversation(
      id: 7,
      matchId: 3,
      lastMessage: 'On se retrouve vendredi ?',
      lastMessageAt: DateTime(2026, 10, 23, 18, 30),
      unreadCount: unread,
      otherUser: ConversationUser(userId: 12, displayName: 'Sarah'),
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double safeBottom = 0,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      theme: AppTheme.lightTheme,
      builder: (context, app) => MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          padding: EdgeInsets.only(bottom: safeBottom),
          viewPadding: EdgeInsets.only(bottom: safeBottom),
        ),
        child: app!,
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('ligne de conversation', () {
    testWidgets('non lue : pastille tekhelet et texte plus marqué', (tester) async {
      await _pump(
        tester,
        ConversationRow(conversation: _conversation(unread: 2), formattedTime: '18:30', onTap: () {}),
      );
      final dot = find.byKey(ConversationRow.unreadDotKey);
      expect(dot, findsOneWidget);
      expect(tester.getSize(dot), const Size(8, 8));
      final decoration = tester.widget<Container>(dot).decoration! as BoxDecoration;
      expect(decoration.color, AppColors.tekhelet);
      final preview = tester.widget<Text>(find.byKey(ConversationRow.previewKey));
      expect(preview.style?.fontWeight, FontWeight.w500);
      expect(preview.style?.color, AppColors.ink);
      expect(tester.getSize(find.byType(ConversationRow)).height, greaterThanOrEqualTo(80));
    });

    testWidgets('lue : ni pastille ni texte marqué', (tester) async {
      await _pump(
        tester,
        ConversationRow(conversation: _conversation(), formattedTime: '18:30', onTap: () {}),
      );
      expect(find.byKey(ConversationRow.unreadDotKey), findsNothing);
      final preview = tester.widget<Text>(find.byKey(ConversationRow.previewKey));
      expect(preview.style?.fontWeight, FontWeight.w400);
      expect(preview.style?.color, AppColors.muted);
      expect(find.text('Sarah'), findsOneWidget);
      expect(find.text('18:30'), findsOneWidget);
    });

    testWidgets('un appui déclenche onTap', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        ConversationRow(conversation: _conversation(), formattedTime: '18:30', onTap: () => taps++),
      );
      await tester.tap(find.byType(ConversationRow));
      expect(taps, 1);
    });
  });
}
