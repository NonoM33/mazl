import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/core/matching/discover_filters_providers.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/matching/screens/filters_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../presentation/privacy/privacy_fakes.dart';
import 'discover_filters_fakes.dart';

// The search filters on the foldable iPhone (iPhone Duo). Held like a book the
// search (age, distance) and the denomination are on the reading-start page,
// the other religious criteria and the options on the other one, the apply
// button on a side; set down like a laptop and flat it is one list.

class _Profile implements ApiService {
  @override
  Future<ApiResponse<UserProfile>> getCurrentUser() async =>
      ApiResponse.failure('offline');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_Profile: ${invocation.memberName}');
}

Future<void> _pump(
  WidgetTester tester,
  DuoPose pose, {
  Locale locale = const Locale('fr'),
}) async {
  setDuoPose(tester, pose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoverFiltersApiProvider.overrideWithValue(FakeDiscoverFiltersApi()),
        privacyConsentApiProvider.overrideWithValue(FakePrivacyConsentApi()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: duoAppBuilder(DuoPoseController(pose)),
        home: FiltersScreen(apiService: _Profile()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await settleFold(tester);
}

AppLocalizations _l10n(Locale locale) => lookupAppLocalizations(locale);

Rect _rect(WidgetTester tester, String text) => tester.getRect(find.text(text));

void main() {
  setUpAll(loadAppFonts);

  const fr = Locale('fr');
  const he = Locale('he');

  testWidgets('book: age, distance and denomination left, the rest right', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook);
    final fold = DuoPose.halfOpenBook.fold!;
    final l10n = _l10n(fr);
    for (final title in [
      l10n.matchingFiltersAge,
      l10n.matchingFiltersDistance,
      l10n.matchingFiltersDenomination,
    ]) {
      expect(
        _rect(tester, title).right,
        lessThanOrEqualTo(fold.left),
        reason: title,
      );
    }
    for (final title in [
      l10n.matchingFiltersKashrut,
      l10n.matchingFiltersShabbatSection,
      l10n.matchingFiltersOptions,
    ]) {
      expect(
        _rect(tester, title).left,
        greaterThanOrEqualTo(fold.right),
        reason: title,
      );
    }
  });

  testWidgets('book in Hebrew: the search is on the right page', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook, locale: he);
    final fold = DuoPose.halfOpenBook.fold!;
    final l10n = _l10n(he);
    expect(
      _rect(tester, l10n.matchingFiltersAge).left,
      greaterThanOrEqualTo(fold.right),
    );
    expect(
      _rect(tester, l10n.matchingFiltersKashrut).right,
      lessThanOrEqualTo(fold.left),
    );
  });

  testWidgets('book: the apply button sits on one side of the fold', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook);
    await tester.tap(find.text('Massorti'));
    await settleFold(tester);
    await settleFold(tester);
    final button = tester.getRect(find.text(_l10n(fr).matchingFiltersApply));
    final fold = DuoPose.halfOpenBook.fold!;
    expect(button.overlaps(fold), isFalse, reason: '$button vs $fold');
  });

  testWidgets('laptop: unchanged, one list in the same order', (tester) async {
    await _pump(tester, DuoPose.halfOpenLaptop);
    final l10n = _l10n(fr);
    final age = _rect(tester, l10n.matchingFiltersAge);
    final distance = _rect(tester, l10n.matchingFiltersDistance);
    final denomination = _rect(tester, l10n.matchingFiltersDenomination);
    expect(age.left, distance.left);
    expect(age.top, lessThan(distance.top));
    expect(distance.top, lessThan(denomination.top));
  });
}
