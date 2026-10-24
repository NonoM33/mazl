import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Régression : le 2026-10-24 un testeur TestFlight a vu l'application se
/// fermer d'elle-même. RevenueCat était configuré avec une clé « Test Store » :
/// dans un build de production le SDK affiche une alerte puis fait planter
/// l'application exprès quand on la ferme. Les achats passent désormais par le
/// plugin officiel `in_app_purchase` ; RevenueCat ne doit plus jamais revenir.
void main() {
  final lib = Directory('lib');
  final keyLiteral = RegExp(
    r'''['"](test|appl|goog|amzn|rcb)_[A-Za-z0-9]{16,}['"]''',
  );

  List<File> dartFiles(Directory dir) => dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test(
    'pubspec.yaml ne déclare ni purchases_flutter ni purchases_ui_flutter',
    () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('purchases_flutter')));
      expect(pubspec, isNot(contains('purchases_ui_flutter')));
      expect(pubspec.toLowerCase(), isNot(contains('revenuecat')));
    },
  );

  test('pubspec.lock ne résout aucun paquet RevenueCat', () {
    final lock = File('pubspec.lock').readAsStringSync();
    expect(lock, isNot(contains('purchases_flutter')));
    expect(lock, isNot(contains('purchases_ui_flutter')));
  });

  test("aucun fichier de lib/ n'importe package:purchases", () {
    final offenders = [
      for (final file in dartFiles(lib))
        if (file.readAsStringSync().contains('package:purchases')) file.path,
    ];
    expect(offenders, isEmpty);
  });

  test('aucun fichier de lib/ ne mentionne RevenueCat', () {
    final offenders = [
      for (final file in dartFiles(lib))
        if (file.readAsStringSync().toLowerCase().contains('revenuecat'))
          file.path,
    ];
    expect(offenders, isEmpty);
  });

  test(
    "aucune clé d'API de type RevenueCat (test_… / appl_… / goog_…) dans lib/",
    () {
      final offenders = [
        for (final file in dartFiles(lib))
          if (keyLiteral.hasMatch(file.readAsStringSync())) file.path,
      ];
      expect(offenders, isEmpty);
    },
  );

  test(
    'le détecteur de clé reconnaît la clé qui a fait planter TestFlight',
    () {
      expect(
        keyLiteral.hasMatch("const k = 'test_ABCDEFGHIJKLMNOPQRSTUVWXYZa';"),
        isTrue,
      );
      expect(
        keyLiteral.hasMatch('const k = "appl_abcdefghijklmnopqrstuvwxyz";'),
        isTrue,
      );
      expect(
        keyLiteral.hasMatch("const id = 'com.mazl.app.plus.1m';"),
        isFalse,
      );
    },
  );

  test('les fichiers natifs iOS ne tirent plus RevenueCat', () {
    for (final path in [
      'ios/Podfile.lock',
      'ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved',
      'ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved',
    ]) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final content = file.readAsStringSync().toLowerCase();
      expect(content, isNot(contains('revenuecat')), reason: path);
      expect(content, isNot(contains('purchases-hybrid-common')), reason: path);
      expect(content, isNot(contains('purchaseshybridcommon')), reason: path);
    }
  });
}
