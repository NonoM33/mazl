import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/models/conversation.dart';
import 'package:mazl/presentation/features/chat/screens/conversations_screen.dart';

import '../../../helpers/l10n_helpers.dart';

Conversation _conversation({String? lastMessage, int unread = 0}) =>
    Conversation(
      id: 7,
      matchId: 3,
      lastMessage: lastMessage,
      unreadCount: unread,
      otherUser: ConversationUser(userId: 9, displayName: 'Sarah'),
    );

void main() {
  setUpAll(() => initializeDateFormatting());

  group('a row of the conversation list', () {
    testWidgets(
      'in English: the server words are translated, a new match is named',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpLocalized(
          tester,
          Scaffold(
            body: Column(
              children: [
                ConversationRow(
                  conversation: _conversation(
                    lastMessage: 'Message vocal',
                    unread: 1,
                  ),
                  formattedTime: '09:05',
                  onTap: () {},
                ),
                ConversationRow(
                  conversation: _conversation(),
                  formattedTime: 'Yesterday',
                  onTap: () {},
                ),
              ],
            ),
          ),
          locale: const Locale('en'),
        );
        expect(find.text('Voice message'), findsOneWidget);
        expect(find.text('New match'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Sarah, unread message')),
          findsOneWidget,
        );
        semantics.dispose();
      },
    );

    for (final brightness in Brightness.values) {
      for (final code in ['en', 'he', 'ru', 'es']) {
        testWidgets(
          '$code ${brightness.name}: no overflow at 360 px, right to left in Hebrew',
          (tester) async {
            await pumpLocalized(
              tester,
              Scaffold(
                body: ConversationRow(
                  conversation: _conversation(
                    lastMessage: 'Message retiré',
                    unread: 3,
                  ),
                  formattedTime: '09:05',
                  onTap: () {},
                ),
              ),
              locale: Locale(code),
              brightness: brightness,
            );
            expect(tester.takeException(), isNull);
            expect(
              textDirectionAt(tester, find.text('Sarah')),
              code == 'he' ? TextDirection.rtl : TextDirection.ltr,
            );
          },
        );
      }
    }
  });

  group('the list screen', () {
    testWidgets('title and search field in English', (tester) async {
      tester.view.physicalSize = kSmallPhone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const ConversationsScreen()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      expect(find.text('Messages'), findsOneWidget);
      // Without a server the list cannot load: the error is told in English.
      expect(
        find.text('Check your connection, then try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
