import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller.dart';
import 'package:mazl/presentation/features/chat/widgets/swipe_to_reply.dart';

import 'chat_test_support.dart';

const _barKey = ValueKey('reaction-bar');
const _menuKey = ValueKey('message-menu');

Future<void> _longPress(WidgetTester tester, ChatMessage m) async {
  await tester.longPress(bubbleOf(m));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadChatFonts);

  group('long press', () {
    testWidgets(
      'lifts the bubble: a reaction bar above it (the six emojis) and the menu below',
      (tester) async {
        final m = msg(5, other, 'Shabbat chez moi ?', at: today(10, 0));
        await ChatHarness(initial: chatState([m])).pump(tester);
        await _longPress(tester, m);

        // The lifted copy is the second one drawn (the overlay is on top).
        final lifted = tester.getRect(find.text('Shabbat chez moi ?').last);
        final bar = tester.getRect(find.byKey(_barKey));
        final menu = tester.getRect(find.byKey(_menuKey));
        expect(bar.bottom, lessThanOrEqualTo(lifted.top));
        expect(menu.top, greaterThanOrEqualTo(lifted.bottom));
        expect(menu.width, 220);
        expect(bar.height, 48);
        for (final emoji in allowedReactions) {
          expect(
            find.descendant(
              of: find.byKey(_barKey),
              matching: find.text(emoji),
            ),
            findsOneWidget,
          );
        }
        // The bubble is drawn a second time, in place, above the veil.
        expect(find.text('Shabbat chez moi ?'), findsNWidgets(2));
      },
    );

    testWidgets(
      'a received message offers Répondre, Copier, Signaler; no Retirer',
      (tester) async {
        final m = msg(5, other, 'Salut', at: today(10, 0));
        await ChatHarness(initial: chatState([m])).pump(tester);
        await _longPress(tester, m);
        expect(
          find.descendant(
            of: find.byKey(_menuKey),
            matching: find.text('Répondre'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(_menuKey),
            matching: find.text('Copier'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(_menuKey),
            matching: find.text('Signaler'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(_menuKey),
            matching: find.text('Retirer'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'my recent message offers Retirer; after 15 minutes it does not',
      (tester) async {
        final recent = msg(
          5,
          me,
          'Récent',
          at: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        final harness = ChatHarness(initial: chatState([recent]));
        await harness.pump(tester);
        await _longPress(tester, recent);
        expect(find.text('Retirer'), findsOneWidget);
        expect(find.text('Signaler'), findsNothing);
        await tester.tap(find.text('Retirer'));
        await tester.pumpAndSettle();
        expect(harness.actions.unsent, [5]);
      },
    );

    testWidgets('too old to be taken back', (tester) async {
      final old = msg(
        5,
        me,
        'Ancien',
        at: DateTime.now().subtract(const Duration(minutes: 16)),
      );
      await ChatHarness(initial: chatState([old])).pump(tester);
      await _longPress(tester, old);
      expect(find.text('Retirer'), findsNothing);
      expect(find.text('Répondre'), findsOneWidget);
    });

    testWidgets('tapping an emoji reacts with it and closes the menu', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      final harness = ChatHarness(initial: chatState([m]));
      await harness.pump(tester);
      await _longPress(tester, m);
      await tester.tap(
        find.descendant(of: find.byKey(_barKey), matching: find.text('😂')),
      );
      await tester.pumpAndSettle();
      expect(harness.actions.reactions, [(messageId: 5, emoji: '😂')]);
      expect(find.byKey(_barKey), findsNothing);
    });

    testWidgets('tapping the veil closes everything and does nothing', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      final harness = ChatHarness(initial: chatState([m]));
      await harness.pump(tester);
      await _longPress(tester, m);
      await tester.tapAt(const Offset(200, 780));
      await tester.pumpAndSettle();
      expect(find.byKey(_menuKey), findsNothing);
      expect(harness.actions.reactions, isEmpty);
    });

    testWidgets('Signaler asks for a reason, then reports the message', (
      tester,
    ) async {
      final m = msg(5, other, 'Envoyez-moi 200 euros', at: today(10, 0));
      final harness = ChatHarness(initial: chatState([m]));
      await harness.pump(tester);
      await _longPress(tester, m);
      await tester.tap(find.text('Signaler'));
      await tester.pumpAndSettle();
      expect(find.text('Signaler ce message'), findsOneWidget);
      await tester.tap(find.text('Arnaque ou demande d\'argent'));
      await tester.pumpAndSettle();
      expect(harness.actions.reported, [
        (id: 5, reason: 'Arnaque ou demande d\'argent'),
      ]);
    });

    testWidgets('Copier puts the text on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final m = msg(5, other, 'À copier', at: today(10, 0));
      await ChatHarness(initial: chatState([m])).pump(tester);
      await _longPress(tester, m);
      await tester.tap(find.text('Copier'));
      await tester.pumpAndSettle();
      expect(copied, 'À copier');
    });

    testWidgets(
      'a bubble near the bottom: the menu never goes under the system bar',
      (tester) async {
        final m = msg(5, other, 'Dernier message', at: today(10, 0));
        await ChatHarness(initial: chatState([m])).pump(tester, safeBottom: 34);
        await _longPress(tester, m);
        final menu = tester.getRect(find.byKey(_menuKey));
        final bar = tester.getRect(find.byKey(_barKey));
        expect(menu.bottom, lessThanOrEqualTo(844 - 34));
        expect(bar.top, greaterThanOrEqualTo(0));
      },
    );

    testWidgets('the overlay lives on the root navigator, above everything', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      await ChatHarness(initial: chatState([m])).pump(tester);
      await _longPress(tester, m);
      // Nothing of the screen answers a tap while the menu is up.
      expect(
        tester
            .getRect(find.byKey(_menuKey))
            .overlaps(tester.getRect(find.byType(Scaffold).first)),
        isTrue,
      );
      expect(find.byType(ModalBarrier), findsWidgets);
    });
  });

  group('double tap', () {
    testWidgets('toggles a heart and plays the pop', (tester) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      final harness = ChatHarness(initial: chatState([m]));
      await harness.pump(tester);
      await tester.tap(bubbleOf(m));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(bubbleOf(m));
      await tester.pump(const Duration(milliseconds: 100));
      expect(harness.actions.reactions, [(messageId: 5, emoji: '❤️')]);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets(
      'when I already hearted it, the double tap takes it back (no pop)',
      (tester) async {
        final m = msg(
          5,
          other,
          'Salut',
          at: today(10, 0),
          reactions: const [
            Reaction(emoji: '❤️', userIds: [me]),
          ],
        );
        final harness = ChatHarness(initial: chatState([m]));
        await harness.pump(tester);
        await tester.tap(bubbleOf(m));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(bubbleOf(m));
        await tester.pump(const Duration(milliseconds: 100));
        expect(harness.actions.reactions, [(messageId: 5, emoji: '❤️')]);
        expect(find.byIcon(Icons.favorite), findsNothing);
      },
    );
  });

  group('reactions under a bubble', () {
    testWidgets(
      'a pill with the emoji and the count; tapping lists who reacted',
      (tester) async {
        final m = msg(
          5,
          me,
          'Salut',
          at: today(10, 0),
          reactions: const [
            Reaction(emoji: '❤️', userIds: [other]),
            Reaction(emoji: '😂', userIds: [other, me]),
          ],
        );
        await ChatHarness(initial: chatState([m])).pump(tester);
        expect(find.text('❤️'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        // It bites into the bubble's bottom edge by 8 px.
        final pill = tester.getRect(find.text('❤️'));
        expect(
          pill.center.dy,
          greaterThan(rectOf(tester, bubbleOf(m)).bottom - 8),
        );

        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        expect(find.text('Réactions'), findsOneWidget);
        expect(find.text('Noémie'), findsWidgets);
        expect(find.text('Vous'), findsOneWidget);
      },
    );
  });

  group('swipe to reply', () {
    testWidgets(
      'past 64 px: the quote bar shows above the field and the next message carries replyToId',
      (tester) async {
        final m = msg(5, other, 'On se voit jeudi ?', at: today(10, 0));
        final harness = ChatHarness(initial: chatState([m]));
        await harness.pump(tester);

        await tester.drag(bubbleOf(m), const Offset(120, 0));
        await tester.pumpAndSettle();
        expect(find.text('Réponse à Noémie'), findsOneWidget);
        expect(find.text('On se voit jeudi ?'), findsNWidgets(2));

        await tester.enterText(find.byType(TextField), 'Oui, jeudi');
        await tester.pump();
        await tester.tap(find.bySemanticsLabel('Envoyer'));
        await tester.pump();
        expect(harness.actions.sentTexts, [(text: 'Oui, jeudi', replyToId: 5)]);
        expect(find.text('Réponse à Noémie'), findsNothing);
      },
    );

    testWidgets(
      'short of the threshold nothing happens and the bubble springs back',
      (tester) async {
        final m = msg(5, other, 'Salut', at: today(10, 0));
        await ChatHarness(initial: chatState([m])).pump(tester);
        final home = rectOf(tester, bubbleOf(m)).left;
        final gesture = await tester.startGesture(
          tester.getCenter(bubbleOf(m)),
        );
        await gesture.moveBy(const Offset(20, 0));
        await gesture.moveBy(const Offset(40, 0));
        await tester.pump();
        expect(rectOf(tester, bubbleOf(m)).left, greaterThan(home));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text('Réponse à Noémie'), findsNothing);
        expect(rectOf(tester, bubbleOf(m)).left, closeTo(home, 0.5));
      },
    );

    testWidgets('the row stops following the finger near the threshold', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      await ChatHarness(initial: chatState([m])).pump(tester);
      final home = rectOf(tester, bubbleOf(m)).left;
      final gesture = await tester.startGesture(tester.getCenter(bubbleOf(m)));
      await gesture.moveBy(const Offset(20, 0));
      await gesture.moveBy(const Offset(300, 0));
      await tester.pump();
      expect(
        rectOf(tester, bubbleOf(m)).left - home,
        lessThanOrEqualTo(SwipeToReply.threshold + 24),
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('Répondre in the menu does the same thing', (tester) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      await ChatHarness(initial: chatState([m])).pump(tester);
      await _longPress(tester, m);
      await tester.tap(find.text('Répondre'));
      await tester.pumpAndSettle();
      expect(find.text('Réponse à Noémie'), findsOneWidget);
    });

    testWidgets('the cross cancels the reply', (tester) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      final harness = ChatHarness(initial: chatState([m]));
      await harness.pump(tester);
      await _longPress(tester, m);
      await tester.tap(find.text('Répondre'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Annuler la réponse'));
      await tester.pumpAndSettle();
      expect(find.text('Réponse à Noémie'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Salut');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Envoyer'));
      await tester.pump();
      expect(harness.actions.sentTexts.single.replyToId, isNull);
    });
  });

  group('quote inside a bubble', () {
    testWidgets(
      'shows who and what; tapping it scrolls back to the original and highlights it',
      (tester) async {
        final messages = [
          for (var i = 1; i <= 40; i++)
            msg(
              i,
              i.isEven ? me : other,
              i == 40 ? 'La réponse' : 'Message numéro $i',
              at: today(8, 0).add(Duration(minutes: i * 10)),
              replyTo: i == 40
                  ? const ReplyRef(
                      id: 3,
                      senderId: other,
                      type: ChatMessageType.text,
                      preview: 'Message numéro 3',
                    )
                  : null,
            ),
        ];
        await ChatHarness(initial: chatState(messages)).pump(tester);
        expect(find.text('Noémie'), findsWidgets);
        final original = messages[2];
        final quote = find.descendant(
          of: bubbleOf(messages.last),
          matching: find.text('Message numéro 3'),
        );
        expect(quote, findsOneWidget);
        expect(
          bubbleOf(original),
          findsNothing,
          reason: 'the original is far off screen, not even built',
        );

        await tester.tap(quote);
        Finder? row;
        var highlighted = false;
        for (var i = 0; i < 40 && !highlighted; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (bubbleOf(original).evaluate().isEmpty) continue;
          row = find
              .ancestor(
                of: bubbleOf(original),
                matching: find.byType(AnimatedContainer),
              )
              .first;
          highlighted =
              ((tester.widget<AnimatedContainer>(row).decoration!
                          as BoxDecoration)
                      .color
                      ?.a ??
                  0) >
              0;
        }
        expect(
          highlighted,
          isTrue,
          reason: 'the original is highlighted once reached',
        );
        final rect = rectOf(tester, bubbleOf(original));
        expect(rect.top, inInclusiveRange(0, 844));
        expect(rect.bottom, lessThan(844));
        Color? fill() =>
            (tester.widget<AnimatedContainer>(row!).decoration!
                    as BoxDecoration)
                .color;
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(fill()!.a, 0);
      },
    );
  });
}
