import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/content_max_width.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/couple/screens/couple_mode_setup_screen.dart';
import 'package:mazl/presentation/features/couple/screens/couple_us_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../duo/duo_geometry.dart';
import 'couple_flow_fakes.dart';

// The couple screens on the foldable iPhone (iPhone Duo) held half open.
// Like a book (fold down the middle, 455.5 .. 495.5): one page to read or
// look at on the reading-start side, one to act on or to detail on the other,
// nothing in the curve. Like a laptop (fold across): the list of saved
// activities stays below the fold.

AppLocalizations _l10n([String code = 'fr']) =>
    lookupAppLocalizations(Locale(code));

Future<DuoPoseController> _pump(
  WidgetTester tester,
  DuoPose pose,
  Widget home, {
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
      home: ContentMaxWidth(child: home),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settleFold(tester);
  return controller;
}

Rect _rect(WidgetTester tester, Finder finder) {
  expect(finder, findsAtLeastNWidgets(1), reason: finder.toString());
  return tester.getRect(finder.first);
}

/// [finder] lies on the reading-start page of the book (left, or right in
/// Hebrew).
void _onFirstPage(WidgetTester tester, Finder finder, {bool rtl = false}) {
  final fold = DuoPose.halfOpenBook.fold!;
  final rect = _rect(tester, finder);
  if (rtl) {
    expect(rect.left, greaterThanOrEqualTo(fold.right - 0.5), reason: '$rect');
  } else {
    expect(rect.right, lessThanOrEqualTo(fold.left + 0.5), reason: '$rect');
  }
}

void _onSecondPage(WidgetTester tester, Finder finder, {bool rtl = false}) {
  final fold = DuoPose.halfOpenBook.fold!;
  final rect = _rect(tester, finder);
  if (rtl) {
    expect(rect.right, lessThanOrEqualTo(fold.left + 0.5), reason: '$rect');
  } else {
    expect(rect.left, greaterThanOrEqualTo(fold.right - 0.5), reason: '$rect');
  }
}

void _nothingInTheCurve(WidgetTester tester, DuoPose pose) {
  expect(foldCrossingProblems(tester, pose), isEmpty);
  expectFitsDuoPose(tester, pose, 'couple');
}

FakeCoupleTransport _spaceTransport() {
  final t = FakeCoupleTransport();
  t.reply(
    'GET /api/couple/stats',
    ok({'stats': statsRow(), 'achievements': []}),
  );
  t.reply(
    'GET /api/couple/bucket-list',
    ok({
      'items': [
        bucketRow(id: 1, title: 'Voir les aurores boréales'),
        bucketRow(id: 2, title: 'Apprendre à danser le tango'),
      ],
    }),
  );
  t.reply(
    'GET /api/couple/dates',
    ok({
      'dates': [dateRow(id: 1, title: 'Notre anniversaire')],
    }),
  );
  t.reply(
    'GET /api/couple/memories',
    ok({
      'memories': [memoryRow(id: 1, title: 'Notre premier voyage')],
    }),
  );
  return t;
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('couple space', () {
    Future<DuoPoseController> pumpSpace(
      WidgetTester tester, {
      Locale locale = const Locale('fr'),
    }) => _pump(
      tester,
      DuoPose.halfOpenBook,
      CoupleUsScreen(
        apiService: CoupleApiService(transport: _spaceTransport()),
      ),
      locale: locale,
    );

    testWidgets('book: the couple and its numbers on the first page, the '
        'actions, goals and dates on the other', (tester) async {
      await pumpSpace(tester);
      final l10n = _l10n();
      _onFirstPage(tester, find.text(l10n.coupleSpaceStoryBegins));
      _onFirstPage(tester, find.byKey(const Key('couple-stat-0')));
      _onFirstPage(tester, find.byKey(const Key('couple-stat-2')));
      _onFirstPage(tester, find.text('Notre premier voyage'));
      _onSecondPage(tester, find.text(l10n.coupleSpaceQuickAddMemory));
      _onSecondPage(tester, find.text('Voir les aurores boréales'));
      _onSecondPage(tester, find.text('Notre anniversaire'));
      _nothingInTheCurve(tester, DuoPose.halfOpenBook);
    });

    testWidgets('book in Hebrew: the pages swap sides', (tester) async {
      await pumpSpace(tester, locale: const Locale('he'));
      final l10n = _l10n('he');
      _onFirstPage(tester, find.byKey(const Key('couple-stat-0')), rtl: true);
      _onSecondPage(
        tester,
        find.text(l10n.coupleSpaceQuickAddMemory),
        rtl: true,
      );
      _nothingInTheCurve(tester, DuoPose.halfOpenBook);
    });

    testWidgets('open portrait stays one column', (tester) async {
      await _pump(
        tester,
        DuoPose.openPortrait,
        CoupleUsScreen(
          apiService: CoupleApiService(transport: _spaceTransport()),
        ),
      );
      final stats = _rect(tester, find.byKey(const Key('couple-stat-0')));
      final actions = _rect(
        tester,
        find.text(_l10n().coupleSpaceQuickAddMemory),
      );
      expect(actions.left, lessThan(stats.right));
      expect(actions.top, greaterThan(stats.bottom));
    });
  });

  group('couple mode setup', () {
    late FakeCoupleApi api;
    late CoupleService service;

    Future<ApiResponse<List<Map<String, dynamic>>>> matches() async =>
        ApiResponse.success([
          {
            'id': 3,
            'profile': {
              'user_id': 45,
              'display_name': 'Myriam',
              'picture': null,
            },
          },
          {
            'id': 4,
            'profile': {
              'user_id': 46,
              'display_name': 'Noémie',
              'picture': null,
            },
          },
        ]);

    setUp(() {
      api = FakeCoupleApi();
      service = CoupleService.forTesting(
        api: api,
        pollInterval: const Duration(hours: 1),
      );
    });
    tearDown(() => service.dispose());

    Widget screen() =>
        CoupleModeSetupScreen(service: service, loadMatches: matches);

    testWidgets('book: the question on the first page, the matches and the '
        'button on the other', (tester) async {
      await _pump(tester, DuoPose.halfOpenBook, screen());
      final l10n = _l10n();
      _onFirstPage(tester, find.text(l10n.coupleSpaceSetupWho));
      _onFirstPage(tester, find.byKey(const ValueKey('couple-setup-heart')));
      _onFirstPage(tester, find.text(l10n.coupleSpaceSetupExplain));
      _onSecondPage(tester, find.text('Myriam'));
      _onSecondPage(tester, find.text('Noémie'));
      _onSecondPage(tester, find.text(l10n.coupleSpaceSetupSend));
      _nothingInTheCurve(tester, DuoPose.halfOpenBook);
    });

    testWidgets('book: the person chosen shows on the first page and stays '
        'chosen when the device is folded and unfolded', (tester) async {
      final pose = await _pump(tester, DuoPose.halfOpenBook, screen());
      await tester.tap(find.text('Noémie'));
      await tester.pump();
      _onFirstPage(tester, find.byKey(const ValueKey('couple-setup-chosen')));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('couple-setup-chosen')))
            .data,
        'Noémie',
      );

      for (final next in [DuoPose.openPortrait, DuoPose.halfOpenBook]) {
        await pose.moveTo(tester, next);
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const ValueKey('couple-setup-chosen')), findsOneWidget);
      await tester.tap(find.text(_l10n().coupleSpaceSetupSend));
      await tester.pump();
      await tester.pump();
      expect(api.calls, contains('send:46'));
      await service.cancelCoupleRequest();
    });

    testWidgets('book: once sent, the answer is on the first page and the '
        'button on the other', (tester) async {
      await _pump(tester, DuoPose.halfOpenBook, screen());
      await tester.tap(find.text('Myriam'));
      await tester.pump();
      await tester.tap(find.text(_l10n().coupleSpaceSetupSend));
      await tester.pump();
      await tester.pump();
      final l10n = _l10n();
      _onFirstPage(tester, find.text(l10n.coupleSpaceSetupSentTitle));
      _onFirstPage(tester, find.text(l10n.coupleSpaceSetupSentBody('Myriam')));
      _onSecondPage(tester, find.text(l10n.coupleSpaceSetupGotIt));
      _nothingInTheCurve(tester, DuoPose.halfOpenBook);
      await service.cancelCoupleRequest();
    });
  });
}
