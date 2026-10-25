import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/plist_reader.dart';

/// `PrivacyInfo.xcprivacy` est exigé par Apple (cible Runner). Ce test relit le
/// fichier et le projet Xcode d'après les règles d'Apple : un manifeste absent
/// du projet n'est pas copié dans l'app, un code de raison inventé est refusé
/// à l'envoi.
void main() {
  const manifestPath = 'ios/Runner/PrivacyInfo.xcprivacy';
  const pbxprojPath = 'ios/Runner.xcodeproj/project.pbxproj';

  // Types de données et finalités : la liste officielle d'Apple.
  const appleDataTypes = <String>{
    'Name',
    'EmailAddress',
    'PhoneNumber',
    'PhysicalAddress',
    'OtherUserContactInfo',
    'Contacts',
    'EmailsOrTextMessages',
    'PhotosorVideos',
    'AudioData',
    'GameplayContent',
    'CustomerSupport',
    'OtherUserContent',
    'Health',
    'Fitness',
    'PaymentInfo',
    'CreditInfo',
    'OtherFinancialInfo',
    'PreciseLocation',
    'CoarseLocation',
    'SensitiveInfo',
    'BrowsingHistory',
    'SearchHistory',
    'UserID',
    'DeviceID',
    'PurchaseHistory',
    'ProductInteraction',
    'AdvertisingData',
    'OtherUsageData',
    'CrashData',
    'PerformanceData',
    'OtherDiagnosticData',
    'EnvironmentScanning',
    'Hands',
    'Head',
    'OtherDataTypes',
  };
  const applePurposes = <String>{
    'ThirdPartyAdvertising',
    'DeveloperAdvertising',
    'Analytics',
    'ProductPersonalization',
    'AppFunctionality',
    'Other',
  };
  // Raisons valables par catégorie d'API (documentation d'Apple).
  const appleReasons = <String, Set<String>>{
    'NSPrivacyAccessedAPICategoryFileTimestamp': {
      'DDA9.1',
      'C617.1',
      '3B52.1',
      '0A2A.1',
    },
    'NSPrivacyAccessedAPICategorySystemBootTime': {
      '35F9.1',
      '8FFB.1',
      '3D61.1',
    },
    'NSPrivacyAccessedAPICategoryDiskSpace': {
      '85F4.1',
      'E174.1',
      '7D9E.1',
      'B728.1',
    },
    'NSPrivacyAccessedAPICategoryActiveKeyboards': {'3EC4.1', '54BD.1'},
    'NSPrivacyAccessedAPICategoryUserDefaults': {
      'CA92.1',
      '1C8F.1',
      'C56D.1',
      'AC6B.1',
    },
  };

  test('le fichier existe et se lit', () {
    expect(File(manifestPath).existsSync(), isTrue, reason: manifestPath);
    expect(parsePlist(File(manifestPath).readAsStringSync()), isA<Map>());
  });

  late Map<String, Object?> manifest;
  setUpAll(() {
    final file = File(manifestPath);
    manifest = file.existsSync()
        ? parsePlist(file.readAsStringSync())! as Map<String, Object?>
        : <String, Object?>{};
  });

  group('projet Xcode', () {
    late String pbxproj;
    setUpAll(() => pbxproj = File(pbxprojPath).readAsStringSync());

    test('le fichier est référencé dans le groupe Runner', () {
      expect(
        pbxproj,
        contains('path = PrivacyInfo.xcprivacy; sourceTree = "<group>";'),
      );
    });

    test('il est copié dans les ressources de la cible Runner', () {
      final reference = RegExp(
        r'(\w{24}) /\* PrivacyInfo\.xcprivacy \*/ = \{isa = PBXFileReference',
      ).firstMatch(pbxproj)!.group(1)!;
      final buildFile = RegExp(
        '(\\w{24}) /\\* PrivacyInfo\\.xcprivacy in Resources \\*/ = '
        '\\{isa = PBXBuildFile; fileRef = $reference',
      ).firstMatch(pbxproj)!.group(1)!;

      final runnerTarget = RegExp(
        r'/\* Runner \*/ = \{[^}]*?isa = PBXNativeTarget;.*?buildPhases = \((.*?)\);',
        dotAll: true,
      ).firstMatch(pbxproj)!.group(1)!;
      final resourcesPhase = RegExp(
        r'(\w{24}) /\* Resources \*/',
      ).allMatches(runnerTarget).single.group(1)!;
      final phaseBody = RegExp(
        '$resourcesPhase /\\* Resources \\*/ = \\{.*?files = \\((.*?)\\);',
        dotAll: true,
      ).firstMatch(pbxproj)!.group(1)!;
      expect(phaseBody, contains(buildFile));

      expect(
        RegExp('$buildFile /\\* PrivacyInfo').allMatches(pbxproj).length,
        greaterThanOrEqualTo(2),
        reason: 'défini une fois, utilisé une fois',
      );
    });
  });

  test('aucun suivi, aucun domaine de suivi', () {
    expect(manifest['NSPrivacyTracking'], isFalse);
    expect(manifest['NSPrivacyTrackingDomains'], isEmpty);
  });

  group('données collectées', () {
    late List<Map<String, Object?>> collected;
    setUpAll(() {
      collected = (manifest['NSPrivacyCollectedDataTypes']! as List)
          .cast<Map<String, Object?>>();
    });

    String shortName(Map<String, Object?> entry) =>
        (entry['NSPrivacyCollectedDataType']! as String).replaceFirst(
          'NSPrivacyCollectedDataType',
          '',
        );

    test('chaque entrée a un type, des finalités, « lié » et « suivi »', () {
      expect(collected, isNotEmpty);
      for (final entry in collected) {
        expect(appleDataTypes, contains(shortName(entry)));
        expect(entry['NSPrivacyCollectedDataTypeLinked'], isA<bool>());
        expect(entry['NSPrivacyCollectedDataTypeTracking'], isA<bool>());
        expect(entry['NSPrivacyCollectedDataTypePurposes'], isA<List>());
      }
    });

    test('aucun type déclaré deux fois', () {
      final names = collected.map(shortName).toList();
      expect(names.toSet().length, names.length);
    });

    test('rien n\'est utilisé pour le suivi, tout sert au fonctionnement', () {
      for (final entry in collected) {
        expect(
          entry['NSPrivacyCollectedDataTypeTracking'],
          isFalse,
          reason: shortName(entry),
        );
        final purposes = (entry['NSPrivacyCollectedDataTypePurposes']! as List)
            .cast<String>()
            .map(
              (p) => p.replaceFirst('NSPrivacyCollectedDataTypePurpose', ''),
            );
        expect(applePurposes, containsAll(purposes), reason: shortName(entry));
        expect(purposes, ['AppFunctionality'], reason: shortName(entry));
      }
    });

    test('tout est lié à l\'identité du membre', () {
      for (final entry in collected) {
        expect(
          entry['NSPrivacyCollectedDataTypeLinked'],
          isTrue,
          reason: shortName(entry),
        );
      }
    });

    test('couvre ce que MAZL envoie à ses serveurs', () {
      expect(
        collected.map(shortName),
        containsAll(<String>[
          'EmailAddress', // connexion Apple / Google
          'Name', // nom affiché
          'CoarseLocation', // ville et coordonnées dégradées
          'PhotosorVideos', // photos de profil, photos du chat
          'AudioData', // messages vocaux
          'EmailsOrTextMessages', // messages du chat
          'SensitiveInfo', // pratique religieuse, gabarit du visage
          'UserID', // identifiant de membre
          'DeviceID', // identifiant OneSignal de l'appareil
          'PurchaseHistory', // abonnement mazl+, Boosts
          'CrashData', // Sentry, quand le DSN est fourni
          'PerformanceData', // déclaré aussi par le manifeste de Sentry
          'OtherDiagnosticData', // appareil et système joints à un plantage
        ]),
      );
    });
  });

  group('API à raison requise', () {
    late List<Map<String, Object?>> accessed;
    setUpAll(() {
      accessed = (manifest['NSPrivacyAccessedAPITypes']! as List)
          .cast<Map<String, Object?>>();
    });

    test('chaque catégorie est connue d\'Apple, avec des raisons valables', () {
      expect(accessed, isNotEmpty);
      for (final entry in accessed) {
        final category = entry['NSPrivacyAccessedAPIType']! as String;
        expect(appleReasons, contains(category));
        final reasons = (entry['NSPrivacyAccessedAPITypeReasons']! as List)
            .cast<String>();
        expect(reasons, isNotEmpty, reason: category);
        expect(appleReasons[category]!, containsAll(reasons), reason: category);
      }
    });

    test('déclare UserDefaults, utilisé par shared_preferences', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('shared_preferences:'));
      final userDefaults = accessed.singleWhere(
        (e) =>
            e['NSPrivacyAccessedAPIType'] ==
            'NSPrivacyAccessedAPICategoryUserDefaults',
      );
      expect(userDefaults['NSPrivacyAccessedAPITypeReasons'], ['CA92.1']);
    });

    test('ne déclare aucune catégorie en double', () {
      final categories = accessed.map((e) => e['NSPrivacyAccessedAPIType']);
      expect(categories.toSet().length, categories.length);
    });
  });
}
