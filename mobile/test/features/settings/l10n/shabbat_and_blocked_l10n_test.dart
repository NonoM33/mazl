import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/presentation/common/widgets/directional_icon.dart';
import 'package:mazl/presentation/features/settings/screens/blocked_users_screen.dart';
import 'package:mazl/presentation/features/settings/screens/shabbat_mode_screen.dart';
import 'package:mazl/presentation/features/settings/widgets/shabbat_hero.dart';

import '../../../helpers/l10n_helpers.dart';

const _english = Locale('en');
const _hebrew = Locale('he');
const _russian = Locale('ru');
const _spanish = Locale('es');

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  group('bandeau du mode Shabbat', () {
    Widget hero({VoidCallback? onBack}) => Scaffold(
      body: SingleChildScrollView(
        child: ShabbatHero(
          candleLighting: '17:42',
          havdala: '18:51',
          city: 'Paris',
          onBack: onBack,
        ),
      ),
    );

    testWidgets('en anglais', (tester) async {
      await pumpLocalized(tester, hero(onBack: () {}), locale: _english);

      expect(find.text('Shabbat\nshalom.'), findsOneWidget);
      expect(find.text('CANDLE LIGHTING'), findsOneWidget);
      expect(find.text('HAVDALAH'), findsOneWidget);
      expect(
        find.text(
          'Mazl is resting with you. Your messages will wait for you at Havdalah.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
    });

    testWidgets('en russe et en espagnol, les termes usuels', (tester) async {
      await pumpLocalized(tester, hero(), locale: _russian);
      expect(find.text('Шаббат\nшалом.'), findsOneWidget);
      expect(find.text('АВДАЛА'), findsOneWidget);

      await pumpLocalized(tester, hero(), locale: _spanish);
      expect(find.text('Shabat\nshalom.'), findsOneWidget);
      expect(find.text('HAVDALÁ'), findsOneWidget);
    });

    for (final brightness in Brightness.values) {
      testWidgets(
        'en hébreu (${brightness.name}) : l\'allumage à droite, la flèche retournée, sans débordement',
        (tester) async {
          await pumpLocalized(
            tester,
            hero(onBack: () {}),
            locale: _hebrew,
            brightness: brightness,
          );

          expect(find.text('שבת\nשלום.'), findsOneWidget);
          expect(
            textDirectionAt(tester, find.text('שבת\nשלום.')),
            TextDirection.rtl,
          );
          final candles = tester.getCenter(find.text('הדלקת נרות'));
          final havdalah = tester.getCenter(find.text('הבדלה'));
          expect(candles.dx, greaterThan(havdalah.dx));
          expect(find.byType(DirectionalIcon), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('en français, l\'allumage reste à gauche', (tester) async {
      await pumpLocalized(tester, hero());

      expect(
        tester.getCenter(find.text('ALLUMAGE')).dx,
        lessThan(tester.getCenter(find.text('HAVDALA')).dx),
      );
    });
  });

  group('écran du mode Shabbat', () {
    testWidgets('en anglais : réglages, curseur de marge, explication', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 1600);
      await pumpLocalized(
        tester,
        const ShabbatModeScreen(),
        locale: _english,
        size: const Size(360, 1600),
      );

      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('Turn on Shabbat mode'), findsOneWidget);
      expect(
        find.text('Notifications pause automatically during Shabbat'),
        findsOneWidget,
      );
      expect(find.text('Include holidays'), findsOneWidget);
      expect(find.text('Also pause during Yom Tov'), findsOneWidget);
      expect(find.text('Margin before candle lighting'), findsOneWidget);
      expect(find.text('18 min'), findsOneWidget);
      expect(find.text('Based on Paris, France'), findsWidgets);
      expect(find.text('Edit'), findsOneWidget);
      expect(
        find.textContaining('your status will show “Shabbat mode”.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('en français, les textes d\'origine', (tester) async {
      await pumpLocalized(
        tester,
        const ShabbatModeScreen(),
        size: const Size(360, 1600),
      );

      expect(find.text('RÉGLAGES'), findsOneWidget);
      expect(find.text('Activer le mode Shabbat'), findsOneWidget);
      expect(find.text("Marge avant l'allumage"), findsOneWidget);
      expect(find.text('18 min'), findsOneWidget);
      expect(find.text('Modifier'), findsOneWidget);
      expect(
        find.text(
          'Les notifications sont mises en pause et les messages attendent. '
          'Vous recevrez tout après la fin de Shabbat, et votre statut '
          'affichera « Mode Shabbat ».',
        ),
        findsOneWidget,
      );
    });

    testWidgets('le curseur annonce ses pas en toutes lettres, au bon pluriel', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpLocalized(
        tester,
        const ShabbatModeScreen(),
        locale: _russian,
        size: const Size(360, 1600),
      );

      final slider = tester.getSemantics(find.byType(Slider));
      final labels = <String>[];
      final spoken = <String>[];
      slider.visitChildren((child) {
        labels.add(child.label);
        spoken
          ..add(child.value)
          ..add(child.increasedValue)
          ..add(child.decreasedValue);
        return true;
      });
      // The short label is what the thumb shows; the values are spoken in full.
      expect(labels, contains('18 мин'));
      expect(spoken.where((text) => text.isNotEmpty), isNotEmpty);
      for (final text in spoken.where((text) => text.isNotEmpty)) {
        expect(text, matches(RegExp(r'^\d+ (минута|минуты|минут)$')));
      }
      semantics.dispose();
    });

    for (final brightness in Brightness.values) {
      testWidgets(
        'en hébreu (${brightness.name}) : de droite à gauche, sans débordement',
        (tester) async {
          await pumpLocalized(
            tester,
            const ShabbatModeScreen(),
            locale: _hebrew,
            brightness: brightness,
            size: const Size(360, 1600),
          );

          expect(find.text('הפעלת מצב שבת'), findsOneWidget);
          expect(
            textDirectionAt(tester, find.text('הפעלת מצב שבת')),
            TextDirection.rtl,
          );
          expect(find.text('18 דק׳'), findsOneWidget);
          expect(find.text('עריכה'), findsOneWidget);
          // The title of a row starts at the right edge.
          expect(
            tester.getTopRight(find.text('הפעלת מצב שבת')).dx,
            greaterThan(kSmallPhone.width / 2),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('utilisateurs bloqués', () {
    Map<String, Object?> blocked(int id, String? name) => {
      'id': id,
      'user_id': 100 + id,
      'display_name': name,
      'picture': null,
      'blocked_at': '2026-10-05T10:00:00.000Z',
    };

    Future<void> withServer(
      List<Map<String, Object?>> users,
      Future<void> Function() body, {
      int unblockStatus = 200,
    }) => http.runWithClient(
      body,
      () => MockClient((request) async {
        if (request.method == 'DELETE') {
          return http.Response(
            jsonEncode({'success': unblockStatus == 200}),
            unblockStatus,
          );
        }
        return http.Response(
          jsonEncode({'success': true, 'blocked_users': users}),
          200,
        );
      }),
    );

    testWidgets('en français, les textes d\'origine', (tester) async {
      await withServer([blocked(1, 'Myriam')], () async {
        await pumpLocalized(tester, const BlockedUsersScreen());
        await _settle(tester);

        expect(find.text('Utilisateurs bloqués'), findsOneWidget);
        expect(find.text('Myriam'), findsOneWidget);
        expect(find.text('Bloqué le 05/10/2026'), findsOneWidget);
        expect(find.text('Débloquer'), findsOneWidget);
      });
    });

    testWidgets('en anglais : la date suit la langue, la confirmation aussi', (
      tester,
    ) async {
      await withServer([blocked(1, 'Myriam'), blocked(2, null)], () async {
        await pumpLocalized(
          tester,
          const BlockedUsersScreen(),
          locale: _english,
        );
        await _settle(tester);

        expect(find.text('Blocked users'), findsOneWidget);
        expect(find.text('Blocked on 10/5/2026'), findsNWidgets(2));
        expect(find.text('User'), findsOneWidget);

        await tester.tap(find.text('Unblock').first);
        await _settle(tester);
        expect(find.text('Unblock this user?'), findsOneWidget);
        expect(
          find.text(
            'Do you want to unblock Myriam?\n\n'
            'This person will be able to see your profile and contact you again.',
          ),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Unblock'));
        await _settle(tester);
        expect(find.text('Myriam was unblocked'), findsOneWidget);
        expect(find.text('Myriam'), findsNothing);
      });
    });

    testWidgets('le déblocage échoue : la phrase est celle de l\'écran', (
      tester,
    ) async {
      await withServer([blocked(1, 'Myriam')], () async {
        await pumpLocalized(
          tester,
          const BlockedUsersScreen(),
          locale: _english,
        );
        await _settle(tester);

        await tester.tap(find.text('Unblock'));
        await _settle(tester);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Unblock'));
        await _settle(tester);

        expect(find.text("Couldn't unblock this user"), findsOneWidget);
        expect(find.textContaining('Failed to unblock'), findsNothing);
      }, unblockStatus: 500);
    });

    testWidgets('personne de bloqué, en anglais', (tester) async {
      await withServer(const [], () async {
        await pumpLocalized(
          tester,
          const BlockedUsersScreen(),
          locale: _english,
        );
        await _settle(tester);

        expect(find.text('No blocked users'), findsOneWidget);
        expect(find.text('People you block\nwill appear here'), findsOneWidget);
      });
    });

    testWidgets('chargement impossible, en russe', (tester) async {
      await http.runWithClient(() async {
        await pumpLocalized(
          tester,
          const BlockedUsersScreen(),
          locale: _russian,
        );
        await _settle(tester);

        expect(find.text('Ошибка загрузки'), findsOneWidget);
        expect(find.text('Повторить'), findsOneWidget);
      }, () => MockClient((_) async => http.Response('{}', 500)));
    });

    for (final brightness in Brightness.values) {
      testWidgets(
        'en hébreu (${brightness.name}) : de droite à gauche, sans débordement',
        (tester) async {
          await withServer([blocked(1, 'Myriam')], () async {
            await pumpLocalized(
              tester,
              const BlockedUsersScreen(),
              locale: _hebrew,
              brightness: brightness,
            );
            await _settle(tester);

            expect(find.text('משתמשים חסומים'), findsOneWidget);
            expect(
              textDirectionAt(tester, find.text('Myriam')),
              TextDirection.rtl,
            );
            expect(find.textContaining('תאריך החסימה'), findsOneWidget);
            // The unblock button sits at the end of the row: the left, in RTL.
            expect(
              tester.getCenter(find.text('ביטול חסימה')).dx,
              lessThan(kSmallPhone.width / 2),
            );
            expect(tester.takeException(), isNull);
          });
        },
      );
    }
  });
}
