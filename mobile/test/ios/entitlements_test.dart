import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/plist_reader.dart';

/// Les notifications push d'une app envoyée à l'App Store passent par le
/// serveur APNs de production. Avec `development` dans l'archive, TestFlight
/// et l'App Store ne reçoivent jamais rien. Le debug garde `development`.
void main() {
  Map<String, Object?> load(String path) =>
      parsePlist(File(path).readAsStringSync())! as Map<String, Object?>;

  final pbxproj = File(
    'ios/Runner.xcodeproj/project.pbxproj',
  ).readAsStringSync();

  /// La valeur de CODE_SIGN_ENTITLEMENTS de la configuration [name] de la
  /// cible Runner (celle qui porte PRODUCT_BUNDLE_IDENTIFIER = com.mazl.app).
  String entitlementsOf(String name) {
    final configs = RegExp(
      r'isa = XCBuildConfiguration;(.*?)name = (\w+);',
      dotAll: true,
    ).allMatches(pbxproj);
    final runner = configs.where(
      (m) =>
          m.group(2) == name &&
          m.group(1)!.contains('PRODUCT_BUNDLE_IDENTIFIER = com.mazl.app;'),
    );
    expect(runner, hasLength(1), reason: 'configuration Runner $name');
    return RegExp(
      r'CODE_SIGN_ENTITLEMENTS = ([^;]+);',
    ).firstMatch(runner.single.group(1)!)!.group(1)!;
  }

  test('la configuration Debug garde l\'environnement de développement', () {
    final path = entitlementsOf('Debug');
    expect(load('ios/$path')['aps-environment'], 'development');
  });

  for (final configuration in ['Release', 'Profile']) {
    test('la configuration $configuration envoie vers APNs de production', () {
      final path = entitlementsOf(configuration);
      expect(load('ios/$path')['aps-environment'], 'production');
    });
  }

  test('la lane fastlane construit la configuration Release', () {
    final fastfile = File('ios/fastlane/Fastfile').readAsStringSync();
    expect(fastfile, contains('configuration: "Release"'));
    expect(fastfile, contains('export_method: "app-store"'));
  });

  test('les deux fichiers ne diffèrent que par aps-environment', () {
    final debug = load('ios/Runner/Runner.entitlements');
    final release = load('ios/Runner/RunnerRelease.entitlements');
    debug.remove('aps-environment');
    release.remove('aps-environment');
    expect(release, debug);
    expect(release.keys, contains('com.apple.developer.applesignin'));
    expect(
      release.keys,
      contains('com.apple.developer.nfc.readersession.formats'),
    );
  });

  test('le fichier de release est dans le groupe Runner du projet Xcode', () {
    expect(
      pbxproj,
      contains('path = RunnerRelease.entitlements; sourceTree = "<group>";'),
    );
  });
}
