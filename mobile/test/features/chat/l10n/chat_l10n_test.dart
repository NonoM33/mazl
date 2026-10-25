import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/chat/chat_realtime.dart';
import 'package:mazl/core/services/icebreaker_service.dart';
import 'package:mazl/presentation/features/chat/conversation_time.dart';
import 'package:mazl/presentation/features/chat/l10n/chat_failure_text.dart';
import 'package:mazl/presentation/features/chat/l10n/chat_preview_text.dart';
import 'package:mazl/presentation/features/chat/l10n/icebreaker_text.dart';
import 'package:mazl/presentation/features/chat/logic/chat_dates.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller.dart';

import '../../../helpers/l10n_helpers.dart';
import '../chat_test_support.dart';

const _en = Locale('en');
const _he = Locale('he');
const _locales = [Locale('fr'), _en, _he, Locale('es'), Locale('ru')];

AppLocalizations _l10n(String code) => lookupAppLocalizations(Locale(code));

void main() {
  setUpAll(() async {
    await loadChatFonts();
    await initializeDateFormatting();
  });

  group('the conversation speaks the language of the member', () {
    testWidgets('in English: header, bubbles, times, composer', (tester) async {
      final semantics = tester.ensureSemantics();
      final seen = msg(2, me, 'Hello', at: today(10, 5), readAt: today(10, 6));
      final harness = ChatHarness(
        initial: chatState([msg(1, other, 'Hi there', at: today(10, 0)), seen]),
      );
      await harness.pump(tester, locale: _en);

      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Seen at 10:06'), findsOneWidget);
      expect(find.byTooltip('Attach photos'), findsOneWidget);
      expect(find.bySemanticsLabel('Video call'), findsNothing);
      expect(find.byTooltip('Options'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Hold to record a voice message'),
        findsOneWidget,
      );
      expect(find.text('En ligne'), findsNothing);
      expect(find.text('Vu à 10:06'), findsNothing);
      semantics.dispose();
    });

    testWidgets('an empty conversation, in English', (tester) async {
      await ChatHarness().pump(tester, locale: _en);
      expect(find.text('Say hello.'), findsOneWidget);
      expect(
        find.text('Send the first message to break the ice.'),
        findsOneWidget,
      );
      expect(find.text('NEW MATCH'), findsOneWidget);
    });

    testWidgets('a failed first load names the cause in English', (
      tester,
    ) async {
      final harness = ChatHarness(
        initial: chatState(const [], error: ChatFailure.network),
      );
      await harness.pump(tester, locale: _en);
      expect(find.text('No internet connection.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('the long-press menu, in English', (tester) async {
      final mine = msg(5, me, 'Dinner tonight?', at: DateTime.now());
      await ChatHarness(initial: chatState([mine])).pump(tester, locale: _en);
      await tester.longPress(bubbleOf(mine));
      await tester.pumpAndSettle();
      for (final label in ['Reply', 'Copy', 'Unsend']) {
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('message-menu')),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }
    });

    testWidgets(
      'a refused send closes the composer with the English sentence',
      (tester) async {
        final harness = ChatHarness()..actions.error = ChatFailure.blocked;
        await harness.pump(tester, locale: _en);
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.bySemanticsLabel('Send'));
        await tester.pump();
        await tester.pump();
        expect(
          find.text('You can no longer write in this conversation.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'a failed bubble says « Failed · Try again » and the sheet offers Try again / Delete',
      (tester) async {
        final failed = msg(
          3,
          me,
          'Oops',
          at: DateTime.now(),
          status: MessageStatus.failed,
        );
        await ChatHarness(
          initial: chatState([failed]),
        ).pump(tester, locale: _en);
        expect(find.text('Failed · Try again'), findsOneWidget);
        await tester.tap(find.text('Failed · Try again'));
        await tester.pumpAndSettle();
        expect(find.text('Try again'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      },
    );

    testWidgets('a reply to a photo is quoted in the language of the member', (
      tester,
    ) async {
      final quoted = msg(
        4,
        me,
        'Yes',
        at: DateTime.now(),
        replyTo: const ReplyRef(
          id: 1,
          senderId: other,
          type: ChatMessageType.photo,
          preview: 'Photo',
        ),
      );
      await ChatHarness(initial: chatState([quoted])).pump(tester, locale: _he);
      expect(find.text('תמונה'), findsOneWidget);
      expect(find.text('Photo'), findsNothing);
    });
  });

  group('right to left: the bubbles turn around like in iMessage', () {
    for (final (code, locale) in [('en', _en), ('he', _he)]) {
      testWidgets(
        '$code: my message sits on the END side, the other member on the START side',
        (tester) async {
          final theirs = msg(1, other, 'Shalom', at: today(9, 0));
          final mine = msg(2, me, 'Hello', at: today(9, 1));
          await ChatHarness(
            initial: chatState([theirs, mine]),
          ).pump(tester, locale: locale);
          final screen = tester.getSize(find.byType(Scaffold).first);
          final theirsRect = tester.getRect(bubbleOf(theirs));
          final mineRect = tester.getRect(bubbleOf(mine));
          final rtl = locale == _he;
          expect(
            textDirectionAt(tester, bubbleOf(mine)),
            rtl ? TextDirection.rtl : TextDirection.ltr,
          );
          if (rtl) {
            expect(
              mineRect.left,
              closeTo(16, 1),
              reason: 'mine hugs the left margin in Hebrew',
            );
            expect(theirsRect.right, lessThan(screen.width - 16 + 1));
            expect(theirsRect.right, greaterThan(screen.width / 2));
          } else {
            expect(mineRect.right, closeTo(screen.width - 16, 1));
            expect(theirsRect.left, lessThan(screen.width / 2));
          }
        },
      );
    }

    testWidgets('the corners follow: the tail stays on the outer bottom corner', (
      tester,
    ) async {
      final mine = msg(2, me, 'Hello', at: today(9, 1));
      await ChatHarness(initial: chatState([mine])).pump(tester, locale: _he);
      final decoration =
          tester.widget<Container>(bubbleOf(mine)).decoration! as BoxDecoration;
      final radius = (decoration.borderRadius! as BorderRadiusDirectional)
          .resolve(TextDirection.rtl);
      // In Hebrew my bubble is on the left: the 6 px tail is its bottom LEFT corner.
      expect(
        [
          radius.topLeft.x,
          radius.topRight.x,
          radius.bottomLeft.x,
          radius.bottomRight.x,
        ],
        [22, 22, 6, 22],
      );
    });

    testWidgets('swiping to reply goes toward the END of the screen', (
      tester,
    ) async {
      final m = msg(5, other, 'On se voit jeudi ?', at: today(10, 0));
      final harness = ChatHarness(initial: chatState([m]));
      await harness.pump(tester, locale: _he);

      await tester.drag(bubbleOf(m), const Offset(120, 0));
      await tester.pumpAndSettle();
      expect(
        find.text('תשובה אל Noémie'),
        findsNothing,
        reason: 'toward the start does nothing',
      );

      await tester.drag(bubbleOf(m), const Offset(-120, 0));
      await tester.pumpAndSettle();
      expect(find.text('תשובה אל Noémie'), findsOneWidget);
    });

    testWidgets(
      'long press: the reaction bar lines up with the side of the bubble',
      (tester) async {
        final mine = msg(5, me, 'Hello', at: DateTime.now());
        await ChatHarness(initial: chatState([mine])).pump(tester, locale: _he);
        await tester.longPress(bubbleOf(mine));
        await tester.pumpAndSettle();
        final bar = tester.getRect(find.byKey(const ValueKey('reaction-bar')));
        final lifted = tester.getRect(find.text('Hello').last);
        expect(
          bar.left,
          lessThan(tester.getSize(find.byType(Scaffold).first).width / 2),
        );
        expect(
          lifted.left,
          lessThan(tester.getSize(find.byType(Scaffold).first).width / 2),
        );
      },
    );

    testWidgets(
      'sliding the mic toward the field cancels in Hebrew (start side)',
      (tester) async {
        final harness = ChatHarness();
        await harness.pump(tester, locale: _he);
        final mic = find.byIcon(LucideIcons.mic);
        expect(mic, findsOneWidget);
        final start = tester.getCenter(mic);
        final gesture = await tester.startGesture(start);
        await tester.pump(const Duration(milliseconds: 400));
        await gesture.moveTo(start + const Offset(120, 0));
        await tester.pump();
        expect(find.text('יש לשחרר כדי לבטל'), findsOneWidget);
        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });

  group('no overflow at 360 px, in every language, light and dark', () {
    for (final locale in _locales) {
      for (final brightness in Brightness.values) {
        testWidgets('${locale.languageCode} ${brightness.name}', (
          tester,
        ) async {
          final reaction = [
            const Reaction(emoji: '❤️', userIds: [2]),
            const Reaction(emoji: '👍', userIds: [1, 2]),
          ];
          final messages = [
            msg(
              1,
              other,
              'Hello, want to meet this weekend? Send me money or a gift card',
              at: today(9, 0),
            ),
            msg(
              2,
              me,
              'Sure',
              at: today(9, 1),
              readAt: today(9, 2),
              reactions: reaction,
            ),
            msg(3, me, 'Oops', at: today(9, 5), status: MessageStatus.failed),
            msg(4, other, '', at: today(9, 6), unsent: true),
          ];
          final harness = ChatHarness(
            initial: chatState(messages, typing: true),
          );
          await harness.pump(
            tester,
            locale: locale,
            brightness: brightness,
            size: kSmallPhone,
            isScamFlagged: (m) => m.id == 1,
          );
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          expect(
            find.text(
              'Hello, want to meet this weekend? Send me money or a gift card',
            ),
            findsOneWidget,
          );
        });
      }
    }

    for (final locale in [_en, _he, const Locale('ru')]) {
      testWidgets(
        '${locale.languageCode}: the long-press menu and the unsend line',
        (tester) async {
          final mine = msg(5, me, 'Hello', at: DateTime.now());
          await ChatHarness(
            initial: chatState([mine]),
          ).pump(tester, locale: locale, size: kSmallPhone);
          await tester.longPress(bubbleOf(mine));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('every message has a sentence in every language', () {
    test('a chat failure', () {
      for (final code in ['fr', 'en', 'he', 'es', 'ru']) {
        for (final failure in ChatFailure.values) {
          expect(
            failure.text(_l10n(code)).trim(),
            isNotEmpty,
            reason: '$code ${failure.name}',
          );
        }
      }
    });

    test('a failure keeps its meaning in English', () {
      final en = _l10n('en');
      expect(
        ChatFailure.tooManyPhotos.text(en),
        'Ten photos at most per message.',
      );
      expect(
        ChatFailure.cannotUnsend.text(en),
        'This message can no longer be unsent.',
      );
      expect(
        ChatFailure.conversationGone.text(en),
        'This conversation is no longer available.',
      );
    });

    test('every icebreaker, with its words filled in', () {
      for (final code in ['fr', 'en', 'he', 'es', 'ru']) {
        for (final phrase in IcebreakerPhrase.values) {
          final text = icebreakerText(
            _l10n(code),
            Icebreaker(
              phrase: phrase,
              type: IcebreakerType.generic,
              location: 'Lyon',
              promptText: 'Ma passion',
              answer: 'La randonnée',
              topic: 'passion',
              followUp: IcebreakerPhrase.followUpTellMe,
            ),
          );
          expect(text.trim(), isNotEmpty, reason: '$code ${phrase.name}');
          expect(text, isNot(contains('{')), reason: '$code ${phrase.name}');
        }
      }
    });

    test(
      'icebreaker: French stays as written (tutoiement), English reads naturally',
      () {
        final prompt = Icebreaker(
          phrase: IcebreakerPhrase.promptLoved,
          type: IcebreakerType.prompt,
          promptText: 'My favourite trip',
          followUp: IcebreakerPhrase.followUpKnowMore,
        );
        expect(
          icebreakerText(_l10n('fr'), prompt),
          'J\'ai adoré ta réponse à "My favourite trip". J\'aimerais en savoir plus.',
        );
        expect(
          icebreakerText(_l10n('en'), prompt),
          'I loved your answer to "My favourite trip". I\'d love to know more.',
        );
        final noTopic = Icebreaker(
          phrase: IcebreakerPhrase.promptCurious,
          type: IcebreakerType.prompt,
          answer: 'Oui',
        );
        expect(
          icebreakerText(_l10n('fr'), noTopic),
          'Je suis curieux(se) de savoir pourquoi tu as répondu "Oui" à la question sur ça',
        );
      },
    );

    test(
      'the server words for a photo, a voice note and a retraction are translated',
      () {
        final en = _l10n('en');
        expect(chatPreviewLabel(en, 'Photo'), 'Photo');
        expect(chatPreviewLabel(en, 'Message vocal'), 'Voice message');
        expect(chatPreviewLabel(en, 'Message retiré'), 'Message removed');
        expect(
          chatPreviewLabel(en, 'On se voit jeudi ?'),
          'On se voit jeudi ?',
        );
        expect(chatPreviewLabel(_l10n('he'), 'Message vocal'), 'הודעה קולית');
        expect(chatPreviewKindOf('Photo'), ChatPreviewKind.photo);
      },
    );
  });

  group('dates follow the language', () {
    final now = DateTime(2026, 10, 23, 12);

    test('the day label of the thread', () {
      expect(dayLabel(_l10n('en'), DateTime(2026, 10, 23), now), 'Today');
      expect(dayLabel(_l10n('en'), DateTime(2026, 10, 22), now), 'Yesterday');
      expect(dayLabel(_l10n('en'), DateTime(2026, 10, 21), now), 'Wed, Oct 21');
      expect(
        dayLabel(_l10n('en'), DateTime(2025, 12, 31), now),
        'Wed, Dec 31, 2025',
      );
      expect(dayLabel(_l10n('es'), DateTime(2026, 10, 21), now), 'Mié, 21 oct');
      expect(dayLabel(_l10n('ru'), DateTime(2026, 10, 21), now), 'Ср, 21 окт.');
    });

    test('Hebrew writes the month in Hebrew', () {
      final label = dayLabel(_l10n('he'), DateTime(2026, 10, 21), now);
      expect(RegExp('[֐-׿]').hasMatch(label), isTrue, reason: label);
      expect(shortDate(_l10n('he'), DateTime(2026, 10, 21)), contains('21'));
    });

    test('the start-of-conversation marker', () {
      expect(shortDate(_l10n('fr'), DateTime(2026, 10, 21)), '21 oct.');
      expect(shortDate(_l10n('en'), DateTime(2026, 10, 21)), 'Oct 21');
    });

    test('the clock of a bubble', () {
      expect(clock(_l10n('en'), DateTime(2026, 1, 1, 9, 5)), '09:05');
    });

    test('the time of a row of the list', () {
      final en = _l10n('en');
      final later = DateTime(2026, 10, 23, 20, 30);
      expect(
        formatConversationTime(en, DateTime(2026, 10, 23, 9, 5), later),
        '09:05',
      );
      expect(
        formatConversationTime(en, DateTime(2026, 10, 22, 18), later),
        'Yesterday',
      );
      expect(
        formatConversationTime(en, DateTime(2026, 10, 20, 12), later),
        'Tue',
      );
      expect(
        formatConversationTime(en, DateTime(2026, 10, 15, 12), later),
        'Oct 15',
      );
    });
  });
}
