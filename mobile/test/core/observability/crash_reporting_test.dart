import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/observability/crash_reporting.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Le signalement des plantages ne part que si le DSN est fourni au build, et
/// ce qu'il emporte est réduit au strict nécessaire.
void main() {
  group('CrashReportingConfig', () {
    test('sans DSN : désactivé', () {
      expect(
        const CrashReportingConfig(dsn: '', environment: 'prod').isEnabled,
        isFalse,
      );
    });

    test('un DSN fait d\'espaces ne compte pas', () {
      expect(
        const CrashReportingConfig(dsn: '  \n', environment: 'prod').isEnabled,
        isFalse,
      );
    });

    test('avec un DSN : activé', () {
      expect(
        const CrashReportingConfig(
          dsn: 'https://cle@o0.ingest.example.com/1',
          environment: 'prod',
        ).isEnabled,
        isTrue,
      );
    });

    test('le build de test n\'a pas de DSN : aucun envoi par défaut', () {
      expect(const CrashReportingConfig.fromEnvironment().isEnabled, isFalse);
    });
  });

  group('startCrashReporting', () {
    test('sans DSN : n\'initialise rien, donc aucun appel réseau', () async {
      var initCalls = 0;
      final started = await startCrashReporting(
        const CrashReportingConfig(dsn: '', environment: 'prod'),
        init: (configure) async => initCalls++,
      );
      expect(started, isFalse);
      expect(initCalls, 0);
    });

    test('avec un DSN : initialise une fois', () async {
      var initCalls = 0;
      final started = await startCrashReporting(
        const CrashReportingConfig(
          dsn: 'https://cle@o0.ingest.example.com/1',
          environment: 'staging',
        ),
        init: (configure) async => initCalls++,
      );
      expect(started, isTrue);
      expect(initCalls, 1);
    });
  });

  group('options Sentry', () {
    late SentryFlutterOptions options;

    setUp(() async {
      options = SentryFlutterOptions();
      await startCrashReporting(
        const CrashReportingConfig(
          dsn: 'https://cle@o0.ingest.example.com/1',
          environment: 'staging',
          release: 'com.mazl.app@1.2.3+45',
        ),
        init: (configure) async => configure(options),
      );
    });

    test('renseignent l\'environnement, la release et le DSN', () {
      expect(options.dsn, 'https://cle@o0.ingest.example.com/1');
      expect(options.environment, 'staging');
      expect(options.release, 'com.mazl.app@1.2.3+45');
    });

    test(
      'sans release fournie, laissent Sentry la déduire de l\'app',
      () async {
        final auto = SentryFlutterOptions();
        await startCrashReporting(
          const CrashReportingConfig(
            dsn: 'https://cle@o0.ingest.example.com/1',
            environment: 'prod',
          ),
          init: (configure) async => configure(auto),
        );
        expect(auto.release, isNull);
      },
    );

    test('n\'envoient aucune donnée personnelle par défaut', () {
      expect(options.sendDefaultPii, isFalse);
    });

    test('ne joignent ni capture d\'écran ni hiérarchie de vues', () {
      expect(options.attachScreenshot, isFalse);
      expect(options.attachViewHierarchy, isFalse);
    });

    test(
      'ne joignent aucun corps de requête et ne suivent pas les requêtes',
      () {
        expect(options.maxRequestBodySize, MaxRequestBodySize.never);
        expect(options.captureFailedRequests, isFalse);
      },
    );

    test('ne mesurent ni sessions, ni performances, ni gestes', () {
      expect(options.enableAutoSessionTracking, isFalse);
      expect(options.tracesSampleRate ?? 0, 0);
      expect(options.enableUserInteractionBreadcrumbs, isFalse);
    });

    test('branchent le filtre qui retire e-mails et jetons', () {
      expect(options.beforeSend, same(scrubCrashEvent));
      expect(options.beforeBreadcrumb, same(scrubCrashBreadcrumb));
    });
  });

  group('scrubCrashEvent', () {
    const email = 'jeanne.exemple@example.com';
    const jwt =
        'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.c2lnbmF0dXJlRmljdGlmMTIz';

    SentryEvent dirtyEvent() => SentryEvent(
      message: SentryMessage(
        'Connexion refusée pour $email',
        template: 'Connexion refusée pour %s',
        params: [email],
      ),
      exceptions: [
        SentryException(
          type: 'ApiException',
          value: 'Requête rejetée, Authorization: Bearer $jwt ($email)',
        ),
      ],
      user: SentryUser(id: '42', email: email, ipAddress: '203.0.113.7'),
      request: SentryRequest(
        url: 'https://api.mazl.app/api/messages?to=$email',
        data: {'text': 'bonjour $email'},
        headers: {'authorization': 'Bearer $jwt'},
        cookies: 'session=$jwt',
      ),
      serverName: 'mac-de-jeanne',
      // ignore: deprecated_member_use
      extra: {'compte': email, 'jeton': 'token=$jwt', 'nombre': 3},
      contexts: Contexts()
        ..['flutter_error_details'] = {'information': 'pour $email'},
      breadcrumbs: [
        Breadcrumb(message: 'ouvre le fil de $email', data: {'jeton': jwt}),
      ],
    );

    test('aucun e-mail ni jeton ne survit dans l\'événement envoyé', () async {
      final scrubbed = await scrubCrashEvent(dirtyEvent(), Hint());
      final wire = jsonEncode(scrubbed!.toJson());
      expect(wire, isNot(contains('jeanne')));
      expect(wire, isNot(contains('@example.com')));
      expect(wire, isNot(contains('eyJ')));
      expect(wire, isNot(contains('c2lnbmF0dXJl')));
      expect(wire, isNot(contains('203.0.113.7')));
      expect(wire, isNot(contains('mac-de-jeanne')));
    });

    test('retire l\'utilisateur, la requête et le nom de machine', () async {
      final scrubbed = (await scrubCrashEvent(dirtyEvent(), Hint()))!;
      expect(scrubbed.user, isNull);
      expect(scrubbed.request, isNull);
      expect(scrubbed.serverName, isNull);
    });

    test('garde ce qui sert à diagnostiquer', () async {
      final scrubbed = (await scrubCrashEvent(dirtyEvent(), Hint()))!;
      expect(scrubbed.exceptions!.single.type, 'ApiException');
      expect(scrubbed.exceptions!.single.value, contains('Requête rejetée'));
      expect(scrubbed.message!.formatted, contains('Connexion refusée'));
      // ignore: deprecated_member_use
      expect(scrubbed.extra!['nombre'], 3);
    });
  });

  group('scrubCrashBreadcrumb', () {
    test('masque le message et les données', () {
      final out = scrubCrashBreadcrumb(
        Breadcrumb(
          message: 'écrit à jeanne@example.com',
          data: {'url': 'https://x.example/?token=abcd1234efgh'},
        ),
        Hint(),
      )!;
      final wire = jsonEncode(out.toJson());
      expect(wire, isNot(contains('jeanne')));
      expect(wire, isNot(contains('abcd1234efgh')));
    });

    test('ignore un fil d\'Ariane absent', () {
      expect(scrubCrashBreadcrumb(null, Hint()), isNull);
    });
  });
}
