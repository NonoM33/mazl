import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/push_gateway.dart';
import 'package:mazl/core/services/push_navigator.dart';
import 'package:mazl/core/services/push_notification_service.dart';

class _FakeGateway implements PushGateway {
  final List<String> log = [];
  void Function(Map<String, dynamic> data)? onClick;

  /// While set, the system permission dialog stays open.
  Completer<void>? permissionDialog;

  @override
  Future<void> start({
    required void Function(Map<String, dynamic> data) onClick,
  }) async {
    log.add('start');
    this.onClick = onClick;
  }

  @override
  Future<void> login(int userId) async => log.add('login $userId');

  @override
  Future<void> logout() async => log.add('logout');

  @override
  Future<void> askPermission() async {
    log.add('askPermission');
    await permissionDialog?.future;
  }
}

void main() {
  late _FakeGateway gateway;
  late List<String> opened;
  late PushNotificationService service;

  setUp(() {
    gateway = _FakeGateway();
    opened = [];
    service = PushNotificationService.withGateway(
      gateway,
      PushNavigator(isReady: () => true, open: opened.add),
    );
  });

  group('la permission des notifications', () {
    test('n\'est plus demandée au lancement, avant la connexion', () async {
      await service.initialize();

      expect(gateway.log, ['start']);
    });

    test('est demandée une fois le membre connecté', () async {
      await service.initialize();
      await service.loginUser(5);

      expect(gateway.log, ['start', 'login 5', 'askPermission']);
    });

    test('une seule fois par session, même à chaque connexion', () async {
      await service.initialize();
      await service.loginUser(5);
      await service.loginUser(5);

      expect(gateway.log.where((e) => e == 'askPermission'), hasLength(1));
    });

    test('ne fait pas attendre la connexion derrière la fenêtre iOS', () async {
      gateway.permissionDialog = Completer<void>();
      await service.initialize();

      // Si loginUser attendait la réponse du membre, ceci ne finirait jamais.
      await service.loginUser(5).timeout(const Duration(seconds: 2));

      expect(gateway.log, contains('askPermission'));
      gateway.permissionDialog!.complete();
    });

    test('une erreur de la fenêtre n\'empêche pas la connexion', () async {
      final failing = _ThrowingGateway();
      final failingService = PushNotificationService.withGateway(
        failing,
        PushNavigator(isReady: () => true, open: opened.add),
      );

      await failingService.loginUser(5);
      await Future<void>.delayed(Duration.zero);

      expect(failing.log, ['login 5', 'askPermission']);
    });
  });

  group('un toucher sur une notification', () {
    test('mène à la conversation', () async {
      await service.initialize();

      gateway.onClick!({'type': 'new_message', 'conversation_id': 41});

      expect(opened, ['/chat/41']);
    });

    test('un ancien type ne plante pas et ne navigue pas', () async {
      await service.initialize();

      gateway.onClick!({'type': 'event_reminder', 'eventId': 3});
      gateway.onClick!(const {});

      expect(opened, isEmpty);
    });
  });

  test('la déconnexion passe par la passerelle', () async {
    await service.logoutUser();

    expect(gateway.log, ['logout']);
  });
}

class _ThrowingGateway extends _FakeGateway {
  @override
  Future<void> askPermission() async {
    log.add('askPermission');
    throw StateError('permission dialog failed');
  }
}
