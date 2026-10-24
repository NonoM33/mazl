import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/services/store/credits_service.dart';
import 'package:mazl/presentation/features/matching/screens/daily_picks_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_helpers.dart';
import '../../support/credits_fakes.dart';
import '../../support/store_fakes.dart';

class _Api implements ApiService {
  _Api(this.picks, {this.refuse = false});

  final List<Profile> picks;
  final bool refuse;
  final List<String> swipes = [];

  @override
  Future<ApiResponse<List<Profile>>> getDailyPicks() async =>
      ApiResponse.success(picks);

  @override
  Future<ApiResponse<Map<String, dynamic>>> sendSwipe({
    required int targetUserId,
    required String action,
  }) async {
    swipes.add('$targetUserId:$action');
    if (!refuse) {
      return ApiResponse.success(<String, dynamic>{'match': false});
    }
    CreditsService().applyFromServer(
      serverCredits(superLikeRemaining: 0, superLikePurchased: 0),
    );
    return ApiResponse(
      success: false,
      errorKind: ApiErrorKind.creditsExhausted,
      errorCode: 'super_likes_exhausted',
      statusCode: 402,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_Api: ${invocation.memberName}');
}

List<Profile> _picks() => [
  for (var i = 1; i <= 2; i++)
    Profile(
      id: i,
      userId: 100 + i,
      displayName: 'Jeanne$i',
      age: 20 + i,
      location: 'Paris',
    ),
];

Future<void> _pump(WidgetTester tester, _Api api) async {
  await pumpLocalized(tester, DailyPicksScreen(apiService: api));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _tapStar(WidgetTester tester) async {
  await tester.tap(find.byIcon(LucideIcons.star).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late CreditsService credits;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
    PremiumGate.debugPremiumOverride = false;
    credits = installTestCredits(
      gateway: FakeStoreGateway()
        ..productResponse = ProductDetailsResponse(
          productDetails: [
            storeProduct(testSuperLikePackId, price: 3.99),
            storeProduct('com.mazl.app.superlikes.15', price: 9.99),
          ],
          notFoundIDs: const [],
        ),
    );
  });

  tearDown(PremiumGate.resetForTest);

  testWidgets('avec un Super Like en solde : il part, la carte s\'en va', (
    tester,
  ) async {
    credits.applyFromServer(serverCredits());
    final api = _Api(_picks());
    await _pump(tester, api);

    await _tapStar(tester);

    expect(api.swipes, ['101:super_like']);
    expect(find.textContaining('Jeanne1'), findsNothing);
    expect(find.text('Vous n’avez plus de Super Likes.'), findsNothing);
  });

  testWidgets('solde à zéro : la feuille « packs », aucun envoi', (
    tester,
  ) async {
    credits.applyFromServer(
      serverCredits(superLikeRemaining: 0, superLikePurchased: 0),
    );
    final api = _Api(_picks());
    await _pump(tester, api);

    await _tapStar(tester);

    expect(api.swipes, isEmpty);
    expect(find.text('Vous n’avez plus de Super Likes.'), findsOneWidget);
    expect(find.text('5 Super Likes'), findsOneWidget);
    expect(find.textContaining('Jeanne1'), findsOneWidget);
  });

  testWidgets('le serveur répond 402 malgré le solde : la feuille s\'ouvre', (
    tester,
  ) async {
    credits.applyFromServer(serverCredits());
    final api = _Api(_picks(), refuse: true);
    await _pump(tester, api);

    await _tapStar(tester);

    expect(api.swipes, ['101:super_like']);
    expect(find.text('Vous n’avez plus de Super Likes.'), findsOneWidget);
    expect(find.textContaining('Jeanne1'), findsOneWidget);
  });
}
