import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/layout/content_max_width.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';
import 'package:mazl/presentation/features/couple/screens/couple_activities_feed_screen.dart';
import 'package:mazl/presentation/features/couple/screens/couple_activity_detail_screen.dart';
import 'package:mazl/presentation/features/couple/screens/couple_event_detail_screen.dart';
import 'package:mazl/presentation/features/couple/screens/mazel_tov_screen.dart';
import 'package:mazl/presentation/features/couple/screens/saved_activities_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../duo/duo_geometry.dart';

// The couple's lists and details on the foldable iPhone (iPhone Duo) held
// half open: like a book (fold down the middle, 455.5 .. 495.5) one page to
// look at and one to act on; like a laptop (fold across) the saved list stays
// below the fold. See couple_book_layout_test.dart for the other screens.

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
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settleFold(tester);
  return controller;
}

Rect _rect(WidgetTester tester, Finder finder) {
  expect(finder, findsAtLeastNWidgets(1), reason: finder.toString());
  return tester.getRect(finder.first);
}

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

/// The round button of the deck that carries [icon] (the discs that appear
/// while a card is thrown carry the same icons).
Finder _button(IconData icon) => find.widgetWithIcon(RoundIconButton, icon);

void _nothingInTheCurve(WidgetTester tester, DuoPose pose) {
  expect(foldCrossingProblems(tester, pose), isEmpty);
  expectFitsDuoPose(tester, pose, 'couple');
}

CoupleApiService _api(void Function(FakeCoupleTransport) setUp) {
  final transport = FakeCoupleTransport();
  setUp(transport);
  return CoupleApiService(transport: transport);
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('activities feed', () {
    const feed = 'GET /api/couple/activities?limit=50&offset=0';
    CoupleApiService api() => _api((t) {
      t.reply(
        feed,
        ok({
          'activities': [
            activityRow(id: 1, title: 'Spa en duo'),
            activityRow(id: 2, title: 'Atelier poterie'),
          ],
        }),
      );
      t.reply('POST /api/couple/activities/1/pass', ok({}));
    });

    testWidgets('book: the card on the first page, the title, the categories '
        'and the buttons on the other', (tester) async {
      await _pump(
        tester,
        DuoPose.halfOpenBook,
        CoupleActivitiesFeedScreen(apiService: api()),
      );
      final l10n = _l10n();
      _onFirstPage(tester, find.text('Spa en duo'));
      _onFirstPage(tester, find.textContaining('Moment de détente'));
      _onSecondPage(tester, find.text(l10n.coupleFeedActivitiesTitle));
      _onSecondPage(tester, find.text(l10n.coupleFeedFilterAll));
      _onSecondPage(tester, _button(LucideIcons.x));
      _onSecondPage(tester, _button(LucideIcons.info).last);
      _nothingInTheCurve(tester, DuoPose.halfOpenBook);
    });

    testWidgets('folding keeps the card on top: the one thrown stays gone', (
      tester,
    ) async {
      final pose = await _pump(
        tester,
        DuoPose.halfOpenBook,
        CoupleActivitiesFeedScreen(apiService: api()),
      );
      expect(find.text('Spa en duo'), findsOneWidget);
      await tester.tap(_button(LucideIcons.x));
      await tester.pumpAndSettle();
      expect(find.text('Atelier poterie'), findsOneWidget);
      expect(find.text('Spa en duo'), findsNothing);

      for (final next in [DuoPose.openPortrait, DuoPose.halfOpenBook]) {
        await pose.moveTo(tester, next);
        await tester.pumpAndSettle();
        expect(find.text('Atelier poterie'), findsOneWidget, reason: '$next');
        expect(find.text('Spa en duo'), findsNothing, reason: '$next');
      }
    });

    testWidgets('book: with nothing to show, the message and its button '
        'stay on the first page', (tester) async {
      await _pump(
        tester,
        DuoPose.halfOpenBook,
        CoupleActivitiesFeedScreen(
          apiService: _api((t) => t.reply(feed, ok({'activities': []}))),
        ),
      );
      final l10n = _l10n();
      _onFirstPage(tester, find.text(l10n.coupleFeedActivitiesEmptyTitle));
      _onFirstPage(tester, find.text(l10n.coupleFeedRefresh));
      _nothingInTheCurve(tester, DuoPose.halfOpenBook);
    });
  });

  group('activity detail', () {
    CoupleApiService api() => _api((t) {
      t.reply(
        'GET /api/couple/activities/1',
        ok({'activity': activityRow(id: 1, title: 'Spa en duo')}),
      );
      t.reply('GET /api/couple/saved', ok({'activities': []}));
    });

    testWidgets('book: the visual and the title on the first page, the '
        'description, the address and the booking on the other', (
      tester,
    ) async {
      await _pump(
        tester,
        DuoPose.halfOpenBook,
        CoupleActivityDetailScreen(activityId: '1', apiService: api()),
      );
      final l10n = _l10n();
      _onFirstPage(tester, find.text('Spa en duo'));
      // Share and save follow the back button at the top of the vertical bar.
      expect(
        DuoPose.halfOpenBook.verticalBar!.controls
            .inflate(0.5)
            .contains(tester.getCenter(find.byIcon(LucideIcons.bookmark))),
        isTrue,
        reason: 'save is not in the vertical bar',
      );
      _onSecondPage(tester, find.text('Moment de détente à deux.'));
      _onSecondPage(tester, find.text('Spa Marais'));
      _onSecondPage(tester, find.text(l10n.coupleFeedBook));
      _nothingInTheCurve(tester, DuoPose.halfOpenBook);
    });
  });

  group('event detail', () {
    CoupleApiService api() => _api((t) {
      t.reply(
        'GET /api/couple/events/3',
        ok({'event': eventRow(id: 3, title: 'Dîner de Shabbat')}),
      );
      t.reply('GET /api/couple/events/registered', ok({'events': []}));
    });

    testWidgets('book: the title and the price on the first page, the '
        'practical details and the registration on the other', (tester) async {
      await _pump(
        tester,
        DuoPose.halfOpenBook,
        CoupleEventDetailScreen(eventId: '3', apiService: api()),
      );
      final l10n = _l10n();
      _onFirstPage(tester, find.text('Dîner de Shabbat'));
      _onFirstPage(tester, find.text(l10n.coupleFeedEventSpotsLeft(17)));
      _onSecondPage(tester, find.text('Maison Cohen'));
      _onSecondPage(tester, find.text('Un dîner entre couples.'));
      _onSecondPage(tester, find.text(l10n.coupleFeedEventRegister));
      _nothingInTheCurve(tester, DuoPose.halfOpenBook);
    });
  });

  group('mazal tov', () {
    testWidgets('book: the blessing and the couple on the first page, the '
        'words and the button on the other', (tester) async {
      await _pump(
        tester,
        DuoPose.halfOpenBook,
        const MazelTovScreen(partnerName: 'Noémie'),
      );
      final l10n = _l10n();
      _onFirstPage(tester, find.text(l10n.coupleSpaceMazelTovTitle));
      _onFirstPage(tester, find.byIcon(LucideIcons.heart));
      _onSecondPage(
        tester,
        find.text(l10n.coupleSpaceMazelTovCongrats('Noémie')),
      );
      _onSecondPage(tester, find.text(l10n.coupleSpaceMazelTovStart));
      _nothingInTheCurve(tester, DuoPose.halfOpenBook);
    });

    testWidgets('book in Hebrew: the button is on the left page', (
      tester,
    ) async {
      await _pump(
        tester,
        DuoPose.halfOpenBook,
        const MazelTovScreen(partnerName: 'Noémie'),
        locale: const Locale('he'),
      );
      final l10n = _l10n('he');
      _onFirstPage(tester, find.text(l10n.coupleSpaceMazelTovTitle), rtl: true);
      _onSecondPage(
        tester,
        find.text(l10n.coupleSpaceMazelTovStart),
        rtl: true,
      );
    });
  });

  group('saved activities', () {
    const saved = 'GET /api/couple/saved';
    CoupleApiService full() => _api(
      (t) => t.reply(
        saved,
        ok({
          'activities': [
            savedActivityRow(id: 5, title: 'Atelier poterie'),
            savedActivityRow(id: 6, title: 'Dîner sur la Seine'),
          ],
        }),
      ),
    );
    CoupleApiService empty() =>
        _api((t) => t.reply(saved, ok({'activities': []})));

    testWidgets('laptop: the count is above the fold, the activities below', (
      tester,
    ) async {
      await _pump(
        tester,
        DuoPose.halfOpenLaptop,
        SavedActivitiesScreen(apiService: full()),
      );
      final fold = DuoPose.halfOpenLaptop.fold!;
      expect(
        _rect(tester, find.byKey(const ValueKey('saved-count'))).bottom,
        lessThanOrEqualTo(fold.top),
      );
      for (final title in ['Atelier poterie', 'Dîner sur la Seine']) {
        expect(
          _rect(tester, find.text(title)).top,
          greaterThanOrEqualTo(fold.bottom),
          reason: title,
        );
      }
      _nothingInTheCurve(tester, DuoPose.halfOpenLaptop);
    });

    testWidgets('book: the count on the first page, the activities on the '
        'other', (tester) async {
      await _pump(
        tester,
        DuoPose.halfOpenBook,
        SavedActivitiesScreen(apiService: full()),
      );
      _onFirstPage(tester, find.byKey(const ValueKey('saved-count')));
      _onSecondPage(tester, find.text('Atelier poterie'));
      _onSecondPage(tester, find.byIcon(LucideIcons.trash2));
      _nothingInTheCurve(tester, DuoPose.halfOpenBook);
    });

    testWidgets('laptop, nothing saved: the words above the fold, the way '
        'out below', (tester) async {
      await _pump(
        tester,
        DuoPose.halfOpenLaptop,
        SavedActivitiesScreen(apiService: empty()),
      );
      final fold = DuoPose.halfOpenLaptop.fold!;
      final l10n = _l10n();
      expect(
        _rect(tester, find.text(l10n.coupleFeedSavedEmptyTitle)).bottom,
        lessThanOrEqualTo(fold.top),
      );
      expect(
        _rect(tester, find.text(l10n.coupleFeedSavedEmptyAction)).top,
        greaterThanOrEqualTo(fold.bottom),
      );
      _nothingInTheCurve(tester, DuoPose.halfOpenLaptop);
    });

    testWidgets('book, nothing saved: the words on the first page, the way '
        'out on the other', (tester) async {
      await _pump(
        tester,
        DuoPose.halfOpenBook,
        SavedActivitiesScreen(apiService: empty()),
      );
      final l10n = _l10n();
      _onFirstPage(tester, find.text(l10n.coupleFeedSavedEmptyTitle));
      _onSecondPage(tester, find.text(l10n.coupleFeedSavedEmptyAction));
      _nothingInTheCurve(tester, DuoPose.halfOpenBook);
    });
  });
}
