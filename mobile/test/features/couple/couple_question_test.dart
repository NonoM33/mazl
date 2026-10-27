import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/presentation/features/couple/screens/couple_question_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../duo/duo_geometry.dart';
import 'question_checkin_test_support.dart';

// Shapes written from docs/couple/ESPACE-COUPLE.md §5: the question is
// `{ id, text, myAnswer, partnerAnswer }`, and `partnerAnswer` stays null
// until the caller has answered.

const _text = 'Quel petit geste de l\'autre vous a touché cette semaine ?';
const _partnerText = 'Un café apporté au lit, sans rien demander.';
const _mine = 'Les fleurs sur la table, sans raison.';

Map<String, dynamic> _question({String? mine, String? partner}) => ok({
  'question': {
    'id': 5,
    'text': _text,
    'myAnswer': mine,
    'partnerAnswer': partner,
  },
});

Map<String, dynamic> _today({required bool partnerAnswered, int id = 5}) => ok({
  'data': {
    'days': 214,
    'partner': {'id': 45, 'name': 'Noémie'},
    'question': {
      'id': id,
      'text': _text,
      'myAnswered': false,
      'partnerAnswered': partnerAnswered,
    },
    'upcoming': <Object>[],
  },
});

/// A server where the partner answered first and only gives that answer back
/// once the caller's own has been posted.
class _Server {
  _Server(this.transport, {this.partnerAnswered = true}) {
    transport
      ..on(
        'GET /api/couple/12/question',
        (_) => _question(
          mine: posted,
          partner: posted == null ? null : _partnerText,
        ),
      )
      ..on('POST /api/couple/12/question/5/answer', (body) {
        posted = body['answer'] as String;
        return ok({});
      })
      ..reply(
        'GET /api/couple/today',
        _today(partnerAnswered: partnerAnswered),
      );
  }

  final FakeCoupleTransport transport;
  final bool partnerAnswered;
  String? posted;
}

Finder get _field => find.byType(TextField);
Finder get _send => find.widgetWithText(ElevatedButton, 'Envoyer à Noémie');

Future<void> _pump(
  WidgetTester tester,
  FakeCoupleTransport transport, {
  CoupleService? couple,
}) async {
  final service = couple ?? await coupleOf();
  await pumpPhone(
    tester,
    CoupleQuestionScreen(api: apiOn(transport), couple: service),
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows a spinner while it loads', (tester) async {
    final transport = FakeCoupleTransport()
      ..on('GET /api/couple/12/question', (_) => _question())
      ..reply('GET /api/couple/today', _today(partnerAnswered: false));
    final service = await coupleOf();
    tester.view
      ..physicalSize = const Size(400, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: kTestLocale,
        home: CoupleQuestionScreen(api: apiOn(transport), couple: service),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await settle(tester);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  group('before answering', () {
    testWidgets('eyebrow with the day, the question, a field and the button', (
      tester,
    ) async {
      final server = _Server(FakeCoupleTransport());
      await _pump(tester, server.transport);

      expect(find.text('QUESTION DU JOUR · 214'), findsOneWidget);
      expect(find.text(_text), findsOneWidget);
      expect(_field, findsOneWidget);
      expect(_send, findsOneWidget);
      expect(find.text('Vos réponses précédentes'), findsOneWidget);
    });

    testWidgets('the partner\'s answer is not in the tree, whatever the '
        'server sends back', (tester) async {
      final transport = FakeCoupleTransport()
        ..on(
          'GET /api/couple/12/question',
          // A server that would leak: the answer comes with no answer of mine.
          (_) => _question(partner: _partnerText),
        )
        ..reply('GET /api/couple/today', _today(partnerAnswered: true));
      await _pump(tester, transport);

      expect(find.textContaining(_partnerText), findsNothing);
      expect(find.text('Réponse de Noémie'.toUpperCase()), findsNothing);
      expect(find.text('Noémie a répondu'), findsOneWidget);
      expect(
        find.text('Répondez à votre tour pour lire sa réponse.'),
        findsOneWidget,
      );
    });

    testWidgets('says the partner has not answered when today says so', (
      tester,
    ) async {
      final server = _Server(FakeCoupleTransport(), partnerAnswered: false);
      await _pump(tester, server.transport);
      expect(find.text('Noémie n\'a pas encore répondu'), findsOneWidget);
    });

    testWidgets('stays neutral when today is not available', (tester) async {
      final transport = FakeCoupleTransport()
        ..on('GET /api/couple/12/question', (_) => _question())
        ..reply('GET /api/couple/today', error('Not Found'));
      await _pump(tester, transport);

      expect(find.text('Sa réponse est masquée'), findsOneWidget);
      expect(find.textContaining('a répondu'), findsNothing);
      // Without the server\'s count of days the eyebrow falls back to the
      // couple\'s own: 7 days in the test couple.
      expect(find.textContaining('QUESTION DU JOUR'), findsOneWidget);
    });

    testWidgets('does not use a status that belongs to another question', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..on('GET /api/couple/12/question', (_) => _question())
        ..reply('GET /api/couple/today', _today(partnerAnswered: true, id: 9));
      await _pump(tester, transport);
      expect(find.text('Noémie a répondu'), findsNothing);
      expect(find.text('Sa réponse est masquée'), findsOneWidget);
    });

    testWidgets('the button stays off while the field is empty or blank', (
      tester,
    ) async {
      final server = _Server(FakeCoupleTransport());
      await _pump(tester, server.transport);

      expect(buttonEnabled(tester, _send), isFalse);
      await tester.enterText(_field, '   \n ');
      await tester.pump();
      expect(buttonEnabled(tester, _send), isFalse);
      await tester.enterText(_field, 'Un mot');
      await tester.pump();
      expect(buttonEnabled(tester, _send), isTrue);
    });

    testWidgets('the field is at least 120 pt high, the button 48', (
      tester,
    ) async {
      final server = _Server(FakeCoupleTransport());
      await _pump(tester, server.transport);
      expect(tester.getSize(_field).height, greaterThanOrEqualTo(120));
      expect(tester.getSize(_send).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(_send).width, greaterThan(300));
    });

    testWidgets('the counter only appears near the limit and the field '
        'stops at 2000', (tester) async {
      final server = _Server(FakeCoupleTransport());
      await _pump(tester, server.transport);

      await tester.enterText(_field, 'a' * 1000);
      await tester.pump();
      expect(find.textContaining('/ 2000'), findsNothing);
      await tester.enterText(_field, 'a' * 1850);
      await tester.pump();
      expect(find.text('1850 / 2000'), findsOneWidget);
      await tester.enterText(_field, 'a' * 2500);
      await tester.pump();
      expect(find.text('2000 / 2000'), findsOneWidget);
    });
  });

  group('answering', () {
    testWidgets('posts the answer, reloads, and then shows both answers', (
      tester,
    ) async {
      final server = _Server(FakeCoupleTransport());
      await _pump(tester, server.transport);
      expect(find.textContaining(_partnerText), findsNothing);

      await tester.enterText(_field, '  $_mine  ');
      await tester.pump();
      await tester.tap(_send);
      await settle(tester);

      final t = server.transport;
      expect(t.count('POST /api/couple/12/question/5/answer'), 1);
      expect(t.bodies['POST /api/couple/12/question/5/answer'], {
        'answer': _mine,
      });
      // The question was read again after the post.
      expect(t.count('GET /api/couple/12/question'), 2);
      expect(_field, findsNothing);
      expect(find.text(_mine), findsOneWidget);
      expect(find.text(_partnerText), findsOneWidget);
      expect(find.text('RÉPONSE DE NOÉMIE'), findsOneWidget);
    });

    testWidgets('shows a spinner on the button and locks the field while '
        'sending', (tester) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/today', _today(partnerAnswered: true))
        ..on('GET /api/couple/12/question', (_) => _question());
      // The post never answers until released.
      final release = Completer<Map<String, dynamic>>();
      final hanging = _HangingTransport(transport, release);
      final service = await coupleOf();
      await pumpPhone(
        tester,
        CoupleQuestionScreen(api: apiOn(hanging), couple: service),
      );

      await tester.enterText(_field, _mine);
      await tester.pump();
      await tester.tap(_send);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<TextField>(_field).enabled, isFalse);

      release.complete(ok({}));
      await settle(tester);
    });

    testWidgets('a failed send keeps the text and says so', (tester) async {
      final server = _Server(FakeCoupleTransport());
      server.transport.fail(
        'POST /api/couple/12/question/5/answer',
        const SocketException('down'),
      );
      await _pump(tester, server.transport);

      await tester.enterText(_field, _mine);
      await tester.pump();
      await tester.tap(_send);
      await settle(tester);

      expect(find.textContaining('Votre réponse n\'est pas partie'), findsOne);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        _mine,
      );
      expect(buttonEnabled(tester, _send), isTrue);
      expect(find.textContaining(_partnerText), findsNothing);
    });

    testWidgets('the server refusing the answer keeps the text too', (
      tester,
    ) async {
      final server = _Server(FakeCoupleTransport());
      server.transport.reply(
        'POST /api/couple/12/question/5/answer',
        error('Server error'),
      );
      await _pump(tester, server.transport);

      await tester.enterText(_field, _mine);
      await tester.pump();
      await tester.tap(_send);
      await settle(tester);

      expect(find.textContaining('Votre réponse n\'est pas partie'), findsOne);
      expect(find.text(_mine), findsOneWidget);
    });
  });

  group('already answered', () {
    testWidgets('opens on both answers, with no field', (tester) async {
      final transport = FakeCoupleTransport()
        ..on(
          'GET /api/couple/12/question',
          (_) => _question(mine: _mine, partner: _partnerText),
        )
        ..reply('GET /api/couple/today', _today(partnerAnswered: true));
      await _pump(tester, transport);

      expect(_field, findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text(_mine), findsOneWidget);
      expect(find.text(_partnerText), findsOneWidget);
      expect(find.text('Noémie a répondu'), findsNothing);
    });

    testWidgets('says the partner has not answered yet', (tester) async {
      final transport = FakeCoupleTransport()
        ..on('GET /api/couple/12/question', (_) => _question(mine: _mine))
        ..reply('GET /api/couple/today', _today(partnerAnswered: false));
      await _pump(tester, transport);

      expect(find.text(_mine), findsOneWidget);
      expect(
        find.text(
          'Noémie n\'a pas encore répondu. Revenez lire sa réponse plus tard.',
        ),
        findsOneWidget,
      );
      // No way to edit an answer: the contract has no such route.
      expect(find.text('Modifier'), findsNothing);
    });
  });

  group('empty and errors', () {
    testWidgets('a server without the route reads as an empty state', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/12/question', error('Not Found'))
        ..reply('GET /api/couple/today', error('Not Found'));
      await _pump(tester, transport);

      expect(find.text('La question du jour arrive bientôt'), findsOneWidget);
      expect(find.text('Chargement impossible'), findsNothing);
    });

    testWidgets('no question for today is an empty state', (tester) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/12/question', ok({'question': null}))
        ..reply('GET /api/couple/today', error('Not Found'));
      await _pump(tester, transport);
      expect(find.text('La question du jour arrive bientôt'), findsOneWidget);
    });

    testWidgets('outside a couple there is nothing to ask the server', (
      tester,
    ) async {
      final transport = FakeCoupleTransport();
      final service = await coupleOf(inCouple: false);
      await _pump(tester, transport, couple: service);

      expect(find.text('La question du jour arrive bientôt'), findsOneWidget);
      expect(transport.calls, isEmpty);
    });

    testWidgets('a failing load shows an error and retries', (tester) async {
      final transport = FakeCoupleTransport()
        ..fail('GET /api/couple/12/question', const SocketException('down'))
        ..reply('GET /api/couple/today', _today(partnerAnswered: true));
      await _pump(tester, transport);
      expect(find.text('Chargement impossible'), findsOneWidget);

      transport.on('GET /api/couple/12/question', (_) => _question());
      await tester.tap(find.text('Réessayer'));
      await settle(tester);
      expect(find.text(_text), findsOneWidget);
    });

    testWidgets('a failed reload after the send offers to retry, and the '
        'retry shows the answers', (tester) async {
      final server = _Server(FakeCoupleTransport());
      await _pump(tester, server.transport);
      await tester.enterText(_field, _mine);
      await tester.pump();
      var reads = 0;
      server.transport.on('GET /api/couple/12/question', (_) {
        reads++;
        if (reads == 1) throw const SocketException('down');
        return _question(mine: server.posted, partner: _partnerText);
      });
      await tester.tap(_send);
      await settle(tester);
      expect(find.text('Chargement impossible'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await settle(tester);
      expect(find.text(_partnerText), findsOneWidget);
    });
  });

  testWidgets('the history link opens the previous answers', (tester) async {
    final server = _Server(FakeCoupleTransport());
    final service = await coupleOf();
    final visited = await pumpRouted(
      tester,
      CoupleQuestionScreen(api: apiOn(server.transport), couple: service),
      targets: [RoutePaths.coupleQuestions],
    );
    final link = find.text('Vos réponses précédentes');
    expect(
      tester
          .getSize(find.ancestor(of: link, matching: find.byType(TextButton)))
          .height,
      greaterThanOrEqualTo(44),
    );
    await tester.tap(link);
    await settle(tester);
    expect(visited, [RoutePaths.coupleQuestions]);
  });

  group('dark theme and languages', () {
    testWidgets('renders in the dark theme', (tester) async {
      final server = _Server(FakeCoupleTransport());
      final service = await coupleOf();
      await pumpPhone(
        tester,
        CoupleQuestionScreen(api: apiOn(server.transport), couple: service),
        brightness: Brightness.dark,
      );
      expect(find.text(_text), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final code in ['en', 'he', 'es', 'ru']) {
      testWidgets('fits a small phone in $code', (tester) async {
        final server = _Server(FakeCoupleTransport());
        final service = await coupleOf();
        await pumpPhone(
          tester,
          CoupleQuestionScreen(api: apiOn(server.transport), couple: service),
          locale: Locale(code),
        );
        expect(find.byType(TextField), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('iPhone Duo', () {
    Future<DuoPoseController> pump(WidgetTester tester, DuoPose pose) async {
      final server = _Server(FakeCoupleTransport());
      final service = await coupleOf();
      return pumpInPose(
        tester,
        pose,
        CoupleQuestionScreen(api: apiOn(server.transport), couple: service),
      );
    }

    testWidgets('book: the question on the first page, the field and the '
        'button on the other, nothing in the curve', (tester) async {
      await pump(tester, DuoPose.halfOpenBook);
      final fold = DuoPose.halfOpenBook.fold!;
      expect(
        rectOf(tester, find.text(_text)).right,
        lessThanOrEqualTo(fold.left + 0.5),
      );
      expect(
        rectOf(tester, _field).left,
        greaterThanOrEqualTo(fold.right - 0.5),
      );
      expect(
        rectOf(tester, _send).left,
        greaterThanOrEqualTo(fold.right - 0.5),
      );
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
      expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'question');
    });

    testWidgets('book in Hebrew: the question on the right page, the field '
        'on the left', (tester) async {
      final server = _Server(FakeCoupleTransport());
      final service = await coupleOf();
      await pumpInPose(
        tester,
        DuoPose.halfOpenBook,
        CoupleQuestionScreen(api: apiOn(server.transport), couple: service),
        locale: const Locale('he'),
      );
      final fold = DuoPose.halfOpenBook.fold!;
      expect(
        rectOf(tester, find.text(_text)).left,
        greaterThanOrEqualTo(fold.right - 0.5),
      );
      expect(rectOf(tester, _field).right, lessThanOrEqualTo(fold.left + 0.5));
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
    });

    testWidgets('laptop: the question above the fold, the field below, the '
        'field above the keyboard line', (tester) async {
      await pump(tester, DuoPose.halfOpenLaptop);
      final fold = DuoPose.halfOpenLaptop.fold!;
      expect(
        rectOf(tester, find.text(_text)).bottom,
        lessThanOrEqualTo(fold.top + 0.5),
      );
      expect(
        rectOf(tester, _field).top,
        greaterThanOrEqualTo(fold.bottom - 0.5),
      );
      expect(
        rectOf(tester, _send).top,
        greaterThanOrEqualTo(fold.bottom - 0.5),
      );
      expect(foldCrossingProblems(tester, DuoPose.halfOpenLaptop), isEmpty);
      expectFitsDuoPose(tester, DuoPose.halfOpenLaptop, 'question');
    });

    testWidgets('what was typed survives folding and unfolding', (
      tester,
    ) async {
      final controller = await pump(tester, DuoPose.openLandscape);
      await tester.enterText(_field, _mine);
      await tester.pump();
      for (final pose in [
        DuoPose.halfOpenBook,
        DuoPose.halfOpenLaptop,
        DuoPose.openPortrait,
        DuoPose.closed,
        DuoPose.openLandscape,
      ]) {
        await controller.moveTo(tester, pose);
        await settle(tester);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          _mine,
          reason: pose.name,
        );
        expect(buttonEnabled(tester, _send), isTrue, reason: pose.name);
      }
    });
  });
}

/// Lets the post wait for [release] and answers everything else from [inner].
class _HangingTransport implements CoupleTransport {
  _HangingTransport(this.inner, this.release);
  final FakeCoupleTransport inner;
  final Completer<Map<String, dynamic>> release;

  @override
  Future<Map<String, dynamic>> get(String path) => inner.get(path);

  @override
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      release.future;

  @override
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      inner.patch(path, body);

  @override
  Future<Map<String, dynamic>> delete(String path) => inner.delete(path);
}
