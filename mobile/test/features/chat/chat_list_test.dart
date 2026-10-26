import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/theme/app_colors.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller.dart';
import 'package:mazl/presentation/features/chat/widgets/date_separator.dart';
import 'package:mazl/presentation/features/chat/widgets/list_states.dart';
import 'package:mazl/presentation/features/chat/widgets/message_composer.dart';
import 'package:mazl/presentation/features/chat/widgets/new_messages_pill.dart';
import 'package:mazl/presentation/features/chat/widgets/typing_indicator.dart';

import 'chat_test_support.dart';

List<ChatMessage> _many(int count, {DateTime? from}) {
  final start = from ?? today(8, 0);
  return [
    for (var i = 1; i <= count; i++)
      msg(
        i,
        i.isEven ? me : other,
        'Message numéro $i',
        at: start.add(Duration(minutes: i * 10)),
      ),
  ];
}

Finder get _profilePhotosInThread =>
    find.byWidgetPredicate((w) => w is ProfilePhoto && w.radius == 14);

void main() {
  setUpAll(loadChatFonts);

  group('grouping on screen', () {
    testWidgets('2 px inside a group, 12 px between groups', (tester) async {
      final a = msg(1, other, 'Salut', at: today(10, 0));
      final b = msg(2, other, 'Tu es là ?', at: today(10, 1));
      final c = msg(3, me, 'Oui !', at: today(10, 2));
      await ChatHarness(initial: chatState([a, b, c])).pump(tester);

      expect(
        rectOf(tester, bubbleOf(b)).top - rectOf(tester, bubbleOf(a)).bottom,
        2,
      );
      final timeOfB = tester.getRect(find.text('10:01'));
      expect(rectOf(tester, bubbleOf(c)).top - timeOfB.bottom, 12);
    });

    testWidgets(
      'the avatar shows only beside the last bubble of a received group',
      (tester) async {
        final a = msg(1, other, 'Salut', at: today(10, 0));
        final b = msg(2, other, 'Tu es là ?', at: today(10, 1));
        await ChatHarness(initial: chatState([a, b])).pump(tester);
        expect(_profilePhotosInThread, findsOneWidget);
        final avatar = tester.getRect(_profilePhotosInThread);
        expect(avatar.size, const Size(28, 28));
        expect(avatar.bottom, closeTo(rectOf(tester, bubbleOf(b)).bottom, 0.5));
      },
    );

    testWidgets('the time sits under the last bubble of a group only', (
      tester,
    ) async {
      await ChatHarness(
        initial: chatState([
          msg(1, other, 'a', at: today(10, 0)),
          msg(2, other, 'b', at: today(10, 1)),
        ]),
      ).pump(tester);
      expect(find.text('10:00'), findsNothing);
      expect(find.text('10:01'), findsOneWidget);
    });

    testWidgets('touching a bubble reveals its time', (tester) async {
      final a = msg(1, other, 'a', at: today(10, 0));
      await ChatHarness(
        initial: chatState([a, msg(2, other, 'b', at: today(10, 1))]),
      ).pump(tester);
      await tester.tap(bubbleOf(a));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('10:00'), findsOneWidget);
    });
  });

  group('markers', () {
    testWidgets('a date label per day, « Aujourd\'hui » and « Hier »', (
      tester,
    ) async {
      final yesterday = today(12, 0).subtract(const Duration(days: 1));
      await ChatHarness(
        initial: chatState([
          msg(1, other, 'a', at: yesterday),
          msg(2, me, 'b', at: today(0, 1)),
        ], hasMore: true),
      ).pump(tester);
      expect(find.text('HIER'), findsOneWidget);
      expect(find.text("AUJOURD'HUI"), findsOneWidget);
    });

    testWidgets('start of the conversation: « Match · date »', (tester) async {
      await ChatHarness(
        initial: chatState([msg(1, other, 'a', at: DateTime(2026, 10, 21, 9))]),
      ).pump(tester);
      expect(find.text('MATCH · 21 OCT.'), findsOneWidget);
    });

    testWidgets(
      '« Vu à 20:47 » under the last read message of mine, nothing for the others',
      (tester) async {
        await ChatHarness(
          initial: chatState([
            msg(1, me, 'a', at: today(20, 40), readAt: today(20, 47)),
            msg(2, other, 'b', at: today(20, 48)),
            msg(3, me, 'c', at: today(20, 50)),
          ]),
        ).pump(tester);
        expect(find.text('Vu à 20:47'), findsOneWidget);
        expect(find.textContaining('Vu à'), findsOneWidget);
      },
    );

    testWidgets('the typing indicator shows in the thread and in the header', (
      tester,
    ) async {
      await ChatHarness(
        initial: chatState([msg(1, other, 'a')], typing: true),
      ).pump(tester);
      expect(find.byType(TypingIndicator), findsOneWidget);
      expect(find.text('écrit…'), findsOneWidget);
      final size = tester.getSize(find.byType(TypingIndicator));
      expect(size, const Size(56, 36));
    });

    testWidgets(
      'the day label sticks to the top while its messages scroll, and gives way to the real label',
      (tester) async {
        final messages = _many(
          40,
          from: today(0, 0).subtract(const Duration(hours: 2)),
        );
        await ChatHarness(
          initial: chatState(messages, hasMore: true),
        ).pump(tester);
        await tester.pump();
        final sticky = find.byType(StickyDateLabel);
        expect(sticky, findsOneWidget);
        expect(
          find.descendant(of: sticky, matching: find.text("AUJOURD'HUI")),
          findsOneWidget,
        );

        await tester.fling(
          find.byType(ListView).first,
          const Offset(0, 5000),
          6000,
        );
        await tester.pumpAndSettle();
        expect(sticky, findsNothing);
        expect(find.text('HIER'), findsOneWidget);
      },
    );
  });

  group('states', () {
    testWidgets('a skeleton while the first page loads', (tester) async {
      await ChatHarness(
        initial: chatState(const [], loading: true),
      ).pump(tester);
      expect(find.byType(ListSkeleton), findsOneWidget);
    });

    testWidgets(
      'a failed first load shows the error and « Réessayer » loads again',
      (tester) async {
        final harness = ChatHarness(
          initial: chatState(
            const [],
            error: ChatFailure.loadFailed,
          ),
        );
        await harness.pump(tester);
        expect(
          find.text('Impossible de charger la conversation.'),
          findsOneWidget,
        );
        final before = harness.actions.loadCalls;
        await tester.tap(find.text('Réessayer'));
        await tester.pump();
        expect(harness.actions.loadCalls, before + 1);
      },
    );

    testWidgets('an empty conversation invites to say hello', (tester) async {
      await ChatHarness(initial: chatState(const [])).pump(tester);
      expect(find.text('Dites bonjour.'), findsOneWidget);
    });

    testWidgets('an unsent message reads « Message retiré » in italics', (
      tester,
    ) async {
      await ChatHarness(
        initial: chatState([msg(1, other, '', unsent: true)]),
      ).pump(tester);
      final text = tester.widget<Text>(find.text('Message retiré'));
      expect(text.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('a message being sent is drawn at 60 %', (tester) async {
      final sending = msg(
        -1,
        me,
        'Envoi…',
        status: MessageStatus.sending,
        clientId: 'c-new',
      );
      await ChatHarness(initial: chatState([sending])).pump(tester);
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(of: bubbleOf(sending), matching: find.byType(Opacity))
            .first,
      );
      expect(opacity.opacity, 0.6);
    });

    testWidgets(
      'a failed message shows « Échec · Réessayer »; the sheet retries it or drops it',
      (tester) async {
        final failed = msg(
          -2,
          me,
          'Raté',
          status: MessageStatus.failed,
          clientId: 'c-failed',
        );
        final harness = ChatHarness(initial: chatState([failed]));
        await harness.pump(tester);
        expect(find.text('Échec · Réessayer'), findsOneWidget);

        await tester.tap(find.text('Échec · Réessayer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Réessayer'));
        await tester.pumpAndSettle();
        expect(harness.actions.retried, ['c-failed']);

        await tester.tap(find.text('Échec · Réessayer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Supprimer'));
        await tester.pumpAndSettle();
        expect(harness.actions.discarded, ['c-failed']);
      },
    );
  });

  group('scrolling', () {
    testWidgets('reaching the top loads older messages, once per page', (
      tester,
    ) async {
      final harness = ChatHarness(initial: chatState(_many(40), hasMore: true));
      await harness.pump(tester);
      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 3000),
        4000,
      );
      await tester.pumpAndSettle();
      expect(harness.actions.loadOlderCalls, 1);
    });

    testWidgets(
      'the newest message from the other member is marked read on open',
      (tester) async {
        final harness = ChatHarness(
          initial: chatState([msg(7, other, 'a'), msg(8, me, 'b')]),
        );
        await harness.pump(tester);
        await tester.pump();
        expect(harness.actions.readUpTo, [7]);
      },
    );

    testWidgets(
      'scrolled up, a new message shows « 1 nouveau message »; tapping it returns to the bottom',
      (tester) async {
        final messages = _many(40);
        final harness = ChatHarness(initial: chatState(messages));
        await harness.pump(tester, safeBottom: 34);
        await tester.drag(find.byType(ListView).first, const Offset(0, 600));
        await tester.pump();

        harness.setState(
          harness.state.copyWith(
            messages: [
              ...messages,
              msg(99, other, 'Coucou', at: today(23, 0)),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('1 nouveau message'), findsOneWidget);
        final pill = tester.getRect(find.byType(NewMessagesPill));
        final capsule = tester.getRect(find.byKey(MessageComposer.capsuleKey));
        expect(
          capsule.top - pill.bottom,
          greaterThanOrEqualTo(NewMessagesPill.gapAboveComposer),
        );

        await tester.tap(find.text('1 nouveau message'));
        await tester.pumpAndSettle();
        expect(find.text('Coucou'), findsOneWidget);
        expect(
          tester
              .widget<AnimatedOpacity>(
                find.descendant(
                  of: find.byType(NewMessagesPill),
                  matching: find.byType(AnimatedOpacity),
                ),
              )
              .opacity,
          0,
        );
      },
    );

    testWidgets('at the bottom, a new message needs no pill', (tester) async {
      final messages = _many(10);
      final harness = ChatHarness(initial: chatState(messages));
      await harness.pump(tester);
      harness.setState(
        harness.state.copyWith(
          messages: [
            ...messages,
            msg(99, other, 'Coucou', at: today(23, 0)),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Coucou'), findsOneWidget);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.descendant(
                of: find.byType(NewMessagesPill),
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .opacity,
        0,
      );
    });

    testWidgets('sending scrolls to the bottom even when scrolled up', (
      tester,
    ) async {
      final messages = _many(40);
      final harness = ChatHarness(initial: chatState(messages));
      await harness.pump(tester);
      await tester.drag(find.byType(ListView).first, const Offset(0, 600));
      await tester.pump();
      harness.setState(
        harness.state.copyWith(
          messages: [
            ...messages,
            msg(
              -1,
              me,
              'Mon envoi',
              status: MessageStatus.sending,
              clientId: 'c-mine',
              at: today(23, 0),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mon envoi'), findsOneWidget);
    });
  });

  group('design rules on screen', () {
    double luminance(Color c) => c.computeLuminance();
    double contrast(Color a, Color b) {
      final hi = luminance(a) > luminance(b) ? a : b, lo = hi == a ? b : a;
      return (luminance(hi) + 0.05) / (luminance(lo) + 0.05);
    }

    for (final brightness in Brightness.values) {
      testWidgets(
        'text on my bubble is readable in ${brightness.name} mode, from the colour scheme',
        (tester) async {
          final mine = msg(1, me, 'Shabbat shalom');
          await ChatHarness(
            initial: chatState([mine]),
          ).pump(tester, brightness: brightness);
          final scheme = Theme.of(
            tester.element(find.text('Shabbat shalom')),
          ).colorScheme;
          final box = tester.widget<Container>(bubbleOf(mine));
          final fill = (box.decoration! as BoxDecoration).color!;
          final ink = tester
              .widget<Text>(find.text('Shabbat shalom'))
              .style!
              .color!;
          expect(fill, scheme.primaryContainer);
          expect(ink, scheme.onPrimaryContainer);
          expect(contrast(fill, ink), greaterThanOrEqualTo(4.5));
        },
      );
    }

    testWidgets(
      'received bubble: mist with ink text; tail corner only on the last bubble',
      (tester) async {
        final a = msg(1, other, 'Premier', at: today(10, 0));
        final b = msg(2, other, 'Dernier', at: today(10, 1));
        await ChatHarness(initial: chatState([a, b])).pump(tester);
        BorderRadius radius(ChatMessage m) =>
            ((tester.widget<Container>(bubbleOf(m)).decoration!
                        as BoxDecoration)
                    .borderRadius!
                as BorderRadiusDirectional)
                .resolve(TextDirection.ltr);
        final first = radius(a), last = radius(b);
        expect(first.topLeft.x, 22);
        expect(first.bottomLeft.x, 8);
        expect(first.bottomRight.x, 22);
        expect(last.topLeft.x, 8);
        expect(last.bottomLeft.x, 6);
        expect(
          (tester.widget<Container>(bubbleOf(a)).decoration! as BoxDecoration)
              .color,
          AppColors.mist,
        );
      },
    );

    testWidgets('mine: the tail is bottom right', (tester) async {
      final a = msg(1, me, 'Seul');
      await ChatHarness(initial: chatState([a])).pump(tester);
      final r =
          ((tester.widget<Container>(bubbleOf(a)).decoration! as BoxDecoration)
                      .borderRadius!
                  as BorderRadiusDirectional)
              .resolve(TextDirection.ltr);
      expect(
        [r.topLeft.x, r.topRight.x, r.bottomLeft.x, r.bottomRight.x],
        [22, 22, 22, 6],
      );
    });

    testWidgets('the composer floats at least 12 px above the safe area', (
      tester,
    ) async {
      await ChatHarness(
        initial: chatState([msg(1, other, 'a')]),
      ).pump(tester, safeBottom: 34);
      final capsule = tester.getRect(find.byKey(MessageComposer.capsuleKey));
      expect(844 - 34 - capsule.bottom, greaterThanOrEqualTo(12));
      expect(capsule.height, greaterThanOrEqualTo(60));
    });
  });
}
