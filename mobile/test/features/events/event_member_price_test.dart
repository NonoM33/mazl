import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/event.dart';
import 'package:mazl/presentation/features/events/l10n/event_texts.dart';
import 'package:mazl/presentation/features/events/widgets/event_member_price.dart';

import '../../helpers/l10n_helpers.dart';

// docs/premium/MONETISATION.md §10: a paying event shows the mazl+ rate next
// to the price. A member without mazl+ sees a sober « mazl+ : 8 € » line that
// opens the offer; a subscriber sees « Tarif membre : 8 € » first and the
// regular price struck through.

Event _event({
  double price = 25,
  int? memberPriceCents = 800,
  String currency = 'EUR',
}) => Event(
  id: 1,
  title: 'Dîner',
  date: DateTime(2026, 11, 20),
  price: price,
  currency: currency,
  memberPriceCents: memberPriceCents,
);

Future<void> _pump(
  WidgetTester tester,
  Event event, {
  required bool subscriber,
  VoidCallback? onOffer,
  Locale locale = kTestLocale,
  Brightness brightness = Brightness.light,
}) => pumpLocalized(
  tester,
  Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: EventMemberPrice(
        event: event,
        subscriber: subscriber,
        onOffer: onOffer ?? () {},
      ),
    ),
  ),
  locale: locale,
  brightness: brightness,
);

/// « 8 € »: the amount, then the currency, whatever space the locale puts.
Finder _text(String pattern) => find.byWidgetPredicate(
  (w) => w is Text && RegExp(pattern).hasMatch(w.data ?? ''),
);

void main() {
  group('who sees what', () {
    testWidgets('a member without mazl+ sees « mazl+ : 8 € »', (tester) async {
      await _pump(tester, _event(), subscriber: false);
      expect(_text(r'^mazl\+ : 8\s€$'), findsOneWidget);
      expect(find.textContaining('Tarif membre'), findsNothing);
    });

    testWidgets(
      'a subscriber sees « Tarif membre : 8 € » and the regular price struck',
      (tester) async {
        await _pump(tester, _event(), subscriber: true);
        expect(_text(r'^Tarif membre : 8\s€$'), findsOneWidget);
        final regular = tester.widget<Text>(_text(r'^25\s€$'));
        expect(regular.style?.decoration, TextDecoration.lineThrough);
      },
    );

    testWidgets('the member price is the stronger text for a subscriber', (
      tester,
    ) async {
      await _pump(tester, _event(), subscriber: true);
      final member = tester.widget<Text>(_text(r'^Tarif membre'));
      final regular = tester.widget<Text>(_text(r'^25\s€$'));
      expect(member.style!.fontWeight, FontWeight.bold);
      expect(
        member.style!.fontSize!,
        greaterThanOrEqualTo(regular.style!.fontSize!),
      );
    });

    testWidgets('no member price: nothing at all', (tester) async {
      await _pump(tester, _event(memberPriceCents: null), subscriber: false);
      expect(find.byType(Text), findsNothing);
      await _pump(tester, _event(memberPriceCents: null), subscriber: true);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('a free event has no member price to show', (tester) async {
      await _pump(tester, _event(price: 0), subscriber: true);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('a member price that is not lower is not a reduction', (
      tester,
    ) async {
      await _pump(tester, _event(memberPriceCents: 2500), subscriber: false);
      expect(find.byType(Text), findsNothing);
      await _pump(tester, _event(memberPriceCents: 3000), subscriber: true);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('free for members is said « Gratuit »', (tester) async {
      await _pump(tester, _event(memberPriceCents: 0), subscriber: true);
      expect(find.text('Tarif membre : Gratuit'), findsOneWidget);
      await _pump(tester, _event(memberPriceCents: 0), subscriber: false);
      expect(find.text('mazl+ : Gratuit'), findsOneWidget);
    });
  });

  group('the amount', () {
    testWidgets('cents show only when there are some', (tester) async {
      await _pump(tester, _event(memberPriceCents: 850), subscriber: true);
      expect(_text(r'^Tarif membre : 8,50\s€$'), findsOneWidget);
    });

    testWidgets('the event currency is used, not euros', (tester) async {
      await _pump(
        tester,
        _event(currency: 'USD', memberPriceCents: 1000),
        subscriber: false,
        locale: const Locale('en'),
      );
      expect(find.text(r'mazl+: $10'), findsOneWidget);
    });

    test('eventMemberPriceText is null without a real reduction', () {
      expect(
        eventMemberPriceText(_event(memberPriceCents: null), 'fr'),
        isNull,
      );
      expect(eventMemberPriceText(_event(price: 0), 'fr'), isNull);
      expect(
        eventMemberPriceText(_event(memberPriceCents: 2500), 'fr'),
        isNull,
      );
      expect(eventMemberPriceText(_event(), 'fr'), matches(r'^8\s€$'));
    });
  });

  group('the offer', () {
    testWidgets('a tap on the mazl+ line opens the offer', (tester) async {
      var opened = 0;
      await _pump(tester, _event(), subscriber: false, onOffer: () => opened++);
      await tester.tap(_text(r'^mazl\+'));
      expect(opened, 1);
    });

    testWidgets(
      'the line is a 44 pt target all along its width, also near the edge',
      (tester) async {
        var opened = 0;
        await _pump(
          tester,
          _event(),
          subscriber: false,
          onOffer: () => opened++,
        );
        final rect = tester.getRect(find.byType(InkWell));
        expect(rect.height, greaterThanOrEqualTo(44));
        expect(rect.width, greaterThanOrEqualTo(44));
        await tester.tapAt(rect.topLeft + const Offset(2, 2));
        await tester.tapAt(rect.bottomRight - const Offset(2, 2));
        expect(opened, 2);
      },
    );

    testWidgets('a subscriber has nothing to tap', (tester) async {
      await _pump(tester, _event(), subscriber: true);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('VoiceOver says what the line leads to', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _event(), subscriber: false);
      expect(
        find.bySemanticsLabel(
          RegExp(r"^Avec mazl\+, cet événement coûte 8\s€\. Voir l'offre\.$"),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('every language, light and dark, on a small phone', () {
    for (final brightness in Brightness.values) {
      for (final code in ['fr', 'en', 'es', 'ru', 'he']) {
        for (final subscriber in [false, true]) {
          testWidgets('$code ${brightness.name} subscriber=$subscriber', (
            tester,
          ) async {
            await _pump(
              tester,
              _event(),
              subscriber: subscriber,
              locale: Locale(code),
              brightness: brightness,
            );
            expect(tester.takeException(), isNull);
            expect(find.byType(EventMemberPrice), findsOneWidget);
          });
        }
      }
    }
  });
}
