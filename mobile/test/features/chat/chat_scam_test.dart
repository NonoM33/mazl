import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/chat/widgets/scam_warning_card.dart';

import 'chat_test_support.dart';

void main() {
  setUpAll(loadChatFonts);

  group('built-in rules', () {
    testWidgets(
      'a received message asking for a gift card gets the warning card under it',
      (tester) async {
        await ChatHarness(
          initial: chatState([
            msg(1, other, 'Bonjour, comment allez-vous ?', at: today(10, 0)),
            msg(
              2,
              other,
              'Pouvez-vous m\'envoyer une carte cadeau ?',
              at: today(10, 5),
            ),
          ]),
        ).pump(tester);
        expect(find.byType(ScamWarningCard), findsNWidgets(2));
        expect(find.text('Restez prudent'), findsOneWidget);
        expect(
          find.text(
            "Ne transférez jamais d'argent à quelqu'un que vous n'avez pas rencontré.",
          ),
          findsOneWidget,
        );
        final card = tester.getRect(find.text('Restez prudent'));
        expect(
          card.top,
          greaterThan(
            tester
                .getRect(find.text('Pouvez-vous m\'envoyer une carte cadeau ?'))
                .bottom,
          ),
        );
      },
    );

    testWidgets('my own message with the same words is not flagged', (
      tester,
    ) async {
      await ChatHarness(
        initial: chatState([
          msg(
            1,
            me,
            'Je n\'enverrai jamais de carte cadeau.',
            at: today(10, 0),
          ),
        ]),
      ).pump(tester);
      expect(find.text('Restez prudent'), findsNothing);
    });

    testWidgets('an ordinary message is not flagged', (tester) async {
      await ChatHarness(
        initial: chatState([
          msg(1, other, 'On se voit jeudi ?', at: today(10, 0)),
        ]),
      ).pump(tester);
      expect(find.text('Restez prudent'), findsNothing);
    });

    testWidgets('moving to WhatsApp early in the conversation is flagged', (
      tester,
    ) async {
      await ChatHarness(
        initial: chatState([
          msg(
            1,
            other,
            'Passons sur WhatsApp, c\'est plus simple',
            at: today(10, 0),
          ),
        ]),
      ).pump(tester);
      expect(find.text('Restez prudent'), findsOneWidget);
    });

    testWidgets(
      '« Signaler » on the card asks for a reason and reports that message',
      (tester) async {
        final harness = ChatHarness(
          initial: chatState([
            msg(7, other, 'Envoyez des bitcoins', at: today(10, 0)),
          ]),
        );
        await harness.pump(tester);
        await tester.tap(find.text('Signaler'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Arnaque ou demande d\'argent'));
        await tester.pumpAndSettle();
        expect(harness.actions.reported.single.id, 7);
      },
    );

    testWidgets('« En savoir plus » opens advice in a sheet', (tester) async {
      await ChatHarness(
        initial: chatState([
          msg(7, other, 'Envoyez des bitcoins', at: today(10, 0)),
        ]),
      ).pump(tester);
      await tester.tap(find.text('En savoir plus'));
      await tester.pumpAndSettle();
      expect(find.text('Se protéger des arnaques'), findsOneWidget);
    });
  });

  group('the card itself', () {
    testWidgets('show: false draws nothing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ScamWarningCard(show: false, onReport: () {})),
      );
      expect(find.byType(Container), findsNothing);
    });

    testWidgets(
      'spans the width minus 32 px, with 44 px touch targets for its links',
      (tester) async {
        await ChatHarness(
          initial: chatState([msg(7, other, 'carte cadeau', at: today(10, 0))]),
        ).pump(tester);
        final card = tester.getRect(find.byType(ScamWarningCard));
        expect(card.width, 390 - 32);
        expect(
          tester
              .getSize(
                find
                    .ancestor(
                      of: find.text('Signaler'),
                      matching: find.byType(InkWell),
                    )
                    .first,
              )
              .height,
          greaterThanOrEqualTo(44),
        );
      },
    );
  });
}
