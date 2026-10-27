import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/premium/purchase_moments.dart';
import 'package:mazl/core/premium/swipe_undo_api.dart';
import 'package:mazl/core/motion/reduce_motion_scope.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/l10n/generated/app_localizations_fr.dart';
import 'package:mazl/presentation/features/matching/screens/discover_screen.dart';
import 'package:mazl/presentation/features/matching/widgets/discover_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_helpers.dart';
import '../../helpers/swipe_gestures.dart';
import '../../mocks/fake_discover_api.dart';
import '../../support/credits_fakes.dart';
import '../../support/premium_fakes.dart';

// « Retour arrière » (docs/premium/MONETISATION.md §7): the button takes the
// last pass or like back through POST /api/swipes/undo. The SERVER decides:
// the card only comes back after it said yes (or when it never recorded the
// choice), and the deck is never left different from the server.

const _undoLabel = 'Annuler le dernier choix';

Finder _card(int userId) => find.byWidgetPredicate(
  (w) => w is DiscoverCard && w.profile.userId == userId,
);

double _restX(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;

void _expectAtRest(WidgetTester tester, Finder card) {
  expect(card, findsOneWidget);
  expect((tester.getCenter(card).dx - _restX(tester)).abs(), lessThan(1));
}

UndoneSwipe _undone(int user, String action) =>
    UndoneSwipe(targetUserId: user, action: action, remainingFreeUndos: 0);

class _Setup {
  _Setup(this.api, this.undo, this.offers);

  final FakeDiscoverApi api;
  final FakeSwipeUndoApi undo;
  final List<PurchaseMoment> offers;
}

Future<_Setup> _pump(
  WidgetTester tester, {
  FakeSwipeUndoApi? undo,
  bool offerShown = true,
  void Function(FakeDiscoverApi api)? configure,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final api = FakeDiscoverApi(discoverProfiles(4));
  configure?.call(api);
  final fakeUndo = undo ?? FakeSwipeUndoApi(answer: _undone(101, 'pass'));
  final offers = <PurchaseMoment>[];
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
        swipeUndoApi: fakeUndo,
        offerPlus: (context, moment) async {
          offers.add(moment);
          return offerShown;
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return _Setup(api, fakeUndo, offers);
}

Future<void> _pass(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Passer').first);
  await tester.pump();
  await settle(tester);
}

Future<void> _like(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel("J'aime").first);
  await tester.pump();
  await settle(tester);
}

Future<void> _tapUndo(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel(_undoLabel).first);
  await tester.pump();
  await settle(tester);
}

void main() {
  late SemanticsHandle semantics;

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

  testWidgets('the undo button is on the card', (tester) async {
    semantics = tester.ensureSemantics();
    await _pump(tester);
    expect(find.bySemanticsLabel(_undoLabel), findsWidgets);
    semantics.dispose();
  });

  testWidgets('a pass is taken back: the server agrees, the card returns', (
    tester,
  ) async {
    semantics = tester.ensureSemantics();
    final s = await _pump(tester);
    await _pass(tester);
    expect(_card(101), findsNothing);

    await _tapUndo(tester);

    expect(s.undo.calls, 1);
    _expectAtRest(tester, _card(101));
    semantics.dispose();
  });

  testWidgets('a like is taken back the same way', (tester) async {
    semantics = tester.ensureSemantics();
    final s = await _pump(
      tester,
      undo: FakeSwipeUndoApi(answer: _undone(101, 'like')),
    );
    await _like(tester);
    expect(_card(101), findsNothing);

    await _tapUndo(tester);

    expect(s.undo.calls, 1);
    _expectAtRest(tester, _card(101));
    semantics.dispose();
  });

  testWidgets('nothing thrown yet: no call, and the member is told', (
    tester,
  ) async {
    semantics = tester.ensureSemantics();
    final s = await _pump(tester);

    await _tapUndo(tester);

    expect(s.undo.calls, 0);
    expect(find.text('Rien à annuler pour le moment.'), findsOneWidget);
    _expectAtRest(tester, _card(101));
    semantics.dispose();
  });

  testWidgets('402 undo_limit_reached: the card does NOT return and the '
      'undo-refused offer opens', (tester) async {
    semantics = tester.ensureSemantics();
    final s = await _pump(
      tester,
      undo: FakeSwipeUndoApi()
        ..failure = const SwipeUndoException(
          SwipeUndoErrorKind.limitReached,
          status: 402,
        ),
    );
    await _pass(tester);

    await _tapUndo(tester);

    expect(s.undo.calls, 1);
    expect(_card(101), findsNothing, reason: 'the server said no');
    _expectAtRest(tester, _card(102));
    expect(s.offers, [PurchaseMoment.undoRefused]);
    expect(find.byType(SnackBar), findsNothing);
    semantics.dispose();
  });

  testWidgets('402 when the offer was already shown today: the member is told '
      'why nothing moved', (tester) async {
    semantics = tester.ensureSemantics();
    final s = await _pump(
      tester,
      offerShown: false,
      undo: FakeSwipeUndoApi()
        ..failure = const SwipeUndoException(SwipeUndoErrorKind.limitReached),
    );
    await _pass(tester);

    await _tapUndo(tester);

    expect(s.offers, [PurchaseMoment.undoRefused]);
    expect(
      find.text(
        'Votre retour arrière gratuit du jour est utilisé. '
        'Avec mazl+, il est illimité.',
      ),
      findsOneWidget,
    );
    expect(_card(101), findsNothing);
    semantics.dispose();
  });

  testWidgets('404 nothing_to_undo: a message, the deck is unchanged', (
    tester,
  ) async {
    semantics = tester.ensureSemantics();
    await _pump(
      tester,
      undo: FakeSwipeUndoApi()
        ..failure = const SwipeUndoException(SwipeUndoErrorKind.nothingToUndo),
    );
    await _pass(tester);

    await _tapUndo(tester);

    expect(find.text('Rien à annuler pour le moment.'), findsOneWidget);
    expect(_card(101), findsNothing);
    _expectAtRest(tester, _card(102));
    semantics.dispose();
  });

  testWidgets('409 undo_not_possible: a message, the deck is unchanged', (
    tester,
  ) async {
    semantics = tester.ensureSemantics();
    await _pump(
      tester,
      undo: FakeSwipeUndoApi()
        ..failure = const SwipeUndoException(SwipeUndoErrorKind.notPossible),
    );
    await _pass(tester);

    await _tapUndo(tester);

    expect(
      find.textContaining('Ce choix ne peut pas être annulé'),
      findsOneWidget,
    );
    expect(_card(101), findsNothing);
    semantics.dispose();
  });

  for (final (kind, text) in [
    (SwipeUndoErrorKind.network, AppLocalizationsFr().errorNetwork),
    (SwipeUndoErrorKind.timeout, AppLocalizationsFr().errorTimeout),
    (SwipeUndoErrorKind.server, AppLocalizationsFr().errorServer),
    (
      SwipeUndoErrorKind.sessionExpired,
      AppLocalizationsFr().errorSessionExpired,
    ),
    (SwipeUndoErrorKind.unknown, "Impossible d'annuler pour le moment."),
  ]) {
    testWidgets('${kind.name}: the card stays gone and the member is told', (
      tester,
    ) async {
      semantics = tester.ensureSemantics();
      await _pump(
        tester,
        undo: FakeSwipeUndoApi()..failure = SwipeUndoException(kind),
      );
      await _pass(tester);

      await _tapUndo(tester);

      expect(find.text(text), findsOneWidget);
      expect(_card(101), findsNothing);
      semantics.dispose();
    });
  }

  testWidgets('the server is asked only after the swipe it takes back has '
      'been recorded', (tester) async {
    semantics = tester.ensureSemantics();
    final hold = Completer<void>();
    final s = await _pump(
      tester,
      undo: FakeSwipeUndoApi(answer: _undone(101, 'like')),
      configure: (api) => api.holdLikes = hold,
    );
    await tester.tap(find.bySemanticsLabel("J'aime").first);
    await tester.pump();
    await settle(tester);
    expect(_card(101), findsNothing);

    await tester.tap(find.bySemanticsLabel(_undoLabel).first);
    await tester.pump();
    await settle(tester);
    expect(s.undo.calls, 0, reason: 'the like is still on its way');
    expect(_card(101), findsNothing);

    hold.complete();
    await settle(tester);
    await settle(tester);

    expect(s.undo.calls, 1);
    _expectAtRest(tester, _card(101));
    semantics.dispose();
  });

  testWidgets('a choice the server never received comes back without asking '
      'it', (tester) async {
    semantics = tester.ensureSemantics();
    final s = await _pump(tester, configure: (api) => api.swipesFail = true);
    await _pass(tester);
    expect(_card(101), findsNothing);

    await _tapUndo(tester);

    expect(s.undo.calls, 0);
    _expectAtRest(tester, _card(101));
    semantics.dispose();
  });

  testWidgets('a second tap while the server answers sends nothing more', (
    tester,
  ) async {
    semantics = tester.ensureSemantics();
    final hold = Completer<void>();
    final s = await _pump(
      tester,
      undo: FakeSwipeUndoApi(answer: _undone(101, 'pass'))..hold = hold,
    );
    await _pass(tester);

    await tester.tap(find.bySemanticsLabel(_undoLabel).first);
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(_undoLabel).first);
    await tester.pump();
    expect(s.undo.calls, 1);

    hold.complete();
    await settle(tester);
    _expectAtRest(tester, _card(101));
    semantics.dispose();
  });

  testWidgets('two choices are taken back one after the other, last first', (
    tester,
  ) async {
    semantics = tester.ensureSemantics();
    final s = await _pump(
      tester,
      undo: FakeSwipeUndoApi(answer: _undone(102, 'pass')),
    );
    await _pass(tester);
    await _pass(tester);
    _expectAtRest(tester, _card(103));

    await _tapUndo(tester);
    _expectAtRest(tester, _card(102));
    s.undo.answer = _undone(101, 'pass');
    await _tapUndo(tester);

    _expectAtRest(tester, _card(101));
    expect(s.undo.calls, 2);
    semantics.dispose();
  });

  testWidgets('a card that came back can be thrown again', (tester) async {
    semantics = tester.ensureSemantics();
    final s = await _pump(tester);
    await _pass(tester);
    await _tapUndo(tester);

    await _like(tester);

    expect(s.api.swipes, ['101:pass', '101:like']);
    expect(_card(101), findsNothing);
    semantics.dispose();
  });

  testWidgets('a Super Like is not taken back: the server says 409', (
    tester,
  ) async {
    semantics = tester.ensureSemantics();
    final s = await _pump(
      tester,
      undo: FakeSwipeUndoApi()
        ..failure = const SwipeUndoException(SwipeUndoErrorKind.notPossible),
    );
    await dragSlowly(tester, _card(101), const Offset(0, -360));
    await settle(tester);
    await tester.tap(find.text('Envoyer sans mot'));
    await settle(tester);
    expect(s.api.swipes, ['101:super_like']);

    await _tapUndo(tester);

    expect(s.undo.calls, 1);
    expect(_card(101), findsNothing);
    semantics.dispose();
  });
}
