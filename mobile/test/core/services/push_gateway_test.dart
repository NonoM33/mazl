import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/push_device_server.dart';
import 'package:mazl/core/services/push_gateway.dart';
import 'package:mazl/core/services/quiet_display.dart';

const _channelName = 'mazl/push';
const _token =
    'ab12cd34ef56ab12cd34ef56ab12cd34ef56ab12cd34ef56ab12cd34ef56ab12';
const _otherToken =
    '00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff';

class _FakeServer implements PushDeviceServer {
  final List<String> calls = [];
  final List<Map<String, String>> bodies = [];
  Object? failure;
  Completer<void>? hang;

  @override
  Future<void> register({
    required String token,
    required String environment,
  }) async {
    calls.add('PUT');
    bodies.add({'token': token, 'environment': environment});
    if (failure != null) throw failure!;
  }

  @override
  Future<void> unregister({required String token}) async {
    calls.add('DELETE');
    bodies.add({'token': token});
    if (hang != null) await hang!.future;
    if (failure != null) throw failure!;
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const codec = StandardMethodCodec();

  late _FakeServer server;
  late QuietDisplay quiet;
  late List<MethodCall> nativeCalls;
  late String authorization;
  Map<Object?, Object?>? launchTap;
  late List<Map<String, dynamic>> taps;
  late ApnsPushGateway gateway;

  setUp(() {
    server = _FakeServer();
    quiet = QuietDisplay();
    nativeCalls = [];
    authorization = 'notDetermined';
    launchTap = null;
    taps = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(_channelName),
      (call) async {
        nativeCalls.add(call);
        switch (call.method) {
          case 'authorizationStatus':
            return authorization;
          case 'requestAuthorization':
            return true;
          case 'takeLaunchTap':
            final tap = launchTap;
            launchTap = null;
            return tap;
        }
        return null;
      },
    );
    gateway = ApnsPushGateway(
      server: server,
      quiet: quiet,
      environment: 'sandbox',
      logoutTimeout: const Duration(milliseconds: 200),
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(_channelName),
      null,
    );
  });

  Future<void> nativeSays(String method, Object? arguments) async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      _channelName,
      codec.encodeMethodCall(MethodCall(method, arguments)),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> started() async {
    await gateway.start(onClick: taps.add);
  }

  List<String> methods() => nativeCalls.map((c) => c.method).toList();

  group('le jeton APNs est déclaré au serveur', () {
    test('jeton puis connexion : un seul PUT, avec le corps exact', () async {
      await started();
      await nativeSays('onToken', _token);
      expect(server.calls, isEmpty);

      await gateway.login(7);

      expect(server.calls, ['PUT']);
      expect(server.bodies.single, {'token': _token, 'environment': 'sandbox'});
    });

    test('connexion puis jeton : un seul PUT', () async {
      await started();
      await gateway.login(7);
      expect(server.calls, isEmpty);

      await nativeSays('onToken', _token);

      expect(server.calls, ['PUT']);
      expect(server.bodies.single['token'], _token);
    });

    test('le même jeton reçu deux fois : un seul PUT', () async {
      await started();
      await gateway.login(7);
      await nativeSays('onToken', _token);
      await nativeSays('onToken', _token);

      expect(server.calls, ['PUT']);
    });

    test('un nouveau jeton : un nouveau PUT', () async {
      await started();
      await gateway.login(7);
      await nativeSays('onToken', _token);
      await nativeSays('onToken', _otherToken);

      expect(server.calls, ['PUT', 'PUT']);
      expect(server.bodies.last['token'], _otherToken);
    });

    test('un autre membre sur le même appareil : un nouveau PUT', () async {
      await started();
      await nativeSays('onToken', _token);
      await gateway.login(7);
      await gateway.login(8);

      expect(server.calls, ['PUT', 'PUT']);
    });

    test('l\'environnement de production est transmis tel quel', () async {
      gateway = ApnsPushGateway(
        server: server,
        quiet: quiet,
        environment: 'production',
      );
      await started();
      await gateway.login(7);
      await nativeSays('onToken', _token);

      expect(server.bodies.single['environment'], 'production');
    });

    test('une erreur serveur est avalée, et le PUT sera retenté', () async {
      server.failure = StateError('503');
      await started();
      await gateway.login(7);
      await nativeSays('onToken', _token);
      expect(server.calls, ['PUT']);

      server.failure = null;
      await nativeSays('onToken', _token);

      expect(server.calls, ['PUT', 'PUT']);
    });

    test('une erreur de jeton natif ne plante pas', () async {
      await started();
      await nativeSays('onTokenError', 'no aps-environment');

      expect(server.calls, isEmpty);
    });
  });

  group('la déconnexion', () {
    test('supprime le jeton connu côté serveur', () async {
      await started();
      await gateway.login(7);
      await nativeSays('onToken', _token);

      await gateway.logout();

      expect(server.calls, ['PUT', 'DELETE']);
      expect(server.bodies.last, {'token': _token});
    });

    test('une erreur serveur ne la bloque pas', () async {
      await started();
      await gateway.login(7);
      await nativeSays('onToken', _token);
      server.failure = StateError('500');

      await gateway.logout();

      expect(server.calls, ['PUT', 'DELETE']);
    });

    test('n\'attend pas le serveur plus que le délai maximal', () async {
      await started();
      await gateway.login(7);
      await nativeSays('onToken', _token);
      server.hang = Completer<void>();

      await gateway.logout().timeout(const Duration(seconds: 2));

      expect(server.calls, ['PUT', 'DELETE']);
      server.hang!.complete();
    });

    test('oublie le membre : le jeton suivant n\'est plus déclaré', () async {
      await started();
      await gateway.login(7);
      await nativeSays('onToken', _token);
      await gateway.logout();
      server.calls.clear();

      await nativeSays('onToken', _otherToken);

      expect(server.calls, isEmpty);
    });

    test('sans jeton connu : rien à supprimer', () async {
      await started();
      await gateway.login(7);
      await gateway.logout();

      expect(server.calls, isEmpty);
    });

    test('se reconnecter déclare de nouveau le même jeton', () async {
      await started();
      await gateway.login(7);
      await nativeSays('onToken', _token);
      await gateway.logout();
      await gateway.login(7);

      expect(server.calls, ['PUT', 'DELETE', 'PUT']);
    });
  });

  group('un toucher sur une notification', () {
    test('arrive à onClick sans la clé aps', () async {
      await started();

      await nativeSays('onTap', {
        'aps': {'alert': 'Salut'},
        'type': 'new_message',
        'conversation_id': 41,
      });

      expect(taps, [
        {'type': 'new_message', 'conversation_id': 41},
      ]);
    });

    test('garde les valeurs imbriquées sous des clés texte', () async {
      await started();

      await nativeSays('onTap', {
        'type': 'new_match',
        'extra': {
          'ids': [1, 2],
        },
      });

      expect(taps.single['extra'], {
        'ids': [1, 2],
      });
    });

    test('le toucher qui a lancé l\'app est pris au démarrage', () async {
      launchTap = {
        'aps': {'alert': 'Salut'},
        'type': 'new_message',
        'conversation_id': 41,
      };

      await started();

      expect(methods(), contains('takeLaunchTap'));
      expect(taps, [
        {'type': 'new_message', 'conversation_id': 41},
      ]);
    });

    test('sans toucher de lancement, onClick n\'est pas appelé', () async {
      await started();

      expect(taps, isEmpty);
    });

    test('le démarrage demande l\'enregistrement APNs', () async {
      await started();

      expect(methods(), contains('registerForRemoteNotifications'));
    });
  });

  group('le mode Shabbat', () {
    test('est transmis au natif au démarrage', () async {
      quiet.enter();
      await started();

      final call = nativeCalls.firstWhere((c) => c.method == 'setQuiet');
      expect(call.arguments, true);
    });

    test('est retransmis à chaque changement', () async {
      await started();
      nativeCalls.clear();

      quiet.enter();
      await Future<void>.delayed(Duration.zero);
      quiet.leave();
      await Future<void>.delayed(Duration.zero);

      final sent = nativeCalls
          .where((c) => c.method == 'setQuiet')
          .map((c) => c.arguments)
          .toList();
      expect(sent, [true, false]);
    });
  });

  group('l\'autorisation', () {
    test('demandée seulement si jamais décidée', () async {
      authorization = 'notDetermined';
      await started();

      await gateway.askPermission();

      expect(methods(), contains('requestAuthorization'));
    });

    for (final status in ['denied', 'authorized', 'provisional', 'ephemeral']) {
      test('pas redemandée quand le statut est $status', () async {
        authorization = status;
        await started();

        await gateway.askPermission();

        expect(methods(), isNot(contains('requestAuthorization')));
      });
    }
  });

  test('sans plugin natif (tests, Android), rien ne plante', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(_channelName),
      null,
    );

    await started();
    await gateway.askPermission();
    await gateway.login(7);
    await gateway.logout();

    expect(server.calls, isEmpty);
  });
}
