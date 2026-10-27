import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/premium/boost_schedule_api.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/services/store/credit_models.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/boost/screens/boost_screen.dart';
import 'package:mazl/presentation/features/boost/widgets/boost_best_time_card.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../support/credits_fakes.dart';
import '../../support/store_fakes.dart';
import '../duo/duo_geometry.dart';

// The Boost page with its « Meilleur moment » card (docs/premium/MONETISATION.md
// §8) in every pose of the foldable iPhone, light and dark: with a best time,
// with the Boost scheduled, without enough data, and when the server fails.

class _BoostServer implements ApiService {
  @override
  Future<ApiResponse<BoostStatus>> getBoostStatus() async {
    final credits = CreditBalance.fromJson(serverCredits(boostPurchased: 1));
    return ApiResponse.success(
      BoostStatus(
        isActive: false,
        remainingBoosts: credits.boost.available,
        credits: credits,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_BoostServer: ${invocation.memberName}');
}

enum _Card { bestTime, scheduled, noData, failing }

class _Schedule implements BoostScheduleApi {
  _Schedule(this.card);

  final _Card card;

  // Saturday 2026-10-31 21:00 local.
  static final _saturday = DateTime(2026, 10, 31, 21).toUtc();

  @override
  Future<BoostScheduleInfo> bestTime() async => switch (card) {
    _Card.bestTime => BoostScheduleInfo(
      city: 'Paris',
      bestTime: BoostBestTime(startsAt: _saturday, weekday: 6, hour: 21),
      scheduledAt: null,
    ),
    _Card.scheduled => BoostScheduleInfo(
      city: 'Paris',
      bestTime: BoostBestTime(startsAt: _saturday, weekday: 6, hour: 21),
      scheduledAt: _saturday,
    ),
    _Card.noData => const BoostScheduleInfo(
      city: null,
      bestTime: null,
      scheduledAt: null,
    ),
    _Card.failing => throw const BoostScheduleException(
      BoostScheduleErrorKind.network,
    ),
  };

  @override
  Future<DateTime> schedule(DateTime at) async => at.toUtc();

  @override
  Future<void> cancel() async {}
}

Future<DuoPoseController> _pump(
  WidgetTester tester,
  DuoPose pose,
  _Card card, {
  bool dark = false,
  Locale locale = const Locale('fr'),
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: duoAppBuilder(controller),
      home: BoostScreen(
        apiService: _BoostServer(),
        scheduleApi: _Schedule(card),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await settleFold(tester);
  return controller;
}

/// The card, scrolled into view in a pose that cuts the page short.
Future<void> _reveal(WidgetTester tester) async {
  final card = find.byType(BoostBestTimeCard);
  expect(card, findsOneWidget);
  await tester.ensureVisible(card);
  await tester.pump(const Duration(milliseconds: 100));
}

/// Every button of the card is a 44 pt target inside the safe area of [pose]
/// (or the app's part of the vertical bar), clear of the system's occlusions,
/// and out of the fold unless it is in a scrolling list.
void _expectButtonsUsable(WidgetTester tester, DuoPose pose, String reason) {
  final bar = pose.verticalBar?.controls;
  final buttons = find.descendant(
    of: find.byType(BoostBestTimeCard),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  for (final element in buttons.evaluate()) {
    final box = element.renderObject! as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final label = '$reason in ${pose.name}: button at $rect';
    expect(rect.height, greaterThanOrEqualTo(44), reason: label);
    expect(rect.width, greaterThanOrEqualTo(44), reason: label);
    bool inside(Rect area) =>
        area.inflate(0.5).contains(rect.topLeft) &&
        area.inflate(0.5).contains(rect.bottomRight);
    expect(
      inside(pose.safeRect) || (bar != null && inside(bar)),
      isTrue,
      reason: '$label is outside ${pose.safeRect}',
    );
    for (final occluded in pose.foldState.occlusions) {
      expect(
        rect.overlaps(occluded),
        isFalse,
        reason: '$label under $occluded',
      );
    }
  }
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting();
  });

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

  testWidgets(
    'book: the card sits on the page of the benefits, right of the fold',
    (tester) async {
      await _pump(tester, DuoPose.halfOpenBook, _Card.bestTime);
      final fold = DuoPose.halfOpenBook.fold!;
      expect(
        tester.getRect(find.byType(BoostBestTimeCard)).left,
        greaterThanOrEqualTo(fold.right),
      );
      expect(find.textContaining('après Shabbat'), findsOneWidget);
    },
  );

  testWidgets('folding and unfolding keep the card and what it loaded', (
    tester,
  ) async {
    final pose = await _pump(tester, DuoPose.openLandscape, _Card.scheduled);
    for (final next in [
      DuoPose.halfOpenBook,
      DuoPose.halfOpenLaptop,
      DuoPose.halfOpenBook,
      DuoPose.openPortrait,
    ]) {
      await pose.moveTo(tester, next);
      await tester.pumpAndSettle();
      expect(
        find.text('Programmé pour samedi 21 h'),
        findsOneWidget,
        reason: next.name,
      );
      expect(foldCrossingProblems(tester, next), isEmpty, reason: next.name);
    }
  });

  for (final pose in DuoPose.values) {
    for (final dark in [false, true]) {
      for (final card in _Card.values) {
        testWidgets('${pose.name} ${dark ? 'dark' : 'light'} ${card.name}', (
          tester,
        ) async {
          await _pump(tester, pose, card, dark: dark);
          await _reveal(tester);
          expect(
            foldCrossingProblems(tester, pose),
            isEmpty,
            reason: '${pose.name} ${card.name}',
          );
          expect(tester.takeException(), isNull);
          _expectButtonsUsable(tester, pose, 'boost ${card.name}');
          switch (card) {
            case _Card.bestTime:
              expect(find.text('Programmer pour ce moment'), findsOneWidget);
            case _Card.scheduled:
              expect(find.text('Annuler la programmation'), findsOneWidget);
            case _Card.noData:
              expect(
                find.text('Pas encore assez de données pour votre ville.'),
                findsOneWidget,
              );
            case _Card.failing:
              expect(
                find.text('Impossible de charger le meilleur moment.'),
                findsOneWidget,
              );
          }
        });
      }
    }
  }

  testWidgets(
    'the four rotations of the closed and open states keep the card usable',
    (tester) async {
      for (final pose in [
        DuoPose.closed,
        DuoPose.tent,
        DuoPose.openPortrait,
        DuoPose.openLandscape,
      ]) {
        await _pump(tester, pose, _Card.bestTime, locale: const Locale('he'));
        await _reveal(tester);
        expect(foldCrossingProblems(tester, pose), isEmpty, reason: pose.name);
        _expectButtonsUsable(tester, pose, 'boost he');
      }
    },
  );
}
