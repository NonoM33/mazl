import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/core/di/providers/service_providers.dart';
import 'package:mazl/core/layout/content_max_width.dart';
import 'package:mazl/core/router/app_router.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/profile/screens/profile_setup_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../helpers/test_helpers.dart';
import '../../presentation/privacy/privacy_fakes.dart';

// The sign-up on the foldable iPhone (iPhone Duo): the four steps must fit
// the six postures, with the main button in view and nothing interactive
// under the status bar column or in the fold.

const _stepTitles = [
  'Parlez-nous de vous',
  'Ajoutez des photos',
  'Votre pratique',
  'Ce que vous recherchez',
];

/// The bodies of the `PUT /api/profile` the app sent.
class _Server {
  final List<Map<String, dynamic>> profileBodies = [];

  http.Client client() => MockClient((request) async {
    if (request.method == 'PUT' && request.url.path == '/api/profile') {
      profileBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response(
        jsonEncode({
          'success': true,
          'profile': {'id': 1, 'user_id': 1},
        }),
        200,
      );
    }
    return http.Response(jsonEncode({'success': true}), 200);
  });
}

// One container for the whole file, never closed: closing it would also
// dispose the app's single AuthService (same as removed_screens_test).
final ProviderContainer _container = ProviderContainer(
  overrides: [
    isAuthenticatedProvider.overrideWithValue(true),
    privacyConsentApiProvider.overrideWithValue(
      FakePrivacyConsentApi(granted: true, version: '2026-10-24'),
    ),
  ],
);

/// Opens the sign-up through the real router of the app, in [pose].
Future<DuoPoseController> _openSetup(
  WidgetTester tester,
  DuoPose pose, {
  Locale locale = kTestLocale,
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  final router = _container.read(appRouterProvider)
    ..go(RoutePaths.profileSetup);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _container,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        routerConfig: router,
        builder: duoAppBuilder(controller),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await settleFold(tester);
  return controller;
}

/// The screen alone, on a tall phone, with a stub router behind it.
Future<void> _openPlain(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Fills the first step the way the member does.
Future<void> _fillFirstStep(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Prénom'),
    'Jeanne',
  );
  await _tap(tester, find.byIcon(LucideIcons.calendar));
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Une femme'));
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text('Suivant'));
  await tester.pumpAndSettle();
  await settleFold(tester);
}

Finder get _mainButton => find.byType(ElevatedButton);

void _expectMainButtonInView(WidgetTester tester, DuoPose pose, String reason) {
  expect(_mainButton, findsOneWidget, reason: reason);
  expect(_mainButton.hitTestable(), findsOneWidget, reason: reason);
  final rect = tester.getRect(_mainButton);
  expect(
    pose.safeRect.inflate(0.5).contains(rect.topLeft) &&
        pose.safeRect.inflate(0.5).contains(rect.bottomRight),
    isTrue,
    reason: '$reason: the main button $rect is not inside ${pose.safeRect}',
  );
}

Future<T> _withServer<T>(_Server server, Future<T> Function() body) =>
    http.runWithClient(body, server.client);

void main() {
  group('every posture, every step', () {
    for (final pose in DuoPose.values) {
      testWidgets(
        '${pose.name}: the four steps fit and the button is in view',
        (tester) async {
          await _withServer(_Server(), () async {
            await _openSetup(tester, pose);
            for (var step = 0; step < 4; step++) {
              final reason = 'step ${step + 1}';
              expect(
                find.text(_stepTitles[step]),
                findsOneWidget,
                reason: reason,
              );
              expectFitsDuoPose(tester, pose, reason);
              _expectMainButtonInView(tester, pose, reason);
              if (step == 3) break;
              if (step == 0) await _fillFirstStep(tester);
              await _next(tester);
            }
          });
        },
      );
    }
  });

  group('half open', () {
    testWidgets('laptop: title above the fold, fields and button below', (
      tester,
    ) async {
      await _withServer(_Server(), () async {
        await _openSetup(tester, DuoPose.halfOpenLaptop);
        final fold = DuoPose.halfOpenLaptop.fold!;
        expect(
          tester.getRect(find.text(_stepTitles[0])).bottom,
          lessThanOrEqualTo(fold.top),
        );
        expect(
          tester.getRect(find.widgetWithText(TextFormField, 'Prénom')).top,
          greaterThanOrEqualTo(fold.bottom),
        );
        expect(
          tester.getRect(_mainButton).top,
          greaterThanOrEqualTo(fold.bottom),
        );
        // The header is not repeated inside the page.
        expect(find.text(_stepTitles[0]), findsOneWidget);
      });
    });

    testWidgets('book: title left of the fold, fields and button right', (
      tester,
    ) async {
      await _withServer(_Server(), () async {
        await _openSetup(tester, DuoPose.halfOpenBook);
        final fold = DuoPose.halfOpenBook.fold!;
        expect(
          tester.getRect(find.text(_stepTitles[0])).right,
          lessThanOrEqualTo(fold.left),
        );
        expect(
          tester.getRect(find.widgetWithText(TextFormField, 'Prénom')).left,
          greaterThanOrEqualTo(fold.right),
        );
        expect(
          tester.getRect(_mainButton).left,
          greaterThanOrEqualTo(fold.right),
        );
        expect(find.text(_stepTitles[0]), findsOneWidget);
      });
    });

    testWidgets('book in Hebrew: the title is on the right', (tester) async {
      await _withServer(_Server(), () async {
        await _openSetup(
          tester,
          DuoPose.halfOpenBook,
          locale: const Locale('he'),
        );
        final fold = DuoPose.halfOpenBook.fold!;
        final title = find.byWidgetPredicate(
          (w) => w is Text && w.style?.fontSize == 28,
        );
        expect(title, findsOneWidget);
        expect(tester.getRect(title).left, greaterThanOrEqualTo(fold.right));
        expect(
          tester.getRect(find.byType(TextFormField).first).right,
          lessThanOrEqualTo(fold.left),
        );
        expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'hebrew');
      });
    });
  });

  group('regular width', () {
    for (final pose in [DuoPose.openPortrait, DuoPose.openLandscape]) {
      testWidgets('${pose.name}: the fields stay in the reading column', (
        tester,
      ) async {
        await _withServer(_Server(), () async {
          await _openSetup(tester, pose);
          expect(find.byType(ContentMaxWidth), findsOneWidget);
          final field = find.widgetWithText(TextFormField, 'Prénom');
          expect(
            tester.getSize(field).width,
            lessThanOrEqualTo(kContentMaxWidth),
          );
          expect(
            tester.getSize(_mainButton).width,
            lessThanOrEqualTo(kContentMaxWidth),
          );
        });
      });
    }
  });

  group('main button', () {
    testWidgets('fills the width of the page, margins like the fields', (
      tester,
    ) async {
      await _withServer(_Server(), () async {
        await _openSetup(tester, DuoPose.closed);
        final field = tester.getRect(
          find.widgetWithText(TextFormField, 'Prénom'),
        );
        final button = tester.getRect(_mainButton);
        expect(button.left, field.left);
        expect(button.right, field.right);
      });
    });
  });

  group('folding keeps the sign-up', () {
    testWidgets('step 3 and the typed name survive fold and unfold', (
      tester,
    ) async {
      await _withServer(_Server(), () async {
        final pose = await _openSetup(tester, DuoPose.openPortrait);
        await _fillFirstStep(tester);
        await _next(tester);
        await _next(tester);
        expect(find.text(_stepTitles[2]), findsOneWidget);
        for (final next in [
          DuoPose.halfOpenLaptop,
          DuoPose.openPortrait,
          DuoPose.halfOpenBook,
          DuoPose.closed,
        ]) {
          await pose.moveTo(tester, next);
          await tester.pumpAndSettle();
          expect(find.text(_stepTitles[2]), findsOneWidget, reason: next.name);
        }
        await pose.moveTo(tester, DuoPose.halfOpenLaptop);
        await tester.pumpAndSettle();
        // Back to the first step: the name is still there.
        for (var i = 0; i < 2; i++) {
          await tester.tap(find.byIcon(LucideIcons.arrowLeft));
          await tester.pumpAndSettle();
        }
        expect(find.text(_stepTitles[0]), findsOneWidget);
        expect(find.text('Jeanne'), findsOneWidget);
      });
    });
  });

  group('server limits', () {
    testWidgets(
      'a 60 letter name and a 120 letter city are cut to 50 and 100',
      (tester) async {
        final server = _Server();
        await _withServer(server, () async {
          await _openPlain(tester);
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Prénom'),
            'A' * 60,
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Ville'),
            'B' * 120,
          );
          await tester.tap(find.byIcon(LucideIcons.calendar));
          await tester.pumpAndSettle();
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
          await _tap(tester, find.text('Une femme'));
          for (var i = 0; i < 3; i++) {
            await _next(tester);
          }
          await _tap(tester, find.text('Un homme'));
          await _tap(tester, find.text('Terminer'));
        });
        expect(server.profileBodies, hasLength(1));
        final body = server.profileBodies.single;
        expect((body['displayName'] as String).length, lessThanOrEqualTo(50));
        expect((body['location'] as String).length, lessThanOrEqualTo(100));
      },
    );

    testWidgets('the limit shows no counter', (tester) async {
      await _withServer(_Server(), () async {
        await _openPlain(tester);
        expect(find.text('0/50'), findsNothing);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Prénom'),
          'Jeanne',
        );
        await tester.pump();
        expect(find.text('6/50'), findsNothing);
        expect(find.byType(ProfileSetupScreen), findsOneWidget);
      });
    });
  });
}
