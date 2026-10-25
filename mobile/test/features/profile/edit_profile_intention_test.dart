import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/presentation/features/profile/screens/edit_profile_screen.dart';

import '../../helpers/l10n_helpers.dart';
import '../../presentation/privacy/privacy_fakes.dart';

/// What `PUT /api/profile` accepts for `relationshipIntention`
/// (src/shared/http/validation.ts).
const _serverIntentions = ['marriage', 'serious', 'open', 'friends_first'];

/// Opens the profile editor on a member whose profile holds [stored] as
/// intention, saves, and returns the body of the `PUT /api/profile`.
Future<Map<String, dynamic>?> _saveWithStoredIntention(
  WidgetTester tester,
  String stored,
) async {
  Map<String, dynamic>? sent;
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await http.runWithClient(() async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/edit', builder: (_, _) => const EditProfileScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyConsentApiProvider.overrideWithValue(
            FakePrivacyConsentApi(granted: true, version: '2026-10-24'),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          routerConfig: router,
        ),
      ),
    );
    unawaited(router.push('/edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
  }, () => MockClient((request) async {
    final json = {'content-type': 'application/json; charset=utf-8'};
    switch ((request.method, request.url.path)) {
      case ('GET', '/api/auth/me'):
        return http.Response(
          jsonEncode({
            'success': true,
            'user': {'id': 1, 'email': 'jeanne@example.com'},
            'profile': {
              'id': 1,
              'user_id': 1,
              'display_name': 'Jeanne Exemple',
              'relationship_intention': stored,
            },
          }),
          200,
          headers: json,
        );
      case ('PUT', '/api/profile'):
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'success': true,
            'profile': {'id': 1, 'user_id': 1},
          }),
          200,
          headers: json,
        );
      default:
        return http.Response(
          jsonEncode({'success': true, 'photos': [], 'prompts': []}),
          200,
          headers: json,
        );
    }
  }));
  return sent;
}

void main() {
  testWidgets('a profile stored with « Mariage » is saved back as the server word', (
    tester,
  ) async {
    final body = await _saveWithStoredIntention(tester, 'Mariage');
    expect(body, isNotNull);
    expect(_serverIntentions, contains(body!['relationshipIntention']));
    expect(body['relationshipIntention'], 'marriage');
  });

  testWidgets('a profile stored with « Je ne sais pas » is saved without it', (
    tester,
  ) async {
    final body = await _saveWithStoredIntention(tester, 'Je ne sais pas');
    expect(body, isNotNull);
    expect(body!['relationshipIntention'], isNull);
  });

  testWidgets('a profile stored with a server word keeps it', (tester) async {
    final body = await _saveWithStoredIntention(tester, 'friends_first');
    expect(body!['relationshipIntention'], 'friends_first');
  });
}
