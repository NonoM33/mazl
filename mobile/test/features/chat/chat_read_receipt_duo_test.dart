import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/chat/voice.dart';
import 'package:mazl/core/chat/voice_impl.dart';
import 'package:mazl/core/models/conversation.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/chat/chat_providers.dart';
import 'package:mazl/presentation/features/chat/screens/chat_conversation_screen.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller_impl.dart';
import 'package:mazl/presentation/features/chat/widgets/read_receipt_line.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../duo/duo_geometry.dart';
import 'chat_test_support.dart';

// « Lu à 21:04 » under the last message I sent (docs/premium/MONETISATION.md
// §4) in every pose of the foldable iPhone, light and dark, in every
// language: the line is on screen when the server sent a read_at, absent
// otherwise, and never crosses the fold or goes under the system.

Future<void> _pump(
  WidgetTester tester,
  DuoPose pose, {
  required DateTime? readAt,
  bool dark = false,
  Locale locale = kTestLocale,
}) async {
  final actions = FakeChatNotifier(
    chatState([
      msg(1, other, 'Salut !', at: today(20, 40)),
      msg(2, me, 'Salut, tu vas bien ?', at: today(20, 55), readAt: readAt),
    ]),
  );
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatControllerProvider.overrideWith((ref, id) => actions),
        voiceRecorderProvider.overrideWithValue(FakeVoiceRecorder()),
        voicePlayerProvider.overrideWithValue(FakeVoicePlayer()),
        chatMediaPickerProvider.overrideWithValue(FakePicker()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: duoAppBuilder(controller),
        home: ChatConversationScreen(
          conversationId: conversationId,
          otherUser: ConversationUser(userId: other, displayName: 'Noémie'),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await settleFold(tester);
}

void main() {
  setUpAll(() async {
    await loadChatFonts();
    await initializeDateFormatting();
  });

  testWidgets('with a read_at the line says « Lu à 21:04 »', (tester) async {
    await _pump(tester, DuoPose.openPortrait, readAt: today(21, 4));
    expect(find.text('Lu à 21:04'), findsOneWidget);
  });

  testWidgets('without a read_at there is no line at all', (tester) async {
    await _pump(tester, DuoPose.openPortrait, readAt: null);
    expect(find.byType(ReadReceiptLine), findsNothing);
    expect(find.textContaining('Lu à'), findsNothing);
  });

  for (final pose in DuoPose.values) {
    for (final dark in [false, true]) {
      for (final read in [true, false]) {
        testWidgets(
          '${pose.name} ${dark ? 'dark' : 'light'} ${read ? 'read' : 'no read_at'}',
          (tester) async {
            await _pump(
              tester,
              pose,
              readAt: read ? today(21, 4) : null,
              dark: dark,
            );
            expect(
              find.byType(ReadReceiptLine),
              read ? findsOneWidget : findsNothing,
            );
            // Alone on a bare route the thread is not split at the fold (the
            // shell does that in the app, and the crawl of all_screens_duo_test
            // measures this very conversation there): the line itself must
            // stay clear of it.
            if (pose.fold == null) {
              expect(foldCrossingProblems(tester, pose), isEmpty);
            }
            expect(tester.takeException(), isNull);
            if (read) {
              final rect = tester.getRect(find.byType(ReadReceiptLine));
              final bar = pose.verticalBar?.controls;
              expect(
                pose.safeRect.inflate(0.5).contains(rect.topLeft) &&
                    pose.safeRect.inflate(0.5).contains(rect.bottomRight),
                isTrue,
                reason: '$rect is outside ${pose.safeRect} ($bar)',
              );
              for (final occluded in pose.foldState.occlusions) {
                expect(rect.overlaps(occluded), isFalse);
              }
              if (pose.fold != null) {
                expect(rect.overlaps(pose.fold!), isFalse, reason: '$rect');
              }
            }
          },
        );
      }
    }
  }

  for (final code in ['fr', 'en', 'es', 'ru', 'he']) {
    testWidgets('$code: the line fits a small phone, light and dark', (
      tester,
    ) async {
      for (final dark in [false, true]) {
        await _pump(
          tester,
          DuoPose.closed,
          readAt: today(21, 4),
          locale: Locale(code),
          dark: dark,
        );
        expect(find.byType(ReadReceiptLine), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
