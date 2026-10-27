import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mazl/core/services/couple_daily_api.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/couple/screens/couple_concierge_screen.dart';
import 'package:mazl/presentation/features/couple/screens/couple_concierge_thread_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../duo/duo_geometry.dart';
import 'couple_flow_fakes.dart';

// The concierge of the couple (docs/couple/ESPACE-COUPLE.md §0.2, §0.4, §0.5,
// §7). The JSON below is written from the contract tables, not from the
// decoders. The member is user 12; the partner is Myriam.

const _list = 'GET /api/couple/concierge';
const _create = 'POST /api/couple/concierge';
const _thread1 = 'GET /api/couple/concierge/1';
const _messages1 = 'POST /api/couple/concierge/1/messages';
const _choose1 = 'POST /api/couple/concierge/1/choose';
const _cancel1 = 'POST /api/couple/concierge/1/cancel';

AppLocalizations get _l10n => lookupAppLocalizations(const Locale('fr'));

Map<String, dynamic> _idea(int n, {String price = 'environ 120 € pour deux'}) =>
    {'title': 'Idée $n', 'details': 'Détail de l\'idée $n', 'priceHint': price};

Map<String, dynamic> _request({
  int id = 1,
  String title = 'Dîner surprise pour vos un an',
  String status = 'proposed',
  List<Map<String, dynamic>>? options,
  int? chosenIndex,
  String? wantedAt = '2099-11-09',
}) => {
  'id': id,
  'title': title,
  'brief': 'Un dîner calme et casher',
  'wantedAt': wantedAt,
  'city': 'Paris',
  'constraints': {'kosher': true},
  'status': status,
  'options': options ?? [_idea(1), _idea(2), _idea(3)],
  'chosenIndex': chosenIndex,
  'staffNote': null,
  'updatedAt': '2026-10-27T09:00:00.000Z',
};

Map<String, dynamic> _message(
  int id,
  String role,
  String text, {
  int? authorId,
}) => {
  'id': id,
  'role': role,
  'authorId': role == 'member' ? (authorId ?? 12) : null,
  'text': text,
  'createdAt': '2026-10-27T09:00:00.000Z',
};

Map<String, dynamic> _thread(
  Map<String, dynamic> request, [
  List<Map<String, dynamic>>? messages,
]) => ok({
  'data': {
    'request': request,
    'messages':
        messages ??
        [
          _message(1, 'member', 'On aimerait un dîner calme et casher.'),
          _message(2, 'member', 'Moi aussi, vers 20 h.', authorId: 45),
          _message(3, 'assistant', 'Voici trois idées. Choisissez-en une.'),
        ],
  },
});

Map<String, dynamic> _summary({
  int id = 1,
  String title = 'Dîner surprise pour vos un an',
  String status = 'proposed',
  int step = 1,
  String? wantedAt = '2099-11-09',
}) => {
  'id': id,
  'title': title,
  'status': status,
  'wantedAt': wantedAt,
  'updatedAt': '2026-10-27T09:00:00.000Z',
  'step': step,
};

Map<String, dynamic> _listBody(List<Map<String, dynamic>> requests) => ok({
  'data': {'requests': requests},
});

/// A transport whose message route waits for [gate] before answering, to look
/// at the screen while a message is on its way.
class _GatedTransport extends FakeCoupleTransport {
  Completer<void>? gate;

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final wait = gate;
    if (wait != null && path.endsWith('/messages')) await wait.future;
    return super.post(path, body);
  }
}

Future<CoupleService> _service(
  WidgetTester tester, {
  required bool active,
}) async {
  SharedPreferences.setMockInitialValues({});
  final api = FakeCoupleApi()
    ..couple = contractCouple()
    ..premium = {
      'active': active,
      'paidBy': active ? 'me' : null,
      'renewsAt': null,
    };
  final service = CoupleService.forTesting(api: api);
  await tester.runAsync(service.refresh);
  addTearDown(service.dispose);
  return service;
}

CoupleDailyApi _api(FakeCoupleTransport transport) =>
    CoupleDailyApi(transport: transport, callerId: () => 12);

/// The list answers with [requests]; the thread of request 1 with [thread].
FakeCoupleTransport _server({
  List<Map<String, dynamic>>? requests,
  Map<String, dynamic>? thread,
  FakeCoupleTransport? transport,
}) {
  final t = transport ?? FakeCoupleTransport();
  t.reply(_list, _listBody(requests ?? [_summary()]));
  t.reply(_thread1, thread ?? _thread(_request()));
  return t;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await settleFold(tester);
}

Future<DuoPoseController> _pump(
  WidgetTester tester,
  FakeCoupleTransport transport,
  CoupleService service, {
  DuoPose pose = DuoPose.halfOpenBook,
  Locale locale = const Locale('fr'),
  Widget? screen,
  bool router = false,
  double? height,
}) async {
  setDuoPose(tester, pose);
  if (height != null) {
    tester.view.physicalSize = Size(pose.size.width, height) * 3;
  }
  final controller = DuoPoseController(pose);
  final home =
      screen ?? CoupleConciergeScreen(api: _api(transport), couple: service);
  Widget app;
  if (router) {
    final goRouter = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(
          path: '/couple/premium',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: const Text('PAGE ABONNEMENT'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/couple/concierge/:requestId',
          builder: (context, state) => ConciergeThreadScreen(
            requestId: int.parse(state.pathParameters['requestId']!),
            api: _api(transport),
            couple: service,
          ),
        ),
      ],
    );
    addTearDown(goRouter.dispose);
    app = MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: duoAppBuilder(controller),
      routerConfig: goRouter,
    );
  } else {
    app = MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: duoAppBuilder(controller),
      home: home,
    );
  }
  await tester.pumpWidget(app);
  await _settle(tester);
  return controller;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first);
  await _settle(tester);
}

bool _enabled(WidgetTester tester, Finder button) {
  final widget = tester.widget(button);
  return switch (widget) {
    FilledButton(:final onPressed) => onPressed != null,
    OutlinedButton(:final onPressed) => onPressed != null,
    _ => throw StateError('not a button: $widget'),
  };
}

Finder get _field => find.byType(TextField);
Finder get _send => find.byKey(const ValueKey('concierge-send'));

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_field, text);
  await tester.pump();
}

/// Every body the screen sent, keys only: the contract allows text, wantedAt,
/// city and kind and nothing that names the member (§0.4).
void _expectNothingPersonal(FakeCoupleTransport t) {
  const allowed = {'text', 'wantedAt', 'city', 'kind', 'index'};
  for (final entry in t.bodies.entries) {
    if (!entry.key.startsWith('POST')) continue;
    expect(
      entry.value.keys.toSet().difference(allowed),
      isEmpty,
      reason: '${entry.key} sent ${entry.value}',
    );
    final json = entry.value.toString().toLowerCase();
    for (final secret in ['léa', 'myriam', '@', 'phone', 'email', 'name']) {
      expect(json.contains(secret), isFalse, reason: '${entry.key}: $json');
    }
  }
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('fr');
  });

  group('without MAZL Couple', () {
    testWidgets('the subscription call replaces the list and the field', (
      tester,
    ) async {
      final transport = FakeCoupleTransport();
      final service = await _service(tester, active: false);
      await _pump(tester, transport, service, pose: DuoPose.openPortrait);

      expect(find.text('INCLUS DANS MAZL COUPLE'), findsOneWidget);
      expect(find.text(_l10n.coupleConciergeTitle), findsOneWidget);
      expect(find.text(_l10n.coupleConciergeQuickTable), findsOneWidget);
      expect(find.text(_l10n.coupleConciergeDiscover), findsOneWidget);
      expect(_field, findsNothing);
      expect(
        find.text(_l10n.coupleConciergeInProgress.toUpperCase()),
        findsNothing,
      );
      expect(transport.calls, isEmpty, reason: 'no request at all');
    });

    testWidgets('a 402 on the list shows the same call, nothing is created', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply(_list, error('couple_subscription_required'));
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service, pose: DuoPose.openPortrait);

      expect(find.text('INCLUS DANS MAZL COUPLE'), findsOneWidget);
      expect(find.text(_l10n.coupleConciergeDiscover), findsOneWidget);
      expect(_field, findsNothing);
      expect(transport.count(_create), 0);
      expect(transport.calls.where((c) => c.startsWith('POST')), isEmpty);
    });

    testWidgets('the button opens MAZL Couple, and coming back with the '
        'subscription reads the requests', (tester) async {
      final transport = _server();
      SharedPreferences.setMockInitialValues({});
      final fake = FakeCoupleApi()
        ..couple = contractCouple()
        ..premium = {'active': false, 'paidBy': null, 'renewsAt': null};
      final service = CoupleService.forTesting(api: fake);
      addTearDown(service.dispose);
      await tester.runAsync(service.refresh);
      await _pump(
        tester,
        transport,
        service,
        pose: DuoPose.openPortrait,
        router: true,
      );
      expect(transport.calls, isEmpty);

      await _tap(tester, find.text(_l10n.coupleConciergeDiscover));
      expect(find.text('PAGE ABONNEMENT'), findsOneWidget);

      // The couple subscribes on that page.
      fake.premium = {'active': true, 'paidBy': 'me', 'renewsAt': null};
      await tester.tap(find.text('PAGE ABONNEMENT'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await _settle(tester);
      await _settle(tester);

      expect(transport.count(_list), 1);
      expect(find.text('Dîner surprise pour vos un an'), findsOneWidget);
      expect(find.text(_l10n.coupleConciergeDiscover), findsNothing);
    });
  });

  group('the list', () {
    testWidgets('one card per request, the steps follow `step`, closed ones '
        'go below', (tester) async {
      final handle = tester.ensureSemantics();
      final transport = _server(
        requests: [
          _summary(id: 1, title: 'Reçue', step: 1),
          _summary(id: 2, title: 'Choisie', status: 'chosen', step: 2),
          _summary(id: 3, title: 'Réservée', status: 'booked', step: 3),
          _summary(id: 4, title: 'Passée', status: 'closed', step: 3),
          _summary(id: 5, title: 'Abandonnée', status: 'cancelled', step: 1),
        ],
      );
      final service = await _service(tester, active: true);
      await _pump(
        tester,
        transport,
        service,
        pose: DuoPose.openPortrait,
        height: 2400,
      );

      for (final title in ['Reçue', 'Choisie', 'Réservée']) {
        expect(find.text(title), findsOneWidget);
      }
      expect(
        find.bySemanticsLabel('étape 1 sur 3 : Demande reçue'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('étape 2 sur 3 : Idée choisie'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('étape 3 sur 3 : Réservé par l\'équipe'),
        findsOneWidget,
      );
      // 1 -> one segment filled, 2 -> two, 3 -> three (closed ones draw none).
      expect(
        find.byKey(const ValueKey('concierge-step-1-on')),
        findsNWidgets(3),
      );
      expect(
        find.byKey(const ValueKey('concierge-step-2-on')),
        findsNWidgets(2),
      );
      expect(find.byKey(const ValueKey('concierge-step-3-on')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('concierge-step-3-off')),
        findsNWidgets(2),
      );
      // The closed and cancelled requests are in words, under their own label.
      expect(find.text(_l10n.coupleConciergeStatusClosed), findsOneWidget);
      expect(find.text(_l10n.coupleConciergeStatusCancelled), findsOneWidget);
      expect(
        find.text(_l10n.coupleConciergeClosedSection.toUpperCase()),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the deadline: « Avant <jour> » this week, a date later', (
      tester,
    ) async {
      final soon = DateTime.now().add(const Duration(days: 3));
      final transport = _server(
        requests: [
          _summary(
            id: 1,
            title: 'Bientôt',
            wantedAt: DateFormat('yyyy-MM-dd').format(soon),
          ),
          _summary(id: 2, title: 'Loin', wantedAt: '2099-11-09'),
        ],
      );
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service, pose: DuoPose.openPortrait);

      await tester.ensureVisible(find.text('Bientôt'));
      expect(
        find.text('Avant ${DateFormat.EEEE('fr').format(soon)}'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Loin'));
      expect(find.text('Pour le 9 novembre'), findsOneWidget);
    });

    testWidgets('no request: a sentence, the quick asks and the field stay', (
      tester,
    ) async {
      final transport = _server(requests: []);
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service, pose: DuoPose.openPortrait);

      expect(find.text(_l10n.coupleConciergeNoRequests), findsOneWidget);
      expect(find.text(_l10n.coupleConciergeQuickGift), findsOneWidget);
      expect(_field, findsOneWidget);
    });

    testWidgets('a route the server does not have is an empty list, not an '
        'error', (tester) async {
      final transport = FakeCoupleTransport()..reply(_list, error('not_found'));
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service, pose: DuoPose.openPortrait);

      expect(find.text(_l10n.coupleConciergeNoRequests), findsOneWidget);
      expect(find.text(_l10n.commonRetry), findsNothing);
    });

    testWidgets('a failing read shows an error with a retry that works', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..fail(_list, const SocketException('down'));
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service, pose: DuoPose.openPortrait);

      expect(find.text(_l10n.errorNetwork), findsOneWidget);
      transport.reply(_list, _listBody([_summary()]));
      await _tap(tester, find.text(_l10n.commonRetry));

      expect(find.text('Dîner surprise pour vos un an'), findsOneWidget);
      expect(transport.count(_list), 2);
    });

    testWidgets('the privacy mention is on screen, word for word', (
      tester,
    ) async {
      const mention =
          'Vos demandes sont lues par un assistant automatique puis par '
          'l\'équipe MAZL.';
      for (final pose in [DuoPose.openPortrait, DuoPose.halfOpenBook]) {
        final service = await _service(tester, active: true);
        await _pump(tester, _server(), service, pose: pose);
        expect(find.text(mention), findsOneWidget, reason: pose.name);
        final rect = tester.getRect(find.text(mention));
        expect(
          rect.bottom,
          lessThanOrEqualTo(pose.safeRect.bottom),
          reason: '${pose.name}: under the system bar',
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });

  group('opening a request', () {
    testWidgets('a single column opens the conversation as a page', (
      tester,
    ) async {
      final transport = _server();
      final service = await _service(tester, active: true);
      await _pump(
        tester,
        transport,
        service,
        pose: DuoPose.openPortrait,
        router: true,
      );
      expect(transport.count(_thread1), 0);

      await _tap(tester, find.text('Dîner surprise pour vos un an'));

      expect(transport.count(_thread1), 1);
      expect(
        find.text('On aimerait un dîner calme et casher.'),
        findsOneWidget,
      );
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('the book shows it on the page at the right, opened for the '
        'first open request', (tester) async {
      final transport = _server();
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service);

      expect(transport.count(_thread1), 1);
      final fold = DuoPose.halfOpenBook.fold!;
      expect(
        tester.getRect(find.text(_l10n.coupleConciergeTitle)).right,
        lessThanOrEqualTo(fold.left),
      );
      expect(
        tester.getRect(find.text('On aimerait un dîner calme et casher.')).left,
        greaterThanOrEqualTo(fold.right),
      );
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
      expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'concierge');
    });
  });

  group('the conversation', () {
    testWidgets('mine on the end side in the accent, the other member under '
        'their first name, the assistant and the team under their eyebrow', (
      tester,
    ) async {
      final transport = _server(
        thread: _thread(_request(status: 'new', options: []), [
          _message(1, 'member', 'Mon message.'),
          _message(2, 'member', 'Le message de Myriam.', authorId: 45),
          _message(3, 'assistant', 'Une réponse de l\'assistant.'),
          _message(4, 'staff', 'On vous répond demain.'),
        ]),
      );
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service);

      expect(find.text('MYRIAM'), findsOneWidget);
      expect(find.text('ASSISTANT'), findsOneWidget);
      expect(find.text('ÉQUIPE MAZL'), findsOneWidget);
      expect(find.text('On vous répond demain.'), findsOneWidget);
      // « l'équipe vous répond »: no error, no idea to choose from.
      expect(find.text(_l10n.coupleConciergeNoteFresh), findsOneWidget);
      expect(find.byKey(const ValueKey('concierge-book')), findsNothing);

      final mine = tester.getRect(find.text('Mon message.'));
      final theirs = tester.getRect(find.text('Le message de Myriam.'));
      expect(mine.right, greaterThan(theirs.right));
      expect(mine.left, greaterThan(theirs.left));
      // Mine is white on the accent, the others on a surface.
      final accent = Theme.of(
        tester.element(find.text('Mon message.')),
      ).colorScheme;
      final bubble = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('Mon message.'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((bubble.decoration as BoxDecoration).color, accent.primary);
      final text = tester.widget<Text>(find.text('Mon message.'));
      expect(text.style?.color, accent.onPrimary);
    });

    testWidgets('choosing an idea: « Oui, réservez » waits for a tick, then '
        'POSTs the index and marks the idea « Choisie »', (tester) async {
      final transport = _server();
      transport.reply(
        _choose1,
        _thread(_request(status: 'chosen', chosenIndex: 1), [
          _message(1, 'member', 'On aimerait un dîner calme et casher.'),
          _message(5, 'staff', 'On a bien reçu votre choix.'),
        ]),
      );
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service);

      const book = ValueKey('concierge-book');
      expect(_enabled(tester, find.byKey(book)), isFalse);
      expect(find.text('environ 120 € pour deux'), findsNWidgets(3));

      await _tap(tester, find.byKey(const ValueKey('concierge-option-1')));
      expect(_enabled(tester, find.byKey(book)), isTrue);
      expect(transport.count(_choose1), 0, reason: 'ticking only ticks');

      await _tap(tester, find.byKey(book));

      expect(transport.count(_choose1), 1);
      expect(transport.bodies[_choose1], {'index': 1});
      expect(find.text(_l10n.coupleConciergeChosen), findsOneWidget);
      expect(find.byKey(const ValueKey('concierge-retained')), findsOneWidget);
      expect(find.text('Idée 2'), findsOneWidget);
      expect(find.text('Idée 1'), findsNothing);
      expect(find.byKey(book), findsNothing);
      expect(find.byKey(const ValueKey('concierge-other-idea')), findsNothing);
      expect(find.text('On a bien reçu votre choix.'), findsOneWidget);
      expect(find.text(_l10n.coupleConciergeNoteChosen), findsOneWidget);
      _expectNothingPersonal(transport);
    });

    testWidgets('a refused choice leaves the idea ticked and says so', (
      tester,
    ) async {
      final transport = _server()
        ..fail(_choose1, const SocketException('down'));
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service);

      await _tap(tester, find.byKey(const ValueKey('concierge-option-2')));
      await _tap(tester, find.byKey(const ValueKey('concierge-book')));

      expect(find.text(_l10n.errorNetwork), findsOneWidget);
      expect(
        _enabled(tester, find.byKey(const ValueKey('concierge-book'))),
        isTrue,
      );
      expect(find.text(_l10n.coupleConciergeChosen), findsNothing);
    });

    testWidgets('« Autre idée » asks the assistant for another one', (
      tester,
    ) async {
      final transport = _server()
        ..reply(
          _messages1,
          _thread(_request(options: [_idea(4)]), [
            _message(1, 'member', 'Pouvez-vous me proposer une autre idée ?'),
            _message(6, 'assistant', 'En voici une autre.'),
          ]),
        );
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service);

      await _tap(tester, find.byKey(const ValueKey('concierge-other-idea')));

      expect(transport.bodies[_messages1], {
        'text': 'Pouvez-vous me proposer une autre idée ?',
      });
      expect(find.text('En voici une autre.'), findsOneWidget);
      expect(find.text('Idée 4'), findsOneWidget);
    });

    testWidgets('sending: the message shows at once, the field empties, '
        'sending is off and « … » shows until the answer', (tester) async {
      final transport = _GatedTransport()..gate = Completer<void>();
      _server(transport: transport);
      transport.reply(
        _messages1,
        _thread(_request(), [
          _message(1, 'member', 'On aimerait un dîner calme et casher.'),
          _message(7, 'member', 'Plutôt végétarien.'),
          _message(8, 'assistant', 'Bien noté.'),
        ]),
      );
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service);

      await _type(tester, 'Plutôt végétarien.');
      await tester.tap(_send);
      await tester.pump();

      expect(find.text('Plutôt végétarien.'), findsOneWidget);
      expect(tester.widget<TextField>(_field).controller!.text, isEmpty);
      expect(find.text('…'), findsOneWidget);
      // A second message cannot leave while the first is on its way.
      await _type(tester, 'Un autre.');
      await tester.tap(_send);
      await tester.pump();
      expect(transport.count(_messages1), 0, reason: 'still held at the gate');

      transport.gate!.complete();
      await _settle(tester);

      expect(transport.count(_messages1), 1);
      expect(transport.bodies[_messages1], {'text': 'Plutôt végétarien.'});
      expect(find.text('Plutôt végétarien.'), findsOneWidget);
      expect(find.text('Bien noté.'), findsOneWidget);
      expect(find.text('…'), findsNothing);
      _expectNothingPersonal(transport);
    });

    testWidgets('a failed send takes the message back into the field', (
      tester,
    ) async {
      final transport = _server()
        ..fail(_messages1, const SocketException('down'));
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service);

      await _type(tester, 'Plutôt végétarien.');
      await tester.tap(_send);
      await _settle(tester);

      expect(transport.count(_messages1), 1);
      expect(
        tester.widget<TextField>(_field).controller!.text,
        'Plutôt végétarien.',
      );
      // Only the field holds it again: no bubble is left behind.
      expect(find.text('Plutôt végétarien.'), findsOneWidget);
      expect(find.text(_l10n.errorNetwork), findsOneWidget);
      expect(find.text('…'), findsNothing);
    });

    testWidgets('the daily limit (429) is said in French and the field keeps '
        'the text', (tester) async {
      final transport = _server()
        ..reply(_messages1, error('concierge_rate_limited'));
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service);

      await _type(tester, 'Encore une idée ?');
      await tester.tap(_send);
      await _settle(tester);

      expect(find.text(_l10n.coupleFailRateLimited), findsOneWidget);
      expect(
        tester.widget<TextField>(_field).controller!.text,
        'Encore une idée ?',
      );
      expect(find.text('Encore une idée ?'), findsOneWidget);
    });

    testWidgets('cancelling asks first, then POSTs, and closes the field', (
      tester,
    ) async {
      final transport = _server()
        ..reply(
          _cancel1,
          _thread(_request(status: 'cancelled', options: []), [
            _message(1, 'member', 'On aimerait un dîner calme et casher.'),
          ]),
        );
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service);

      await _tap(tester, find.byKey(const ValueKey('concierge-cancel')));
      expect(find.text(_l10n.coupleConciergeCancelTitle), findsOneWidget);
      expect(
        transport.count(_cancel1),
        0,
        reason: 'a confirmation comes first',
      );

      // Keeping the request changes nothing.
      await _tap(tester, find.text(_l10n.coupleConciergeKeep));
      expect(transport.count(_cancel1), 0);

      await _tap(tester, find.byKey(const ValueKey('concierge-cancel')));
      await _tap(
        tester,
        find.byKey(const ValueKey('concierge-cancel-confirm')),
      );

      expect(transport.count(_cancel1), 1);
      expect(find.text(_l10n.coupleConciergeNoteCancelled), findsOneWidget);
      expect(_field, findsNothing);
      // The mention is still there once the field is gone.
      expect(find.text(_l10n.coupleConciergePrivacy), findsOneWidget);
    });

    testWidgets('the open conversation is read again every 15 s, and not '
        'after the screen is gone', (tester) async {
      final transport = _server();
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service);
      expect(transport.count(_thread1), 1);

      transport.reply(
        _thread1,
        _thread(_request(), [
          _message(1, 'member', 'On aimerait un dîner calme et casher.'),
          _message(9, 'staff', 'Une table est possible à 20 h.'),
        ]),
      );
      await tester.pump(const Duration(seconds: 16));
      await tester.pump();

      expect(transport.count(_thread1), 2);
      expect(find.text('Une table est possible à 20 h.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      final before = transport.count(_thread1);
      await tester.pump(const Duration(seconds: 60));
      expect(transport.count(_thread1), before);
    });
  });

  group('creating a request', () {
    testWidgets('a quick ask prepares the field, and sending creates the '
        'request with its kind', (tester) async {
      final transport = _server(requests: []);
      transport.reply(
        _create,
        _thread(_request(id: 1), [
          _message(
            1,
            'member',
            'Je voudrais réserver une table pour deux ce soir',
          ),
          _message(2, 'assistant', 'Voici trois idées.'),
        ]),
      );
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service);
      expect(find.text(_l10n.coupleConciergeNewLine), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('concierge-quick-table')));

      final controller = tester.widget<TextField>(_field).controller!;
      expect(controller.text, 'Je voudrais réserver une table pour deux ');
      expect(tester.widget<TextField>(_field).focusNode!.hasFocus, isTrue);
      expect(transport.count(_create), 0, reason: 'a quick ask only prepares');

      await _type(tester, 'Je voudrais réserver une table pour deux ce soir');
      transport.reply(
        _list,
        _listBody([_summary(id: 1, title: 'Une table pour deux')]),
      );
      await tester.tap(_send);
      await _settle(tester);

      expect(transport.count(_create), 1);
      expect(transport.bodies[_create], {
        'text': 'Je voudrais réserver une table pour deux ce soir',
        'kind': 'table',
      });
      _expectNothingPersonal(transport);
      // The request is open on the second page and in the list.
      expect(find.text('Voici trois idées.'), findsOneWidget);
      expect(find.text('Une table pour deux'), findsWidgets);
      expect(transport.count(_list), 2);
    });

    testWidgets('each quick ask sends its own kind', (tester) async {
      for (final (kind, key) in [
        ('surprise', 'concierge-quick-surprise'),
        ('gift', 'concierge-quick-gift'),
        ('weekend', 'concierge-quick-weekend'),
      ]) {
        final transport = _server(requests: []);
        transport.reply(_create, _thread(_request(id: 1)));
        final service = await _service(tester, active: true);
        await _pump(tester, transport, service);

        await _tap(tester, find.byKey(ValueKey(key)));
        await _type(tester, 'Pour Myriam');
        await tester.tap(_send);
        await _settle(tester);

        expect(transport.bodies[_create]?['kind'], kind);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('a single column opens the new request as a page', (
      tester,
    ) async {
      final transport = _server(requests: []);
      transport.reply(_create, _thread(_request(id: 1)));
      final service = await _service(tester, active: true);
      await _pump(
        tester,
        transport,
        service,
        pose: DuoPose.openPortrait,
        router: true,
      );

      await _type(tester, 'Une surprise pour nos un an');
      await tester.tap(_send);
      await _settle(tester);

      expect(transport.bodies[_create], {
        'text': 'Une surprise pour nos un an',
      });
      expect(find.byType(BackButton), findsOneWidget);
      expect(
        find.text('Voici trois idées. Choisissez-en une.'),
        findsOneWidget,
      );
    });
  });

  group('the page of one request', () {
    testWidgets('loads the thread, has a way back, and answers like the '
        'book page', (tester) async {
      final transport = _server();
      transport.reply(
        _messages1,
        _thread(_request(), [_message(1, 'member', 'Plutôt végétarien.')]),
      );
      final service = await _service(tester, active: true);
      await _pump(
        tester,
        transport,
        service,
        pose: DuoPose.closed,
        screen: ConciergeThreadScreen(
          requestId: 1,
          api: _api(transport),
          couple: service,
        ),
      );

      expect(transport.count(_thread1), 1);
      expect(find.text('Dîner surprise pour vos un an'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text(_l10n.coupleConciergePrivacy), findsOneWidget);

      await _type(tester, 'Plutôt végétarien.');
      await tester.tap(_send);
      await _settle(tester);
      expect(transport.bodies[_messages1], {'text': 'Plutôt végétarien.'});
      expectFitsDuoPose(tester, DuoPose.closed, 'concierge thread');
    });

    testWidgets('a thread that cannot be read shows an error with a retry', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..fail(_thread1, const SocketException('down'));
      final service = await _service(tester, active: true);
      await _pump(
        tester,
        transport,
        service,
        pose: DuoPose.openPortrait,
        screen: ConciergeThreadScreen(
          requestId: 1,
          api: _api(transport),
          couple: service,
        ),
      );
      expect(find.text(_l10n.errorNetwork), findsOneWidget);

      transport.reply(_thread1, _thread(_request()));
      await _tap(tester, find.text(_l10n.commonRetry));
      expect(find.text('Idée 1'), findsOneWidget);
    });
  });

  group('the page of one request on the foldable iPhone', () {
    testWidgets('book: the ideas and the buttons on one page, the bubbles and '
        'the field on the other', (tester) async {
      final transport = _server();
      final service = await _service(tester, active: true);
      await _pump(
        tester,
        transport,
        service,
        screen: ConciergeThreadScreen(
          requestId: 1,
          api: _api(transport),
          couple: service,
        ),
      );

      final fold = DuoPose.halfOpenBook.fold!;
      expect(
        tester.getRect(find.text('Idée 1')).right,
        lessThanOrEqualTo(fold.left),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('concierge-book'))).right,
        lessThanOrEqualTo(fold.left),
      );
      expect(
        tester.getRect(find.text('Voici trois idées. Choisissez-en une.')).left,
        greaterThanOrEqualTo(fold.right),
      );
      expect(tester.getRect(_field).left, greaterThanOrEqualTo(fold.right));
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
      expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'concierge thread');
    });

    testWidgets('the idea ticked survives moving from the book to the '
        'laptop and to one column', (tester) async {
      final transport = _server();
      final service = await _service(tester, active: true);
      final controller = await _pump(
        tester,
        transport,
        service,
        screen: ConciergeThreadScreen(
          requestId: 1,
          api: _api(transport),
          couple: service,
        ),
      );
      await _tap(tester, find.byKey(const ValueKey('concierge-option-0')));

      for (final pose in [
        DuoPose.halfOpenLaptop,
        DuoPose.openPortrait,
        DuoPose.halfOpenBook,
      ]) {
        await controller.moveTo(tester, pose);
        await _settle(tester);
        expect(
          _enabled(tester, find.byKey(const ValueKey('concierge-book'))),
          isTrue,
          reason: pose.name,
        );
      }
      expect(transport.count(_thread1), 1, reason: 'no new read when folding');
    });
  });

  group('on the foldable iPhone', () {
    testWidgets('laptop: the title above the fold, the conversation and the '
        'field below, nothing in the fold', (tester) async {
      final transport = _server();
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service, pose: DuoPose.halfOpenLaptop);

      final fold = DuoPose.halfOpenLaptop.fold!;
      expect(
        tester.getRect(find.text(_l10n.coupleConciergeTitle)).bottom,
        lessThanOrEqualTo(fold.top),
      );
      expect(tester.getRect(_field).top, greaterThanOrEqualTo(fold.bottom));
      expect(
        tester.getRect(find.text(_l10n.coupleConciergePrivacy)).top,
        greaterThanOrEqualTo(fold.bottom),
      );
      expect(foldCrossingProblems(tester, DuoPose.halfOpenLaptop), isEmpty);
      expectFitsDuoPose(tester, DuoPose.halfOpenLaptop, 'concierge');
    });

    testWidgets('the ticked idea and the draft survive folding and '
        'unfolding', (tester) async {
      final transport = _server();
      final service = await _service(tester, active: true);
      final controller = await _pump(tester, transport, service);

      await _tap(tester, find.byKey(const ValueKey('concierge-option-2')));
      await _type(tester, 'Plutôt végétarien');
      expect(
        _enabled(tester, find.byKey(const ValueKey('concierge-book'))),
        isTrue,
      );

      for (final pose in [
        DuoPose.halfOpenLaptop,
        DuoPose.openPortrait,
        DuoPose.halfOpenBook,
      ]) {
        await controller.moveTo(tester, pose);
        await _settle(tester);
        if (pose == DuoPose.openPortrait) {
          // One column: the conversation is not there, the field starts a new
          // request. Nothing is lost on the way back.
          expect(find.byKey(const ValueKey('concierge-book')), findsNothing);
          continue;
        }
        expect(
          _enabled(tester, find.byKey(const ValueKey('concierge-book'))),
          isTrue,
          reason: '${pose.name}: the idea ticked is still ticked',
        );
        expect(
          tester.widget<TextField>(_field).controller!.text,
          'Plutôt végétarien',
          reason: '${pose.name}: the draft is still there',
        );
      }
      expect(transport.count(_thread1), greaterThanOrEqualTo(1));
    });

    testWidgets('in Hebrew the list is the page at the right, the '
        'conversation the page at the left', (tester) async {
      final transport = _server();
      final service = await _service(tester, active: true);
      await _pump(tester, transport, service, locale: const Locale('he'));

      final fold = DuoPose.halfOpenBook.fold!;
      final he = lookupAppLocalizations(const Locale('he'));
      expect(
        tester.getRect(find.text(he.coupleConciergeTitle)).left,
        greaterThanOrEqualTo(fold.right - 0.5),
      );
      expect(tester.getRect(_field).right, lessThanOrEqualTo(fold.left + 0.5));
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
    });
  });
}
