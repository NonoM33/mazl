import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/services/store/credit_models.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/boost/screens/boost_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../support/credits_fakes.dart';
import '../../support/store_fakes.dart';
import '../duo/duo_geometry.dart';

// The Boost page on the foldable iPhone (iPhone Duo) held like a book: the
// Boost card on the page where reading starts, what it brings and the
// activation button on the other.

class _BoostServer implements ApiService {
  _BoostServer({this.active = false});

  final bool active;

  @override
  Future<ApiResponse<BoostStatus>> getBoostStatus() async {
    final credits = CreditBalance.fromJson(serverCredits(boostPurchased: 1));
    return ApiResponse.success(
      BoostStatus(
        isActive: active,
        expiresAt: active
            ? DateTime.now().add(const Duration(minutes: 20))
            : null,
        remainingBoosts: credits.boost.available,
        credits: credits,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_BoostServer: ${invocation.memberName}');
}

Future<DuoPoseController> _pump(
  WidgetTester tester,
  DuoPose pose, {
  bool active = false,
  Locale locale = const Locale('fr'),
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: duoAppBuilder(controller),
      home: BoostScreen(apiService: _BoostServer(active: active)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await settleFold(tester);
  return controller;
}

AppLocalizations _l10n([String code = 'fr']) =>
    lookupAppLocalizations(Locale(code));

void main() {
  setUpAll(loadAppFonts);

  setUp(() {
    PremiumGate.resetForTest();
    PremiumGate.debugPremiumOverride = false;
    installTestCredits(
      gateway: FakeStoreGateway()
        ..productResponse = ProductDetailsResponse(
          productDetails: [storeProduct('com.mazl.app.boost.1', price: 1.99)],
          notFoundIDs: const [],
        ),
    );
  });

  tearDown(PremiumGate.resetForTest);

  testWidgets('book: the Boost card left of the fold, benefits and button '
      'right', (tester) async {
    await _pump(tester, DuoPose.halfOpenBook);
    final fold = DuoPose.halfOpenBook.fold!;
    final l10n = _l10n();
    expect(
      tester.getRect(find.text(l10n.boostHeadlineIdle)).right,
      lessThanOrEqualTo(fold.left),
    );
    expect(
      tester.getRect(find.text(l10n.boostTagline)).right,
      lessThanOrEqualTo(fold.left),
    );
    expect(
      tester.getRect(find.text(l10n.boostBenefitsTitle)).left,
      greaterThanOrEqualTo(fold.right),
    );
    final button = tester.getRect(find.byType(ElevatedButton));
    expect(button.left, greaterThanOrEqualTo(fold.right));
    expect(button.height, greaterThanOrEqualTo(44));
    expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
    expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'boost');
  });

  testWidgets(
    'book while a Boost runs: the countdown left, the results right',
    (tester) async {
      await _pump(tester, DuoPose.halfOpenBook, active: true);
      final fold = DuoPose.halfOpenBook.fold!;
      final l10n = _l10n();
      expect(
        tester.getRect(find.text(l10n.boostHeadlineActive)).right,
        lessThanOrEqualTo(fold.left),
      );
      expect(
        tester.getRect(find.text(l10n.boostDuringTitle)).left,
        greaterThanOrEqualTo(fold.right),
      );
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
    },
  );

  testWidgets('book in Hebrew: the Boost card right of the fold, the button '
      'left', (tester) async {
    await _pump(tester, DuoPose.halfOpenBook, locale: const Locale('he'));
    final fold = DuoPose.halfOpenBook.fold!;
    expect(
      tester.getRect(find.text(_l10n('he').boostHeadlineIdle)).left,
      greaterThanOrEqualTo(fold.right),
    );
    expect(
      tester.getRect(find.byType(ElevatedButton)).right,
      lessThanOrEqualTo(fold.left),
    );
  });

  testWidgets('open portrait: one column, the header above the benefits', (
    tester,
  ) async {
    await _pump(tester, DuoPose.openPortrait);
    final l10n = _l10n();
    expect(
      tester.getRect(find.text(l10n.boostBenefitsTitle)).top,
      greaterThan(tester.getRect(find.text(l10n.boostTagline)).bottom),
    );
    expect(tester.getRect(find.byType(ElevatedButton)).width, greaterThan(500));
  });

  testWidgets('folding and unfolding keep the screen whole', (tester) async {
    final pose = await _pump(tester, DuoPose.openLandscape);
    final l10n = _l10n();
    for (final next in [
      DuoPose.halfOpenBook,
      DuoPose.halfOpenLaptop,
      DuoPose.halfOpenBook,
      DuoPose.openPortrait,
    ]) {
      await pose.moveTo(tester, next);
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.boostHeadlineIdle),
        findsOneWidget,
        reason: next.name,
      );
      expect(find.byType(ElevatedButton), findsOneWidget, reason: next.name);
      expect(foldCrossingProblems(tester, next), isEmpty, reason: next.name);
    }
  });
}
