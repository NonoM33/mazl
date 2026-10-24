import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/services/websocket_service.dart';
import 'package:mazl/presentation/features/couple/screens/couple_mode_setup_screen.dart';
import 'package:mazl/presentation/features/couple/screens/mazel_tov_screen.dart';
import 'package:mazl/presentation/features/couple/widgets/couple_flow_host.dart';
import 'package:mazl/presentation/features/couple/widgets/couple_request_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/l10n_helpers.dart';
import '../couple_flow_fakes.dart';
import 'text_fit.dart';

const _languages = [
  Locale('fr'),
  Locale('en'),
  Locale('he'),
  Locale('es'),
  Locale('ru'),
];

Future<ApiResponse<List<Map<String, dynamic>>>> _twoMatches() async =>
    ApiResponse.success([
      for (final (i, name) in ['Myriam', 'Noé'].indexed)
        {
          'id': i + 1,
          'profile': {'user_id': 40 + i, 'display_name': name, 'picture': null},
        },
    ]);

void main() {
  late FakeCoupleApi api;
  late CoupleService service;

  setUpAll(loadAppFont);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeCoupleApi();
    service = CoupleService.forTesting(
      api: api,
      pollInterval: const Duration(hours: 1),
    );
  });

  tearDown(() => service.dispose());

  group('mise en place du mode couple', () {
    Future<void> pumpSetup(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      Brightness brightness = Brightness.light,
    }) async {
      await pumpLocalized(
        tester,
        CoupleModeSetupScreen(service: service, loadMatches: _twoMatches),
        locale: locale,
        brightness: brightness,
      );
      await tester.pump();
    }

    testWidgets('en anglais : titre, choix et envoi', (tester) async {
      await pumpSetup(tester);
      expect(find.text('Couple mode'), findsOneWidget);
      expect(find.text('Who with?'), findsOneWidget);

      await tester.tap(find.text('Myriam'));
      await tester.pump();
      await tester.tap(find.text('Send request'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Request sent'), findsOneWidget);
      expect(
        find.text(
          "Myriam needs to accept. We'll let you know as soon as they answer.",
        ),
        findsOneWidget,
      );
      expect(find.text('Got it'), findsOneWidget);
      await service.cancelCoupleRequest();
    });

    testWidgets(
      'un refus du serveur se dit dans la langue, pas en texte brut',
      (tester) async {
        api.sendError = 'not_matched';
        await pumpSetup(tester);
        await tester.tap(find.text('Myriam'));
        await tester.pump();
        await tester.tap(find.text('Send request'));
        await tester.pump();
        await tester.pump();

        expect(
          find.text('Couple mode can only be turned on with a match.'),
          findsOneWidget,
        );
        expect(find.text('not_matched'), findsNothing);
      },
    );

    testWidgets('la demande sans nom connu a sa propre phrase', (tester) async {
      api.sent = [
        {...contractSentRequest(), 'target_name': null},
      ];
      await service.refresh();
      expect(service.pendingRequest?.targetName, isNull);
      await pumpSetup(tester);
      expect(
        find.text(
          "This person needs to accept. We'll let you know as soon as they answer.",
        ),
        findsOneWidget,
      );
      await service.cancelCoupleRequest();
    });

    testWidgets(
      'en hébreu : de droite à gauche, la flèche de retour se retourne',
      (tester) async {
        await pumpSetup(tester, locale: const Locale('he'));
        expect(find.text('מצב זוגי'), findsOneWidget);
        expect(
          textDirectionAt(tester, find.text('מצב זוגי')),
          TextDirection.rtl,
        );

        // La flèche « retour » de la barre pointe vers la droite en hébreu.
        final back = find.byIcon(LucideIcons.arrowLeft);
        expect(back, findsOneWidget);
        final flipped = tester.widget<Transform>(
          find.ancestor(of: back, matching: find.byType(Transform)).first,
        );
        expect(flipped.transform.storage[0], -1);
      },
    );

    for (final locale in _languages) {
      for (final brightness in Brightness.values) {
        testWidgets(
          '${locale.languageCode} ${brightness.name} : choix et confirmation sans débordement',
          (tester) async {
            await pumpSetup(tester, locale: locale, brightness: brightness);
            expect(tester.takeException(), isNull);
            expect(wordsTooWide(tester), isEmpty);

            await tester.tap(find.text('Myriam'));
            await tester.pump();
            await tester.tap(find.byType(ElevatedButton));
            await tester.pump();
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(wordsTooWide(tester), isEmpty);
            await service.cancelCoupleRequest();
          },
        );
      }
    }
  });

  group('demande reçue', () {
    final request = CoupleRequest.fromJson(contractReceivedRequest());

    Future<void> pumpDialog(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      Brightness brightness = Brightness.light,
      CoupleRequest? custom,
    }) async {
      await pumpLocalized(
        tester,
        Scaffold(
          body: CoupleRequestDialog(
            request: custom ?? request,
            service: service,
          ),
        ),
        locale: locale,
        brightness: brightness,
      );
    }

    testWidgets('en anglais', (tester) async {
      await pumpDialog(tester);
      expect(
        find.text('Myriam would like to turn on couple mode with you'),
        findsOneWidget,
      );
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('No, thanks'), findsOneWidget);
    });

    testWidgets('sans nom connu : phrase sans nom', (tester) async {
      final anonymous = CoupleRequest.fromJson({
        ...contractReceivedRequest(),
        'requester_name': '',
      });
      await pumpDialog(tester, custom: anonymous);
      expect(
        find.text('This person would like to turn on couple mode with you'),
        findsOneWidget,
      );
    });

    testWidgets('une demande retirée entre-temps est dite dans la langue', (
      tester,
    ) async {
      api.received = [contractReceivedRequest()];
      await service.refresh();
      api
        ..respondError = 'Couple request is no longer pending'
        ..received = [];
      await pumpLocalized(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => CoupleRequestDialog.show(
                context,
                request: request,
                service: service,
              ),
              child: const Text('open'),
            ),
          ),
        ),
        locale: const Locale('en'),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(find.text('This request is no longer pending.'), findsOneWidget);
    });

    for (final locale in _languages) {
      for (final brightness in Brightness.values) {
        testWidgets(
          '${locale.languageCode} ${brightness.name} : sans débordement',
          (tester) async {
            await pumpDialog(tester, locale: locale, brightness: brightness);
            expect(tester.takeException(), isNull);
            expect(wordsTooWide(tester), isEmpty);
          },
        );
      }
    }
  });

  group('Mazal tov', () {
    Future<void> pumpMazelTov(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      Brightness brightness = Brightness.light,
    }) async {
      await pumpLocalized(
        tester,
        const MazelTovScreen(partnerName: 'Myriam'),
        locale: locale,
        brightness: brightness,
      );
      await tester.pump(const Duration(seconds: 2));
    }

    testWidgets('en anglais : le titre, le message et le bouton', (
      tester,
    ) async {
      await pumpMazelTov(tester);
      expect(find.text('מזל טוב'), findsOneWidget);
      expect(find.text('Mazel tov'), findsOneWidget);
      expect(find.text('Congratulations to you and Myriam'), findsOneWidget);
      expect(
        find.text('MAZL is with you on this new chapter.'),
        findsOneWidget,
      );
      expect(find.text('Start our adventure'), findsOneWidget);
    });

    testWidgets(
      'en hébreu : le titre est la bénédiction, écrite une seule fois',
      (tester) async {
        await pumpMazelTov(tester, locale: const Locale('he'));
        expect(find.text('מזל טוב'), findsOneWidget);
        expect(
          textDirectionAt(tester, find.text('מזל טוב')),
          TextDirection.rtl,
        );
      },
    );

    for (final locale in _languages) {
      for (final brightness in Brightness.values) {
        testWidgets(
          '${locale.languageCode} ${brightness.name} : sans débordement',
          (tester) async {
            await pumpMazelTov(tester, locale: locale, brightness: brightness);
            expect(tester.takeException(), isNull);
            expect(wordsTooWide(tester), isEmpty);
          },
        );
      }
    }
  });

  group('hôte du flux (messages brefs et archivage)', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late GoRouter router;

    Future<void> pumpHost(WidgetTester tester, Locale locale) async {
      navigatorKey = GlobalKey<NavigatorState>();
      router = GoRouter(
        navigatorKey: navigatorKey,
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('home')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          routerConfig: router,
          builder: (context, child) => CoupleFlowHost(
            service: service,
            router: router,
            navigatorKey: navigatorKey,
            realtime: const Stream<ChatEvent>.empty(),
            auth: ValueNotifier<int>(0),
            isAuthenticated: () => true,
            child: child!,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('la fin du couple se dit dans la langue', (tester) async {
      api.couple = contractCouple();
      await pumpHost(tester, const Locale('en'));
      await service.initialize();
      expect(service.isCoupleModeEnabled, isTrue);

      api.couple = null;
      await service.refresh();
      await tester.pump();
      await tester.pump();

      expect(find.text('Couple mode has ended.'), findsOneWidget);
    });

    testWidgets('la phrase d\'archivage part dans la langue de l\'app', (
      tester,
    ) async {
      await pumpHost(tester, const Locale('en'));
      api
        ..received = [contractReceivedRequest()]
        ..acceptedCouple = contractCouple();
      await service.refresh();
      await service.acceptCoupleRequest(service.receivedRequest!);
      await tester.pump();

      expect(api.archiveMessages, [
        "I found love on Mazl. I'm no longer available. Good luck with your search.",
      ]);
    });

    testWidgets('en français, la phrase d\'archivage est celle d\'avant', (
      tester,
    ) async {
      await pumpHost(tester, const Locale('fr'));
      api
        ..received = [contractReceivedRequest()]
        ..acceptedCouple = contractCouple();
      await service.refresh();
      await service.acceptCoupleRequest(service.receivedRequest!);
      await tester.pump();

      expect(api.archiveMessages, [
        "J'ai trouvé l'amour sur Mazl. Je ne suis plus disponible. Bonne chance dans votre recherche.",
      ]);
    });
  });
}
