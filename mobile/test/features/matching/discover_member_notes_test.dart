import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/profile.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/matching/widgets/discover_member_notes.dart';

import '../../helpers/l10n_helpers.dart';

// What a Discover card says beyond the profile: « De passage à X » for a
// member using the Passeport, a Super Like mark and its word.

Profile _profile({bool superLiked = false, String? note, String? traveling}) =>
    Profile(
      id: 1,
      userId: 101,
      superLikedYou: superLiked,
      superLikeNote: note,
      travelingCity: traveling,
    );

Future<void> _pump(
  WidgetTester tester,
  Profile profile, {
  Locale locale = kTestLocale,
  Brightness brightness = Brightness.light,
}) async {
  await pumpLocalized(
    tester,
    Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: DiscoverMemberNotes(profile: profile),
      ),
    ),
    locale: locale,
    brightness: brightness,
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a plain profile draws nothing', (tester) async {
    await _pump(tester, _profile());
    expect(find.byKey(const ValueKey('discover-traveling')), findsNothing);
    expect(find.byKey(const ValueKey('discover-super-liked')), findsNothing);
  });

  testWidgets('a member passing through a suggested city: its translated '
      'name', (tester) async {
    await _pump(tester, _profile(traveling: 'Tel Aviv'));
    expect(find.text('De passage à Tel-Aviv'), findsOneWidget);
  });

  testWidgets('a member passing through any other city: the city as it is', (
    tester,
  ) async {
    await _pump(tester, _profile(traveling: 'Haïfa'));
    expect(find.text('De passage à Haïfa'), findsOneWidget);
  });

  testWidgets('the name follows the language', (tester) async {
    await _pump(
      tester,
      _profile(traveling: 'London'),
      locale: const Locale('en'),
    );
    expect(find.text('Visiting London'), findsOneWidget);
    await _pump(
      tester,
      _profile(traveling: 'London'),
      locale: const Locale('he'),
    );
    expect(find.text('בביקור בלונדון'), findsOneWidget);
  });

  testWidgets('a Super Like with its word shows the mark and the word', (
    tester,
  ) async {
    await _pump(
      tester,
      _profile(superLiked: true, note: 'Votre playlist de Shabbat est top.'),
    );
    expect(find.text('Vous a envoyé un Super Like'), findsOneWidget);
    expect(find.text('« Votre playlist de Shabbat est top. »'), findsOneWidget);
  });

  testWidgets('a Super Like with no word shows the mark only', (tester) async {
    await _pump(tester, _profile(superLiked: true));
    expect(find.text('Vous a envoyé un Super Like'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('discover-super-like-note')),
      findsNothing,
    );
  });

  testWidgets('a word without the Super Like flag is not shown', (
    tester,
  ) async {
    await _pump(tester, _profile(note: 'Orphan word'));
    expect(find.textContaining('Orphan'), findsNothing);
    expect(find.byKey(const ValueKey('discover-super-liked')), findsNothing);
  });

  testWidgets('both marks together, in dark mode, fit a 360 pt phone', (
    tester,
  ) async {
    await _pump(
      tester,
      _profile(superLiked: true, note: 'x' * 140, traveling: 'New York'),
      brightness: Brightness.dark,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('De passage à New York'), findsOneWidget);
    expect(find.byKey(const ValueKey('discover-super-liked')), findsOneWidget);
  });

  testWidgets('on a short window the marks are chips on one line', (
    tester,
  ) async {
    await pumpLocalized(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: DiscoverMemberNotes(
            profile: _profile(
              superLiked: true,
              note: 'Votre playlist de Shabbat m’a donné envie de vous écrire.',
              traveling: 'Tel Aviv',
            ),
          ),
        ),
      ),
      size: const Size(678, 466),
    );
    expect(tester.takeException(), isNull);
    final pill = tester.getRect(
      find.byKey(const ValueKey('discover-traveling')),
    );
    final chip = tester.getRect(
      find.byKey(const ValueKey('discover-super-liked')),
    );
    expect(pill.height, lessThanOrEqualTo(32));
    expect(chip.height, lessThanOrEqualTo(32));
    expect(
      (pill.center.dy - chip.center.dy).abs(),
      lessThan(1),
      reason: 'both on the same line',
    );
  });

  testWidgets('the detailed half shows the whole word', (tester) async {
    final word = 'Un mot très long. ' * 7;
    await pumpLocalized(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: DiscoverMemberNotes(
            profile: _profile(superLiked: true, note: word.trim()),
            detailed: true,
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(
      find.byKey(const ValueKey('discover-super-like-note')),
    );
    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
  });

  testWidgets('elsewhere the word is limited to three lines', (tester) async {
    await _pump(tester, _profile(superLiked: true, note: 'x' * 140));
    final text = tester.widget<Text>(
      find.byKey(const ValueKey('discover-super-like-note')),
    );
    expect(text.maxLines, 3);
  });

  group('contrast (AA, 4.5:1) in both themes', () {
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final scheme = theme.colorScheme;
      final name = theme.brightness.name;
      test('$name: the Super Like block text on its fill', () {
        expect(
          ratio(scheme.onPrimaryContainer, scheme.primaryContainer),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('$name: the traveling pill text on its fill', () {
        expect(
          ratio(scheme.onSurface, scheme.surfaceContainerHighest),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });
}
