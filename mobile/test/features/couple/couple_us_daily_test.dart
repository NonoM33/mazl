import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/couple/l10n/couple_failure_label.dart';
import 'package:mazl/presentation/features/couple/widgets/couple_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../duo/duo_geometry.dart';
import 'couple_flow_fakes.dart';
import 'l10n_space/text_fit.dart';
import 'us_daily_fakes.dart';

// « Nous deux »: the question of the day, the monthly check-in and the
// settings of the couple. Server shapes come from
// docs/couple/ESPACE-COUPLE.md (§5, §6), not from the decoders.

const _question = 'Quel est votre plus beau souvenir ensemble ?';
const _mine = 'Notre premier voyage a Lisbonne';
const _theirs = 'Le soir ou il a plu sur la terrasse';

/// The shared space with nothing in it: these tests are about the daily part.
void _space(FakeCoupleTransport t) {
  t
    ..reply(
      'GET /api/couple/stats',
      ok({'stats': statsRow(), 'achievements': []}),
    )
    ..reply('GET /api/couple/memories', ok({'memories': []}))
    ..reply('GET /api/couple/bucket-list', ok({'items': []}))
    ..reply('GET /api/couple/dates', ok({'dates': []}));
}

class _Harness {
  _Harness(this.transport, this.api, this.service, this.router);

  final FakeCoupleTransport transport;
  final FakeCoupleApi api;
  final CoupleService service;
  final GoRouter router;
}

const _routes = [
  '/couple/question',
  '/couple/questions',
  '/couple/checkin',
  '/couple/premium',
  '/couple/us/settings',
];

Future<_Harness> _pump(
  WidgetTester tester, {
  required void Function(FakeCoupleTransport) setUp,
  Map<String, dynamic>? premium,
  String status = 'in_relationship',
  Locale locale = kTestLocale,
  DuoPoseController? pose,
  Size size = const Size(420, 3000),
}) async {
  if (pose == null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  SharedPreferences.setMockInitialValues({});
  final api = FakeCoupleApi()
    ..couple = contractCouple(status: status)
    ..premium = premium;
  final service = CoupleService.forTesting(api: api);
  addTearDown(service.dispose);
  await tester.runAsync(service.refresh);

  final transport = FakeCoupleTransport();
  _space(transport);
  setUp(transport);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => usScreen(transport, couple: service),
      ),
      for (final path in _routes)
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text('page $path')),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: pose == null ? null : duoAppBuilder(pose),
    ),
  );
  await _settle(tester);
  return _Harness(transport, api, service, router);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void _withQuestion(
  FakeCoupleTransport t, {
  String? mine,
  String? theirs,
  bool partnerAnswered = false,
}) {
  t
    ..reply(
      'GET /api/couple/12/question',
      questionReply(text: _question, myAnswer: mine, partnerAnswer: theirs),
    )
    ..reply(
      'GET /api/couple/today',
      todayReply(partnerAnswered: partnerAnswered, myAnswered: mine != null),
    )
    ..reply('GET /api/couple/checkin', error('Not Found'));
}

void main() {
  setUpAll(loadAppFont);

  group('la question du jour', () {
    testWidgets(
      'avant ma reponse, celle de l\'autre n\'est PAS dans l\'arbre',
      (tester) async {
        // Le serveur n'envoie pas la reponse tant que je n'ai pas repondu
        // (§0.4). Meme un serveur fautif qui l'enverrait ne la fait pas lire.
        await _pump(tester, setUp: (t) => _withQuestion(t, theirs: _theirs));

        expect(find.text(_question), findsOneWidget);
        expect(find.text(_theirs, skipOffstage: false), findsNothing);
        expect(
          find.textContaining('terrasse', skipOffstage: false),
          findsNothing,
        );
        expect(find.text('Répondre'), findsOneWidget);
      },
    );

    testWidgets('l\'etat dit que l\'autre a repondu, sans dire quoi', (
      tester,
    ) async {
      await _pump(
        tester,
        setUp: (t) => _withQuestion(t, partnerAnswered: true),
      );

      expect(find.text('Myriam a répondu · à vous'), findsOneWidget);
      expect(find.text(_theirs, skipOffstage: false), findsNothing);
    });

    testWidgets('personne n\'a repondu : c\'est a moi', (tester) async {
      await _pump(tester, setUp: _withQuestion);

      expect(find.text('À vous de répondre'), findsOneWidget);
    });

    testWidgets('le resume du jour absent ne casse rien', (tester) async {
      await _pump(
        tester,
        setUp: (t) {
          _withQuestion(t);
          t.fail('GET /api/couple/today', const SocketException('down'));
        },
      );

      expect(find.text(_question), findsOneWidget);
      expect(find.text('À vous de répondre'), findsOneWidget);
    });

    testWidgets('j\'ai repondu, l\'autre pas : en attente, bouton Voir', (
      tester,
    ) async {
      await _pump(tester, setUp: (t) => _withQuestion(t, mine: _mine));

      expect(find.text('En attente de Myriam'), findsOneWidget);
      expect(find.text('Voir'), findsOneWidget);
      expect(find.text('Répondre'), findsNothing);
      expect(find.text(_theirs, skipOffstage: false), findsNothing);
    });

    testWidgets('les deux ont repondu : les deux reponses dans la carte', (
      tester,
    ) async {
      await _pump(
        tester,
        setUp: (t) => _withQuestion(t, mine: _mine, theirs: _theirs),
      );

      expect(find.text('Vous avez répondu'), findsOneWidget);
      expect(find.text(_mine), findsOneWidget);
      expect(find.text(_theirs), findsOneWidget);
      expect(find.text('MYRIAM'), findsOneWidget);
    });

    testWidgets('Repondre ouvre la question, et le retour relit l\'etat', (
      tester,
    ) async {
      final h = await _pump(tester, setUp: _withQuestion);
      expect(h.transport.count('GET /api/couple/12/question'), 1);

      // Pendant que la page de reponse est ouverte, le membre repond.
      h.transport.reply(
        'GET /api/couple/12/question',
        questionReply(text: _question, myAnswer: _mine, partnerAnswer: _theirs),
      );
      await tester.tap(find.text('Répondre'));
      await _settle(tester);
      expect(find.text('page /couple/question'), findsOneWidget);

      h.router.pop();
      await _settle(tester);

      expect(h.transport.count('GET /api/couple/12/question'), 2);
      expect(find.text(_theirs), findsOneWidget);
    });

    testWidgets('le lien de l\'historique ouvre /couple/questions', (
      tester,
    ) async {
      await _pump(tester, setUp: _withQuestion);

      await tester.tap(find.text('Voir l\'historique des réponses'));
      await _settle(tester);

      expect(find.text('page /couple/questions'), findsOneWidget);
    });

    testWidgets('route absente (404) : pas de carte, pas d\'erreur', (
      tester,
    ) async {
      await _pump(tester, setUp: (t) => t.dailyRoutesAbsent(coupleId: 12));

      expect(find.text('Nous deux'), findsOneWidget);
      expect(find.text('QUESTION DU JOUR'), findsNothing);
      expect(find.text('BILAN'), findsNothing);
      expect(find.text('Chargement impossible'), findsNothing);
      expect(find.text('Impossible de charger cette partie.'), findsNothing);
      expect(
        find.text('Cette fonction n\'est pas encore disponible.'),
        findsNothing,
      );
    });

    testWidgets('la question en panne n\'efface pas le reste, et se relance', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        setUp: (t) {
          _withQuestion(t);
          t.fail('GET /api/couple/12/question', const SocketException('down'));
          t.reply(
            'GET /api/couple/memories',
            ok({
              'memories': [memoryRow(id: 1, title: 'Notre premier voyage')],
            }),
          );
        },
      );

      expect(find.text('Notre premier voyage'), findsOneWidget);
      expect(find.text('Impossible de charger cette partie.'), findsNothing);
      expect(find.text('Question du jour'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);

      h.transport.reply(
        'GET /api/couple/12/question',
        questionReply(text: _question),
      );
      await tester.tap(find.text('Réessayer'));
      await _settle(tester);

      expect(find.text(_question), findsOneWidget);
      expect(find.text('Notre premier voyage'), findsOneWidget);
    });
  });

  group('le bilan', () {
    Map<String, dynamic> checkin({
      Map<String, int>? mine,
      bool partnerDone = false,
      Map<String, dynamic>? summary,
    }) => checkinReply(mine: mine, partnerDone: partnerDone, summary: summary);

    void daily(FakeCoupleTransport t, Map<String, dynamic> reply) {
      _withQuestion(t);
      t.reply('GET /api/couple/checkin', reply);
    }

    testWidgets('pas encore repondu : il attend, bouton Faire le bilan', (
      tester,
    ) async {
      await _pump(tester, setUp: (t) => daily(t, checkin()));

      expect(find.text('Le bilan de novembre vous attend'), findsOneWidget);
      await tester.tap(find.text('Faire le bilan'));
      await _settle(tester);
      expect(find.text('page /couple/checkin'), findsOneWidget);
    });

    testWidgets('j\'ai repondu, l\'autre non : en attente, sans bouton', (
      tester,
    ) async {
      await _pump(
        tester,
        setUp: (t) =>
            daily(t, checkin(mine: {'talk': 4, 'time': 2, 'close': 5})),
      );

      expect(find.text('En attente de Myriam'), findsOneWidget);
      expect(find.text('Faire le bilan'), findsNothing);
    });

    testWidgets('synthese : points en phase et theme le plus bas', (
      tester,
    ) async {
      await _pump(
        tester,
        setUp: (t) => daily(
          t,
          checkin(
            mine: {'talk': 4, 'time': 2, 'close': 5},
            partnerDone: true,
            summary: {'aligned': 2, 'lowest': 'time', 'trend': 'up'},
          ),
        ),
      );

      expect(find.text('En phase sur 2 points sur 3'), findsOneWidget);
      expect(
        find.text('Le thème à soigner ce mois-ci : le temps à deux.'),
        findsOneWidget,
      );
      expect(find.text('Faire le bilan'), findsNothing);
    });

    testWidgets('un seul point en phase s\'ecrit au singulier', (tester) async {
      await _pump(
        tester,
        setUp: (t) => daily(
          t,
          checkin(
            mine: {'talk': 4, 'time': 2, 'close': 5},
            partnerDone: true,
            summary: {'aligned': 1, 'lowest': 'talk'},
          ),
        ),
      );

      expect(find.text('En phase sur 1 point sur 3'), findsOneWidget);
    });

    testWidgets('jamais les notes de l\'autre, meme si le serveur les envoie', (
      tester,
    ) async {
      await _pump(
        tester,
        setUp: (t) => daily(t, {
          'success': true,
          'data': {
            'period': '2026-11',
            'mine': {'talk': 4, 'time': 2, 'close': 5},
            'partnerDone': true,
            'partner': {'talk': 4242, 'time': 4243, 'close': 4244},
            'partnerScores': {'talk': 4242},
            'summary': {
              'aligned': 2,
              'lowest': 'time',
              'partnerTalk': 4242,
              'scores': {'talk': 4242},
            },
          },
        }),
      );

      expect(find.text('En phase sur 2 points sur 3'), findsOneWidget);
      expect(find.textContaining('424', skipOffstage: false), findsNothing);
    });

    testWidgets('le bilan en panne n\'efface pas la question', (tester) async {
      await _pump(
        tester,
        setUp: (t) {
          _withQuestion(t);
          t.fail('GET /api/couple/checkin', const SocketException('down'));
        },
      );

      expect(find.text(_question), findsOneWidget);
      expect(find.text('Bilan'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });
  });

  group('les reglages du couple', () {
    testWidgets('le statut part au serveur d\'abord', (tester) async {
      final h = await _pump(tester, setUp: _withQuestion);
      CouplePill pill(String status) => tester.widget<CouplePill>(
        find.byKey(Key('couple-us-status-$status')),
      );
      expect(pill('inRelationship').selected, isTrue);

      await tester.tap(find.text('Fiancés'));
      await _settle(tester);

      expect(h.api.statuses, ['engaged']);
      expect(pill('engaged').selected, isTrue);
      expect(pill('inRelationship').selected, isFalse);
      expect(h.service.coupleData?.status, RelationshipStatus.engaged);
    });

    testWidgets('un refus du serveur ramene la selection et le dit', (
      tester,
    ) async {
      final h = await _pump(tester, setUp: _withQuestion);
      h.api.statusError = 'Forbidden';

      await tester.tap(find.text('Mariés'));
      await _settle(tester);

      final l10n = lookupAppLocalizations(kTestLocale);
      expect(h.api.calls, contains('status:12:married'));
      expect(
        tester
            .widget<CouplePill>(
              find.byKey(const Key('couple-us-status-married')),
            )
            .selected,
        isFalse,
      );
      expect(
        tester
            .widget<CouplePill>(
              find.byKey(const Key('couple-us-status-inRelationship')),
            )
            .selected,
        isTrue,
      );
      expect(find.text(CoupleActionFailure.server.label(l10n)), findsOneWidget);
    });

    testWidgets(
      'PATCH /api/couple/:id/status {"relationshipStatus":"engaged"}',
      (tester) async {
        // Le corps exact du contrat, lu sur le fil (pas sur le faux).
        late http.Request seen;
        final result = await http.runWithClient(
          () => ApiService().updateCoupleStatus(
            12,
            RelationshipStatus.engaged.serverValue!,
          ),
          () => MockClient((request) async {
            seen = request;
            return http.Response(jsonEncode({'success': true}), 200);
          }),
        );

        expect(result.success, isTrue);
        expect(seen.method, 'PATCH');
        expect(seen.url.path, '/api/couple/12/status');
        expect(jsonDecode(seen.body), {'relationshipStatus': 'engaged'});
      },
    );

    testWidgets('sans abonnement : Decouvrir MAZL Couple', (tester) async {
      await _pump(tester, setUp: _withQuestion);

      expect(find.text('Découvrir MAZL Couple'), findsOneWidget);
      await tester.tap(find.text('MAZL Couple'));
      await _settle(tester);
      expect(find.text('page /couple/premium'), findsOneWidget);
    });

    testWidgets('abonnement paye par moi', (tester) async {
      await _pump(
        tester,
        setUp: _withQuestion,
        premium: {'active': true, 'paidBy': 'me', 'renewsAt': null},
      );

      expect(find.text('Actif · payé par vous'), findsOneWidget);
    });

    testWidgets('abonnement paye par l\'autre', (tester) async {
      await _pump(
        tester,
        setUp: _withQuestion,
        premium: {'active': true, 'paidBy': 'partner', 'renewsAt': null},
      );

      expect(find.text('Actif · payé par Myriam'), findsOneWidget);
    });

    testWidgets('la roue des reglages ouvre /couple/us/settings', (
      tester,
    ) async {
      await _pump(tester, setUp: _withQuestion);

      await tester.tap(find.byIcon(LucideIcons.settings));
      await _settle(tester);

      expect(find.text('page /couple/us/settings'), findsOneWidget);
    });

    testWidgets('l\'en-tete dit le jour du couple', (tester) async {
      await _pump(tester, setUp: _withQuestion);

      expect(find.textContaining(RegExp(r'^Jour \d+$')), findsOneWidget);
      expect(find.text('Myriam', skipOffstage: false), findsNothing);
      expect(find.textContaining('& Myriam'), findsOneWidget);
    });
  });

  group('iPhone Duo', () {
    Future<(_Harness, DuoPoseController)> pumpAt(
      WidgetTester tester,
      DuoPose pose, {
      void Function(FakeCoupleTransport)? setUp,
    }) async {
      setDuoPose(tester, pose);
      final controller = DuoPoseController(pose);
      final h = await _pump(
        tester,
        pose: controller,
        setUp: setUp ?? (t) => _withQuestion(t, partnerAnswered: true),
      );
      await settleFold(tester);
      return (h, controller);
    }

    Rect rect(WidgetTester tester, Finder f) {
      expect(f, findsAtLeastNWidgets(1), reason: f.toString());
      return tester.getRect(f.first);
    }

    void checkinDue(FakeCoupleTransport t) {
      _withQuestion(t, partnerAnswered: true);
      t.reply('GET /api/couple/checkin', checkinReply());
    }

    testWidgets(
      'livre : couple, question et bilan a gauche, le reste a droite',
      (tester) async {
        await pumpAt(tester, DuoPose.halfOpenBook, setUp: checkinDue);
        final fold = DuoPose.halfOpenBook.fold!;

        for (final left in [
          find.text('Nous deux'),
          find.textContaining('& Myriam'),
          find.text(_question),
          find.text('Répondre'),
          find.text('Le bilan de novembre vous attend'),
          find.text('Faire le bilan'),
        ]) {
          expect(rect(tester, left).right, lessThanOrEqualTo(fold.left + 0.5));
        }
        expect(
          rect(tester, find.byKey(const Key('couple-stat-0'))).left,
          greaterThanOrEqualTo(fold.right - 0.5),
        );
        await tester.drag(find.byType(ListView).last, const Offset(0, -1500));
        // iOS bounce (StarRefresh): let the list settle back on its end.
        await tester.pumpAndSettle();
        expect(
          rect(tester, find.text('RÉGLAGES DU COUPLE')).left,
          greaterThanOrEqualTo(fold.right - 0.5),
        );
        expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
      },
    );

    testWidgets('portable : titre, couple et question au-dessus du pli', (
      tester,
    ) async {
      await pumpAt(tester, DuoPose.halfOpenLaptop, setUp: checkinDue);
      final fold = DuoPose.halfOpenLaptop.fold!;

      for (final above in [
        find.text('Nous deux'),
        find.textContaining('& Myriam'),
        find.text(_question),
        find.text('Répondre'),
      ]) {
        expect(rect(tester, above).bottom, lessThanOrEqualTo(fold.top + 0.5));
      }
      for (final below in [
        find.text('Le bilan de novembre vous attend'),
        find.byKey(const Key('couple-stat-0')),
      ]) {
        expect(
          rect(tester, below).top,
          greaterThanOrEqualTo(fold.bottom - 0.5),
        );
      }
      expect(foldCrossingProblems(tester, DuoPose.halfOpenLaptop), isEmpty);
    });

    testWidgets('plier ne recharge rien et ne perd pas le statut choisi', (
      tester,
    ) async {
      final (h, pose) = await pumpAt(tester, DuoPose.openPortrait);
      await tester.scrollUntilVisible(
        find.text('Mariés'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Mariés'));
      await _settle(tester);
      expect(h.service.coupleData?.status, RelationshipStatus.married);
      final questionCalls = h.transport.count('GET /api/couple/12/question');

      await pose.moveTo(tester, DuoPose.halfOpenBook);
      await pose.moveTo(tester, DuoPose.halfOpenLaptop);
      await pose.moveTo(tester, DuoPose.closed);

      expect(h.transport.count('GET /api/couple/12/question'), questionCalls);
      expect(find.text(_question), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Mariés'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<CouplePill>(
              find.byKey(const Key('couple-us-status-married')),
            )
            .selected,
        isTrue,
      );
    });
  });

  group('langues', () {
    for (final locale in const [
      Locale('fr'),
      Locale('en'),
      Locale('he'),
      Locale('es'),
      Locale('ru'),
    ]) {
      testWidgets('${locale.languageCode} : les deux reponses et la synthese '
          'tiennent a 360 px', (tester) async {
        await _pump(
          tester,
          locale: locale,
          size: const Size(360, 3000),
          premium: {'active': true, 'paidBy': 'partner'},
          setUp: (t) {
            _withQuestion(t, mine: _mine, theirs: _theirs);
            t.reply(
              'GET /api/couple/checkin',
              checkinReply(
                mine: {'talk': 4, 'time': 2, 'close': 5},
                partnerDone: true,
                summary: {'aligned': 3, 'lowest': 'close'},
              ),
            );
          },
        );

        expect(tester.takeException(), isNull);
        expect(wordsTooWide(tester), isEmpty);
        expect(find.text(_theirs), findsOneWidget);
      });
    }
  });
}
