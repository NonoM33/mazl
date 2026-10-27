import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/premium/premium_settings.dart';
import 'package:mazl/core/premium/premium_settings_api.dart';
import 'package:mazl/core/premium/purchase_moments.dart';
import 'package:mazl/core/services/places_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/passport/screens/passport_screen.dart';

import '../../helpers/l10n_helpers.dart';
import '../../support/premium_fakes.dart';

// The Passeport (mazl+): the member's current passport comes from the server,
// the suggested cities are fixed, the search goes through the app's geocoder,
// and a member without mazl+ gets the offer, never a silent dead end.

const _telAviv = Passport(
  city: 'Tel Aviv',
  latitude: 32.0853,
  longitude: 34.7818,
);

class _Harness {
  _Harness({required this.api, this.search, this.locale = kTestLocale});

  final FakePremiumSettingsApi api;
  final CitySearch? search;
  final Locale locale;
  final List<PurchaseMoment> offers = [];
  Object? result = 'not popped';

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<Object?>(
                    MaterialPageRoute(
                      builder: (_) => PassportScreen(
                        api: api,
                        searchCities: search,
                        offerPlus: (context, moment) async {
                          offers.add(moment);
                          return true;
                        },
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }
}

Future<List<CitySuggestion>> Function(String) _geocoder(
  List<String> asked,
  List<CitySuggestion> answer,
) => (query) async {
  asked.add(query);
  return answer;
};

CitySuggestion _lyon() => CitySuggestion(
  placeId: 'x1',
  city: 'Lyon',
  postalCode: '69001',
  displayName: 'Lyon 69001',
  latitude: 45.767,
  longitude: 4.833,
);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const ValueKey('passport-search')), text);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  group('the cities', () {
    testWidgets('the nine suggested cities are listed', (tester) async {
      final harness = _Harness(api: FakePremiumSettingsApi());
      await harness.pump(tester);

      for (final name in [
        'Tel-Aviv',
        'Jérusalem',
        'New York',
        'Londres',
        'Montréal',
        'Paris',
        'Marseille',
        'Lyon',
        'Nice',
      ]) {
        await tester.ensureVisible(find.text(name));
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });

    testWidgets('the names follow the language (Hebrew, Russian)', (
      tester,
    ) async {
      final hebrew = _Harness(
        api: FakePremiumSettingsApi(),
        locale: const Locale('he'),
      );
      await hebrew.pump(tester);
      await tester.ensureVisible(find.text('תל אביב'));
      expect(find.text('תל אביב'), findsOneWidget);
      expect(find.text('ירושלים'), findsOneWidget);
    });

    testWidgets('no passport yet: the member reads that they see their own '
        'city and there is no way back to offer', (tester) async {
      final harness = _Harness(api: FakePremiumSettingsApi());
      await harness.pump(tester);

      expect(find.text('Vous découvrez votre propre ville.'), findsOneWidget);
      expect(find.byKey(const ValueKey('passport-back-home')), findsNothing);
    });

    testWidgets('an active passport is named and can be left', (tester) async {
      final harness = _Harness(api: FakePremiumSettingsApi(passport: _telAviv));
      await harness.pump(tester);

      expect(find.text('Votre passeport : Tel-Aviv'), findsOneWidget);
      expect(find.text('Revenir à ma ville'), findsOneWidget);
    });
  });

  group('choosing a city', () {
    testWidgets('a suggested city is sent with its coordinates and the '
        'screen hands the new passport back', (tester) async {
      final api = FakePremiumSettingsApi();
      final harness = _Harness(api: api);
      await harness.pump(tester);

      await tester.ensureVisible(find.text('Jérusalem'));
      await tester.tap(find.text('Jérusalem'));
      await tester.pumpAndSettle();

      expect(api.passportCalls, hasLength(1));
      final sent = api.passportCalls.single!;
      expect(sent.city, 'Jerusalem');
      expect(sent.latitude, closeTo(31.7683, 0.01));
      expect(sent.longitude, closeTo(35.2137, 0.01));
      expect(find.byType(PassportScreen), findsNothing);
      final change = harness.result! as PassportChange;
      expect(change.passport?.city, 'Jerusalem');
    });

    testWidgets('« Revenir à ma ville » turns the passport off', (
      tester,
    ) async {
      final api = FakePremiumSettingsApi(passport: _telAviv);
      final harness = _Harness(api: api);
      await harness.pump(tester);

      await tester.tap(find.byKey(const ValueKey('passport-back-home')));
      await tester.pumpAndSettle();

      expect(api.passportCalls, [null]);
      final change = harness.result! as PassportChange;
      expect(change.passport, isNull);
    });

    testWidgets('the current suggested city carries a check', (tester) async {
      final harness = _Harness(api: FakePremiumSettingsApi(passport: _telAviv));
      await harness.pump(tester);
      final current = find.byKey(const ValueKey('passport-city-telAviv'));
      final other = find.byKey(const ValueKey('passport-city-paris'));
      expect(
        find.descendant(of: current, matching: find.byIcon(LucideIcons.check)),
        findsOneWidget,
      );
      await tester.ensureVisible(other);
      expect(
        find.descendant(of: other, matching: find.byIcon(LucideIcons.check)),
        findsNothing,
      );
    });

    testWidgets('a write that fails keeps the screen and says so', (
      tester,
    ) async {
      final api = FakePremiumSettingsApi()
        ..writeFailure = const PremiumSettingsException(
          PremiumSettingsErrorKind.server,
          status: 500,
        );
      final harness = _Harness(api: api);
      await harness.pump(tester);

      await tester.ensureVisible(find.text('Paris'));
      await tester.tap(find.text('Paris'));
      await tester.pumpAndSettle();

      expect(find.byType(PassportScreen), findsOneWidget);
      expect(harness.result, 'not popped');
      expect(find.byType(SnackBar), findsOneWidget);
      // The rows answer again.
      api.writeFailure = null;
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.ensureVisible(find.text('Paris'));
      await tester.tap(find.text('Paris'));
      await tester.pumpAndSettle();
      expect(harness.result, isA<PassportChange>());
    });

    testWidgets('a second tap while the server answers sends nothing more', (
      tester,
    ) async {
      final hold = Completer<void>();
      final api = FakePremiumSettingsApi()..holdWrites = hold;
      final harness = _Harness(api: api);
      await harness.pump(tester);

      await tester.ensureVisible(find.text('Nice'));
      await tester.tap(find.text('Nice'));
      await tester.pump();
      await tester.ensureVisible(find.text('Lyon'));
      await tester.tap(find.text('Lyon'), warnIfMissed: false);
      await tester.pump();
      expect(api.passportCalls, hasLength(1));

      hold.complete();
      await tester.pumpAndSettle();
    });
  });

  group('searching a city', () {
    testWidgets('what is typed goes to the app geocoder, and a result is '
        'sent with the geocoder\'s city and coordinates', (tester) async {
      final asked = <String>[];
      final api = FakePremiumSettingsApi();
      final harness = _Harness(api: api, search: _geocoder(asked, [_lyon()]));
      await harness.pump(tester);

      await _type(tester, 'Lyo');

      expect(asked, ['Lyo']);
      expect(find.text('Lyon 69001'), findsOneWidget);
      await tester.tap(find.text('Lyon 69001'));
      await tester.pumpAndSettle();

      final sent = api.passportCalls.single!;
      expect(sent.city, 'Lyon');
      expect(sent.latitude, 45.767);
      expect(sent.longitude, 4.833);
    });

    testWidgets('typing fast asks the geocoder once, for the last text', (
      tester,
    ) async {
      final asked = <String>[];
      final harness = _Harness(
        api: FakePremiumSettingsApi(),
        search: _geocoder(asked, [_lyon()]),
      );
      await harness.pump(tester);

      final field = find.byKey(const ValueKey('passport-search'));
      await tester.enterText(field, 'Ly');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(field, 'Lyo');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(field, 'Lyon');
      await tester.pump(const Duration(milliseconds: 400));

      expect(asked, ['Lyon']);
    });

    testWidgets('under two letters nothing is asked', (tester) async {
      final asked = <String>[];
      final harness = _Harness(
        api: FakePremiumSettingsApi(),
        search: _geocoder(asked, [_lyon()]),
      );
      await harness.pump(tester);

      await _type(tester, 'L');

      expect(asked, isEmpty);
      expect(find.text('Lyon 69001'), findsNothing);
    });

    testWidgets('no result says so', (tester) async {
      final harness = _Harness(
        api: FakePremiumSettingsApi(),
        search: _geocoder([], []),
      );
      await harness.pump(tester);

      await _type(tester, 'Zzzz');

      expect(find.text('Aucune ville trouvée.'), findsOneWidget);
    });

    testWidgets('a result with no coordinates is not offered', (tester) async {
      final harness = _Harness(
        api: FakePremiumSettingsApi(),
        search: _geocoder([], [
          CitySuggestion(
            placeId: 'x2',
            city: 'Sansgps',
            displayName: 'Sansgps',
          ),
        ]),
      );
      await harness.pump(tester);

      await _type(tester, 'Sans');

      expect(find.text('Sansgps'), findsNothing);
      expect(find.text('Aucune ville trouvée.'), findsOneWidget);
    });

    testWidgets('a slow older answer never replaces a newer one', (
      tester,
    ) async {
      final slow = Completer<List<CitySuggestion>>();
      final harness = _Harness(
        api: FakePremiumSettingsApi(),
        search: (query) => query == 'Lyo'
            ? slow.future
            : Future.value([
                CitySuggestion(
                  placeId: 'n',
                  city: 'Nice',
                  displayName: 'Nice 06000',
                  latitude: 43.7,
                  longitude: 7.26,
                ),
              ]),
      );
      await harness.pump(tester);

      await _type(tester, 'Lyo');
      await _type(tester, 'Nice');
      slow.complete([_lyon()]);
      await tester.pump();

      expect(find.text('Nice 06000'), findsOneWidget);
      expect(find.text('Lyon 69001'), findsNothing);
    });
  });

  group('without mazl+', () {
    testWidgets('a tap on a city opens the passport offer and changes '
        'nothing', (tester) async {
      final api = FakePremiumSettingsApi(isPlus: false);
      final harness = _Harness(api: api);
      await harness.pump(tester);

      await tester.ensureVisible(find.text('Paris'));
      await tester.tap(find.text('Paris'));
      await tester.pumpAndSettle();

      expect(harness.offers, [PurchaseMoment.passportAttempt]);
      expect(api.passportCalls, isEmpty, reason: 'the server is not asked');
      expect(find.byType(PassportScreen), findsOneWidget);
    });

    testWidgets('the page always shows a way to mazl+, even when the offer '
        'was already made today', (tester) async {
      final harness = _Harness(api: FakePremiumSettingsApi(isPlus: false));
      await harness.pump(tester);

      expect(
        find.text('Le passeport est réservé aux abonnés mazl+.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('passport-see-plus')), findsOneWidget);
    });

    testWidgets('a stale app that thinks the member is subscribed gets the '
        'server\'s 402 and the same offer', (tester) async {
      final api = FakePremiumSettingsApi(isPlus: true);
      final harness = _Harness(api: api);
      await harness.pump(tester);
      // The subscription ended on another device.
      api.settings = PremiumSettings(
        isPlus: false,
        passport: null,
        incognito: false,
        sendReadReceipts: true,
      );

      await tester.ensureVisible(find.text('Paris'));
      await tester.tap(find.text('Paris'));
      await tester.pumpAndSettle();

      expect(harness.offers, [PurchaseMoment.passportAttempt]);
      expect(find.byType(PassportScreen), findsOneWidget);
      expect(harness.result, 'not popped');
    });

    testWidgets('leaving an existing passport is still allowed', (
      tester,
    ) async {
      final api = FakePremiumSettingsApi(isPlus: false, passport: _telAviv);
      final harness = _Harness(api: api);
      await harness.pump(tester);

      await tester.tap(find.byKey(const ValueKey('passport-back-home')));
      await tester.pumpAndSettle();

      expect(api.passportCalls, [null]);
      expect(harness.offers, isEmpty);
    });

    testWidgets('a subscriber sees no mazl+ banner', (tester) async {
      final harness = _Harness(api: FakePremiumSettingsApi());
      await harness.pump(tester);
      expect(find.byKey(const ValueKey('passport-plus-only')), findsNothing);
    });
  });

  group('loading', () {
    testWidgets('a failed read shows a message and a retry that works', (
      tester,
    ) async {
      final api = FakePremiumSettingsApi()
        ..readFailures.add(
          const PremiumSettingsException(PremiumSettingsErrorKind.network),
        );
      final harness = _Harness(api: api);
      await harness.pump(tester);

      expect(
        find.text('Impossible de charger votre passeport.'),
        findsOneWidget,
      );
      expect(
        find.text('Jérusalem'),
        findsNothing,
        reason: 'no state is invented when the server cannot be read',
      );

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(api.reads, 2);
      expect(find.text('Jérusalem'), findsOneWidget);
    });

    testWidgets('while it loads, only a spinner and the way out', (
      tester,
    ) async {
      final api = FakePremiumSettingsApi();
      final hold = Completer<void>();
      final slow = _SlowSettings(api, hold);
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          theme: AppTheme.lightTheme,
          home: PassportScreen(api: slow),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Paris'), findsNothing);
      hold.complete();
      await tester.pumpAndSettle();
      expect(find.text('Paris'), findsOneWidget);
    });
  });
}

class _SlowSettings implements PremiumSettingsApi {
  _SlowSettings(this.inner, this.hold);

  final FakePremiumSettingsApi inner;
  final Completer<void> hold;

  @override
  Future<PremiumSettings> getSettings() async {
    await hold.future;
    return inner.getSettings();
  }

  @override
  Future<Passport?> setPassport(Passport? passport) =>
      inner.setPassport(passport);

  @override
  Future<bool> setIncognito(bool enabled) => inner.setIncognito(enabled);
}
