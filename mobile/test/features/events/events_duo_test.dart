import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/events/screens/event_detail_screen.dart';
import 'package:mazl/presentation/features/events/screens/events_list_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../duo/duo_geometry.dart';

// The events on the foldable iPhone (iPhone Duo) held like a book: the next
// event, large, on the page where reading starts and the other events on the
// other page; on an event, the visual, the date and the place on one page and
// the description, the price and the registration button on the other.

Map<String, Object?> _event(
  int id,
  String title, {
  String? description,
  bool going = false,
}) => {
  'id': id,
  'title': title,
  'description': description,
  'event_type': 'lecture',
  'location': 'Synagogue de la Victoire',
  'address': '44 rue de la Victoire, Paris',
  'date': DateTime.now().add(Duration(days: 10 + id)).toIso8601String(),
  'time': '19:30',
  'price': 12,
  'currency': 'EUR',
  'max_attendees': 40,
  'attendee_count': 12,
  'user_rsvp_status': going ? 'going' : null,
};

final _events = [
  _event(1, 'Dîner de Shabbat', description: 'Un grand repas chez Jeanne.'),
  _event(2, 'Conférence Talmud'),
  _event(3, 'Soirée rencontres'),
];

/// What the server lists; a test may serve fewer events.
List<Map<String, Object?>> _served = _events;

MockClient _server() => MockClient((request) async {
  final path = request.url.path;
  if (path == '/api/events') {
    return http.Response(jsonEncode({'success': true, 'events': _served}), 200);
  }
  if (request.method == 'POST') {
    return http.Response(jsonEncode({'success': true}), 200);
  }
  final id = int.parse(path.split('/').last);
  return http.Response(
    jsonEncode({
      'success': true,
      'event': _event(
        id,
        'Dîner de Shabbat',
        description:
            'Un grand repas chez Jeanne, avec des invités du monde '
            'entier et beaucoup de chants.',
      ),
    }),
    200,
  );
});

Future<DuoPoseController> _pump(
  WidgetTester tester,
  DuoPose pose,
  Widget home, {
  Locale locale = const Locale('fr'),
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: duoAppBuilder(controller),
      home: home,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await settleFold(tester);
  return controller;
}

Future<void> _inServer(Future<void> Function() body) =>
    http.runWithClient(body, _server);

Rect _rect(WidgetTester tester, String text) => tester.getRect(find.text(text));

void main() {
  setUpAll(loadAppFonts);

  group('list', () {
    testWidgets('book: the next event is left of the fold, the others right', (
      tester,
    ) async {
      await _inServer(() async {
        await _pump(tester, DuoPose.halfOpenBook, const EventsListScreen());
        final fold = DuoPose.halfOpenBook.fold!;
        expect(
          _rect(tester, 'Dîner de Shabbat').right,
          lessThanOrEqualTo(fold.left),
        );
        expect(
          _rect(tester, 'Un grand repas chez Jeanne.').right,
          lessThanOrEqualTo(fold.left),
          reason: 'the large card tells more about the next event',
        );
        for (final title in ['Conférence Talmud', 'Soirée rencontres']) {
          expect(
            _rect(tester, title).left,
            greaterThanOrEqualTo(fold.right),
            reason: title,
          );
        }
        expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
      });
    });

    testWidgets('book with one event: the other page says there is no other', (
      tester,
    ) async {
      _served = [_events.first];
      addTearDown(() => _served = _events);
      await _inServer(() async {
        await _pump(tester, DuoPose.halfOpenBook, const EventsListScreen());
        final fold = DuoPose.halfOpenBook.fold!;
        expect(
          _rect(
            tester,
            "Pas d'autre événement pour l'instant. Revenez bientôt.",
          ).left,
          greaterThanOrEqualTo(fold.right),
        );
      });
    });

    testWidgets('book in Hebrew: the next event is right of the fold', (
      tester,
    ) async {
      await _inServer(() async {
        await _pump(
          tester,
          DuoPose.halfOpenBook,
          const EventsListScreen(),
          locale: const Locale('he'),
        );
        final fold = DuoPose.halfOpenBook.fold!;
        expect(
          _rect(tester, 'Dîner de Shabbat').left,
          greaterThanOrEqualTo(fold.right),
        );
        expect(
          _rect(tester, 'Conférence Talmud').right,
          lessThanOrEqualTo(fold.left),
        );
        expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
      });
    });

    testWidgets('open portrait: still one column of cards', (tester) async {
      await _inServer(() async {
        await _pump(tester, DuoPose.openPortrait, const EventsListScreen());
        final first = _rect(tester, 'Dîner de Shabbat');
        final second = _rect(tester, 'Conférence Talmud');
        expect(second.left, first.left);
        expect(second.top, greaterThan(first.bottom));
        expect(
          find.text('Un grand repas chez Jeanne.'),
          findsNothing,
          reason: 'only the book layout has a large card',
        );
      });
    });

    testWidgets('folding and unfolding keep the events', (tester) async {
      await _inServer(() async {
        final pose = await _pump(
          tester,
          DuoPose.openLandscape,
          const EventsListScreen(),
        );
        for (final next in [
          DuoPose.halfOpenBook,
          DuoPose.halfOpenLaptop,
          DuoPose.openPortrait,
          DuoPose.halfOpenBook,
        ]) {
          await pose.moveTo(tester, next);
          await tester.pumpAndSettle();
          for (final title in [
            'Dîner de Shabbat',
            'Conférence Talmud',
            'Soirée rencontres',
          ]) {
            expect(find.text(title), findsOneWidget, reason: next.name);
          }
          expect(
            foldCrossingProblems(tester, next),
            isEmpty,
            reason: next.name,
          );
        }
      });
    });
  });

  group('detail', () {
    Future<void> openDetail(
      WidgetTester tester,
      DuoPose pose, {
      Locale locale = const Locale('fr'),
    }) => _pump(
      tester,
      pose,
      const EventDetailScreen(eventId: '1'),
      locale: locale,
    );

    testWidgets('book: date and place left of the fold, description and '
        'registration right', (tester) async {
      await _inServer(() async {
        await openDetail(tester, DuoPose.halfOpenBook);
        final fold = DuoPose.halfOpenBook.fold!;
        expect(
          _rect(tester, 'Dîner de Shabbat').right,
          lessThanOrEqualTo(fold.left),
        );
        expect(
          _rect(tester, 'Synagogue de la Victoire').right,
          lessThanOrEqualTo(fold.left),
        );
        expect(
          tester
              .getRect(find.textContaining('Un grand repas chez Jeanne'))
              .left,
          greaterThanOrEqualTo(fold.right),
        );
        expect(
          tester.getRect(find.byType(ElevatedButton)).left,
          greaterThanOrEqualTo(fold.right),
        );
        expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
        expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'event');
      });
    });

    testWidgets('book in Hebrew: the registration is left of the fold', (
      tester,
    ) async {
      await _inServer(() async {
        await openDetail(
          tester,
          DuoPose.halfOpenBook,
          locale: const Locale('he'),
        );
        final fold = DuoPose.halfOpenBook.fold!;
        expect(
          tester.getRect(find.byType(ElevatedButton)).right,
          lessThanOrEqualTo(fold.left),
        );
        expect(
          _rect(tester, 'Dîner de Shabbat').left,
          greaterThanOrEqualTo(fold.right),
        );
      });
    });

    testWidgets('open portrait: the registration bar still spans the page', (
      tester,
    ) async {
      await _inServer(() async {
        await openDetail(tester, DuoPose.openPortrait);
        expect(
          tester.getRect(find.byType(ElevatedButton)).width,
          greaterThan(500),
        );
      });
    });

    testWidgets('registering in the book flips the button, still right of '
        'the fold', (tester) async {
      await _inServer(() async {
        await openDetail(tester, DuoPose.halfOpenBook);
        final fold = DuoPose.halfOpenBook.fold!;
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(ElevatedButton), findsNothing);
        expect(
          tester.getRect(find.byType(OutlinedButton)).left,
          greaterThanOrEqualTo(fold.right),
        );
        expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
      });
    });
  });
}
