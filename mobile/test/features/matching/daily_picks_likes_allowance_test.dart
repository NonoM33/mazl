import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/presentation/features/matching/screens/daily_picks_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_helpers.dart';
import '../../mocks/fake_discover_api.dart';
import '../../support/credits_fakes.dart';

/// Les sélections du jour envoient le like elle-mêmes : si le serveur n'en
/// prend plus (402 `likes_exhausted`), la sélection reste et l'offre s'ouvre.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
    PremiumGate.debugPremiumOverride = false;
    installTestCredits();
  });

  tearDown(PremiumGate.resetForTest);

  Future<void> pumpPicks(WidgetTester tester, FakeDiscoverApi api) async {
    await pumpLocalized(tester, DailyPicksScreen(apiService: api));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('le serveur refuse le like : la sélection reste, l\'offre s\'ouvre',
      (tester) async {
    final api = FakeDiscoverApi(discoverProfiles(2))..refuseLikes = true;
    await pumpPicks(tester, api);

    await tester.tap(find.byIcon(LucideIcons.heart).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(api.refusedLikes, ['101:like']);
    expect(find.text('Vos likes du jour sont partis.'), findsOneWidget);
    expect(find.textContaining('Profil1'), findsWidgets);
  });

  testWidgets('un like accepté retire la sélection, sans feuille', (
    tester,
  ) async {
    final api = FakeDiscoverApi(discoverProfiles(2));
    await pumpPicks(tester, api);

    await tester.tap(find.byIcon(LucideIcons.heart).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(api.swipes, ['101:like']);
    expect(find.text('Vos likes du jour sont partis.'), findsNothing);
    expect(find.textContaining('Profil1'), findsNothing);
  });
}
