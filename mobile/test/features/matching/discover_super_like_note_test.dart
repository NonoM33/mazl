import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/motion/reduce_motion_scope.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/matching/screens/discover_screen.dart';
import 'package:mazl/presentation/features/matching/widgets/discover_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_helpers.dart';
import '../../helpers/swipe_gestures.dart';
import '../../mocks/fake_discover_api.dart';
import '../../support/credits_fakes.dart';

// Super Like with a word (docs/premium/MONETISATION.md §5): the sheet that
// opens when a Super Like leaves is optional (« Envoyer sans mot »), limited to
// 140 characters, and cancelling it keeps the card and spends nothing.

const _title = 'Un mot avec votre Super Like ?';
const _withWord = 'Envoyer avec ce mot';
const _withoutWord = 'Envoyer sans mot';

Finder _card(int userId) => find.byWidgetPredicate(
  (w) => w is DiscoverCard && w.profile.userId == userId,
);

Finder get _field => find.byKey(const ValueKey('super-like-note-field'));

void _expectAtRest(WidgetTester tester, Finder card) {
  final rest =
      tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;
  expect(card, findsOneWidget);
  expect((tester.getCenter(card).dx - rest).abs(), lessThan(1));
}

Future<FakeDiscoverApi> _pump(
  WidgetTester tester, {
  int superLikes = 1,
  void Function(FakeDiscoverApi api)? configure,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final api = FakeDiscoverApi(discoverProfiles(3), superLikes: superLikes);
  configure?.call(api);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      theme: AppTheme.lightTheme,
      builder: (context, child) => ReduceMotionScope(child: child!),
      home: DiscoverScreen(
        apiService: api,
        likeAllowanceApi: FakeLikeAllowanceApi.free(remaining: 50),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return api;
}

Future<void> _throwUp(WidgetTester tester) async {
  await dragSlowly(tester, _card(101), const Offset(0, -360));
  await settle(tester);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
    PremiumGate.debugPremiumOverride = false;
    installTestCredits().applyFromServer(
      serverCredits(
        superLikeAllowance: 1,
        superLikeRemaining: 1,
        superLikePurchased: 0,
        boostAllowance: 0,
        boostRemaining: 0,
        boostPurchased: 0,
      ),
    );
  });

  testWidgets('throwing a Super Like asks for a word, and the card waits', (
    tester,
  ) async {
    final api = await _pump(tester);

    await _throwUp(tester);

    expect(find.text(_title), findsOneWidget);
    expect(find.text(_withWord), findsOneWidget);
    expect(find.text(_withoutWord), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(api.swipes, isEmpty, reason: 'nothing leaves before the choice');
    _expectAtRest(tester, _card(101));
  });

  testWidgets('a word is sent with the Super Like, trimmed', (tester) async {
    final api = await _pump(tester);
    await _throwUp(tester);

    await tester.enterText(_field, '  Votre sourire au kiddouch.  ');
    await tester.pump();
    await tester.tap(find.text(_withWord));
    await settle(tester);

    expect(api.swipes, ['101:super_like']);
    expect(api.swipeNotes, ['Votre sourire au kiddouch.']);
    expect(_card(101), findsNothing);
    expect(PremiumGate.remainingSuperLikes, 0);
  });

  testWidgets('« Envoyer sans mot » sends the Super Like with no note', (
    tester,
  ) async {
    final api = await _pump(tester);
    await _throwUp(tester);

    await tester.tap(find.text(_withoutWord));
    await settle(tester);

    expect(api.swipes, ['101:super_like']);
    expect(api.swipeNotes, [null]);
    expect(_card(101), findsNothing);
  });

  testWidgets('without mot even after typing one: sending without keeps the '
      'Super Like free of any note', (tester) async {
    final api = await _pump(tester);
    await _throwUp(tester);

    await tester.enterText(_field, 'Un mot que je regrette');
    await tester.pump();
    await tester.tap(find.text(_withoutWord));
    await settle(tester);

    expect(api.swipeNotes, [null]);
  });

  testWidgets('an empty or blank word cannot be sent as a word', (
    tester,
  ) async {
    await _pump(tester);
    await _throwUp(tester);

    FilledButton button() =>
        tester.widget(find.byKey(const ValueKey('super-like-note-send')));
    expect(button().onPressed, isNull);

    await tester.enterText(_field, '     ');
    await tester.pump();
    expect(button().onPressed, isNull);

    await tester.enterText(_field, 'a');
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });

  testWidgets('the counter follows the field and stops at 140', (tester) async {
    final api = await _pump(tester);
    await _throwUp(tester);

    expect(find.text('0/140'), findsOneWidget);
    await tester.enterText(_field, 'Shalom');
    await tester.pump();
    expect(find.text('6/140'), findsOneWidget);

    await tester.enterText(_field, 'x' * 200);
    await tester.pump();
    expect(find.text('140/140'), findsOneWidget);
    expect(tester.widget<TextField>(_field).controller!.text.length, 140);

    await tester.tap(find.text(_withWord));
    await settle(tester);
    expect(api.swipeNotes.single, 'x' * 140);
  });

  testWidgets('« Annuler » keeps the card, sends nothing, spends nothing and '
      'opens no purchase sheet', (tester) async {
    final api = await _pump(tester);
    await _throwUp(tester);

    await tester.tap(find.text('Annuler'));
    await settle(tester);

    expect(api.swipes, isEmpty);
    _expectAtRest(tester, _card(101));
    expect(PremiumGate.remainingSuperLikes, 1);
    expect(find.text('Vous n’avez plus de Super Likes.'), findsNothing);
    expect(find.text(_title), findsNothing);
  });

  testWidgets('closing the sheet by its backdrop is the same as cancelling', (
    tester,
  ) async {
    final api = await _pump(tester);
    await _throwUp(tester);

    await tester.tapAt(const Offset(195, 40));
    await settle(tester);

    expect(find.text(_title), findsNothing);
    expect(api.swipes, isEmpty);
    _expectAtRest(tester, _card(101));
  });

  testWidgets('after a cancel the same Super Like can be thrown again', (
    tester,
  ) async {
    final api = await _pump(tester);
    await _throwUp(tester);
    await tester.tap(find.text('Annuler'));
    await settle(tester);

    await _throwUp(tester);
    expect(find.text(_title), findsOneWidget);
    await tester.tap(find.text(_withoutWord));
    await settle(tester);

    expect(api.swipes, ['101:super_like']);
  });

  testWidgets('the Super Like button asks for the word too', (tester) async {
    final semantics = tester.ensureSemantics();
    final api = await _pump(tester);

    await tester.tap(find.bySemanticsLabel('Super like').first);
    await settle(tester);

    expect(find.text(_title), findsOneWidget);
    expect(api.swipes, isEmpty);
    semantics.dispose();
  });

  testWidgets('a like and a pass never ask for a word', (tester) async {
    final api = await _pump(tester);

    await dragSlowly(tester, _card(101), const Offset(180, 0));
    await settle(tester);
    await dragSlowly(tester, _card(102), const Offset(-180, 0));
    await settle(tester);

    expect(find.text(_title), findsNothing);
    expect(api.swipes, ['101:like', '102:pass']);
    expect(api.swipeNotes, [null, null]);
  });

  testWidgets('no Super Like left: the packs sheet opens, not the word sheet', (
    tester,
  ) async {
    await _pump(tester, superLikes: 0);
    installTestCredits().applyFromServer(
      serverCredits(
        superLikeAllowance: 1,
        superLikeRemaining: 0,
        superLikePurchased: 0,
        boostAllowance: 0,
        boostRemaining: 0,
        boostPurchased: 0,
      ),
    );

    await _throwUp(tester);

    expect(find.text(_title), findsNothing);
    expect(find.text('Vous n’avez plus de Super Likes.'), findsWidgets);
  });

  testWidgets('the server refuses the word (400 invalid_note): the card comes '
      'back, nothing is spent, and the member is told', (tester) async {
    final api = await _pump(tester, configure: (api) => api.refuseNote = true);
    await _throwUp(tester);

    await tester.enterText(_field, 'Écrivez-moi sur example.com');
    await tester.pump();
    await tester.tap(find.text(_withWord));
    await settle(tester);
    await settle(tester);

    expect(api.refusedNotes, ['101:super_like']);
    expect(api.swipes, isEmpty);
    _expectAtRest(tester, _card(101));
    expect(PremiumGate.remainingSuperLikes, 1);
    expect(find.textContaining("Ce mot n'a pas été accepté"), findsOneWidget);
  });
}
