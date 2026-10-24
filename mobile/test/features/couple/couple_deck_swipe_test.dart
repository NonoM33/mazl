import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/swipe_deck/swipe_intent_discs.dart';
import 'package:mazl/presentation/features/couple/screens/couple_activities_feed_screen.dart';

import '../../helpers/swipe_gestures.dart';
import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../../helpers/l10n_helpers.dart';

const _feed = 'GET /api/couple/activities?limit=50&offset=0';

Future<FakeCoupleTransport> _pumpDeck(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final transport = FakeCoupleTransport()
    ..reply(
      _feed,
      ok({
        'activities': [
          activityRow(id: 1, title: 'Atelier poterie'),
          activityRow(id: 2, title: 'Cours de cuisine'),
        ],
      }),
    )
    ..reply('POST /api/couple/activities/1/pass', ok({}))
    ..reply('POST /api/couple/activities/1/save', ok({}));
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      theme: AppTheme.lightTheme,
      home: CoupleActivitiesFeedScreen(
        apiService: CoupleApiService(transport: transport),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return transport;
}

final _top = find.text('Atelier poterie');

List<String> _swipeCalls(FakeCoupleTransport t) =>
    t.calls.where((c) => c.startsWith('POST')).toList();

void main() {
  testWidgets('a swipe to the left passes the activity', (tester) async {
    final transport = await _pumpDeck(tester);

    await dragSlowly(tester, _top, const Offset(-200, 0));
    await settle(tester);

    expect(_swipeCalls(transport), ['POST /api/couple/activities/1/pass']);
    expect(_top, findsNothing);
    expect(find.text('Cours de cuisine'), findsOneWidget);
  });

  testWidgets('a swipe up saves the activity and says so', (tester) async {
    final transport = await _pumpDeck(tester);

    await dragSlowly(tester, _top, const Offset(0, -260));
    await settle(tester);

    expect(_swipeCalls(transport), ['POST /api/couple/activities/1/save']);
    expect(find.text('Atelier poterie sauvegardé'), findsOneWidget);
    expect(find.text('Cours de cuisine'), findsOneWidget);
  });

  testWidgets('a swipe to the right does not consume the card', (tester) async {
    final transport = await _pumpDeck(tester);
    final rest = tester.getCenter(_top);

    await dragSlowly(tester, _top, const Offset(300, 0));
    await settle(tester);

    expect(_swipeCalls(transport), isEmpty);
    expect(tester.getCenter(_top), rest);
  });

  testWidgets('a swipe down does not consume the card', (tester) async {
    final transport = await _pumpDeck(tester);
    final rest = tester.getCenter(_top);

    await dragSlowly(tester, _top, const Offset(0, 300));
    await settle(tester);

    expect(_swipeCalls(transport), isEmpty);
    expect(tester.getCenter(_top), rest);
  });

  testWidgets('a fast flick to the right is not a pass either', (tester) async {
    final transport = await _pumpDeck(tester);

    await flick(tester, _top, const Offset(80, 0), 40);
    await settle(tester);

    expect(_swipeCalls(transport), isEmpty);
    expect(_top, findsOneWidget);
  });

  testWidgets('the cross disc shows going left, the bookmark disc going up', (
    tester,
  ) async {
    await _pumpDeck(tester);

    final left = await holdDrag(tester, _top, const Offset(-80, 0));
    expect(_discOpacity(tester, LucideIcons.x), greaterThan(0.3));
    expect(_discOpacity(tester, LucideIcons.bookmark), 0);
    await left.up();
    await settle(tester);

    final up = await holdDrag(tester, _top, const Offset(0, -60));
    expect(_discOpacity(tester, LucideIcons.bookmark), greaterThan(0.3));
    await up.up();
    await settle(tester);
  });

  testWidgets('the bookmark button throws the card up', (tester) async {
    final transport = await _pumpDeck(tester);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Enregistrer',
      ),
    );
    await settle(tester);

    expect(_swipeCalls(transport), ['POST /api/couple/activities/1/save']);
  });
}

/// The opacity of the intent disc that holds [icon]: the round buttons and the
/// card carry the same icons.
double _discOpacity(WidgetTester tester, IconData icon) {
  final disc = find.descendant(
    of: find.byType(SwipeIntentDiscs),
    matching: find.byIcon(icon),
  );
  return tester
      .widget<Opacity>(
        find.ancestor(of: disc, matching: find.byType(Opacity)).first,
      )
      .opacity;
}
