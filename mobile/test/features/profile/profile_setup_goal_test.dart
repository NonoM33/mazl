import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/presentation/features/profile/screens/profile_setup_screen.dart';

import '../../helpers/test_helpers.dart';
import '../../presentation/privacy/privacy_fakes.dart';

/// What `PUT /api/profile` accepts for `relationshipIntention`
/// (src/shared/http/validation.ts): any other word is a 400, which is what
/// the sign-up got when the member picked a goal.
const _serverIntentions = ['marriage', 'serious', 'open', 'friends_first'];

/// Fills the first step, walks to the last one and picks [goal] there.
/// Returns the body of the `PUT /api/profile` the app sends on « Terminer ».
Future<Map<String, dynamic>?> _finishWithGoal(
  WidgetTester tester,
  String? goal,
) async {
  Map<String, dynamic>? sent;
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await http.runWithClient(() async {
    await tester.pumpWidget(
      createTestableWidget(
        const ProfileSetupScreen(),
        overrides: [
          privacyConsentApiProvider.overrideWithValue(
            FakePrivacyConsentApi(granted: true, version: '2026-10-24'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prénom'),
      'Jeanne',
    );
    await tester.tap(find.byIcon(LucideIcons.calendar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Une femme'));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Un homme'));
    await tester.pump();
    if (goal != null) {
      await tester.tap(find.text(goal));
      await tester.pump();
    }
    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();
  }, () => MockClient((request) async {
    if (request.method == 'PUT' && request.url.path == '/api/profile') {
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'success': true,
          'profile': {'id': 1, 'user_id': 1},
        }),
        200,
      );
    }
    // The consent and the profile completeness reads: not what is tested.
    return http.Response(jsonEncode({'success': true}), 200);
  }));
  return sent;
}

void main() {
  testWidgets('« Mariage » is sent as the server word, not as French text', (
    tester,
  ) async {
    final body = await _finishWithGoal(tester, 'Mariage');
    expect(body, isNotNull);
    expect(_serverIntentions, contains(body!['relationshipIntention']));
    expect(body['relationshipIntention'], 'marriage');
  });

  testWidgets('« Relation sérieuse » is sent as the server word', (
    tester,
  ) async {
    final body = await _finishWithGoal(tester, 'Relation sérieuse');
    expect(body!['relationshipIntention'], 'serious');
  });

  testWidgets('« Je ne sais pas » sends no intention', (tester) async {
    final body = await _finishWithGoal(tester, 'Je ne sais pas');
    expect(body, isNotNull);
    expect(body!['relationshipIntention'], isNull);
  });

  testWidgets('no goal chosen: no intention sent either', (tester) async {
    final body = await _finishWithGoal(tester, null);
    expect(body, isNotNull);
    expect(body!['relationshipIntention'], isNull);
  });
}
