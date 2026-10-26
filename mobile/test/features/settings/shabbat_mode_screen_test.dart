import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/presentation/features/onboarding/screens/onboarding_screen.dart';
import 'package:mazl/presentation/features/settings/screens/shabbat_mode_screen.dart';

import '../../helpers/l10n_helpers.dart';

// Décision de Renaud du 2026-10-25 : l'écran garde les horaires réels du lieu
// du membre et l'écran de repos ; il ne promet plus rien que l'app ne tient
// pas (pause des notifications, statut, réglages jamais enregistrés).

class _Api implements ApiService {
  _Api(this.result);

  final Future<ApiResponse<UserProfile>> Function() result;

  @override
  Future<ApiResponse<UserProfile>> getCurrentUser() => result();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_Api: ${invocation.memberName}');
}

_Api _member({String? location, double? latitude, double? longitude}) => _Api(
  () async => ApiResponse.success(
    UserProfile(
      id: 1,
      email: 'jeanne@example.com',
      profile: Profile(
        id: 1,
        userId: 1,
        location: location,
        latitude: latitude,
        longitude: longitude,
      ),
    ),
  ),
);

// Vendredi 9 janvier 2026 ; le mercredi d'avant, le service cherche ce vendredi.
final _wednesday = DateTime(2026, 1, 7);

Future<void> _pump(
  WidgetTester tester,
  ApiService api, {
  Locale locale = kTestLocale,
  Brightness brightness = Brightness.light,
}) async {
  await pumpLocalized(
    tester,
    ShabbatModeScreen(apiService: api, clock: () => _wednesday),
    locale: locale,
    brightness: brightness,
    size: const Size(360, 1600),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Les deux heures du bandeau (allumage, havdala), en minutes depuis minuit.
List<int> _heroMinutes(WidgetTester tester) {
  final times = find.byWidgetPredicate(
    (widget) =>
        widget is Text && RegExp(r'^\d\d:\d\d$').hasMatch(widget.data ?? ''),
  );
  return [
    for (final element in times.evaluate())
      () {
        final parts = (element.widget as Text).data!.split(':');
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }(),
  ];
}

int _minutesOfDay(DateTime utcInstant) {
  final local = utcInstant.toLocal();
  return local.hour * 60 + local.minute;
}

void _expectClose(int actual, int expected, String what) {
  var gap = (actual - expected).abs();
  if (gap > 720) gap = 1440 - gap;
  expect(
    gap,
    lessThanOrEqualTo(2),
    reason: '$what : $actual au lieu de $expected',
  );
}

void main() {
  group('les horaires sont ceux du lieu du membre', () {
    testWidgets('Jérusalem : les heures de Jérusalem, pas celles de Paris', (
      tester,
    ) async {
      await _pump(
        tester,
        _member(location: 'Jérusalem', latitude: 31.7683, longitude: 35.2137),
      );

      // Hebcal : coucher du soleil 16:53 (UTC+2) moins 18 min = 14:35 UTC ;
      // havdala 17:33 (UTC+2) = 15:33 UTC, le samedi 10 janvier 2026.
      final minutes = _heroMinutes(tester);
      expect(minutes, hasLength(2));
      _expectClose(
        minutes[0],
        _minutesOfDay(DateTime.utc(2026, 1, 9, 14, 35)),
        'allumage',
      );
      _expectClose(
        minutes[1],
        _minutesOfDay(DateTime.utc(2026, 1, 10, 15, 33)),
        'havdala',
      );
      expect(find.text('Basé sur Jérusalem'), findsOneWidget);
      expect(find.textContaining('Paris'), findsNothing);
    });

    testWidgets('Paris par les coordonnées : les heures de Paris', (
      tester,
    ) async {
      await _pump(
        tester,
        _member(location: 'Paris 75001', latitude: 48.8566, longitude: 2.3522),
      );

      // Hebcal : allumage 15:55 UTC, havdala 17:08 UTC.
      final minutes = _heroMinutes(tester);
      _expectClose(
        minutes[0],
        _minutesOfDay(DateTime.utc(2026, 1, 9, 15, 55)),
        'allumage',
      );
      _expectClose(
        minutes[1],
        _minutesOfDay(DateTime.utc(2026, 1, 10, 17, 8)),
        'havdala',
      );
      // Le code postal n'est pas un nom de lieu.
      expect(find.text('Basé sur Paris'), findsOneWidget);
    });

    testWidgets('sans coordonnées : Paris, avec la mention claire du lieu', (
      tester,
    ) async {
      await _pump(tester, _member(location: 'Lyon'));

      final minutes = _heroMinutes(tester);
      _expectClose(
        minutes[0],
        _minutesOfDay(DateTime.utc(2026, 1, 9, 15, 55)),
        'allumage',
      );
      expect(find.text('Basé sur Paris, France'), findsOneWidget);
      expect(
        find.textContaining('votre ville n\'est pas connue'),
        findsOneWidget,
      );
    });

    testWidgets('profil illisible (hors ligne) : Paris, avec la même mention', (
      tester,
    ) async {
      await _pump(
        tester,
        _Api(() async => ApiResponse.failure('offline', ApiErrorKind.network)),
      );

      expect(find.text('Basé sur Paris, France'), findsOneWidget);
      expect(
        find.textContaining('votre ville n\'est pas connue'),
        findsOneWidget,
      );
    });

    testWidgets('tant que le profil n\'est pas lu, aucune heure de Paris '
        'n\'est affichée', (tester) async {
      final profile = Completer<ApiResponse<UserProfile>>();
      await _pump(tester, _Api(() => profile.future));

      expect(_heroMinutes(tester), isEmpty);
      expect(find.text('—'), findsNWidgets(2));
      profile.complete(ApiResponse.failure('offline', ApiErrorKind.network));
      await tester.pump();
    });
  });

  group('aucune promesse que l\'app ne tient pas', () {
    final locales = [
      kTestLocale,
      const Locale('en'),
      const Locale('he'),
      const Locale('es'),
      const Locale('ru'),
    ];

    for (final locale in locales) {
      testWidgets('${locale.languageCode} : ni interrupteur, ni curseur, ni '
          'bouton : l\'écran montre les horaires, rien à lancer', (
        tester,
      ) async {
        await _pump(
          tester,
          _member(location: 'Jérusalem', latitude: 31.7683, longitude: 35.2137),
          locale: locale,
        );

        expect(find.byType(Switch), findsNothing);
        expect(find.byType(SwitchListTile), findsNothing);
        expect(find.byType(Slider), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);
        expect(find.byType(TextButton), findsNothing);
        expect(find.byType(ElevatedButton), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('en français, rien sur la pause, le statut ni les messages '
        'retenus', (tester) async {
      await _pump(
        tester,
        _member(location: 'Jérusalem', latitude: 31.7683, longitude: 35.2137),
      );

      for (final promise in const [
        'notification',
        'statut',
        'Pause',
        'pause',
        'attendront',
        'attendent',
        'Activer',
        'Modifier',
        'Marge',
      ]) {
        expect(find.textContaining(promise), findsNothing, reason: promise);
      }
    });

    testWidgets('en anglais, rien sur la pause, le statut ni les messages '
        'retenus', (tester) async {
      await _pump(
        tester,
        _member(location: 'Jérusalem', latitude: 31.7683, longitude: 35.2137),
        locale: const Locale('en'),
      );

      for (final promise in const [
        'otification',
        'status',
        'Pause',
        'pause',
        'will wait',
        'wait for you',
        'Turn on',
        'Edit',
        'Margin',
      ]) {
        expect(find.textContaining(promise), findsNothing, reason: promise);
      }
      expect(find.text('Based on Jérusalem'), findsOneWidget);
    });

    testWidgets('le bandeau de repos reste : titre, allumage et havdala', (
      tester,
    ) async {
      await _pump(
        tester,
        _member(location: 'Jérusalem', latitude: 31.7683, longitude: 35.2137),
      );

      expect(find.text('Shabbat\nshalom.'), findsOneWidget);
      expect(find.text('ALLUMAGE'), findsOneWidget);
      expect(find.text('HAVDALA'), findsOneWidget);
      expect(find.text('Mazl se repose avec vous.'), findsOneWidget);
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('en hébreu (${brightness.name}) : de droite à gauche, sans '
        'débordement', (tester) async {
      await _pump(
        tester,
        _member(location: 'Jérusalem', latitude: 31.7683, longitude: 35.2137),
        locale: const Locale('he'),
        brightness: brightness,
      );

      expect(
        textDirectionAt(tester, find.text('שבת\nשלום.')),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });
  }

  group('la présentation du mode Shabbat', () {
    for (final locale in [kTestLocale, const Locale('en')]) {
      testWidgets('${locale.languageCode} : page 4 ne promet plus de pause', (
        tester,
      ) async {
        await pumpLocalized(tester, const OnboardingScreen(), locale: locale);
        // Pages 1 à 3, puis la quatrième : le mode Shabbat.
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byType(ElevatedButton));
          await tester.pumpAndSettle();
        }

        expect(
          find.text(locale == kTestLocale ? 'Mode Shabbat' : 'Shabbat mode'),
          findsOneWidget,
        );
        expect(find.textContaining('ause'), findsNothing);
        expect(find.textContaining('automati'), findsNothing);
      });
    }
  });
}
