import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/presentation/features/matching/screens/matches_screen.dart';
import 'package:mazl/presentation/features/matching/widgets/avatar_ring.dart';

import '../../helpers/l10n_helpers.dart';

class _FakeMatchesApi implements ApiService {
  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getMatches() async =>
      ApiResponse.success([
        for (var id = 1; id <= 8; id++)
          {
            'conversationId': id,
            'matchedAt': DateTime.now().toIso8601String(),
            'profile': {'user_id': id, 'display_name': 'Membre $id'},
          },
      ]);

  @override
  Future<ApiResponse<LikesData>> getReceivedLikes() async =>
      ApiResponse.failure('no likes');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeMatchesApi: ${invocation.memberName}');
}

// Renaud, 2026-10-27 : « les photos sont encore coupées à gauche quand on
// slide ». The strip of new matches scrolled inside the page's 24 pt margin,
// so a photo sliding left was cut 24 pt before the edge of the column.
void main() {
  testWidgets('the new matches strip scrolls from edge to edge of the column', (
    tester,
  ) async {
    const width = 360.0;
    await pumpLocalized(
      tester,
      MatchesScreen(apiService: _FakeMatchesApi()),
      locale: const Locale('fr'),
      size: const Size(width, 1400),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final strip = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
    );
    expect(strip, findsOneWidget);
    final rect = tester.getRect(strip);
    expect(rect.left, 0, reason: 'the strip must not be clipped by the margin');
    expect(rect.right, width);

    // At rest, the first photo still lines up with the titles.
    final first = tester.getRect(find.byType(AvatarRing).first);
    expect(first.left, 24);

    // Slid left, the photo stays visible up to the edge of the column.
    await tester.drag(strip, const Offset(-80, 0));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getRect(find.byType(AvatarRing).first).left, lessThan(24));
  });
}
