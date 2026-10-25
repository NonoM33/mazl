import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/directional_icon.dart';
import 'package:mazl/presentation/features/settings/l10n/delete_account_reason.dart';
import 'package:mazl/presentation/features/settings/screens/settings_screen.dart';
import 'package:mazl/presentation/features/settings/widgets/settings_couple_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/l10n_helpers.dart';
import '../../couple/couple_flow_fakes.dart';

const _english = Locale('en');
const _hebrew = Locale('he');
const _russian = Locale('ru');
const _spanish = Locale('es');

/// Never disposed, like in the other settings tests: the services are singletons.
final _sharedContainer = ProviderContainer();

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 100);
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
    await tester.pump(step);
  }
}

/// The settings screen, 360 px wide and tall enough to build every row.
Future<void> _pumpSettings(
  WidgetTester tester,
  CoupleService service, {
  Locale locale = kTestLocale,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(360, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await service.initialize();
  CoupleService.instanceForTesting = service;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _sharedContainer,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: const SettingsScreen(),
      ),
    ),
  );
  await _pumpFor(tester, const Duration(milliseconds: 500));
}

/// Every call of the app fails: the settings show their defaults.
Future<void> _offline(Future<void> Function() body) => http.runWithClient(
  body,
  () => MockClient(
    (_) async => http.Response(jsonEncode({'success': false}), 500),
  ),
);

void main() {
  late FakeCoupleApi api;
  late CoupleService service;
  var disposed = false;

  Future<void> stopService(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    service.dispose();
    disposed = true;
  }

  setUp(() {
    disposed = false;
    SharedPreferences.setMockInitialValues({});
    api = FakeCoupleApi();
    service = CoupleService.forTesting(
      api: api,
      pollInterval: const Duration(hours: 1),
    );
  });

  tearDown(() {
    if (!disposed) service.dispose();
  });

  group('réglages, lignes et sections', () {
    testWidgets('en français, les textes d\'origine', (tester) async {
      await _offline(() async {
        await _pumpSettings(tester, service);

        for (final text in [
          'Paramètres',
          'COMPTE',
          'Modifier le profil',
          'Non défini',
          '50 km',
          '18 - 99 ans',
          'PARAMÈTRES JUIFS',
          'Mode Shabbat',
          'Horaires de Shabbat',
          'Alertes fêtes',
          'Notifications avant les fêtes',
          'Nouveaux matchs',
          'MODE COUPLE',
          'ABONNEMENT',
          'Restaurer les achats',
          'CONFIDENTIALITÉ ET SÉCURITÉ',
          'Utilisateurs bloqués',
          'Gérer les personnes bloquées',
          'Vérification du profil',
          'Non vérifié',
          'À PROPOS',
          'Aide et support',
          "Conditions d'utilisation",
          'Conditions de vente',
          'Politique de confidentialité',
          'Se déconnecter',
          'Supprimer mon compte',
        ]) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('en anglais', (tester) async {
      await _offline(() async {
        await _pumpSettings(tester, service, locale: _english);

        for (final text in [
          'Settings',
          'ACCOUNT',
          'Edit profile',
          'Language',
          'Phone language',
          'DISCOVERY',
          'Location',
          'Not set',
          'Maximum distance',
          '50 km',
          'Age range',
          '18 - 99 years',
          'JEWISH SETTINGS',
          'Shabbat mode',
          'Shabbat times',
          'Holiday alerts',
          'Notifications ahead of holidays',
          'NOTIFICATIONS',
          'New matches',
          'Super Likes',
          'COUPLE MODE',
          'SUBSCRIPTION',
          'Restore purchases',
          'PRIVACY AND SAFETY',
          'Blocked users',
          'Manage blocked people',
          'Profile verification',
          'Not verified',
          'ABOUT',
          'Help and support',
          'Terms of use',
          'Privacy policy',
          'Log out',
          'Delete my account',
        ]) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
        // No French is left in the member's part of the screen.
        expect(find.text('Paramètres'), findsNothing);
        expect(find.text('Compte'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('en russe : les nombres suivent la langue', (tester) async {
      await _offline(() async {
        await _pumpSettings(tester, service, locale: _russian);

        expect(find.text('Настройки'), findsOneWidget);
        expect(find.text('50 км'), findsOneWidget);
        expect(find.text('18 - 99 лет'), findsOneWidget);
        expect(find.text('Режим Шаббата'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('en espagnol', (tester) async {
      await _offline(() async {
        await _pumpSettings(tester, service, locale: _spanish);

        expect(find.text('Ajustes'), findsOneWidget);
        expect(find.text('18 - 99 años'), findsOneWidget);
        expect(find.text('Modo Shabat'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    for (final brightness in Brightness.values) {
      testWidgets(
        'en hébreu (${brightness.name}) : de droite à gauche, flèches retournées, sans débordement',
        (tester) async {
          await _offline(() async {
            await _pumpSettings(
              tester,
              service,
              locale: _hebrew,
              brightness: brightness,
            );

            expect(find.text('הגדרות'), findsOneWidget);
            expect(
              textDirectionAt(tester, find.text('הגדרות')),
              TextDirection.rtl,
            );
            expect(find.text('מצב שבת'), findsOneWidget);
            expect(find.text('50 ק״מ'), findsOneWidget);
            expect(find.text('18 - 99 שנים'), findsOneWidget);
            // The chevrons of the rows and the back arrow flip with the direction.
            expect(find.byType(DirectionalIcon), findsWidgets);
            // The row titles start at the right edge of the screen.
            final title = tester.getTopRight(find.text('עריכת פרופיל'));
            expect(title.dx, greaterThan(kSmallPhone.width / 2));
            expect(tester.takeException(), isNull);
          });
        },
      );
    }
  });

  group('feuilles de réglage', () {
    testWidgets('la distance maximale, en anglais', (tester) async {
      await _offline(() async {
        await _pumpSettings(tester, service, locale: _english);

        await tester.tap(find.text('Maximum distance'));
        await _pumpFor(tester, const Duration(milliseconds: 400));

        expect(find.text('50 km'), findsNWidgets(2));
        expect(find.text('Save'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('la tranche d\'âge, en russe', (tester) async {
      await _offline(() async {
        await _pumpSettings(tester, service, locale: _russian);

        await tester.tap(find.text('Возрастной диапазон'));
        await _pumpFor(tester, const Duration(milliseconds: 400));

        expect(find.text('18 - 99 лет'), findsNWidgets(2));
        expect(find.text('Сохранить'), findsOneWidget);
      });
    });

    testWidgets('la localisation, en anglais', (tester) async {
      await _offline(() async {
        await _pumpSettings(tester, service, locale: _english);

        await tester.tap(find.text('Location'));
        await _pumpFor(tester, const Duration(milliseconds: 400));

        expect(find.text('Search for a city...'), findsOneWidget);
        expect(
          find.text('Type your city name and pick a suggestion'),
          findsOneWidget,
        );
        expect(find.text('Close'), findsOneWidget);
      });
    });

    testWidgets('la déconnexion, en anglais', (tester) async {
      await _offline(() async {
        await _pumpSettings(tester, service, locale: _english);

        await tester.tap(find.text('Log out'));
        await _pumpFor(tester, const Duration(milliseconds: 400));

        expect(find.text('Do you really want to log out?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Log out'), findsNWidgets(3));
      });
    });

    testWidgets(
      'la suppression du compte, de la raison à la confirmation finale',
      (tester) async {
        await _offline(() async {
          await _pumpSettings(tester, service, locale: _english);

          await tester.tap(find.text('Delete my account'));
          await _pumpFor(tester, const Duration(milliseconds: 400));
          expect(find.text('Why do you want to leave us?'), findsOneWidget);
          for (final reason in [
            'I found someone',
            'I no longer use the app',
            'I want to take a break',
            'Technical problems',
            "The service isn't right for me",
            'Other reason',
          ]) {
            expect(find.text(reason), findsOneWidget, reason: reason);
          }

          await tester.tap(find.text('I found someone'));
          await _pumpFor(tester, const Duration(milliseconds: 200));
          await tester.tap(find.text('Continue'));
          await _pumpFor(tester, const Duration(milliseconds: 500));

          expect(find.text('Final confirmation'), findsOneWidget);
          expect(find.text('This action cannot be undone.'), findsOneWidget);
          expect(
            find.text(
              'All your data will be deleted:\n• Your profile and photos\n'
              '• Your matches and conversations\n• Your like history\n• Your settings',
            ),
            findsOneWidget,
          );
          expect(find.text('Keep my account'), findsOneWidget);

          // Nobody is signed in: the failure is said in the member's language,
          // never with the French sentence of the auth service.
          await tester.tap(find.text('Delete'));
          await _pumpFor(tester, const Duration(milliseconds: 600));
          expect(find.text("Couldn't delete the account"), findsOneWidget);
          expect(find.textContaining('Aucun utilisateur'), findsNothing);
        });
      },
    );

    test('le serveur reçoit toujours la raison en français', () {
      expect(DeleteAccountReason.values.map((reason) => reason.apiValue), [
        "J'ai trouvé quelqu'un",
        "Je n'utilise plus l'application",
        'Je souhaite faire une pause',
        'Problèmes techniques',
        'Le service ne me convient pas',
        'Autre raison',
      ]);
    });
  });

  group('carte du mode couple', () {
    testWidgets('actif, en anglais : titre, partenaire, boutons', (
      tester,
    ) async {
      api.couple = contractCouple();
      await _offline(() async {
        await _pumpSettings(tester, service, locale: _english);

        expect(find.text('Couple mode on'), findsOneWidget);
        expect(find.textContaining('With Myriam · '), findsOneWidget);
        expect(find.text('Couple space'), findsOneWidget);
        expect(find.text('Calendar'), findsOneWidget);
        expect(find.text('Leave couple mode'), findsOneWidget);
        // A couple hides the discovery rows.
        expect(find.text('DISCOVERY'), findsNothing);
      });
    });

    testWidgets(
      'quitter échoue : la cause dite dans la langue du membre, pas la phrase du service',
      (tester) async {
        api.couple = contractCouple();
        api.endError = 'server exploded';
        await _offline(() async {
          await _pumpSettings(tester, service, locale: _english);

          await tester.tap(find.text('Leave couple mode'));
          await _pumpFor(tester, const Duration(milliseconds: 500));
          expect(
            find.text('You can turn it back on later if you wish.'),
            findsOneWidget,
          );
          await tester.tap(find.text('Leave'));
          await _pumpFor(tester, const Duration(milliseconds: 600));

          expect(
            find.text('The server is unavailable. Try again in a moment.'),
            findsOneWidget,
          );
          expect(find.textContaining('réessayez'), findsNothing);
        });
      },
    );

    testWidgets('demande envoyée, en anglais', (tester) async {
      api.sent = [contractSentRequest()];
      await _offline(() async {
        await _pumpSettings(tester, service, locale: _english);

        expect(find.text('Request sent to Myriam'), findsOneWidget);
        expect(find.text('Waiting for their answer'), findsOneWidget);
        expect(find.text('Cancel request'), findsOneWidget);
        await stopService(tester);
      });
    });

    testWidgets('sans couple, en anglais : l\'invitation', (tester) async {
      await _offline(() async {
        await _pumpSettings(tester, service, locale: _english);

        expect(find.text('Found love?'), findsOneWidget);
        expect(find.text('Turn on'), findsOneWidget);
      });
    });

    for (final locale in [_hebrew, _russian, _spanish]) {
      testWidgets(
        'actif en ${locale.languageCode} : les trois boutons tiennent sur une ligne à 360 px',
        (tester) async {
          api.couple = contractCouple();
          await _offline(() async {
            await _pumpSettings(tester, service, locale: locale);

            final l10n = lookupAppLocalizations(locale);
            for (final label in [
              l10n.settingsCoupleOpenSpace,
              l10n.settingsCoupleOpenCalendar,
              l10n.settingsCoupleLeave,
            ]) {
              final paragraph = tester.renderObject<RenderParagraph>(
                find.text(label),
              );
              expect(
                paragraph.size.height,
                lessThanOrEqualTo(
                  paragraph.getMaxIntrinsicHeight(double.infinity) + 0.5,
                ),
                reason: '${locale.languageCode}: $label',
              );
            }
            expect(tester.takeException(), isNull);
          });
        },
      );
    }
  });

  group('coupleDurationLabel', () {
    final fr = lookupAppLocalizations(kTestLocale);
    final en = lookupAppLocalizations(_english);
    final ru = lookupAppLocalizations(_russian);
    final he = lookupAppLocalizations(_hebrew);
    final today = DateTime(2026, 10, 23, 22);

    test('le jour même', () {
      expect(
        coupleDurationLabel(fr, DateTime(2026, 10, 23, 8), today),
        "Depuis aujourd'hui",
      );
      expect(
        coupleDurationLabel(en, DateTime(2026, 10, 23, 8), today),
        'Since today',
      );
    });

    test('un jour, en toutes langues', () {
      final since = DateTime(2026, 10, 22, 10);
      expect(coupleDurationLabel(fr, since, today), '1 jour');
      expect(coupleDurationLabel(en, since, today), '1 day');
      expect(coupleDurationLabel(he, since, today), 'יום אחד');
    });

    test('le français et l\'anglais accordent le pluriel', () {
      final since = DateTime(2026, 10, 18);
      expect(coupleDurationLabel(fr, since, today), '5 jours');
      expect(coupleDurationLabel(en, since, today), '5 days');
    });

    test('le russe a quatre formes', () {
      expect(coupleDurationLabel(ru, DateTime(2026, 10, 2), today), '21 день');
      expect(coupleDurationLabel(ru, DateTime(2026, 10, 21), today), '2 дня');
      expect(coupleDurationLabel(ru, DateTime(2026, 10, 18), today), '5 дней');
    });

    test('l\'hébreu a une forme pour deux', () {
      expect(coupleDurationLabel(he, DateTime(2026, 10, 21), today), 'יומיים');
      expect(coupleDurationLabel(he, DateTime(2026, 10, 18), today), '5 ימים');
    });
  });
}
