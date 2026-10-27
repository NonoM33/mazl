import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/layout/content_max_width.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/services/couple_daily_api.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';
import 'package:mazl/presentation/features/couple/screens/couple_outings_screen.dart';
import 'package:mazl/presentation/features/couple/widgets/outing_save_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../duo/duo_geometry.dart';

// Shapes written from docs/couple/ESPACE-COUPLE.md §4:
// GET /api/couple/outings?filter=tonight|week|kosher|cheap|mazl
// -> { success, data: { featured: <Outing|null>, items: [<Outing>] } }.

Map<String, dynamic> _outing({
  required int id,
  String kind = 'activity',
  String title = 'Cours de pâtisserie à deux',
  String? subtitle,
  String? city,
  String? startsAt,
  int? priceCents,
  bool saved = false,
}) => {
  'id': id,
  'kind': kind,
  'title': title,
  'subtitle': subtitle,
  'imageUrl': null,
  'city': city,
  'startsAt': startsAt,
  'priceCents': priceCents,
  'kosher': true,
  'saved': saved,
};

Map<String, dynamic> _page({
  Map<String, dynamic>? featured,
  List<Map<String, dynamic>> items = const [],
}) => ok({'featured': featured, 'items': items});

final _event = _outing(
  id: 7,
  kind: 'event',
  title: 'Dîner de Shabbat entre couples',
  subtitle: 'Une table pour huit couples',
  city: 'Paris 17e',
  startsAt: '2026-11-06T12:00:00Z',
  priceCents: 3500,
);

final _pastry = _outing(
  id: 21,
  title: 'Cours de pâtisserie à deux',
  city: 'Paris 3e',
  startsAt: '2026-11-07T12:00:00Z',
  priceCents: 6000,
);
final _brunch = _outing(
  id: 22,
  title: 'Balade et brunch au canal',
  priceCents: 0,
);
final _jazz = _outing(id: 23, title: 'Concert de jazz', city: 'Paris 11e');

/// A transport that holds back the answer to chosen paths until a test lets
/// them go: a slow network.
class _GatedTransport extends FakeCoupleTransport {
  final Map<String, Completer<void>> gates = {};

  @override
  Future<Map<String, dynamic>> get(String path) async {
    final gate = gates[path];
    if (gate != null) await gate.future;
    return super.get(path);
  }
}

class _Rig {
  _Rig(this.transport);

  final FakeCoupleTransport transport;

  CoupleDailyApi get daily =>
      CoupleDailyApi(transport: transport, callerId: () => 12);
  CoupleApiService get content => CoupleApiService(transport: transport);

  Widget screen() => CoupleOutingsScreen(api: daily, contentApi: content);
}

/// The bookmark of an activity that is not saved yet / already saved. (The
/// header's « Sauvegardées » bookmark is another control.)
Finder _save() => find.descendant(
  of: find.byType(OutingSaveButton),
  matching: find.byIcon(LucideIcons.bookmark),
);
Finder _unsave() => find.descendant(
  of: find.byType(OutingSaveButton),
  matching: find.byIcon(LucideIcons.bookmarkCheck),
);

Widget _app(Widget home) {
  Page<void> page(String label) => NoTransitionPage<void>(child: Text(label));
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/couple/activities/saved',
        pageBuilder: (_, _) => page('page:saved'),
      ),
      GoRoute(
        path: '/couple/activities/:id',
        pageBuilder: (_, s) => page('page:activity:${s.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/couple/events/:id',
        pageBuilder: (_, s) => page('page:event:${s.pathParameters['id']}'),
      ),
    ],
  );
  return MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: kTestLocale,
    routerConfig: router,
  );
}

Future<_Rig> _pump(
  WidgetTester tester,
  void Function(FakeCoupleTransport) setUp, {
  FakeCoupleTransport? transport,
}) async {
  tester.view.physicalSize = const Size(450, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final rig = _Rig(transport ?? FakeCoupleTransport());
  setUp(rig.transport);
  await tester.pumpWidget(_app(rig.screen()));
  await tester.pump();
  await tester.pump();
  return rig;
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('content', () {
    testWidgets('shows the featured event, its facts and the ideas', (
      tester,
    ) async {
      await _pump(
        tester,
        (t) => t.reply(
          'GET /api/couple/outings',
          _page(featured: _event, items: [_pastry, _brunch, _jazz]),
        ),
      );

      expect(find.text('PRÈS DE CHEZ VOUS · PARIS 17E'), findsOneWidget);
      expect(find.text('Sorties à deux'), findsOneWidget);
      expect(find.text('Événement MAZL couples'), findsOneWidget);
      expect(find.text('Dîner de Shabbat entre couples'), findsOneWidget);
      expect(find.text('Une table pour huit couples'), findsOneWidget);
      expect(
        find.text('vendredi 6 novembre · Paris 17e · 35 € par couple'),
        findsOneWidget,
      );
      expect(find.text('SÉLECTION POUR VOUS DEUX'), findsOneWidget);
      expect(find.text('Cours de pâtisserie à deux'), findsOneWidget);
      expect(find.text('sam. 7 nov. · Paris 3e · 60 €'), findsOneWidget);
      expect(find.text('Gratuit'), findsOneWidget);
      expect(find.text('Concert de jazz'), findsOneWidget);
      expect(
        find.text(
          'Les idées tiennent compte de votre cacherout, de vos goûts '
          'sauvegardés et de vos dates à venir.',
        ),
        findsOneWidget,
      );
      for (final label in [
        'Ce soir',
        'Ce week-end',
        'Casher',
        'Moins de 50 €',
        'Événements MAZL',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('the eyebrow takes the city of the first idea without a '
        'featured outing, and has none without any city', (tester) async {
      await _pump(
        tester,
        (t) => t.reply(
          'GET /api/couple/outings',
          _page(items: [_brunch, _pastry]),
        ),
      );
      // The first idea has no city: the first city found is not guessed.
      expect(find.text('PRÈS DE CHEZ VOUS'), findsOneWidget);

      await _pump(
        tester,
        (t) =>
            t.reply('GET /api/couple/outings', _page(items: [_pastry, _jazz])),
      );
      expect(find.text('PRÈS DE CHEZ VOUS · PARIS 3E'), findsOneWidget);
    });

    testWidgets('an activity without a photo gets the tinted stand-in', (
      tester,
    ) async {
      await _pump(
        tester,
        (t) => t.reply(
          'GET /api/couple/outings',
          _page(featured: _event, items: [_pastry]),
        ),
      );
      expect(find.byKey(const Key('outing-photo-fallback-7')), findsOneWidget);
      expect(find.byKey(const Key('outing-photo-fallback-21')), findsOneWidget);
    });
  });

  group('filters', () {
    final answers = <String, Map<String, dynamic>>{
      '': _page(featured: _event, items: [_pastry]),
      'tonight': _page(items: [_outing(id: 31, title: 'Ce soir seulement')]),
      'week': _page(items: [_outing(id: 32, title: 'Du week-end')]),
      'kosher': _page(items: [_outing(id: 33, title: 'Table casher')]),
      'cheap': _page(items: [_outing(id: 34, title: 'Petit prix')]),
      'mazl': _page(items: [_outing(id: 35, title: 'Chez MAZL')]),
    };

    void declare(FakeCoupleTransport t) {
      t.reply('GET /api/couple/outings', answers['']!);
      for (final key in answers.keys.where((k) => k.isNotEmpty)) {
        t.reply('GET /api/couple/outings?filter=$key', answers[key]!);
      }
    }

    testWidgets('each pill asks the server for its own filter', (tester) async {
      final rig = await _pump(tester, declare);
      expect(rig.transport.calls, ['GET /api/couple/outings']);

      const pills = {
        'Ce soir': ('tonight', 'Ce soir seulement'),
        'Ce week-end': ('week', 'Du week-end'),
        'Casher': ('kosher', 'Table casher'),
        'Moins de 50 €': ('cheap', 'Petit prix'),
        'Événements MAZL': ('mazl', 'Chez MAZL'),
      };
      for (final entry in pills.entries) {
        await tester.tap(find.text(entry.key));
        await tester.pump();
        await tester.pump();
        expect(
          rig.transport.calls.last,
          'GET /api/couple/outings?filter=${entry.value.$1}',
        );
        expect(find.text(entry.value.$2), findsOneWidget, reason: entry.key);
        expect(find.text('Cours de pâtisserie à deux'), findsNothing);
      }
    });

    testWidgets('touching the chosen pill again goes back to every outing', (
      tester,
    ) async {
      final rig = await _pump(tester, declare);
      await tester.tap(find.text('Casher'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Table casher'), findsOneWidget);

      await tester.tap(find.text('Casher'));
      await tester.pump();
      await tester.pump();

      expect(rig.transport.calls.last, 'GET /api/couple/outings');
      expect(rig.transport.calls, hasLength(3));
      expect(find.text('Table casher'), findsNothing);
      expect(find.text('Cours de pâtisserie à deux'), findsOneWidget);
    });

    testWidgets('only one pill is chosen at a time', (tester) async {
      final rig = await _pump(tester, declare);
      await tester.tap(find.text('Casher'));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Ce soir'));
      await tester.pump();
      await tester.pump();

      expect(
        rig.transport.calls.last,
        'GET /api/couple/outings?filter=tonight',
      );
      expect(find.text('Ce soir seulement'), findsOneWidget);
      expect(find.text('Table casher'), findsNothing);
    });

    testWidgets('a slow answer of an old filter does not overwrite the new '
        'one', (tester) async {
      final transport = _GatedTransport();
      transport.gates['/api/couple/outings?filter=week'] = Completer<void>();
      await _pump(tester, declare, transport: transport);

      await tester.tap(find.text('Ce week-end'));
      await tester.pump();
      await tester.tap(find.text('Casher'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Table casher'), findsOneWidget);

      // The week answer finally arrives, after the kosher one.
      transport.gates['/api/couple/outings?filter=week']!.complete();
      await tester.pump();
      await tester.pump();

      expect(find.text('Table casher'), findsOneWidget);
      expect(find.text('Du week-end'), findsNothing);
    });
  });

  group('save', () {
    final activityFeatured = _outing(
      id: 40,
      title: 'Spa et bains nordiques',
      city: 'Vincennes',
      priceCents: 9000,
    );

    testWidgets('the bookmark of the featured activity saves then removes', (
      tester,
    ) async {
      final rig = await _pump(tester, (t) {
        t.reply('GET /api/couple/outings', _page(featured: activityFeatured));
        t.reply('POST /api/couple/activities/40/save', ok({}));
        t.reply('DELETE /api/couple/saved/40', ok({}));
      });
      expect(find.text('Voir'), findsOneWidget);
      expect(_save(), findsOneWidget);

      await tester.tap(_save());
      await tester.pump();
      expect(rig.transport.calls.last, 'POST /api/couple/activities/40/save');
      await tester.pump();
      expect(_unsave(), findsOneWidget);

      await tester.tap(_unsave());
      await tester.pump();
      await tester.pump();
      expect(rig.transport.calls.last, 'DELETE /api/couple/saved/40');
      expect(_save(), findsOneWidget);
    });

    testWidgets('a failed save puts the bookmark back and says so', (
      tester,
    ) async {
      final rig = await _pump(tester, (t) {
        t.reply('GET /api/couple/outings', _page(featured: activityFeatured));
        t.fail(
          'POST /api/couple/activities/40/save',
          const SocketException('down'),
        );
      });

      await tester.tap(_save());
      await tester.pump();
      // Optimistic: the bookmark is already filled while the call is out.
      expect(rig.transport.count('POST /api/couple/activities/40/save'), 1);
      await tester.pump();
      await tester.pump();

      expect(_save(), findsOneWidget);
      expect(_unsave(), findsNothing);
      expect(
        find.text('Impossible de modifier vos sauvegardes. Réessayez.'),
        findsOneWidget,
      );
    });

    testWidgets('a failed removal keeps the activity saved', (tester) async {
      await _pump(tester, (t) {
        t.reply(
          'GET /api/couple/outings',
          _page(items: [_outing(id: 51, title: 'Déjà gardée', saved: true)]),
        );
        t.fail('DELETE /api/couple/saved/51', const SocketException('down'));
      });
      expect(_unsave(), findsOneWidget);

      await tester.tap(_unsave());
      await tester.pump();
      await tester.pump();

      expect(_unsave(), findsOneWidget);
      expect(
        find.text('Impossible de modifier vos sauvegardes. Réessayez.'),
        findsOneWidget,
      );
    });

    testWidgets('each activity tile carries a bookmark, an event does not', (
      tester,
    ) async {
      await _pump(
        tester,
        (t) => t.reply(
          'GET /api/couple/outings',
          _page(
            featured: _event,
            items: [
              _pastry,
              _outing(id: 8, kind: 'event', title: 'Brunch MAZL'),
              _jazz,
            ],
          ),
        ),
      );

      // Two activities in the grid; the featured event and the grid event
      // have none. (The header's « Sauvegardées » is another control.)
      expect(find.byType(OutingSaveButton), findsNWidgets(2));
      expect(_save(), findsNWidgets(2));
      expect(find.text('Réserver pour nous deux'), findsOneWidget);
      expect(find.text('Voir'), findsNothing);
    });

    testWidgets('saving from a tile does not open the tile', (tester) async {
      await _pump(tester, (t) {
        t.reply('GET /api/couple/outings', _page(items: [_pastry]));
        t.reply('POST /api/couple/activities/21/save', ok({}));
      });

      await tester.tap(_save());
      await tester.pump();
      await tester.pump();

      expect(find.text('page:activity:21'), findsNothing);
      expect(_unsave(), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('« Réserver pour nous deux » opens the event', (tester) async {
      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/outings', _page(featured: _event)),
      );
      await tester.tap(find.text('Réserver pour nous deux'));
      await tester.pumpAndSettle();
      expect(find.text('page:event:7'), findsOneWidget);
    });

    testWidgets('« Voir » opens the featured activity', (tester) async {
      await _pump(
        tester,
        (t) => t.reply(
          'GET /api/couple/outings',
          _page(featured: _outing(id: 40, title: 'Spa')),
        ),
      );
      await tester.tap(find.text('Voir'));
      await tester.pumpAndSettle();
      expect(find.text('page:activity:40'), findsOneWidget);
    });

    testWidgets('a tile opens its activity or its event', (tester) async {
      await _pump(
        tester,
        (t) => t.reply(
          'GET /api/couple/outings',
          _page(
            items: [
              _pastry,
              _outing(id: 8, kind: 'event', title: 'Brunch MAZL'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Brunch MAZL'));
      await tester.pumpAndSettle();
      expect(find.text('page:event:8'), findsOneWidget);
    });

    testWidgets('a tile of an activity opens /couple/activities/:id', (
      tester,
    ) async {
      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/outings', _page(items: [_pastry])),
      );
      await tester.tap(find.text('Cours de pâtisserie à deux'));
      await tester.pumpAndSettle();
      expect(find.text('page:activity:21'), findsOneWidget);
    });

    testWidgets('the bookmark of the header opens the saved list', (
      tester,
    ) async {
      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/outings', _page(items: [_pastry])),
      );
      final button = find.byWidgetPredicate(
        (w) => w is RoundIconButton && w.tooltip == 'Sauvegardées',
      );
      expect(
        tester.getSize(button).shortestSide,
        greaterThanOrEqualTo(44),
        reason: 'touch target',
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('page:saved'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('shows a spinner while the first answer is out', (
      tester,
    ) async {
      final transport = _GatedTransport();
      transport.gates['/api/couple/outings'] = Completer<void>();
      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/outings', _page(items: [_pastry])),
        transport: transport,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The title and the pills are already there.
      expect(find.text('Sorties à deux'), findsOneWidget);
      expect(find.text('Casher'), findsOneWidget);

      transport.gates['/api/couple/outings']!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Cours de pâtisserie à deux'), findsOneWidget);
    });

    testWidgets('nothing for a filter: a sentence and « Tout voir »', (
      tester,
    ) async {
      final rig = await _pump(tester, (t) {
        t.reply('GET /api/couple/outings', _page(items: [_pastry]));
        t.reply('GET /api/couple/outings?filter=tonight', _page());
      });
      await tester.tap(find.text('Ce soir'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Rien pour ce filtre'), findsOneWidget);
      expect(find.text('Cours de pâtisserie à deux'), findsNothing);

      await tester.tap(find.text('Tout voir'));
      await tester.pump();
      await tester.pump();
      expect(rig.transport.calls.last, 'GET /api/couple/outings');
      expect(find.text('Rien pour ce filtre'), findsNothing);
      expect(find.text('Cours de pâtisserie à deux'), findsOneWidget);
    });

    testWidgets('nothing at all: a calm empty state, no error', (tester) async {
      await _pump(tester, (t) => t.reply('GET /api/couple/outings', _page()));
      expect(find.text('Pas de sortie pour le moment'), findsOneWidget);
      expect(find.text('Chargement impossible'), findsNothing);
      expect(find.text('Tout voir'), findsNothing);
    });

    testWidgets('a route the server does not have is an empty page, not an '
        'error', (tester) async {
      await _pump(
        tester,
        // What decodeCoupleBody makes of a 404 without JSON.
        (t) => t.reply('GET /api/couple/outings', {
          'success': false,
          'error': 'not_found',
        }),
      );
      expect(find.text('Chargement impossible'), findsNothing);
      expect(find.text('Pas de sortie pour le moment'), findsOneWidget);
    });

    testWidgets('a failing load shows an error and retries', (tester) async {
      final rig = await _pump(
        tester,
        (t) => t.fail('GET /api/couple/outings', const SocketException('down')),
      );
      expect(find.text('Chargement impossible'), findsOneWidget);
      expect(find.text('Cours de pâtisserie à deux'), findsNothing);

      rig.transport.reply('GET /api/couple/outings', _page(items: [_pastry]));
      await tester.tap(find.text('Réessayer'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Chargement impossible'), findsNothing);
      expect(find.text('Cours de pâtisserie à deux'), findsOneWidget);
      expect(rig.transport.count('GET /api/couple/outings'), 2);
    });

    testWidgets('pulling to refresh asks again and keeps the screen if it '
        'fails', (tester) async {
      final rig = await _pump(
        tester,
        (t) => t.reply('GET /api/couple/outings', _page(items: [_pastry])),
      );
      rig.transport.fail(
        'GET /api/couple/outings',
        const SocketException('down'),
      );
      // A slow finger pull, as the star asks for (StarRefresh).
      final gesture = await tester.startGesture(
        tester.getTopLeft(find.byType(ListView).first) + const Offset(20, 40),
      );
      for (var done = 0; done < 300; done += 10) {
        await gesture.moveBy(const Offset(0, 10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(rig.transport.count('GET /api/couple/outings'), 2);
      expect(find.text('Cours de pâtisserie à deux'), findsOneWidget);
      expect(find.text('Chargement impossible'), findsNothing);
    });
  });

  group('iPhone Duo', () {
    Future<DuoPoseController> pose(
      WidgetTester tester,
      DuoPose p,
      _Rig rig,
    ) async {
      setDuoPose(tester, p);
      final controller = DuoPoseController(p);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          builder: duoAppBuilder(controller),
          home: ContentMaxWidth(child: rig.screen()),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await settleFold(tester);
      return controller;
    }

    _Rig rig() {
      final t = FakeCoupleTransport()
        ..reply(
          'GET /api/couple/outings',
          _page(
            featured: _event,
            items: [
              _pastry,
              _brunch,
              _jazz,
              _outing(id: 24, title: 'Spa'),
            ],
          ),
        )
        ..reply(
          'GET /api/couple/outings?filter=kosher',
          _page(items: [_outing(id: 33, title: 'Table casher')]),
        );
      return _Rig(t);
    }

    testWidgets('book: the featured outing on the first page, the ideas on '
        'the other, nothing in the curve', (tester) async {
      await pose(tester, DuoPose.halfOpenBook, rig());
      final fold = DuoPose.halfOpenBook.fold!;

      final featured = tester.getRect(
        find.text('Dîner de Shabbat entre couples'),
      );
      expect(featured.right, lessThanOrEqualTo(fold.left + 0.5));
      final tile = tester.getRect(find.text('Cours de pâtisserie à deux'));
      expect(tile.left, greaterThanOrEqualTo(fold.right - 0.5));
      final book = tester.getRect(find.text('Réserver pour nous deux'));
      expect(book.right, lessThanOrEqualTo(fold.left + 0.5));
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
      expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'outings');
    });

    testWidgets('laptop: the title and the pills above the fold, the rest '
        'below, nothing in the fold', (tester) async {
      await pose(tester, DuoPose.halfOpenLaptop, rig());
      final fold = DuoPose.halfOpenLaptop.fold!;

      expect(
        tester.getRect(find.text('Sorties à deux')).bottom,
        lessThanOrEqualTo(fold.top + 0.5),
      );
      expect(
        tester.getRect(find.text('Casher')).bottom,
        lessThanOrEqualTo(fold.top + 0.5),
      );
      expect(
        tester.getRect(find.text('Dîner de Shabbat entre couples')).top,
        greaterThanOrEqualTo(fold.bottom - 0.5),
      );
      expect(foldCrossingProblems(tester, DuoPose.halfOpenLaptop), isEmpty);
      expectFitsDuoPose(tester, DuoPose.halfOpenLaptop, 'outings');
    });

    testWidgets('the chosen pill survives folding and unfolding', (
      tester,
    ) async {
      final controller = await pose(tester, DuoPose.openPortrait, rig());
      await tester.tap(find.text('Casher'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Table casher'), findsOneWidget);

      for (final next in [
        DuoPose.halfOpenBook,
        DuoPose.halfOpenLaptop,
        DuoPose.closed,
      ]) {
        await controller.moveTo(tester, next);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Table casher'), findsOneWidget, reason: '$next');
        expect(find.text('Cours de pâtisserie à deux'), findsNothing);
      }
    });

    for (final p in DuoPose.values) {
      testWidgets('${p.name}: fits, nothing crosses the fold', (tester) async {
        // Two ideas: the whole page is in view, so every control is measured.
        final t = FakeCoupleTransport()
          ..reply(
            'GET /api/couple/outings',
            _page(featured: _event, items: [_pastry, _jazz]),
          );
        await pose(tester, p, _Rig(t));
        expect(foldCrossingProblems(tester, p), isEmpty);
        expectFitsDuoPose(tester, p, 'outings');
      });
    }
  });
}
