import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/likes/like_allowance_api.dart';
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

// Le SERVEUR compte les likes du jour (GET /api/likes/allowance, 402
// `likes_exhausted` sur POST /api/swipes). L'app ne tient plus de compteur :
// elle lit le reste au chargement de Découvrir, et un like refusé par le
// serveur rend la carte et ouvre l'offre mazl+.

const _limitTitle = 'Vos likes du jour sont partis.';

Finder _card(int userId) => find.byWidgetPredicate(
  (w) => w is DiscoverCard && w.profile.userId == userId,
);

double _restX(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;

void _expectAtRest(WidgetTester tester, Finder card) {
  expect(card, findsOneWidget);
  expect((tester.getCenter(card).dx - _restX(tester)).abs(), lessThan(1));
}

Future<FakeDiscoverApi> _pumpDiscover(
  WidgetTester tester,
  FakeLikeAllowanceApi allowance, {
  int profiles = 3,
  void Function(FakeDiscoverApi api)? configure,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final api = FakeDiscoverApi(discoverProfiles(profiles));
  configure?.call(api);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      theme: AppTheme.lightTheme,
      builder: (context, child) => ReduceMotionScope(child: child!),
      home: DiscoverScreen(apiService: api, likeAllowanceApi: allowance),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return api;
}

Future<void> _tapLike(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel("J'aime").first);
  await tester.pump();
  await settle(tester);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
    PremiumGate.debugPremiumOverride = false;
    installTestCredits();
  });

  tearDown(PremiumGate.resetForTest);

  testWidgets('Découvrir lit ce que le serveur laisse liker, à l\'ouverture', (
    tester,
  ) async {
    final allowance = FakeLikeAllowanceApi.free(remaining: 7);
    await _pumpDiscover(tester, allowance);

    expect(allowance.reads, 1);
  });

  testWidgets('le serveur refuse un like (402) : la carte revient et l\'offre '
      'mazl+ s\'ouvre', (tester) async {
    final semantics = tester.ensureSemantics();
    // L'app croit qu'il en reste : un autre appareil les a dépensés.
    final allowance = FakeLikeAllowanceApi.free(remaining: 4);
    final api = await _pumpDiscover(
      tester,
      allowance,
      configure: (api) => api.refuseLikes = true,
    );

    await tester.tap(find.bySemanticsLabel("J'aime"));
    await tester.pump();
    await settle(tester);
    await settle(tester);

    // Aucun like n'est enregistré : la carte est là, au repos, pas disparue.
    expect(api.swipes, ['101:like']);
    expect(api.refusedLikes, ['101:like']);
    _expectAtRest(tester, _card(101));
    // La feuille existante, avec la limite que le serveur annonce.
    expect(find.text(_limitTitle), findsOneWidget);
    expect(find.text('LIMITE DU JOUR · 10 / 10'), findsOneWidget);
    expect(find.text('Découvrir mazl+'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('après un 402, les likes suivants ne sont même plus envoyés', (
    tester,
  ) async {
    // Un autre appareil les a dépensés : le serveur le dit à la relecture.
    final allowance = FakeLikeAllowanceApi([
      freeAllowance(remaining: 4),
      freeAllowance(remaining: 0),
    ]);
    final api = await _pumpDiscover(
      tester,
      allowance,
      configure: (api) => api.refuseLikes = true,
    );
    await _tapLike(tester);
    await settle(tester);
    expect(find.text(_limitTitle), findsOneWidget);
    await tester.tap(find.text('Attendre minuit'));
    await tester.pumpAndSettle();
    expect(find.text(_limitTitle), findsNothing);

    await _tapLike(tester);
    await settle(tester);

    expect(api.swipes, ['101:like'], reason: 'le serveur a déjà dit non');
    _expectAtRest(tester, _card(101));
    expect(find.text(_limitTitle), findsOneWidget);
  });

  testWidgets('plus rien à liker dès l\'ouverture : la carte revient, rien '
      'n\'est envoyé, l\'offre s\'ouvre', (tester) async {
    final allowance = FakeLikeAllowanceApi.free(remaining: 0);
    final api = await _pumpDiscover(tester, allowance);

    await dragSlowly(tester, _card(101), const Offset(180, 0));
    await settle(tester);
    await settle(tester);

    expect(api.swipes, isEmpty);
    _expectAtRest(tester, _card(101));
    expect(find.text(_limitTitle), findsOneWidget);
  });

  testWidgets('passer reste possible quand les likes sont épuisés', (
    tester,
  ) async {
    final allowance = FakeLikeAllowanceApi.free(remaining: 0);
    final api = await _pumpDiscover(tester, allowance);

    await dragSlowly(tester, _card(101), const Offset(-180, 0));
    await settle(tester);

    expect(api.swipes, ['101:pass']);
    expect(_card(101), findsNothing);
    expect(find.text(_limitTitle), findsNothing);
  });

  testWidgets('un abonné n\'est jamais arrêté par l\'app : 12 likes partent', (
    tester,
  ) async {
    PremiumGate.debugPremiumOverride = true;
    final allowance = FakeLikeAllowanceApi.unlimited();
    final api = await _pumpDiscover(tester, allowance, profiles: 12);

    for (var i = 0; i < 12; i++) {
      await _tapLike(tester);
    }

    expect(api.swipes, [for (var i = 1; i <= 12; i++) '${100 + i}:like']);
    expect(find.text(_limitTitle), findsNothing);
  });

  testWidgets('un membre gratuit qui a encore des likes n\'est pas compté par '
      'l\'app : 11 likes partent si le serveur les accepte', (tester) async {
    // Plus de compteur local de 10 : seul le serveur ferme la porte.
    final allowance = FakeLikeAllowanceApi.free(remaining: 40);
    final api = await _pumpDiscover(tester, allowance, profiles: 11);

    for (var i = 0; i < 11; i++) {
      await _tapLike(tester);
    }

    expect(api.swipes, hasLength(11));
    expect(find.text(_limitTitle), findsNothing);
  });

  testWidgets('le reste du jour est relu auprès du serveur après un like', (
    tester,
  ) async {
    final allowance = FakeLikeAllowanceApi([
      freeAllowance(remaining: 2),
      freeAllowance(remaining: 1),
    ]);
    await _pumpDiscover(tester, allowance);
    expect(allowance.reads, 1);

    await _tapLike(tester);

    expect(allowance.reads, 2);
  });

  testWidgets('lecture impossible : on ne bloque personne, le serveur décide', (
    tester,
  ) async {
    final allowance = FakeLikeAllowanceApi.free()
      ..failure = const LikeAllowanceException(LikeAllowanceErrorKind.network);
    final api = await _pumpDiscover(tester, allowance);

    await _tapLike(tester);

    expect(api.swipes, ['101:like']);
    expect(_card(101), findsNothing);
    expect(find.text(_limitTitle), findsNothing);
  });

  testWidgets('le 402 arrive après un autre geste : la carte refusée revient '
      'quand même', (tester) async {
    final allowance = FakeLikeAllowanceApi.free(remaining: 4);
    final hold = Completer<void>();
    final api = await _pumpDiscover(
      tester,
      allowance,
      configure: (api) {
        api.refuseLikes = true;
        api.holdLikes = hold;
      },
    );

    await _tapLike(tester); // 101 est aimée, la réponse tarde
    await dragSlowly(tester, _card(102), const Offset(-180, 0)); // 102 passée
    await settle(tester);
    expect(_card(101), findsNothing);
    expect(_card(102), findsNothing);

    hold.complete(); // le serveur répond enfin : refus
    await settle(tester);
    await settle(tester);
    await settle(tester);

    expect(api.refusedLikes, ['101:like']);
    _expectAtRest(tester, _card(101));
    expect(find.text(_limitTitle), findsOneWidget);
  });
}
