import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/presentation/features/boost/screens/boost_screen.dart';

import '../../../helpers/l10n_helpers.dart';
import 'l10n_harness.dart';

class _FakeBoostApi implements ApiService {
  _FakeBoostApi(this.status);

  final ApiResponse<BoostStatus> status;

  @override
  Future<ApiResponse<BoostStatus>> getBoostStatus() async => status;

  @override
  Future<ApiResponse<BoostStatus>> activateBoost() async =>
      ApiResponse.failure('Failed to activate boost');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeBoostApi: ${invocation.memberName}');
}

_FakeBoostApi _idle({int? remaining = 1}) => _FakeBoostApi(
  ApiResponse.success(BoostStatus(isActive: false, remainingBoosts: remaining)),
);

_FakeBoostApi _active() => _FakeBoostApi(
  ApiResponse.success(
    BoostStatus(
      isActive: true,
      expiresAt: DateTime.now().add(const Duration(minutes: 20, seconds: 30)),
      viewsDuringBoost: 12,
      likesDuringBoost: 3,
    ),
  ),
);

Future<void> _pump(WidgetTester tester, ApiService api, L10nCase c) async {
  await pumpLocalized(
    tester,
    BoostScreen(apiService: api),
    locale: c.locale,
    brightness: c.brightness,
    size: const Size(360, 1600),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

const _frenchIdle = [
  'Boostez votre profil',
  'Soyez vu par 10x plus de personnes.',
  'Avantages du Boost',
  'Apparaissez en premier dans les suggestions',
  '10x plus de visibilité pendant 30 min',
  'Plus de chances de matcher',
  'Stats en temps réel pendant le boost',
  'Activer le Boost',
  '1 boost restant',
  'Boosts illimités',
  'Boostez sans limite avec mazl+',
];

const _frenchActive = ['Boost actif', 'Pendant ce boost', 'Vues'];

void main() {
  testWidgets('French stays word for word', (tester) async {
    await pumpLocalized(
      tester,
      BoostScreen(apiService: _idle(remaining: 3)),
      size: const Size(360, 1600),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Boostez votre profil'), findsOneWidget);
    expect(find.text('10x plus de visibilité pendant 30 min'), findsOneWidget);
    expect(find.text('3 boosts restants'), findsOneWidget);
    expect(find.text('Activer le Boost'), findsOneWidget);
  });

  testWidgets('English idle screen', (tester) async {
    await _pump(tester, _idle(), l10nCases.first);
    expect(find.text('Boost your profile'), findsOneWidget);
    expect(find.text('10x more visibility for 30 min'), findsOneWidget);
    expect(find.text('1 Boost left'), findsOneWidget);
    expect(find.text('Turn on Boost'), findsOneWidget);
    expect(find.text('Unlimited Boosts'), findsOneWidget);
  });

  testWidgets('English active boost', (tester) async {
    await _pump(tester, _active(), l10nCases.first);
    expect(find.text('Boost is on'), findsOneWidget);
    expect(find.text('20 min left'), findsOneWidget);
    expect(find.text('During this Boost'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Views'), findsOneWidget);
  });

  testWidgets('Hebrew uses dual and singular forms', (tester) async {
    const he = L10nCase(Locale('he'), Brightness.light);
    await _pump(tester, _idle(remaining: 1), he);
    expect(find.text('נותר בוסט אחד'), findsOneWidget);
  });

  testWidgets('Russian remaining boosts follow the count', (tester) async {
    await _pump(
      tester,
      _idle(remaining: 5),
      const L10nCase(Locale('ru'), Brightness.light),
    );
    expect(find.text('Осталось 5 бустов'), findsOneWidget);
  });

  for (final c in l10nCases) {
    testWidgets('idle screen in ${c.name}', (tester) async {
      await _pump(tester, _idle(), c);
      expectNoFrench(_frenchIdle);
      expectDirection(tester, find.byType(AppBar), c);
      expect(tester.takeException(), isNull);
    });

    testWidgets('active boost in ${c.name}', (tester) async {
      await _pump(tester, _active(), c);
      expectNoFrench(_frenchActive);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failed load in ${c.name} hides the diagnostic', (
      tester,
    ) async {
      await _pump(
        tester,
        _FakeBoostApi(
          ApiResponse.failure('Failed to get boost', ApiErrorKind.timeout),
        ),
        c,
      );
      expect(find.text('Failed to get boost'), findsNothing);
      expectNoFrench(['Réessayer', 'Délai dépassé. Vérifiez votre connexion.']);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'a refused activation does not show the diagnostic in ${c.name}',
      (tester) async {
        await _pump(tester, _idle(), c);
        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Failed to activate boost'), findsNothing);
        expectNoFrench(["Erreur lors de l'activation"]);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
