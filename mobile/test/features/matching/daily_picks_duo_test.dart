import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/motion/reduce_motion_scope.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/matching/screens/daily_picks_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';

// Today's picks on the foldable iPhone (iPhone Duo). Held like a book the
// title and the time left are read on the reading-start page and the cards on
// the other one; set down like a laptop and flat nothing changes.

class _Api implements ApiService {
  @override
  Future<ApiResponse<List<Profile>>> getDailyPicks() async =>
      ApiResponse.success([
        for (var i = 1; i <= 3; i++)
          Profile(
            id: i,
            userId: 100 + i,
            displayName: 'Jeanne$i',
            age: 20 + i,
            location: 'Paris',
          ),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_Api: ${invocation.memberName}');
}

Future<void> _pump(
  WidgetTester tester,
  DuoPose pose, {
  Locale locale = const Locale('fr'),
}) async {
  setDuoPose(tester, pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => ReduceMotionScope(
        child: duoAppBuilder(DuoPoseController(pose))(context, child),
      ),
      home: DailyPicksScreen(apiService: _Api()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await settleFold(tester);
}

Finder _count(Locale locale) =>
    find.text(lookupAppLocalizations(locale).matchingPicksCount(3));

Finder _cardOf(String name) => find.textContaining(name);

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('book: the title is left of the fold, every card right', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook);
    final fold = DuoPose.halfOpenBook.fold!;
    expect(_count(const Locale('fr')), findsOneWidget);
    expect(
      tester.getRect(_count(const Locale('fr'))).right,
      lessThanOrEqualTo(fold.left),
    );
    expect(
      tester.getRect(_cardOf('Jeanne1')).left,
      greaterThanOrEqualTo(fold.right),
    );
  });

  testWidgets('book in Hebrew: the title is on the right, the cards left', (
    tester,
  ) async {
    const he = Locale('he');
    await _pump(tester, DuoPose.halfOpenBook, locale: he);
    final fold = DuoPose.halfOpenBook.fold!;
    expect(tester.getRect(_count(he)).left, greaterThanOrEqualTo(fold.right));
    expect(
      tester.getRect(_cardOf('Jeanne1')).right,
      lessThanOrEqualTo(fold.left),
    );
  });

  testWidgets('laptop: unchanged, the title is above the grid, full width', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenLaptop);
    final title = tester.getRect(_count(const Locale('fr')));
    final card = tester.getRect(_cardOf('Jeanne1'));
    expect(title.bottom, lessThan(card.top));
    expect(title.bottom, lessThanOrEqualTo(DuoPose.halfOpenLaptop.fold!.top));
  });
}
