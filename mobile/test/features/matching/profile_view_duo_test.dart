import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/di/providers/service_providers.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/profile/screens/profile_view_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../mocks/fake_discover_api.dart';

// The page of a member met on Discover, on the foldable iPhone (iPhone Duo).
// Held like a book the photos and the name are on the reading-start page, the
// text to read and the actions on the other; the other postures keep their one
// column.

const _bio = 'Jeanne aime les longues marches et le thé.';
const _looking = 'Quelqu un de curieux.';

FakeDiscoverApi _api() => FakeDiscoverApi([
  Profile(
    id: 1,
    userId: 201,
    displayName: 'Rachel',
    age: 29,
    location: 'Paris',
    bio: _bio,
    lookingFor: _looking,
  ),
]);

Future<void> _pump(
  WidgetTester tester,
  DuoPose pose, {
  Locale locale = const Locale('fr'),
}) async {
  setDuoPose(tester, pose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [isMazlProProvider.overrideWithValue(false)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: duoAppBuilder(DuoPoseController(pose)),
        home: ProfileViewScreen(userId: '201', apiService: _api()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await settleFold(tester);
}

Rect _text(WidgetTester tester, Pattern text) =>
    tester.getRect(find.textContaining(text, findRichText: true).first);

AppLocalizations _l10n(Locale locale) => lookupAppLocalizations(locale);

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('book: the name is left of the fold, the text and the actions '
      'right', (tester) async {
    await _pump(tester, DuoPose.halfOpenBook);
    final fold = DuoPose.halfOpenBook.fold!;
    final l10n = _l10n(const Locale('fr'));
    expect(_text(tester, 'Rachel').right, lessThanOrEqualTo(fold.left));
    expect(_text(tester, _bio).left, greaterThanOrEqualTo(fold.right));
    expect(_text(tester, _looking).left, greaterThanOrEqualTo(fold.right));
    expect(
      _text(tester, l10n.profileLikeName('Rachel')).left,
      greaterThanOrEqualTo(fold.right),
    );
    expect(
      _text(tester, l10n.profileReportThisProfile).left,
      greaterThanOrEqualTo(fold.right),
    );
  });

  testWidgets('book in Hebrew: the name is on the right page, the text left', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook, locale: const Locale('he'));
    final fold = DuoPose.halfOpenBook.fold!;
    expect(_text(tester, 'Rachel').left, greaterThanOrEqualTo(fold.right));
    expect(_text(tester, _bio).right, lessThanOrEqualTo(fold.left));
  });

  testWidgets('laptop: unchanged, one column with the name above the text', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenLaptop);
    final name = _text(tester, 'Rachel');
    final bio = _text(tester, _bio);
    expect(name.left, bio.left);
    expect(name.top, lessThan(bio.top));
  });
}
