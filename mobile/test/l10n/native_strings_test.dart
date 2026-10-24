import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/l10n/app_language.dart';

/// Les textes que le système affiche lui-même, hors Flutter : les demandes
/// d'autorisation iOS (`Info.plist`, traduites dans
/// `<langue>.lproj/InfoPlist.strings`) et les déclarations de langue iOS et
/// Android.
///
/// Sans traduction, iOS affiche le texte de `Info.plist` (français) à un
/// membre qui a choisi l'hébreu ; sans déclaration dans le projet Xcode, le
/// fichier existe mais n'est jamais copié dans l'app.
void main() {
  const infoPlistPath = 'ios/Runner/Info.plist';
  const pbxprojPath = 'ios/Runner.xcodeproj/project.pbxproj';
  const manifestPath = 'android/app/src/main/AndroidManifest.xml';
  const localesConfigPath = 'android/app/src/main/res/xml/locales_config.xml';

  final infoPlist = File(infoPlistPath).readAsStringSync();
  final usageDescriptions = usageDescriptionsIn(infoPlist);
  final languages = AppLanguage.values.map((l) => l.code).toSet();

  test('Info.plist demande bien des autorisations', () {
    expect(
      usageDescriptions.keys,
      containsAll(<String>[
        'NSCameraUsageDescription',
        'NSMicrophoneUsageDescription',
        'NFCReaderUsageDescription',
      ]),
    );
  });

  for (final language in languages) {
    group('$language.lproj/InfoPlist.strings', () {
      final file = File('ios/Runner/$language.lproj/InfoPlist.strings');
      final strings = file.existsSync()
          ? parseStringsFile(file.readAsStringSync())
          : const <String, String>{};

      test('existe', () {
        expect(file.existsSync(), isTrue, reason: file.path);
      });

      test(
        'traduit chaque texte d\'autorisation de Info.plist, et rien d\'autre',
        () {
          expect(strings.keys.toSet(), usageDescriptions.keys.toSet());
          for (final entry in strings.entries) {
            expect(entry.value.trim(), isNotEmpty, reason: entry.key);
          }
        },
      );

      test('ne promet pas d\'effacement « sous 6 h »', () {
        final nfc = strings['NFCReaderUsageDescription'] ?? '';
        expect(nfc, isNot(matches(_sixHours)), reason: nfc);
      });
    });
  }

  test('le français reprend mot pour mot les textes de Info.plist', () {
    final french = parseStringsFile(
      File('ios/Runner/fr.lproj/InfoPlist.strings').readAsStringSync(),
    );
    expect(french, usageDescriptions);
  });

  test('Info.plist déclare les langues de l\'app (CFBundleLocalizations)', () {
    expect(arrayIn(infoPlist, 'CFBundleLocalizations').toSet(), languages);
  });

  test(
    'le projet Xcode connaît chaque langue et copie chaque InfoPlist.strings',
    () {
      final pbxproj = File(pbxprojPath).readAsStringSync();
      final knownRegions = RegExp(r'knownRegions = \(([^)]*)\);')
          .firstMatch(pbxproj)!
          .group(1)!
          .split(',')
          .map((region) => region.trim())
          .where((region) => region.isNotEmpty)
          .toSet();
      expect(knownRegions, containsAll(languages));
      for (final language in languages) {
        expect(
          pbxproj,
          contains('path = $language.lproj/InfoPlist.strings;'),
          reason: '$language.lproj/InfoPlist.strings absent du projet Xcode',
        );
      }
      expect(pbxproj, contains('/* InfoPlist.strings in Resources */,'));
    },
  );

  test(
    'Android lit l\'hébreu de droite à gauche et propose les mêmes langues',
    () {
      final manifest = File(manifestPath).readAsStringSync();
      expect(manifest, contains('android:supportsRtl="true"'));
      expect(manifest, contains('android:localeConfig="@xml/locales_config"'));
      final locales = RegExp(r'<locale android:name="([^"]+)"')
          .allMatches(File(localesConfigPath).readAsStringSync())
          .map((match) => match.group(1)!)
          .toSet();
      expect(locales, languages);
    },
  );

  test('le lecteur de .strings refuse une ligne qu\'il ne comprend pas', () {
    expect(
      () => parseStringsFile('"Key" = "sans point-virgule"'),
      throwsFormatException,
    );
    expect(parseStringsFile('/* note */\n"Key" = "a \\"b\\"";'), {
      'Key': 'a "b"',
    });
  });
}

final _sixHours = RegExp(
  r'6\s*(h\b|heures?|hours?|horas?|час|שעות)',
  caseSensitive: false,
);

/// Les clés `NS…UsageDescription` (et `NFCReaderUsageDescription`) de
/// `Info.plist`, avec leur texte.
Map<String, String> usageDescriptionsIn(String plist) {
  final entry = RegExp(
    r'<key>((?:NS\w+|NFCReader)UsageDescription)</key>\s*<string>([^<]*)</string>',
  );
  return {
    for (final match in entry.allMatches(plist))
      match.group(1)!: _unescapeXml(match.group(2)!),
  };
}

/// Les `<string>` d'un tableau de `Info.plist`.
List<String> arrayIn(String plist, String key) {
  final array = RegExp(
    '<key>$key</key>\\s*<array>(.*?)</array>',
    dotAll: true,
  ).firstMatch(plist);
  if (array == null) return const [];
  return RegExp(
    r'<string>([^<]*)</string>',
  ).allMatches(array.group(1)!).map((match) => match.group(1)!).toList();
}

/// Un fichier `.strings` d'Apple : `"clé" = "valeur";`, commentaires `/* */`
/// et `//`. Toute autre ligne est une erreur : iOS ignorerait le fichier.
Map<String, String> parseStringsFile(String source) {
  final withoutComments = source
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
      .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');
  final line = RegExp(r'^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)";$');
  final result = <String, String>{};
  for (final raw in withoutComments.split('\n')) {
    final text = raw.trim();
    if (text.isEmpty) continue;
    final match = line.firstMatch(text);
    if (match == null) throw FormatException('ligne .strings illisible', text);
    result[_unescapeStrings(match.group(1)!)] = _unescapeStrings(
      match.group(2)!,
    );
  }
  return result;
}

String _unescapeStrings(String text) => text.replaceAllMapped(
  RegExp(r'\\(.)'),
  (m) => m.group(1) == 'n' ? '\n' : m.group(1)!,
);

String _unescapeXml(String text) => text
    .replaceAll('&apos;', "'")
    .replaceAll('&quot;', '"')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');
