import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La lane `beta` construit ce qui part sur TestFlight. Le DSN Sentry ne doit
/// entrer dans le build que s'il est fourni, sans jamais figurer dans le dépôt.
void main() {
  final fastfile = File('ios/fastlane/Fastfile').readAsStringSync();

  test('SENTRY_DSN est lu dans l\'environnement, jamais écrit en dur', () {
    expect(fastfile, contains('ENV.fetch("SENTRY_DSN", "")'));
    expect(fastfile, isNot(contains('ingest.sentry.io')));
    expect(fastfile, isNot(contains('ingest.de.sentry.io')));
  });

  test(
    '--dart-define=SENTRY_DSN n\'est ajouté que si la variable est remplie',
    () {
      expect(fastfile, contains('dsn.empty? ? ""'));
      expect(fastfile, contains('--dart-define=SENTRY_DSN='));
    },
  );

  test('le build de configuration reçoit ce define', () {
    final build = RegExp(
      r'flutter build ios --release --config-only[^\n]*',
    ).firstMatch(fastfile)!.group(0)!;
    expect(build, contains('#{dart_defines}'));
  });

  test('la valeur est échappée pour le shell', () {
    expect(fastfile, contains('Shellwords.escape(dsn)'));
    expect(fastfile, contains('require "shellwords"'));
  });

  test('la commande qui contient le DSN n\'est pas écrite dans le journal', () {
    expect(fastfile, contains('log: dsn.empty?'));
  });
}
