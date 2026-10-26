import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_colors.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/couple/screens/couple_mode_setup_screen.dart';
import 'package:mazl/presentation/features/couple/screens/mazel_tov_screen.dart';
import 'package:mazl/presentation/features/couple/widgets/couple_message_view.dart';
import 'package:mazl/presentation/features/couple/widgets/couple_request_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../couple/couple_flow_fakes.dart';
import '../../helpers/l10n_helpers.dart';

const _sizes = [Size(390, 844), Size(360, 740)];
const _brightnesses = [Brightness.light, Brightness.dark];

Future<ApiResponse<List<Map<String, dynamic>>>> _threeMatches() async =>
    ApiResponse.success([
      for (final (i, name) in ['Myriam', 'Noé', 'Léa'].indexed)
        {
          'id': i + 1,
          'profile': {'user_id': 40 + i, 'display_name': name, 'picture': null},
        },
    ]);

Widget _host(Widget home, Brightness brightness) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: kTestLocale,
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
  home: home,
);

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late FakeCoupleApi api;
  late CoupleService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeCoupleApi();
    service = CoupleService.forTesting(api: api, pollInterval: const Duration(hours: 1));
  });

  tearDown(() => service.dispose());

  group('Mazal Tov', () {
    Future<void> pumpMazelTov(WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const MazelTovScreen(partnerName: 'Myriam'), Brightness.light),
      );
      await tester.pump(const Duration(seconds: 2));
    }

    testWidgets('fond encre, barre d\'état claire, aucun dégradé', (tester) async {
      await pumpMazelTov(tester);

      expect(find.byType(ShaderMask), findsNothing);
      final decorated = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      for (final box in decorated) {
        final decoration = box.decoration;
        if (decoration is BoxDecoration) {
          expect(decoration.gradient, isNull);
          expect(decoration.boxShadow, isNull);
        }
      }

      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(region.value, SystemUiOverlayStyle.light);
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, AppColors.ink);
    });

    testWidgets('titre, hébreu et phrase de félicitations', (tester) async {
      await pumpMazelTov(tester);

      expect(find.text('Mazal tov'), findsOneWidget);
      final hebrew = tester.widget<Text>(find.text('מזל טוב'));
      expect(hebrew.style?.color, AppColors.tekheletLight);
      expect(find.text('Félicitations à vous et à Myriam'), findsOneWidget);
      expect(find.byIcon(LucideIcons.heart), findsOneWidget);
      expect(find.byIcon(LucideIcons.sparkles), findsNothing);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style?.backgroundColor?.resolve({}), Colors.white);
    });

    testWidgets('animations désactivées : tout est visible tout de suite', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _host(const MazelTovScreen(partnerName: 'Myriam'), Brightness.light),
        ),
      );
      await tester.pump();

      final fade = tester.widget<FadeTransition>(
        find.descendant(of: find.byType(SafeArea), matching: find.byType(FadeTransition)).first,
      );
      expect(fade.opacity.value, 1);
    });

    for (final size in _sizes) {
      testWidgets('sans débordement à ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        _setSize(tester, size);
        await pumpMazelTov(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('choix « Avec qui ? »', () {
    Future<void> pumpSetup(WidgetTester tester, Brightness brightness) async {
      // A phone: wide windows show the choice as two pages.
      _setSize(tester, _sizes.first);
      await tester.pumpWidget(
        _host(
          CoupleModeSetupScreen(service: service, loadMatches: _threeMatches),
          brightness,
        ),
      );
      await tester.pump();
    }

    final avatars = find.byKey(const ValueKey('couple-avatar'));

    testWidgets('un avatar par ligne, une seule coche sur la ligne choisie', (tester) async {
      await pumpSetup(tester, Brightness.light);

      expect(avatars, findsNWidgets(3));
      expect(find.byIcon(LucideIcons.check), findsNothing);

      await tester.tap(find.text('Noé'));
      await tester.pump();

      expect(avatars, findsNWidgets(3));
      expect(find.byIcon(LucideIcons.check), findsOneWidget);

      await tester.tap(find.text('Léa'));
      await tester.pump();
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(avatars, findsNWidgets(3));
    });

    for (final size in _sizes) {
      for (final brightness in _brightnesses) {
        testWidgets(
          'sans débordement à ${size.width.toInt()}x${size.height.toInt()} (${brightness.name})',
          (tester) async {
            _setSize(tester, size);
            await pumpSetup(tester, brightness);
            await tester.tap(find.text('Myriam'));
            await tester.pump();
            expect(tester.takeException(), isNull);

            await tester.tap(find.text('Envoyer la demande'));
            await tester.pump();
            await tester.pump();
            expect(find.text('Demande envoyée'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await service.cancelCoupleRequest(); // stops the polling timer
          },
        );
      }
    }
  });

  group('demande reçue et états vides', () {
    for (final size in _sizes) {
      for (final brightness in _brightnesses) {
        final label = '${size.width.toInt()}x${size.height.toInt()} (${brightness.name})';

        testWidgets('boîte de dialogue sans débordement à $label', (tester) async {
          _setSize(tester, size);
          late BuildContext context;
          await tester.pumpWidget(
            _host(Builder(builder: (c) {
              context = c;
              return const Scaffold();
            }), brightness),
          );
          unawaited(CoupleRequestDialog.show(
            context,
            request: const CoupleRequest(
              id: 1,
              requesterId: 45,
              requesterName: 'Myriam',
              targetId: 7,
            ),
            service: service,
          ));
          await tester.pumpAndSettle();

          expect(find.text('Myriam souhaite activer le mode couple avec vous'), findsOneWidget);
          expect(find.widgetWithText(ElevatedButton, 'Accepter'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('message d\'erreur sans débordement à $label', (tester) async {
          _setSize(tester, size);
          await tester.pumpWidget(
            _host(
              Scaffold(
                body: CoupleMessageView.failure(
                  const CoupleFailure(CoupleFailureKind.network, 'Vérifiez votre connexion.'),
                  onRetry: () {},
                ),
              ),
              brightness,
            ),
          );

          expect(find.widgetWithText(ElevatedButton, 'Réessayer'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
