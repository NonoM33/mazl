import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/services/jewish_calendar_service.dart';
import 'package:mazl/core/services/quiet_display.dart';
import 'package:mazl/core/services/screen_keeper.dart';
import 'package:mazl/presentation/features/settings/screens/shabbat_display_screen.dart';
import 'package:mazl/presentation/features/settings/shabbat_place.dart';
import 'package:mazl/presentation/features/settings/widgets/hanukkiah.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';

// Les moments sont choisis par RestDisplayResolver (voir son test) ; ici on
// vérifie ce que l'écran en montre, qu'il ne demande aucune interaction, et
// qu'il tient dans les sept poses de l'iPhone Duo, la tente d'abord.

class _Keeper implements ScreenKeeper {
  int held = 0;
  int released = 0;

  @override
  Future<void> hold() async => held++;

  @override
  Future<void> release() async => released++;
}

const _paris = ShabbatPlace(location: ShabbatLocation.paris, isDefault: true);

final _jerusalem = ShabbatPlace(
  location: const ShabbatLocation(
    name: 'Jérusalem',
    latitude: 31.7683,
    longitude: 35.2137,
  ),
  isDefault: false,
);

// Les moments de l'année 2026 (calendrier Hebcal, diaspora ; voir le test du
// résolveur) : le vendredi avant l'allumage, Shabbat, le 4e soir de Hanoucca,
// le 10e jour de l'Omer, la veille de Pessah et son premier jour.
final _fridayMorning = DateTime(2026, 1, 9, 10);
final _shabbatEvening = DateTime.utc(2026, 1, 9, 19);
final _wednesday = DateTime(2026, 1, 7, 12);
final _hanukkahNight4 = DateTime(2026, 12, 7, 12);
final _hanukkahNight8 = DateTime(2026, 12, 11, 12);
final _omerDay10 = DateTime(2026, 4, 12, 12);
final _pesachEve = DateTime(2026, 4, 1, 10);
final _pesachDay = DateTime(2026, 4, 2, 12);

Future<_Keeper> _pump(
  WidgetTester tester,
  DateTime Function() clock, {
  Locale locale = kTestLocale,
  Size size = const Size(678, 466),
  QuietDisplay? quiet,
  VoidCallback? onExit,
  ShabbatPlace place = _paris,
}) async {
  final keeper = _Keeper();
  await pumpLocalized(
    tester,
    ShabbatDisplayScreen(
      clock: clock,
      place: place,
      keeper: keeper,
      quiet: quiet ?? QuietDisplay(),
      onExit: onExit ?? () {},
    ),
    locale: locale,
    size: size,
  );
  await tester.pump();
  return keeper;
}

/// Tous les textes de l'écran, dans l'ordre où ils sont posés.
List<String> _texts(WidgetTester tester) => [
  for (final element in find.byType(Text).evaluate())
    (element.widget as Text).data ?? '',
];

/// Le texte qui suit [label] : la valeur d'une ligne « libellé, valeur ».
String _valueOf(WidgetTester tester, String label) {
  final texts = _texts(tester);
  final index = texts.indexOf(label);
  expect(index, isNonNegative, reason: '« $label » absent de $texts');
  return texts[index + 1];
}

/// Les minutes depuis minuit d'une valeur « HH:mm » ou « ven. HH:mm ».
int _minutes(String value) {
  final match = RegExp(r'(\d\d):(\d\d)$').firstMatch(value)!;
  return int.parse(match[1]!) * 60 + int.parse(match[2]!);
}

int _minutesOfDay(DateTime utc) {
  final local = utc.toLocal();
  return local.hour * 60 + local.minute;
}

void _expectClose(String value, DateTime utc, String what) {
  var gap = (_minutes(value) - _minutesOfDay(utc)).abs();
  if (gap > 720) gap = 1440 - gap;
  expect(
    gap,
    lessThanOrEqualTo(2),
    reason: '$what : « $value » au lieu de $utc',
  );
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting();
  });

  group('ce que montre l\'affichage', () {
    testWidgets(
      'le vendredi avant l\'allumage : ce soir, Shabbat, les horaires '
      'et la parasha',
      (tester) async {
        await _pump(tester, () => _fridayMorning);

        final texts = _texts(tester);
        expect(texts, contains('10:00'));
        expect(texts, contains('CE SOIR'));
        expect(texts, contains('Shabbat'));
        // Hebcal, Paris : allumage 15:55 UTC le vendredi, havdala 17:07 UTC.
        _expectClose(
          _valueOf(tester, 'ALLUMAGE'),
          DateTime.utc(2026, 1, 9, 15, 55),
          'allumage',
        );
        _expectClose(
          _valueOf(tester, 'HAVDALA'),
          DateTime.utc(2026, 1, 10, 17, 7),
          'havdala',
        );
        expect(_valueOf(tester, 'PARACHA'), 'Shemos');
        expect(find.text('Basé sur Paris, France'), findsOneWidget);
        expect(find.byType(Hanukkiah), findsNothing);
      },
    );

    testWidgets('un jour ordinaire : à venir, avec le jour de l\'allumage', (
      tester,
    ) async {
      await _pump(tester, () => _wednesday);

      expect(_texts(tester), contains('À VENIR'));
      expect(_valueOf(tester, 'ALLUMAGE'), startsWith('ven.'));
    });

    testWidgets('pendant Shabbat : « Shabbat shalom », la sortie seule', (
      tester,
    ) async {
      await _pump(tester, () => _shabbatEvening);

      final texts = _texts(tester);
      expect(texts, contains('Shabbat shalom'));
      expect(texts, contains('HAVDALA'));
      expect(texts, isNot(contains('ALLUMAGE')));
      expect(texts, isNot(contains('CE SOIR')));
      expect(texts, contains('PARACHA'));
    });

    testWidgets('Hanoucca : le numéro du soir, ses bougies et le chamach', (
      tester,
    ) async {
      await _pump(tester, () => _hanukkahNight4);

      final texts = _texts(tester);
      expect(texts, contains('SOIR 4'));
      expect(texts, contains('Hanoucca'));
      // Les horaires qui suivent sont ceux de Shabbat : l'écran le dit.
      expect(texts, contains('Shabbat'));
      final candles = tester.widget<Hanukkiah>(find.byType(Hanukkiah));
      expect(candles.night, 4);
      // Quatre bougies et le chamach.
      expect(Hanukkiah.litSlots(candles.night), hasLength(5));
    });

    testWidgets('chaque soir de Hanoucca ajoute une bougie', (tester) async {
      await _pump(tester, () => _hanukkahNight8);

      final candles = tester.widget<Hanukkiah>(find.byType(Hanukkiah));
      expect(candles.night, 8);
      expect(Hanukkiah.litSlots(8), hasLength(9));
      expect(Hanukkiah.litSlots(1), hasLength(2));
    });

    testWidgets('l\'Omer : le jour du compte', (tester) async {
      await _pump(tester, () => _omerDay10);

      expect(_texts(tester), contains('Jour 10 de l\'Omer'));
      expect(_texts(tester), contains('Shabbat'));
      expect(find.byType(Hanukkiah), findsNothing);
    });

    testWidgets('la veille de Pessah : le nom de la fête, entrée et sortie', (
      tester,
    ) async {
      await _pump(tester, () => _pesachEve);

      final texts = _texts(tester);
      expect(texts, contains('Pessah'));
      expect(texts, contains('ENTRÉE'));
      expect(texts, contains('SORTIE'));
      expect(texts, isNot(contains('PARACHA')));
      expect(texts, isNot(contains('ALLUMAGE')));
    });

    testWidgets('pendant Pessah : seulement la sortie, jamais « Shabbat »', (
      tester,
    ) async {
      await _pump(tester, () => _pesachDay);

      final texts = _texts(tester);
      expect(texts, contains('Pessah'));
      expect(texts, contains('SORTIE'));
      expect(texts, isNot(contains('ENTRÉE')));
      expect(texts, isNot(contains('Shabbat shalom')));
    });

    testWidgets('les horaires sont ceux du lieu du membre', (tester) async {
      await _pump(tester, () => _fridayMorning, place: _jerusalem);

      // Hebcal, Jérusalem : allumage 14:35 UTC, havdala 15:33 UTC.
      _expectClose(
        _valueOf(tester, 'ALLUMAGE'),
        DateTime.utc(2026, 1, 9, 14, 35),
        'allumage',
      );
      expect(find.text('Basé sur Jérusalem'), findsOneWidget);
    });

    testWidgets('l\'heure suit l\'horloge, sans que personne y touche', (
      tester,
    ) async {
      var now = DateTime(2026, 1, 9, 10, 0, 40);
      await _pump(tester, () => now);
      expect(_texts(tester), contains('10:00'));

      now = DateTime(2026, 1, 9, 10, 1, 5);
      await tester.pump(const Duration(seconds: 15));

      expect(_texts(tester), contains('10:01'));
      expect(_texts(tester), isNot(contains('10:00')));
    });
  });

  group('aucune interaction pendant Shabbat', () {
    testWidgets('aucun bouton, aucune bascule, aucun champ, aucun tap', (
      tester,
    ) async {
      await _pump(tester, () => _hanukkahNight4);

      expect(find.byType(ButtonStyleButton), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(find.byType(EditableText), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is GestureDetector &&
              (widget.onTap != null ||
                  widget.onDoubleTap != null ||
                  widget.onTapDown != null ||
                  widget.onPanUpdate != null ||
                  widget.onVerticalDragUpdate != null ||
                  widget.onHorizontalDragUpdate != null),
        ),
        findsNothing,
      );
    });

    testWidgets('le seul geste reconnu est l\'appui long', (tester) async {
      await _pump(tester, () => _fridayMorning);

      final recognized = <Type>{
        for (final element
            in find
                .descendant(
                  of: find.byType(ShabbatDisplayScreen),
                  matching: find.byType(RawGestureDetector),
                )
                .evaluate())
          ...(element.widget as RawGestureDetector).gestures.keys,
      };
      expect(recognized, {LongPressGestureRecognizer});
    });

    testWidgets('un appui, un double appui ou un glissé ne quittent pas', (
      tester,
    ) async {
      var exits = 0;
      await _pump(tester, () => _fridayMorning, onExit: () => exits++);

      await tester.tap(find.byType(Scaffold));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(Scaffold));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.drag(find.byType(Scaffold), const Offset(0, 300));
      await tester.pump();
      await tester.fling(find.byType(Scaffold), const Offset(300, 0), 2000);
      await tester.pumpAndSettle();

      expect(exits, 0);
      expect(find.byType(ShabbatDisplayScreen), findsOneWidget);
    });

    testWidgets('il faut deux secondes d\'appui pour quitter', (tester) async {
      var exits = 0;
      await _pump(tester, () => _fridayMorning, onExit: () => exits++);
      final center = tester.getCenter(find.byType(Scaffold));

      final brief = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 1500));
      await brief.up();
      await tester.pump();
      expect(exits, 0, reason: '1,5 s ne suffit pas');

      final held = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(exits, 0, reason: '1,9 s ne suffit pas');
      await tester.pump(const Duration(milliseconds: 300));
      expect(exits, 1);
      await held.up();
    });

    testWidgets('le retour du système (balayage, bouton) est refusé', (
      tester,
    ) async {
      final keeper = _Keeper();
      await pumpLocalized(tester, const Scaffold(body: Text('PAGE')));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => ShabbatDisplayScreen(
              clock: () => _fridayMorning,
              place: _paris,
              keeper: keeper,
              quiet: QuietDisplay(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShabbatDisplayScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(ShabbatDisplayScreen), findsOneWidget);
    });

    testWidgets('l\'indication de sortie s\'efface après dix secondes mais '
        'reste lue par VoiceOver', (tester) async {
      await _pump(tester, () => _fridayMorning);
      const hint = 'Maintenez deux secondes pour quitter';
      expect(find.text(hint), findsOneWidget);

      await tester.pump(const Duration(seconds: 11));

      expect(find.text(hint), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.hint == hint &&
              widget.properties.onLongPress != null,
        ),
        findsOneWidget,
      );
    });
  });

  group('l\'écran reste allumé, l\'app se tait', () {
    testWidgets('allumé à l\'ouverture, rendu à la sortie', (tester) async {
      final quiet = QuietDisplay();
      final keeper = await _pump(tester, () => _fridayMorning, quiet: quiet);

      expect(keeper.held, 1);
      expect(keeper.released, 0);
      expect(quiet.isOn, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(keeper.released, 1);
      expect(quiet.isOn, isFalse);
    });

    testWidgets('un téléphone qui refuse de rester allumé ne ferme pas '
        'l\'affichage', (tester) async {
      await pumpLocalized(
        tester,
        ShabbatDisplayScreen(
          clock: () => _fridayMorning,
          place: _paris,
          keeper: _RefusingKeeper(),
          quiet: QuietDisplay(),
        ),
        size: const Size(678, 466),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(ShabbatDisplayScreen), findsOneWidget);
    });
  });

  group('une palette de nuit', () {
    testWidgets('aucun blanc pur, un fond presque noir, rien de lumineux', (
      tester,
    ) async {
      await _pump(tester, () => _hanukkahNight4);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor!.computeLuminance(), lessThan(0.01));
      final colors = <Color>[
        for (final element in find.byType(Text).evaluate())
          ?(element.widget as Text).style?.color,
      ];
      expect(colors, isNotEmpty);
      for (final color in colors) {
        expect(color, isNot(const Color(0xFFFFFFFF)));
        expect(color.computeLuminance(), lessThan(0.6), reason: '$color');
      }
      final candles = tester.widget<Hanukkiah>(find.byType(Hanukkiah));
      expect(candles.flame.computeLuminance(), lessThan(0.6));
    });

    testWidgets('aucune animation : rien ne bouge entre deux images', (
      tester,
    ) async {
      await _pump(tester, () => _hanukkahNight4);

      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('les langues', () {
    final cases = {
      const Locale('fr'): ('Shabbat shalom', 'HAVDALA'),
      const Locale('en'): ('Shabbat shalom', 'HAVDALAH'),
      const Locale('es'): ('Shabat shalom', 'HAVDALÁ'),
      const Locale('he'): ('שבת שלום', 'הבדלה'),
      const Locale('ru'): ('Шаббат шалом', 'АВДАЛА'),
    };
    for (final entry in cases.entries) {
      testWidgets('${entry.key.languageCode} : pendant Shabbat, sans '
          'débordement', (tester) async {
        await _pump(tester, () => _shabbatEvening, locale: entry.key);

        final texts = _texts(tester);
        expect(texts, contains(entry.value.$1));
        expect(texts, contains(entry.value.$2));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('en hébreu, de droite à gauche ; l\'heure se lit de gauche à '
        'droite', (tester) async {
      await _pump(tester, () => _fridayMorning, locale: const Locale('he'));

      expect(textDirectionAt(tester, find.text('שבת')), TextDirection.rtl);
      expect(textDirectionAt(tester, find.text('10:00')), TextDirection.ltr);
    });

    final omer = {
      const Locale('fr'): 'Jour 10 de l\'Omer',
      const Locale('en'): 'Day 10 of the Omer',
      const Locale('es'): 'Día 10 del Ómer',
      const Locale('he'): 'יום 10 בעומר',
      const Locale('ru'): 'День 10 Омера',
    };
    for (final entry in omer.entries) {
      testWidgets('${entry.key.languageCode} : le jour de l\'Omer', (
        tester,
      ) async {
        await _pump(tester, () => _omerDay10, locale: entry.key);

        expect(_texts(tester), contains(entry.value));
      });
    }

    final nights = {
      const Locale('fr'): 'SOIR 4',
      const Locale('en'): 'NIGHT 4',
      const Locale('es'): 'NOCHE 4',
      const Locale('he'): 'לילה 4',
      const Locale('ru'): 'НОЧЬ 4',
    };
    for (final entry in nights.entries) {
      testWidgets('${entry.key.languageCode} : le soir de Hanoucca', (
        tester,
      ) async {
        await _pump(tester, () => _hanukkahNight4, locale: entry.key);

        expect(_texts(tester), contains(entry.value));
      });
    }
  });

  group('les sept poses de l\'iPhone Duo', () {
    final moments = {
      'Shabbat': () => _shabbatEvening,
      'veille de Pessah': () => _pesachEve,
      'Hanoucca, 8e soir': () => _hanukkahNight8,
      'Omer': () => _omerDay10,
    };
    final locales = [kTestLocale, const Locale('ru'), const Locale('he')];

    for (final pose in DuoPose.values) {
      for (final moment in moments.entries) {
        for (final locale in locales) {
          testWidgets('${pose.name}, ${moment.key}, ${locale.languageCode}', (
            tester,
          ) async {
            final controller = DuoPoseController(pose);
            setDuoPose(tester, pose);
            final keeper = _Keeper();
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: locale,
                builder: duoAppBuilder(controller),
                home: ShabbatDisplayScreen(
                  clock: moment.value,
                  place: _paris,
                  keeper: keeper,
                  quiet: QuietDisplay(),
                  onExit: () {},
                ),
              ),
            );
            await settleFold(tester);

            expectFitsDuoPose(tester, pose, 'affichage Shabbat');
            _expectTextsInTheOpen(tester, pose);
          });
        }
      }
    }
  });
}

/// Aucun texte ne sort de la zone sûre de [pose], ne passe sous un élément
/// du système, ni sur le pli (le texte n'est pas touchable, mais il doit se
/// lire).
void _expectTextsInTheOpen(WidgetTester tester, DuoPose pose) {
  final texts = find
      .byType(Text)
      .evaluate()
      .where((element) => (element.widget as Text).data?.isNotEmpty ?? false);
  expect(texts, isNotEmpty);
  for (final element in texts) {
    final box = element.renderObject! as RenderBox;
    final rect = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    final label =
        '« ${(element.widget as Text).data} » dans ${pose.name} à $rect';
    final safe = pose.safeRect.inflate(1);
    expect(
      safe.contains(rect.topLeft) && safe.contains(rect.bottomRight),
      isTrue,
      reason: '$label sort de la zone sûre ${pose.safeRect}',
    );
    for (final occluded in pose.foldState.occlusions) {
      expect(rect.overlaps(occluded), isFalse, reason: '$label sous $occluded');
    }
    if (pose.fold != null) {
      expect(rect.overlaps(pose.fold!), isFalse, reason: '$label sur le pli');
    }
  }
}

class _RefusingKeeper implements ScreenKeeper {
  @override
  Future<void> hold() async => throw StateError('refused');

  @override
  Future<void> release() async => throw StateError('refused');
}
