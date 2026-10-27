import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/presentation/common/widgets/directional_icon.dart';
import 'package:mazl/presentation/features/events/screens/event_detail_screen.dart';
import 'package:mazl/presentation/features/events/screens/events_list_screen.dart';

import '../../../helpers/l10n_helpers.dart';

const _english = Locale('en');
const _hebrew = Locale('he');
const _russian = Locale('ru');

Map<String, Object?> _event({
  int id = 1,
  String title = 'Dîner chez Myriam',
  String? type = 'shabbat_dinner',
  DateTime? date,
  String? time = '19:30',
  String? endTime,
  num price = 0,
  String currency = 'EUR',
  int? max,
  int attendees = 0,
  String? rsvp,
  String? description,
  String? location,
}) => {
  'id': id,
  'title': title,
  'event_type': type,
  'date': (date ?? DateTime.now().add(const Duration(days: 30)))
      .toIso8601String(),
  'time': time,
  'end_time': endTime,
  'price': price,
  'currency': currency,
  'max_attendees': max,
  'attendee_count': attendees,
  'user_rsvp_status': rsvp,
  'description': description,
  'location': location,
};

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

/// Runs [body] with every HTTP call of the app answered by [handler].
Future<void> _withServer(
  Future<http.Response> Function(http.Request) handler,
  Future<void> Function() body,
) => http.runWithClient(body, () => MockClient(handler));

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// The filter chips scroll sideways: the last ones are built once revealed.
Future<void> _revealAllChips(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).first, const Offset(-1000, 0));
  await _settle(tester);
}

Future<http.Response> Function(http.Request) _listServer(
  List<Map<String, Object?>> events,
) =>
    (request) async => _json({'success': true, 'events': events});

void main() {
  group('liste des événements', () {
    final tomorrow = DateTime.now().add(const Duration(days: 1, hours: 2));
    final inThreeDays = DateTime.now().add(const Duration(days: 3, hours: 2));
    final events = [
      _event(
        id: 1,
        title: 'Dîner chez Myriam',
        date: tomorrow,
        max: 10,
        attendees: 9,
        price: 25,
      ),
      _event(
        id: 2,
        title: 'Cours de hébreu',
        type: 'lecture',
        date: inThreeDays,
        attendees: 12,
      ),
      _event(id: 3, title: 'Soirée Pourim', type: 'holiday'),
    ];

    testWidgets('en français, les textes d\'origine', (tester) async {
      await _withServer(_listServer(events), () async {
        await pumpLocalized(tester, const EventsListScreen());
        await _settle(tester);

        expect(find.text('Événements'), findsOneWidget);
        expect(find.text('Tous'), findsOneWidget);
        await _revealAllChips(tester);
        for (final chip in ['Fêtes', 'Cours', 'Social']) {
          expect(find.text(chip), findsWidgets, reason: chip);
        }
        expect(find.text('Gratuit'), findsWidgets);
        expect(find.text('Presque complet'), findsOneWidget);
        expect(find.text('Demain'), findsWidgets);
        expect(find.text('12 participants'), findsOneWidget);
        expect(find.textContaining('à 19 h 30'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('en anglais : filtres, badges, dates et pluriels', (
      tester,
    ) async {
      await _withServer(_listServer(events), () async {
        await pumpLocalized(tester, const EventsListScreen(), locale: _english);
        await _settle(tester);

        expect(find.text('Events'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
        await _revealAllChips(tester);
        for (final chip in ['Holidays', 'Class', 'Social']) {
          expect(find.text(chip), findsWidgets, reason: chip);
        }
        expect(find.text('Free'), findsWidgets);
        expect(find.text('Almost full'), findsOneWidget);
        expect(find.text('Tomorrow'), findsWidgets);
        expect(find.text('In 3d'), findsOneWidget);
        expect(find.text('12 participants'), findsOneWidget);
        expect(find.text('€25'), findsOneWidget);
        // Tomorrow at 7:30 pm is written with the word, then the time.
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                RegExp(r'^Tomorrow at 7:30\sPM$').hasMatch(w.data ?? ''),
          ),
          findsOneWidget,
        );
        // A far date is a weekday and a month in English, not in French.
        expect(
          find.textContaining(
            RegExp(
              r'^(Mon|Tues|Wednes|Thurs|Fri|Satur|Sun)day, [A-Z][a-z]+ \d{1,2} at 7:30\sPM$',
            ),
          ),
          findsWidgets,
        );
        expect(find.text('Dîner chez Myriam'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('en russe : « 21 участник » suit le pluriel à quatre formes', (
      tester,
    ) async {
      final crowd = [
        _event(id: 1, attendees: 21),
        _event(id: 2, attendees: 22),
        _event(id: 3, attendees: 25),
      ];
      await _withServer(_listServer(crowd), () async {
        await pumpLocalized(tester, const EventsListScreen(), locale: _russian);
        await _settle(tester);

        expect(find.text('21 участник'), findsOneWidget);
        expect(find.text('22 участника'), findsOneWidget);
        expect(find.text('25 участников'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    for (final brightness in Brightness.values) {
      testWidgets(
        'en hébreu (${brightness.name}) : de droite à gauche, 360 px, sans débordement',
        (tester) async {
          await _withServer(_listServer(events), () async {
            await pumpLocalized(
              tester,
              const EventsListScreen(),
              locale: _hebrew,
              brightness: brightness,
            );
            await _settle(tester);

            expect(find.text('אירועים'), findsOneWidget);
            expect(
              textDirectionAt(tester, find.text('אירועים')),
              TextDirection.rtl,
            );
            expect(find.text('כמעט מלא'), findsOneWidget);
            expect(find.text('חינם'), findsWidgets);
            expect(find.text('מחר'), findsWidgets);
            expect(find.text('בעוד 3 ימים'), findsOneWidget);
            // Not a single French word is left on the screen.
            expect(
              find.textContaining(RegExp('Gratuit|Demain|Complet|Événement')),
              findsNothing,
            );
            expect(tester.takeException(), isNull);

            // The type badge sits at the start (right) of the card.
            final badge = tester.getTopRight(find.text('שבת').last);
            final card = tester.getTopRight(find.byType(Card).first);
            expect(card.dx - badge.dx, lessThan(60));
          });
        },
      );
    }

    testWidgets('chargement impossible : la phrase est traduite', (
      tester,
    ) async {
      await _withServer(
        (request) async => _json({'success': false}, 500),
        () async {
          await pumpLocalized(
            tester,
            const EventsListScreen(),
            locale: _english,
          );
          await _settle(tester);

          expect(find.text("Couldn't load events"), findsOneWidget);
          expect(find.text('Try again'), findsOneWidget);
        },
      );
    });

    testWidgets('aucun événement : titre et explication traduits', (
      tester,
    ) async {
      await _withServer(_listServer(const []), () async {
        await pumpLocalized(tester, const EventsListScreen(), locale: _english);
        await _settle(tester);

        expect(find.text('No events'), findsOneWidget);
        expect(
          find.text('Come back soon to discover\nnew events.'),
          findsOneWidget,
        );
      });
    });
  });

  group('détail d\'un événement', () {
    Future<http.Response> Function(http.Request) detailServer(
      Map<String, Object?> event, {
      List<String>? calls,
    }) => (request) async {
      calls?.add('${request.method} ${request.url.path}');
      if (request.method == 'GET') {
        return _json({'success': true, 'event': event});
      }
      return _json({'success': true});
    };

    final paid = _event(
      id: 7,
      title: 'Dîner chez Myriam',
      price: 25,
      max: 20,
      attendees: 12,
      location: 'Maison de Myriam',
      endTime: '22:00',
      description: 'Un repas de Shabbat.',
    );

    testWidgets('en français, les textes d\'origine', (tester) async {
      await _withServer(detailServer(paid), () async {
        await pumpLocalized(tester, const EventDetailScreen(eventId: '7'));
        await _settle(tester);

        for (final text in [
          'Date',
          'Heure',
          'Lieu',
          'Participants',
          'Prix',
          'Description',
        ]) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
        // Was « Shabbat Dinner » in the French app until 2026-10-27.
        expect(find.text('Dîner de Shabbat'), findsOneWidget);
        expect(find.text('12 / 20 places'), findsOneWidget);
        expect(find.textContaining('par personne'), findsOneWidget);
        expect(find.textContaining('S\'inscrire - '), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('en anglais : libellés, capacité, prix et bouton', (
      tester,
    ) async {
      await _withServer(detailServer(paid), () async {
        await pumpLocalized(
          tester,
          const EventDetailScreen(eventId: '7'),
          locale: _english,
        );
        await _settle(tester);

        for (final text in [
          'Date',
          'Time',
          'Place',
          'Participants',
          'Price',
          'Description',
        ]) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
        expect(find.text('Shabbat dinner'), findsOneWidget);
        expect(find.text('12 / 20 spots'), findsOneWidget);
        expect(find.text('€25 per person'), findsOneWidget);
        expect(find.text('Register - €25'), findsOneWidget);
        expect(
          find.textContaining(
            RegExp(
              r'^(Mon|Tues|Wednes|Thurs|Fri|Satur|Sun)day, [A-Z][a-z]+ \d{1,2}, \d{4}$',
            ),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('gratuit, sans limite de places : « inscrits » au pluriel', (
      tester,
    ) async {
      final free = _event(id: 8, attendees: 1);
      await _withServer(detailServer(free), () async {
        await pumpLocalized(
          tester,
          const EventDetailScreen(eventId: '8'),
          locale: _english,
        );
        await _settle(tester);

        expect(find.text('1 person registered'), findsOneWidget);
        expect(find.text('Free'), findsOneWidget);
        expect(find.text('Register for free'), findsOneWidget);
      });
    });

    testWidgets('complet : le badge et le bouton le disent', (tester) async {
      final full = _event(id: 9, max: 20, attendees: 20);
      await _withServer(detailServer(full), () async {
        await pumpLocalized(
          tester,
          const EventDetailScreen(eventId: '9'),
          locale: _english,
        );
        await _settle(tester);

        expect(find.text('Full'), findsNWidgets(2));
      });
    });

    testWidgets(
      's\'inscrire puis annuler : bandeau, bouton et messages traduits',
      (tester) async {
        final calls = <String>[];
        await _withServer(detailServer(paid, calls: calls), () async {
          await pumpLocalized(
            tester,
            const EventDetailScreen(eventId: '7'),
            locale: _english,
          );
          await _settle(tester);

          await tester.tap(find.text('Register - €25'));
          await _settle(tester);
          expect(find.text('Registration confirmed'), findsOneWidget);
          expect(find.text("You're registered for this event"), findsOneWidget);
          expect(find.text('13 / 20 spots'), findsOneWidget);

          ScaffoldMessenger.of(
            tester.element(find.byType(Scaffold).first),
          ).clearSnackBars();
          await _settle(tester);
          await tester.tap(find.text('Cancel my registration'));
          await _settle(tester);
          expect(find.text('Registration cancelled'), findsOneWidget);
          expect(find.text('Register - €25'), findsOneWidget);
          expect(
            calls,
            containsAll([
              'POST /api/events/7/rsvp',
              'DELETE /api/events/7/rsvp',
            ]),
          );
        });
      },
    );

    testWidgets('introuvable : phrase et bouton traduits', (tester) async {
      await _withServer(
        (request) async => _json({'success': false}, 404),
        () async {
          await pumpLocalized(
            tester,
            const EventDetailScreen(eventId: '404'),
            locale: _english,
          );
          await _settle(tester);

          expect(find.text('Event not found'), findsOneWidget);
          expect(find.text('Back'), findsOneWidget);
        },
      );
    });

    for (final brightness in Brightness.values) {
      testWidgets(
        'en hébreu (${brightness.name}) : de droite à gauche, flèche retournée, sans débordement',
        (tester) async {
          await _withServer(detailServer(paid), () async {
            await pumpLocalized(
              tester,
              const EventDetailScreen(eventId: '7'),
              locale: _hebrew,
              brightness: brightness,
            );
            await _settle(tester);

            expect(find.text('תאריך'), findsOneWidget);
            expect(
              textDirectionAt(tester, find.text('תאריך')),
              TextDirection.rtl,
            );
            expect(find.text('ארוחת שבת'), findsOneWidget);
            expect(find.text('\u200e12 / 20 מקומות'), findsOneWidget);
            expect(find.textContaining('לאדם'), findsOneWidget);
            expect(
              find.textContaining(RegExp('Date|Heure|Prix|places')),
              findsNothing,
            );
            // The back arrow flips with the reading direction.
            final arrow = find.byType(DirectionalIcon);
            expect(arrow, findsWidgets);
            expect(
              find.descendant(
                of: arrow.first,
                matching: find.byType(Transform),
              ),
              findsWidgets,
            );
            // The label column starts at the right edge of the screen.
            final label = tester.getTopRight(find.text('תאריך'));
            expect(label.dx, greaterThan(kSmallPhone.width / 2));
            expect(tester.takeException(), isNull);
          });
        },
      );
    }
  });
}
