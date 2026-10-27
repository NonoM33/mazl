import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:ui' show CheckedState;

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/couple_daily.dart';
import 'package:mazl/presentation/features/couple/l10n/checkin_labels.dart';
import 'package:mazl/presentation/features/couple/screens/couple_checkin_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../duo/duo_geometry.dart';
import 'question_checkin_test_support.dart';

// Shapes written from docs/couple/ESPACE-COUPLE.md §6:
// GET  { period, mine: null | {talk,time,close}, partnerDone, summary: null |
//        { aligned: 0..3, lowest, trend } }
// POST { talk, time, close } -> 409 `checkin_already_done` the second time.

const _questions = [
  'On se parle vraiment',
  'On passe assez de temps à deux',
  'On se sent proches',
];

Map<String, dynamic> _checkin({
  Map<String, int>? mine,
  bool partnerDone = false,
  Map<String, dynamic>? summary,
}) => ok({
  'data': {
    'period': '2026-11',
    'mine': mine,
    'partnerDone': partnerDone,
    'summary': summary,
  },
});

Finder _score(String question, int n) =>
    find.bySemanticsLabel('$question : $n sur 5');

/// The whole cell of a note: what a finger can hit.
Finder _cell(String question, int n) =>
    find.descendant(of: _score(question, n), matching: find.byType(InkWell));

Finder get _send => find.widgetWithText(ElevatedButton, 'Envoyer');

Future<void> _pump(WidgetTester tester, FakeCoupleTransport transport) async {
  final service = await coupleOf();
  await pumpPhone(
    tester,
    CoupleCheckinScreen(api: apiOn(transport), couple: service),
  );
}

Future<void> _rateAll(WidgetTester tester, List<int> notes) async {
  for (var i = 0; i < 3; i++) {
    await tester.tap(_score(_questions[i], notes[i]));
    await tester.pump();
  }
}

void main() {
  setUpAll(loadAppFonts);

  group('the form', () {
    testWidgets('eyebrow with the month, title, explanation, three scales', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', _checkin());
      await _pump(tester, transport);

      expect(find.text('BILAN · NOVEMBRE'), findsOneWidget);
      expect(find.text('Comment ça va entre vous ?'), findsOneWidget);
      expect(
        find.text(
          'Deux minutes, chacun de son côté. Vos réponses restent entre vous deux.',
        ),
        findsOneWidget,
      );
      for (final q in _questions) {
        expect(find.text(q), findsOneWidget);
        for (var n = 1; n <= 5; n++) {
          expect(_score(q, n), findsOneWidget, reason: '$q $n');
        }
      }
      expect(find.text('Pas du tout'), findsNWidgets(3));
      expect(find.text('Tout à fait'), findsNWidgets(3));
    });

    testWidgets('every note is a target of 44 pt at least, edge to edge', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', _checkin());
      await _pump(tester, transport);

      for (final q in _questions) {
        for (var n = 1; n <= 5; n++) {
          final size = tester.getSize(_cell(q, n));
          expect(size.width, greaterThanOrEqualTo(44), reason: '$q $n');
          expect(size.height, greaterThanOrEqualTo(44), reason: '$q $n');
        }
      }
    });

    testWidgets('the group is a radio group for accessibility', (tester) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', _checkin());
      final handle = tester.ensureSemantics();
      await _pump(tester, transport);

      await tester.tap(_score(_questions[1], 4));
      await tester.pump();
      final chosen = tester.getSemantics(_score(_questions[1], 4));
      final other = tester.getSemantics(_score(_questions[1], 3));
      expect(chosen.flagsCollection.isChecked, CheckedState.isTrue);
      expect(other.flagsCollection.isChecked, CheckedState.isFalse);
      expect(chosen.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      handle.dispose();
    });

    testWidgets('the chosen note is full ink, the others are not', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', _checkin());
      await _pump(tester, transport);

      Color? fillOf(int n) {
        final box = tester.widget<AnimatedContainer>(
          find.descendant(
            of: _cell(_questions[0], n),
            matching: find.byType(AnimatedContainer),
          ),
        );
        return (box.decoration! as BoxDecoration).color;
      }

      final scheme = Theme.of(
        tester.element(find.byType(Scaffold)),
      ).colorScheme;
      await tester.tap(_score(_questions[0], 4));
      await tester.pumpAndSettle();
      expect(fillOf(4), scheme.onSurface);
      expect(fillOf(3), isNot(scheme.onSurface));
      await tester.tap(_score(_questions[0], 2));
      await tester.pumpAndSettle();
      expect(fillOf(2), scheme.onSurface);
      expect(fillOf(4), isNot(scheme.onSurface));
    });

    testWidgets('the button is off until the three themes are rated', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', _checkin());
      await _pump(tester, transport);

      expect(buttonEnabled(tester, _send), isFalse);
      await tester.tap(_score(_questions[0], 4));
      await tester.pump();
      await tester.tap(_score(_questions[1], 2));
      await tester.pump();
      expect(buttonEnabled(tester, _send), isFalse);
      await tester.tap(_score(_questions[2], 5));
      await tester.pump();
      expect(buttonEnabled(tester, _send), isTrue);
    });
  });

  group('sending', () {
    testWidgets('posts talk, time and close with the notes chosen', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', _checkin())
        ..reply(
          'POST /api/couple/checkin',
          _checkin(mine: {'talk': 4, 'time': 2, 'close': 5}),
        );
      await _pump(tester, transport);

      await _rateAll(tester, [4, 2, 5]);
      await tester.tap(_send);
      await settle(tester);

      expect(transport.count('POST /api/couple/checkin'), 1);
      expect(transport.bodies['POST /api/couple/checkin'], {
        'talk': 4,
        'time': 2,
        'close': 5,
      });
    });

    testWidgets('changing a note before sending changes what is posted', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', _checkin())
        ..reply(
          'POST /api/couple/checkin',
          _checkin(mine: {'talk': 1, 'time': 3, 'close': 3}),
        );
      await _pump(tester, transport);
      await _rateAll(tester, [4, 3, 3]);
      await tester.tap(_score(_questions[0], 1));
      await tester.pump();
      await tester.tap(_send);
      await settle(tester);
      expect(transport.bodies['POST /api/couple/checkin'], {
        'talk': 1,
        'time': 3,
        'close': 3,
      });
    });

    testWidgets('after sending, a partner still to answer is awaited and no '
        'note is shown', (tester) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', _checkin())
        ..reply(
          'POST /api/couple/checkin',
          _checkin(mine: {'talk': 4, 'time': 2, 'close': 5}),
        );
      await _pump(tester, transport);
      await _rateAll(tester, [4, 2, 5]);
      await tester.tap(_send);
      await settle(tester);

      expect(
        find.text('En attente de Noémie : vous verrez la synthèse ensemble.'),
        findsOneWidget,
      );
      expect(find.byType(ElevatedButton), findsNothing);
      for (final q in _questions) {
        expect(find.text(q), findsNothing);
      }
      expect(find.textContaining('sur 3'), findsNothing);
    });

    testWidgets('a failed send keeps the notes and says so', (tester) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', _checkin())
        ..fail('POST /api/couple/checkin', const SocketException('down'));
      await _pump(tester, transport);
      await _rateAll(tester, [4, 2, 5]);
      await tester.tap(_send);
      await settle(tester);

      expect(find.textContaining('Votre bilan n\'est pas parti'), findsOne);
      expect(buttonEnabled(tester, _send), isTrue);
      transport.reply(
        'POST /api/couple/checkin',
        _checkin(mine: {'talk': 4, 'time': 2, 'close': 5}),
      );
      await tester.tap(_send);
      await settle(tester);
      expect(transport.bodies['POST /api/couple/checkin'], {
        'talk': 4,
        'time': 2,
        'close': 5,
      });
    });

    testWidgets('409 already answered: reloads and shows the answered state', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', _checkin())
        ..reply('POST /api/couple/checkin', error('checkin_already_done'));
      await _pump(tester, transport);
      await _rateAll(tester, [4, 2, 5]);
      transport.reply(
        'GET /api/couple/checkin',
        _checkin(mine: {'talk': 3, 'time': 3, 'close': 3}),
      );
      await tester.tap(_send);
      await settle(tester);

      expect(transport.count('GET /api/couple/checkin'), 2);
      expect(find.text('Merci, c\'est envoyé'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.textContaining('n\'est pas parti'), findsNothing);
    });

    testWidgets('an answer the contract does not describe is read again', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', _checkin())
        ..reply('POST /api/couple/checkin', ok({}));
      await _pump(tester, transport);
      await _rateAll(tester, [4, 2, 5]);
      transport.reply(
        'GET /api/couple/checkin',
        _checkin(mine: {'talk': 4, 'time': 2, 'close': 5}),
      );
      await tester.tap(_send);
      await settle(tester);
      expect(find.text('Merci, c\'est envoyé'), findsOneWidget);
    });
  });

  group('already answered when it opens', () {
    testWidgets('mine set, partner pending: waiting line, no form, no notes', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply(
          'GET /api/couple/checkin',
          _checkin(mine: {'talk': 4, 'time': 2, 'close': 5}),
        );
      await _pump(tester, transport);

      expect(
        find.text('En attente de Noémie : vous verrez la synthèse ensemble.'),
        findsOneWidget,
      );
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.textContaining('sur 3'), findsNothing);
      expect(find.textContaining('sur 5'), findsNothing);
    });

    testWidgets('the summary only appears when the server sends one', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply(
          'GET /api/couple/checkin',
          _checkin(
            mine: {'talk': 4, 'time': 2, 'close': 5},
            partnerDone: true,
            summary: {'aligned': 2, 'lowest': 'time', 'trend': 'down'},
          ),
        );
      await _pump(tester, transport);

      expect(find.text('En phase sur 2 points sur 3'), findsOneWidget);
      expect(
        find.text(
          'Le temps à deux a baissé. Une soirée sans écran cette semaine ?',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('En attente'), findsNothing);
      // Neither of the members' notes is shown again.
      expect(find.text('4'), findsNothing);
      expect(find.text('5'), findsNothing);
    });

    testWidgets('a first check-in has no trend and still has a sentence', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply(
          'GET /api/couple/checkin',
          _checkin(
            mine: {'talk': 4, 'time': 2, 'close': 5},
            partnerDone: true,
            summary: {'aligned': 1, 'lowest': 'close', 'trend': null},
          ),
        );
      await _pump(tester, transport);
      expect(find.text('En phase sur 1 point sur 3'), findsOneWidget);
      expect(find.textContaining('petit geste attentionné'), findsOneWidget);
    });
  });

  group('empty and errors', () {
    testWidgets('a server without the route reads as an empty state', (
      tester,
    ) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', error('Not Found'));
      await _pump(tester, transport);
      expect(find.text('Le bilan arrive bientôt'), findsOneWidget);
      expect(find.text('Chargement impossible'), findsNothing);
    });

    testWidgets('a failing load shows an error and retries', (tester) async {
      final transport = FakeCoupleTransport()
        ..fail('GET /api/couple/checkin', const SocketException('down'));
      await _pump(tester, transport);
      expect(find.text('Chargement impossible'), findsOneWidget);

      transport.reply('GET /api/couple/checkin', _checkin());
      await tester.tap(find.text('Réessayer'));
      await settle(tester);
      expect(find.text('Comment ça va entre vous ?'), findsOneWidget);
    });

    testWidgets('has a close button that leaves the page', (tester) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', _checkin());
      await _pump(tester, transport);
      expect(find.byType(CloseButton), findsOneWidget);
      expect(
        tester.getSize(find.byType(CloseButton)).shortestSide,
        greaterThanOrEqualTo(44),
      );
    });
  });

  group('wording', () {
    const codes = ['fr', 'en', 'he', 'es', 'ru'];

    test('every theme x trend has a sentence in the five languages', () {
      for (final code in codes) {
        final l10n = lookupAppLocalizations(Locale(code));
        final seen = <String>{};
        for (final theme in CheckinTheme.values) {
          for (final trend in [...CheckinTrend.values, null]) {
            final line = checkinAttentionLine(
              l10n,
              CheckinSummary(aligned: 1, lowest: theme, trend: trend),
            );
            expect(line.trim(), isNotEmpty, reason: '$code $theme $trend');
            expect(
              seen.add(line),
              isTrue,
              reason: 'twice: $code $theme $trend',
            );
          }
        }
        expect(seen, hasLength(12));
      }
    });

    test('the attention sentences give no medical advice and no AI claim', () {
      for (final code in codes) {
        final l10n = lookupAppLocalizations(Locale(code));
        for (final theme in CheckinTheme.values) {
          for (final trend in [...CheckinTrend.values, null]) {
            final line = checkinAttentionLine(
              l10n,
              CheckinSummary(aligned: 0, lowest: theme, trend: trend),
            ).toLowerCase();
            expect(line, isNot(contains('thérap')));
            expect(line, isNot(contains('therap')));
            expect(line, isNot(contains('médecin')));
          }
        }
      }
    });

    test('the months are written in full in each language', () {
      final eyebrow = {
        for (final code in codes)
          code: lookupAppLocalizations(Locale(code)).coupleCheckinEyebrow('x'),
      };
      for (final line in eyebrow.values) {
        expect(line, contains('x'));
      }
    });
  });

  group('iPhone Duo', () {
    Future<DuoPoseController> pump(WidgetTester tester, DuoPose pose) async {
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/checkin', _checkin());
      final service = await coupleOf();
      return pumpInPose(
        tester,
        pose,
        CoupleCheckinScreen(api: apiOn(transport), couple: service),
      );
    }

    testWidgets('book: title on the first page, the scales and the button on '
        'the other, no scale across the fold', (tester) async {
      await pump(tester, DuoPose.halfOpenBook);
      final fold = DuoPose.halfOpenBook.fold!;
      expect(
        rectOf(tester, find.text('Comment ça va entre vous ?')).right,
        lessThanOrEqualTo(fold.left + 0.5),
      );
      for (final q in _questions) {
        for (var n = 1; n <= 5; n++) {
          final rect = rectOf(tester, _score(q, n));
          expect(rect.left, greaterThanOrEqualTo(fold.right - 0.5));
          expect(rect.width, greaterThanOrEqualTo(44));
        }
      }
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
      expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'checkin');
    });

    testWidgets('laptop: title above the fold, the scales below', (
      tester,
    ) async {
      await pump(tester, DuoPose.halfOpenLaptop);
      final fold = DuoPose.halfOpenLaptop.fold!;
      expect(
        rectOf(tester, find.text('Comment ça va entre vous ?')).bottom,
        lessThanOrEqualTo(fold.top + 0.5),
      );
      expect(
        rectOf(tester, _score(_questions[0], 1)).top,
        greaterThanOrEqualTo(fold.bottom - 0.5),
      );
      expect(foldCrossingProblems(tester, DuoPose.halfOpenLaptop), isEmpty);
      expectFitsDuoPose(tester, DuoPose.halfOpenLaptop, 'checkin');
    });

    testWidgets('the notes survive folding and unfolding', (tester) async {
      final controller = await pump(tester, DuoPose.openLandscape);
      await _rateAll(tester, [4, 2, 5]);
      for (final pose in [
        DuoPose.halfOpenBook,
        DuoPose.halfOpenLaptop,
        DuoPose.closed,
      ]) {
        await controller.moveTo(tester, pose);
        await settle(tester);
        expect(buttonEnabled(tester, _send), isTrue, reason: pose.name);
      }
    });
  });
}
