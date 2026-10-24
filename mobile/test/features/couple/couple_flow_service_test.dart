
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'couple_flow_fakes.dart';

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  late FakeCoupleApi api;
  late CoupleService service;
  late List<CoupleFlowEvent> events;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeCoupleApi();
    service = CoupleService.forTesting(api: api, pollInterval: const Duration(milliseconds: 30))
      ..archiveMessageProvider = () => 'archive sentence';
    events = [];
    service.events.listen(events.add);
  });

  tearDown(() => service.dispose());

  Future<void> sendToMyriam() => service.sendCoupleRequest(
        targetUserId: 45,
        targetName: 'Myriam',
      );

  group('décodage des formes du contrat', () {
    test('§1 : un couple vu de l\'appelant', () {
      final couple = CoupleData.fromServer(contractCouple(partnerPicture: 'https://img.example/p.jpg'));
      expect(couple.coupleId, 12);
      expect(couple.partnerId, 45);
      expect(couple.partnerName, 'Myriam');
      expect(couple.partnerPicture, 'https://img.example/p.jpg');
      expect(couple.relationshipStartDate, DateTime.utc(2026, 10, 20, 10));
      expect(couple.metOnMazlDate, DateTime.utc(2026, 10, 1, 9, 30));
      expect(couple.status, RelationshipStatus.inRelationship);
    });

    test('§1 : photo absente et statut « dating » (défaut en base) sont lus', () {
      final couple = CoupleData.fromServer(contractCouple(status: 'dating'));
      expect(couple.partnerPicture, isNull);
      expect(couple.status, RelationshipStatus.dating);
    });

    test('§2 : la demande envoyée porte le nom et la photo de la cible', () {
      final request = CoupleRequest.fromJson(contractSentRequest());
      expect(request.id, 77);
      expect(request.targetId, 45);
      expect(request.targetName, 'Myriam');
      expect(request.status, CoupleRequestStatus.pending);
    });

    test('§2 : la demande reçue porte le nom de l\'émetteur', () {
      final request = CoupleRequest.fromJson(contractReceivedRequest());
      expect(request.id, 91);
      expect(request.requesterId, 45);
      expect(request.requesterName, 'Myriam');
    });
  });

  group('demande envoyée', () {
    test('l\'identifiant vient de request.id, pas de data[\'id\']', () async {
      final result = await service.sendCoupleRequest(targetUserId: 45, targetName: 'Myriam');
      expect(result.ok, isTrue);
      expect(service.pendingRequest?.id, 77);
      expect(service.pendingRequest?.targetName, 'Myriam');
      expect(service.relationWithUser(45), CoupleRelation.requestSent);
      expect(service.relationWithUser(46), CoupleRelation.none);
    });

    test('annuler appelle DELETE avec le vrai identifiant', () async {
      await sendToMyriam();
      final result = await service.cancelCoupleRequest();
      expect(result.ok, isTrue);
      expect(api.calls, contains('cancel:77'));
      expect(api.calls, isNot(contains('cancel:0')));
      expect(service.pendingRequest, isNull);
    });

    test('not_matched : rien n\'est en attente et la cause est nommée, pas écrite', () async {
      api.sendError = 'not_matched';
      final result = await service.sendCoupleRequest(targetUserId: 45, targetName: 'Myriam');
      expect(result.ok, isFalse);
      expect(result.failure, CoupleActionFailure.notMatched);
      expect(service.pendingRequest, isNull);
    });

    test('déjà en couple et demande déjà en attente ont leur cause', () async {
      api.sendError = 'One of the users is already in a couple';
      expect((await service.sendCoupleRequest(targetUserId: 45, targetName: 'Myriam')).failure, CoupleActionFailure.alreadyInCouple);
      api.sendError = 'A pending couple request already exists';
      expect((await service.sendCoupleRequest(targetUserId: 45, targetName: 'Myriam')).failure, CoupleActionFailure.requestPending);
    });

    test('l\'archivage envoie la phrase dans la langue fournie par l\'écran', () async {
      service.archiveMessageProvider = () => 'sentence in the member language';
      api.received = [contractReceivedRequest()];
      api.acceptedCouple = contractCouple();
      await service.refresh();
      await service.acceptCoupleRequest(service.receivedRequest!);
      expect(api.archiveMessages, ['sentence in the member language']);
    });

    test('sans phrase fournie, aucune conversation n\'est archivée (jamais la mauvaise langue)', () async {
      service.archiveMessageProvider = null;
      api.received = [contractReceivedRequest()];
      api.acceptedCouple = contractCouple();
      await service.refresh();
      final result = await service.acceptCoupleRequest(service.receivedRequest!);
      expect(result.ok, isTrue);
      expect(service.isCoupleModeEnabled, isTrue);
      expect(api.archiveMessages, isEmpty);
    });

    test('accepté, vu au recalage : couple, archivage, Mazel Tov côté émetteur', () async {
      await sendToMyriam();
      api.sent = [contractSentRequest()];
      api.couple = contractCouple();
      // La demande n'est plus « en attente » côté serveur.
      api.sent = [];

      await service.refresh();
      await _settle();

      expect(service.isCoupleModeEnabled, isTrue);
      expect(service.coupleData?.coupleId, 12);
      expect(service.pendingRequest, isNull);
      expect(api.calls.where((c) => c == 'archive:45'), hasLength(1));
      final formed = events.whereType<CoupleFormed>().single;
      expect(formed.asRequester, isTrue);
      expect(formed.couple.partnerName, 'Myriam');
    });

    test('accepté, vu par le temps réel couple:accepted', () async {
      await sendToMyriam();
      await service.handleRealtime('couple:accepted', {'couple': contractCouple()});
      await _settle();

      expect(service.isCoupleModeEnabled, isTrue);
      expect(service.pendingRequest, isNull);
      expect(api.calls, contains('archive:45'));
      expect(events.whereType<CoupleFormed>().single.asRequester, isTrue);

      // Le recalage qui suit ne rejoue pas la célébration.
      api.couple = contractCouple();
      await service.refresh();
      await _settle();
      expect(events.whereType<CoupleFormed>(), hasLength(1));
      expect(api.calls.where((c) => c == 'archive:45'), hasLength(1));
    });

    test('refusé, vu au recalage : plus rien en attente, un message', () async {
      await sendToMyriam();
      api.sent = [];
      api.couple = null;

      await service.refresh();
      await _settle();

      expect(service.pendingRequest, isNull);
      expect(service.isCoupleModeEnabled, isFalse);
      expect(events.whereType<CoupleRequestDeclined>().single.partnerName, 'Myriam');
    });

    test('refusé, vu par couple:rejected', () async {
      await sendToMyriam();
      await service.handleRealtime('couple:rejected', {'request_id': 77});
      await _settle();
      expect(service.pendingRequest, isNull);
      expect(events.whereType<CoupleRequestDeclined>(), hasLength(1));
    });

    test('couple:rejected d\'une autre demande est ignoré', () async {
      await sendToMyriam();
      await service.handleRealtime('couple:rejected', {'request_id': 5});
      expect(service.pendingRequest?.id, 77);
      expect(events.whereType<CoupleRequestDeclined>(), isEmpty);
    });

    test('réseau coupé pendant l\'attente : on ne conclut ni refus ni couple', () async {
      await sendToMyriam();
      api.unreachable = true;
      await service.refresh();
      await _settle();
      expect(service.pendingRequest?.id, 77);
      expect(events.whereType<CoupleRequestDeclined>(), isEmpty);
    });

    test('la demande en attente survit à un redémarrage de l\'app', () async {
      await sendToMyriam();
      final restarted = CoupleService.forTesting(api: api);
      final restartedEvents = <CoupleFlowEvent>[];
      restarted.events.listen(restartedEvents.add);
      // Pendant que l'app était fermée, l'autre a accepté.
      api.sent = [];
      api.couple = contractCouple();

      await restarted.initialize();
      await _settle();

      expect(restarted.isCoupleModeEnabled, isTrue);
      expect(restartedEvents.whereType<CoupleFormed>().single.asRequester, isTrue);
      restarted.dispose();
    });
  });

  group('demande reçue', () {
    test('un recalage la trouve et prévient une fois', () async {
      api.received = [contractReceivedRequest()];
      await service.refresh();
      await service.refresh();
      await _settle();
      expect(service.receivedRequest?.id, 91);
      expect(events.whereType<CoupleRequestReceived>(), hasLength(1));
      expect(service.relationWithUser(45), CoupleRelation.requestReceived);
    });

    test('couple:request l\'affiche sans attendre le recalage', () async {
      await service.handleRealtime('couple:request', {'request': contractReceivedRequest()});
      await _settle();
      expect(service.receivedRequest?.requesterName, 'Myriam');
      expect(events.whereType<CoupleRequestReceived>(), hasLength(1));
    });

    test('accepter prend le couple de la réponse, sans second POST', () async {
      api.received = [contractReceivedRequest()];
      api.acceptedCouple = contractCouple();
      await service.refresh();

      final result = await service.acceptCoupleRequest(service.receivedRequest!);
      await _settle();

      expect(result.ok, isTrue);
      expect(service.isCoupleModeEnabled, isTrue);
      expect(service.coupleData?.coupleId, 12);
      expect(service.receivedRequest, isNull);
      expect(api.calls.where((c) => c.startsWith('send:')), isEmpty);
      expect(api.calls, containsAllInOrder(['accept:91', 'archive:45']));
      expect(events.whereType<CoupleFormed>().single.asRequester, isFalse);
    });

    test('accepter une demande retirée entre-temps : message, rien d\'activé', () async {
      api.received = [contractReceivedRequest()];
      await service.refresh();
      final request = service.receivedRequest!;
      api.respondError = 'Couple request is no longer pending';
      api.received = [];

      final result = await service.acceptCoupleRequest(request);

      expect(result.ok, isFalse);
      expect(result.failure, CoupleActionFailure.requestNoLongerPending);
      expect(service.isCoupleModeEnabled, isFalse);
      expect(service.receivedRequest, isNull);
    });

    test('refuser efface la demande reçue', () async {
      api.received = [contractReceivedRequest()];
      await service.refresh();
      final result = await service.rejectCoupleRequest(service.receivedRequest!);
      expect(result.ok, isTrue);
      expect(api.calls, contains('reject:91'));
      expect(service.receivedRequest, isNull);
    });
  });

  group('fin du couple', () {
    setUp(() async {
      api.couple = contractCouple();
      await service.initialize();
      events.clear();
    });

    test('quitter : DELETE avec l\'identifiant du couple, puis état vidé', () async {
      final result = await service.leaveCouple();
      expect(result.ok, isTrue);
      expect(api.calls, contains('end:12'));
      expect(service.isCoupleModeEnabled, isFalse);
      expect(service.coupleData, isNull);
    });

    test('échec du serveur : message et rien ne change', () async {
      api.endError = 'boom';
      final result = await service.leaveCouple();
      expect(result.ok, isFalse);
      expect(result.failure, CoupleActionFailure.server);
      expect(service.isCoupleModeEnabled, isTrue);
      expect(service.coupleData?.coupleId, 12);
    });

    test('l\'autre quitte : couple:ended vide l\'état et prévient', () async {
      await service.handleRealtime('couple:ended', {'couple_id': 12});
      await _settle();
      expect(service.isCoupleModeEnabled, isFalse);
      expect(events.whereType<CoupleEnded>(), hasLength(1));
    });

    test('couple:ended d\'un autre couple est ignoré', () async {
      await service.handleRealtime('couple:ended', {'couple_id': 999});
      expect(service.isCoupleModeEnabled, isTrue);
    });

    test('fin vue au recalage : GET couple null', () async {
      api.couple = null;
      await service.refresh();
      await _settle();
      expect(service.isCoupleModeEnabled, isFalse);
      expect(events.whereType<CoupleEnded>(), hasLength(1));
    });

    test('réseau coupé : le mode couple n\'est jamais désactivé en silence', () async {
      api.unreachable = true;
      await service.refresh();
      expect(service.isCoupleModeEnabled, isTrue);
    });

    test('en couple, relationWithUser distingue le partenaire des autres', () {
      expect(service.relationWithUser(45), CoupleRelation.partner);
      expect(service.relationWithUser(46), CoupleRelation.coupleWithSomeoneElse);
    });
  });

  group('relecture toutes les 10 s tant qu\'une demande est en attente', () {
    test('elle tourne pendant l\'attente et s\'arrête après l\'annulation', () async {
      await sendToMyriam();
      expect(service.isPolling, isTrue);
      final before = api.getCoupleCount;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(api.getCoupleCount, greaterThan(before + 1));

      await service.cancelCoupleRequest();
      expect(service.isPolling, isFalse);
      await _settle();
      final after = api.getCoupleCount;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(api.getCoupleCount, after);
    });

    test('elle s\'arrête en arrière-plan et reprend au retour', () async {
      await sendToMyriam();
      service.onPaused();
      expect(service.isPolling, isFalse);
      await service.onResumed();
      expect(service.isPolling, isTrue);
    });

    test('sans demande en attente, aucune relecture périodique', () async {
      await service.refresh();
      expect(service.isPolling, isFalse);
    });

    test('elle s\'arrête quand le couple se forme', () async {
      await sendToMyriam();
      api.sent = [];
      api.couple = contractCouple();
      await service.refresh();
      expect(service.isPolling, isFalse);
    });
  });

  test('reset (déconnexion) oublie tout', () async {
    await sendToMyriam();
    await service.reset();
    expect(service.pendingRequest, isNull);
    expect(service.isPolling, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('couple_pending_request'), isNull);
  });
}
