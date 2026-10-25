import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/presentation/features/matching/screens/discover_screen.dart';
import 'package:mazl/presentation/features/matching/widgets/avatar_ring.dart';
import 'package:mazl/presentation/features/matching/widgets/discover_card.dart';
import 'package:mazl/presentation/features/matching/widgets/match_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/l10n_helpers.dart';
import '../../../mocks/fake_discover_api.dart';
import 'l10n_harness.dart';

/// The server is down: it answers with the English diagnostic that used to
/// leak onto the screen.
class _DownDiscoverApi extends FakeDiscoverApi {
  _DownDiscoverApi(this.kind) : super(const []);

  final ApiErrorKind kind;

  @override
  Future<ApiResponse<List<Profile>>> getDiscoverProfiles({
    int limit = 20,
    int offset = 0,
  }) async => ApiResponse.failure('Failed to get matches', kind);
}

final _jeanne = Profile(
  id: 1,
  userId: 101,
  displayName: 'Jeanne',
  age: 28,
  location: 'Paris',
  distance: 12,
  isVerified: true,
);

const _frenchCard = [
  'Passer',
  "J'aime",
  'Vérifiée',
  'Voir le profil',
  'Sélections du jour',
  'Filtres',
];

Future<void> _pumpDiscover(
  WidgetTester tester,
  FakeDiscoverApi api,
  L10nCase c,
) async {
  await pumpLocalized(
    tester,
    DiscoverScreen(apiService: api),
    locale: c.locale,
    brightness: c.brightness,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('English card: buttons, distance, verification', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpDiscover(tester, FakeDiscoverApi([_jeanne]), l10nCases.first);
    expect(find.bySemanticsLabel('Pass'), findsOneWidget);
    expect(find.bySemanticsLabel('Like'), findsOneWidget);
    expect(find.bySemanticsLabel('Super like'), findsOneWidget);
    expect(find.bySemanticsLabel('Undo'), findsNothing);
    expect(find.bySemanticsLabel('Boost'), findsOneWidget);
    expect(find.bySemanticsLabel('Daily picks'), findsOneWidget);
    expect(find.bySemanticsLabel('Filters'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Paris · 12 km away'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Hebrew card reads right to left', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpDiscover(
      tester,
      FakeDiscoverApi([_jeanne]),
      const L10nCase(Locale('he'), Brightness.light),
    );
    expect(find.bySemanticsLabel('לדלג'), findsOneWidget);
    expect(find.bySemanticsLabel('בוסט'), findsOneWidget);
    expect(find.text('פרופיל מאומת'), findsOneWidget);
    expect(find.text('Paris · במרחק 12 ק״מ'), findsOneWidget);
    expect(
      textDirectionAt(tester, find.text('פרופיל מאומת')),
      TextDirection.rtl,
    );
    semantics.dispose();
  });

  for (final c in l10nCases) {
    testWidgets('card in ${c.name}', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpDiscover(tester, FakeDiscoverApi([_jeanne]), c);
      expectNoFrench(_frenchCard);
      for (final tooltip in _frenchCard) {
        expect(find.bySemanticsLabel(tooltip), findsNothing, reason: tooltip);
      }
      expectDirection(tester, find.byType(DiscoverCard), c);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('empty state in ${c.name}', (tester) async {
      await _pumpDiscover(tester, FakeDiscoverApi(const []), c);
      expectNoFrench([
        'Vous avez tout vu.',
        'Revenez plus tard ou élargissez vos filtres pour voir de nouveaux profils.',
        'Ouvrir les filtres',
        'Actualiser',
      ]);
      expectDirection(tester, find.byType(OutlinedButton), c);
      // « Refresh » starts on the same edge as the title, on the reading side.
      final l10n = lookupAppLocalizations(c.locale);
      final title = tester.getRect(find.text(l10n.matchingDiscoverEmptyTitle));
      final refresh = tester.getRect(find.text(l10n.matchingDiscoverRefresh));
      if (c.isRtl) {
        expect(refresh.right, closeTo(title.right, 1), reason: c.name);
      } else {
        expect(refresh.left, closeTo(title.left, 1), reason: c.name);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed load speaks ${c.name}, never the diagnostic', (
      tester,
    ) async {
      await _pumpDiscover(tester, _DownDiscoverApi(ApiErrorKind.network), c);
      expect(find.text('Failed to get matches'), findsNothing);
      expectNoFrench(['Réessayer', 'Erreur de chargement']);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('match sheet in ${c.name}', (tester) async {
      await pumpLocalized(
        tester,
        Scaffold(
          body: MatchSheetContent(matched: _jeanne, myName: 'Renaud'),
        ),
        locale: c.locale,
        brightness: c.brightness,
      );
      await tester.pump(const Duration(seconds: 2));
      expectNoFrench([
        "C'est un match",
        'Jeanne et vous vous êtes plu.',
        'Envoyer un message',
        'Continuer à découvrir',
      ]);
      expectDirection(tester, find.byType(ElevatedButton), c);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('English failed load', (tester) async {
    await _pumpDiscover(
      tester,
      _DownDiscoverApi(ApiErrorKind.network),
      l10nCases.first,
    );
    expect(
      find.text('No connection. Check your network and try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('English empty state', (tester) async {
    await _pumpDiscover(tester, FakeDiscoverApi(const []), l10nCases.first);
    expect(find.text("You've seen everyone."), findsOneWidget);
    expect(find.text('Open filters'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
  });

  testWidgets('English match sheet', (tester) async {
    await pumpLocalized(
      tester,
      Scaffold(body: MatchSheetContent(matched: _jeanne)),
      locale: const Locale('en'),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text("It's a match!"), findsOneWidget);
    expect(find.text('You and Jeanne liked each other.'), findsOneWidget);
    expect(find.text('Send a message'), findsOneWidget);
    expect(find.text('Keep discovering'), findsOneWidget);
  });

  testWidgets('Russian match sheet and avatar labels', (tester) async {
    await pumpLocalized(
      tester,
      const Scaffold(
        body: Center(child: AvatarRing(name: 'Жанна', isNew: true)),
      ),
      locale: const Locale('ru'),
    );
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Новый мэтч, Жанна'), findsOneWidget);
    handle.dispose();
  });
}
