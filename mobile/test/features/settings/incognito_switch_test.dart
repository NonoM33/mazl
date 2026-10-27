import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/premium/premium_settings.dart';
import 'package:mazl/core/premium/premium_settings_api.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/settings/widgets/incognito_switch.dart';

import '../../helpers/l10n_helpers.dart';
import '../../support/premium_fakes.dart';

// « Mode discret » (mazl+): the switch shows what the server holds and moves
// only when the server answers; a member without mazl+ is sent to the offer.

Finder get _switch => find.byKey(const ValueKey('incognito-switch'));

bool _on(WidgetTester tester) => tester.widget<Switch>(_switch).value;

Future<List<int>> _pump(
  WidgetTester tester,
  PremiumSettingsApi api, {
  Locale locale = kTestLocale,
}) async {
  final opened = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: IncognitoSwitch(
          api: api,
          openPlus: (context) async => opened.add(opened.length + 1),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return opened;
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a subscriber sees the value the server holds', (tester) async {
    await _pump(tester, FakePremiumSettingsApi(incognito: true));

    expect(find.text('Mode discret'), findsOneWidget);
    expect(
      find.text(
        'Seules les personnes que vous avez aimées vous voient dans Découvrir.',
      ),
      findsOneWidget,
    );
    expect(_on(tester), isTrue);
  });

  testWidgets('turning it on sends enabled:true and shows the server\'s '
      'answer', (tester) async {
    final api = FakePremiumSettingsApi();
    await _pump(tester, api);
    expect(_on(tester), isFalse);

    await tester.tap(_switch);
    await tester.pump();
    await tester.pump();

    expect(api.incognitoCalls, [true]);
    expect(_on(tester), isTrue);
  });

  testWidgets('tapping the whole row toggles it, and turning it off sends '
      'enabled:false', (tester) async {
    final api = FakePremiumSettingsApi(incognito: true);
    await _pump(tester, api);

    await tester.tap(find.text('Mode discret'));
    await tester.pump();
    await tester.pump();

    expect(api.incognitoCalls, [false]);
    expect(_on(tester), isFalse);
  });

  testWidgets('while the server answers the switch keeps the old value and '
      'cannot be pushed again', (tester) async {
    final hold = Completer<void>();
    final api = FakePremiumSettingsApi()..holdWrites = hold;
    await _pump(tester, api);

    await tester.tap(_switch);
    await tester.pump();
    expect(_on(tester), isFalse, reason: 'no state the server does not hold');
    expect(tester.widget<Switch>(_switch).onChanged, isNull);

    hold.complete();
    await tester.pump();
    await tester.pump();
    expect(_on(tester), isTrue);
    expect(api.incognitoCalls, [true]);
  });

  testWidgets('a failed change leaves the switch where it was and says so', (
    tester,
  ) async {
    final api = FakePremiumSettingsApi()
      ..writeFailure = const PremiumSettingsException(
        PremiumSettingsErrorKind.server,
        status: 500,
      );
    await _pump(tester, api);

    await tester.tap(_switch);
    await tester.pump();
    await tester.pump();

    expect(_on(tester), isFalse);
    expect(find.text('Réglage non modifié. Réessayez.'), findsOneWidget);
    expect(tester.widget<Switch>(_switch).onChanged, isNotNull);
  });

  testWidgets('reading the setting: nothing can be changed before the '
      'server has answered', (tester) async {
    final hold = Completer<void>();
    final api = _SlowRead(FakePremiumSettingsApi(), hold);
    await _pump(tester, api);

    expect(find.text('Chargement…'), findsOneWidget);
    expect(tester.widget<Switch>(_switch).onChanged, isNull);

    hold.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('Chargement…'), findsNothing);
    expect(tester.widget<Switch>(_switch).onChanged, isNotNull);
  });

  testWidgets('a setting that cannot be read says so and a tap reads it '
      'again', (tester) async {
    final api = FakePremiumSettingsApi(incognito: true)
      ..readFailures.add(
        const PremiumSettingsException(PremiumSettingsErrorKind.network),
      );
    await _pump(tester, api);

    expect(
      find.text('Impossible de lire ce réglage. Touchez pour réessayer.'),
      findsOneWidget,
    );
    expect(tester.widget<Switch>(_switch).onChanged, isNull);

    await tester.tap(find.text('Mode discret'));
    await tester.pump();
    await tester.pump();

    expect(api.reads, 2);
    expect(_on(tester), isTrue);
  });

  group('without mazl+', () {
    testWidgets('the row says it is for subscribers and a tap opens mazl+ '
        'without asking the server for a change', (tester) async {
      final api = FakePremiumSettingsApi(isPlus: false);
      final opened = await _pump(tester, api);

      expect(find.text('Réservé aux abonnés mazl+'), findsOneWidget);
      expect(find.byIcon(LucideIcons.lock), findsOneWidget);
      expect(_switch, findsNothing, reason: 'no switch to show a false state');

      await tester.tap(find.text('Mode discret'));
      await tester.pump();
      await tester.pump();

      expect(opened, [1]);
      expect(api.incognitoCalls, isEmpty);
    });

    testWidgets('back from mazl+ the server is asked again: a new subscriber '
        'gets the switch', (tester) async {
      final api = FakePremiumSettingsApi(isPlus: false);
      await _pump(tester, api);

      // Subscribes while the offer is open.
      api.settings = PremiumSettings(
        isPlus: true,
        passport: null,
        incognito: false,
        sendReadReceipts: true,
      );
      await tester.tap(find.text('Mode discret'));
      await tester.pump();
      await tester.pump();

      expect(api.reads, 2);
      expect(_switch, findsOneWidget);
      expect(find.text('Réservé aux abonnés mazl+'), findsNothing);
    });

    testWidgets('a subscription that ended since the read: the server\'s 402 '
        'opens mazl+ and the row becomes the locked one', (tester) async {
      final api = FakePremiumSettingsApi();
      final opened = await _pump(tester, api);
      api.settings = PremiumSettings(
        isPlus: false,
        passport: null,
        incognito: false,
        sendReadReceipts: true,
      );

      await tester.tap(_switch);
      await tester.pump();
      await tester.pump();

      expect(opened, [1]);
      expect(_switch, findsNothing);
      expect(find.text('Réservé aux abonnés mazl+'), findsOneWidget);
    });
  });

  testWidgets('in Hebrew the row reads right to left', (tester) async {
    await _pump(tester, FakePremiumSettingsApi(), locale: const Locale('he'));
    expect(find.text('מצב דיסקרטי'), findsOneWidget);
    expect(
      textDirectionAt(tester, find.text('מצב דיסקרטי')),
      TextDirection.rtl,
    );
  });
}

class _SlowRead implements PremiumSettingsApi {
  _SlowRead(this.inner, this.hold);

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
