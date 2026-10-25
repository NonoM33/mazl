import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `main.dart` ne se lance pas dans un test (StoreKit, OneSignal, moteur
/// natif) : ce garde-fou lit sa source et refuse qu'on retire l'un des filets
/// de sécurité du démarrage, ou qu'on les place dans le mauvais ordre.
void main() {
  final main = File('lib/main.dart').readAsStringSync();

  int at(String needle) {
    final index = main.indexOf(needle);
    expect(
      index,
      greaterThanOrEqualTo(0),
      reason: '« $needle » absent de main.dart',
    );
    return index;
  }

  test('debugPrint est rendu muet avant tout autre appel', () {
    expect(at('silenceDebugPrintOutsideDebug();'), lessThan(at('_start()')));
  });

  test('les gestionnaires d\'erreurs sont posés avant Sentry', () {
    expect(
      at('installGlobalErrorHandlers('),
      lessThan(at('startCrashReporting(')),
    );
  });

  test('Sentry se configure par dart-define, sans DSN en dur', () {
    expect(main, contains('CrashReportingConfig.fromEnvironment()'));
    expect(main, isNot(contains('ingest.sentry.io')));
  });

  test('les services du démarrage passent par les étapes protégées', () {
    final steps = at('runStartupSteps(');
    for (final service in [
      'SubscriptionService().initialize()',
      'AuthService().initialize()',
      'PushNotificationService().initialize()',
    ]) {
      expect(at(service), greaterThan(steps), reason: service);
      expect(main, isNot(contains('await $service;')), reason: service);
    }
  });

  test('runApp vient après les étapes de démarrage', () {
    expect(at('runApp('), greaterThan(at('runStartupSteps(')));
  });
}
