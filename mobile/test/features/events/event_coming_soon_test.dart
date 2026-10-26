import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/models/event.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/events/screens/event_detail_screen.dart';
import 'package:mazl/presentation/features/events/screens/events_list_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../duo/duo_geometry.dart';

// An event announced « Bientôt disponible » (the fake events of the TestFlight
// phase): no registration button, a disabled « Bientôt disponible » instead,
// and « Me prévenir », which becomes « Vous serez prévenu » once asked. The
// server refuses the registration anyway (409 event_coming_soon).

Map<String, Object?> _event({bool notify = false, String? availability}) => {
  'id': 7,
  'title': 'Dîner de Shabbat des 25-35 ans',
  'description': 'Un vrai dîner de Shabbat, autour de grandes tablées.',
  'event_type': 'shabbat_dinner',
  'location': 'Paris 17e',
  'address': "Adresse communiquée à l'ouverture des inscriptions",
  'date': DateTime.now().add(const Duration(days: 11)).toIso8601String(),
  'time': '19:30',
  'end_time': '23:00',
  'price': 35,
  'currency': 'EUR',
  'max_attendees': 40,
  'attendee_count': 0,
  'availability': availability ?? 'coming_soon',
  'notify_requested': notify,
};

/// The requests the screen made, as « METHOD path ».
final List<String> _calls = [];
int _alertStatus = 200;

MockClient _server() => MockClient((request) async {
  final path = request.url.path;
  _calls.add('${request.method} $path');
  if (path == '/api/events') {
    return http.Response(
      jsonEncode({
        'success': true,
        'events': [_event()],
      }),
      200,
    );
  }
  if (path.endsWith('/notify')) {
    return http.Response(
      jsonEncode({'success': _alertStatus == 200}),
      _alertStatus,
    );
  }
  if (path.endsWith('/rsvp')) {
    return http.Response(
      jsonEncode({'success': false, 'code': 'event_coming_soon'}),
      409,
    );
  }
  return http.Response(jsonEncode({'success': true, 'event': _event()}), 200);
});

Future<void> _pump(WidgetTester tester, DuoPose pose, Widget home) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      builder: duoAppBuilder(controller),
      home: home,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await settleFold(tester);
}

Future<void> _inServer(Future<void> Function() body) =>
    http.runWithClient(body, _server);

ButtonStyleButton _button(WidgetTester tester, String label) =>
    tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );

void main() {
  setUpAll(loadAppFonts);
  setUp(() {
    _calls.clear();
    _alertStatus = 200;
  });

  group('the event model', () {
    test('reads the availability and the alert of the member', () {
      final soon = Event.fromJson(_event(notify: true));
      expect(soon.isComingSoon, isTrue);
      expect(soon.notifyRequested, isTrue);
      final open = Event.fromJson(_event(availability: 'open'));
      expect(open.isComingSoon, isFalse);
      final unknown = Event.fromJson({..._event(), 'availability': 'later'});
      expect(unknown.availability, EventAvailability.open);
      final missing = Event.fromJson({..._event()}..remove('availability'));
      expect(missing.availability, EventAvailability.open);
    });
  });

  group('detail of a coming soon event', () {
    testWidgets('« Bientôt disponible » disabled, no registration button', (
      tester,
    ) async {
      await _inServer(() async {
        await _pump(
          tester,
          DuoPose.closed,
          const EventDetailScreen(eventId: '7'),
        );
        expect(find.text('Bientôt disponible'), findsOneWidget);
        expect(_button(tester, 'Bientôt disponible').onPressed, isNull);
        expect(find.textContaining("S'inscrire"), findsNothing);
        expect(find.text('Me prévenir'), findsOneWidget);
        expect(_button(tester, 'Me prévenir').onPressed, isNotNull);
        expect(_calls.where((call) => call.endsWith('/rsvp')), isEmpty);
      });
    });

    testWidgets('« Me prévenir » asks, « Vous serez prévenu » withdraws', (
      tester,
    ) async {
      await _inServer(() async {
        await _pump(
          tester,
          DuoPose.closed,
          const EventDetailScreen(eventId: '7'),
        );
        await tester.tap(find.text('Me prévenir'));
        await tester.pumpAndSettle();
        expect(_calls, contains('POST /api/events/7/notify'));
        expect(find.text('Vous serez prévenu'), findsOneWidget);
        expect(
          find.text("Nous vous préviendrons à l'ouverture des inscriptions."),
          findsOneWidget,
        );

        await tester.tap(find.text('Vous serez prévenu'));
        await tester.pumpAndSettle();
        expect(_calls, contains('DELETE /api/events/7/notify'));
        expect(find.text('Me prévenir'), findsOneWidget);
      });
    });

    testWidgets('a refused alert keeps « Me prévenir » and says so', (
      tester,
    ) async {
      _alertStatus = 500;
      await _inServer(() async {
        await _pump(
          tester,
          DuoPose.closed,
          const EventDetailScreen(eventId: '7'),
        );
        await tester.tap(find.text('Me prévenir'));
        await tester.pumpAndSettle();
        expect(find.text('Me prévenir'), findsOneWidget);
        expect(find.text('Vous serez prévenu'), findsNothing);
        expect(
          find.text("Impossible d'enregistrer votre demande. Réessayez."),
          findsOneWidget,
        );
      });
    });

    for (final pose in DuoPose.values) {
      testWidgets(
        '${pose.name}: both buttons on screen, 44 pt high at least, nothing in the fold',
        (tester) async {
          await _inServer(() async {
            await _pump(tester, pose, const EventDetailScreen(eventId: '7'));
            final screen = Offset.zero & pose.size;
            for (final label in ['Bientôt disponible', 'Me prévenir']) {
              final button = tester.getRect(
                find.ancestor(
                  of: find.text(label),
                  matching: find.bySubtype<ButtonStyleButton>(),
                ),
              );
              expect(button.height, greaterThanOrEqualTo(44), reason: label);
              expect(
                screen.intersect(button),
                button,
                reason: '$label is fully on screen',
              );
              final fold = pose.fold;
              if (fold != null) {
                expect(fold.overlaps(button), isFalse, reason: label);
              }
            }
            expect(foldCrossingProblems(tester, pose), isEmpty);
          });
        },
      );
    }

    testWidgets('book: the buttons sit on the page of the registration', (
      tester,
    ) async {
      await _inServer(() async {
        await _pump(
          tester,
          DuoPose.halfOpenBook,
          const EventDetailScreen(eventId: '7'),
        );
        final fold = DuoPose.halfOpenBook.fold!;
        for (final label in ['Bientôt disponible', 'Me prévenir']) {
          expect(
            tester.getRect(find.text(label)).left,
            greaterThanOrEqualTo(fold.right),
            reason: label,
          );
        }
      });
    });
  });

  group('list', () {
    testWidgets('the card says « Bientôt disponible », not 0 / 40', (
      tester,
    ) async {
      await _inServer(() async {
        await _pump(tester, DuoPose.closed, const EventsListScreen());
        expect(find.text('Dîner de Shabbat des 25-35 ans'), findsOneWidget);
        expect(find.text('Bientôt disponible'), findsOneWidget);
        expect(find.text('0 / 40'), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      });
    });
  });
}
