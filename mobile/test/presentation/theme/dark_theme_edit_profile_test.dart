import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/profile/screens/edit_profile_screen.dart';

import '../../helpers/l10n_helpers.dart';
import '../../support/dark_theme_audit.dart';
import '../privacy/privacy_fakes.dart';

// Vu sur iPhone en mode sombre : la feuille « Choisissez un prompt », la carte
// de prompt et les puces « Ce que je recherche » restaient BLANCHES alors que
// le texte devenait clair : du gris clair sur du blanc.

MockClient _server() => MockClient((request) async {
  final json = {'content-type': 'application/json; charset=utf-8'};
  Map<String, Object?> body;
  switch (request.url.path) {
    case '/api/auth/me':
      body = {
        'success': true,
        'user': {'id': 1, 'email': 'jeanne@example.com'},
        'profile': {
          'id': 1,
          'user_id': 1,
          'display_name': 'Jeanne Exemple',
          'relationship_intention': 'serious',
        },
      };
    case '/api/prompts':
      body = {
        'success': true,
        'prompts': [
          {'id': 'perfect_sunday', 'text': 'x', 'category': 'personality'},
          {'id': 'fun_fact', 'text': 'x', 'category': 'personality'},
        ],
      };
    case '/api/profile/prompts':
      body = {
        'success': true,
        'prompts': [
          {
            'id': 4,
            'prompt_id': 'life_goal',
            'prompt_text': 'x',
            'answer': 'Ouvrir une librairie à Lyon.',
            'position': 1,
          },
        ],
      };
    default:
      body = {'success': true, 'photos': []};
  }
  return http.Response(jsonEncode(body), 200, headers: json);
});

Future<void> _pumpDark(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: kTestLocale,
        builder: darkCaptureBuilder,
        routerConfig: router,
      ),
    ),
  );
  unawaited(router.push('/edit'));
  await tester.pumpAndSettle();
}

Iterable<Color> _surfaceColors(WidgetTester tester, Finder inside) sync* {
  for (final box in tester.widgetList<DecoratedBox>(
    find.descendant(of: inside, matching: find.byType(DecoratedBox)),
  )) {
    final decoration = box.decoration;
    if (decoration is BoxDecoration && decoration.color != null) {
      yield decoration.color!;
    }
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('dark theme: no white surface, every text readable', (
    tester,
  ) async {
    await http.runWithClient(() async {
      await _pumpDark(tester);
      await captureDarkPng(tester, 'modifier-le-profil');

      final prompt = find.text('Ouvrir une librairie à Lyon.');
      expect(prompt, findsOneWidget);
      final card = find.ancestor(of: prompt, matching: find.byType(Container));
      final colors = _surfaceColors(tester, card.first);
      expect(
        colors.where((c) => c.a > 0.9 && c.computeLuminance() > 0.5),
        isEmpty,
        reason: 'la carte de prompt est restée blanche en mode sombre',
      );

      expect(lowContrastTexts(tester), isEmpty);
    }, _server);
  });

  testWidgets('dark theme: the prompt picker sheet is not white', (
    tester,
  ) async {
    await http.runWithClient(() async {
      await _pumpDark(tester);
      await tester.tap(find.text('Ajouter un prompt'));
      await tester.pumpAndSettle();
      await captureDarkPng(tester, 'choisissez-un-prompt');

      expect(find.text('Choisissez un prompt'), findsOneWidget);
      expect(lowContrastTexts(tester), isEmpty);
    }, _server);
  });
}
