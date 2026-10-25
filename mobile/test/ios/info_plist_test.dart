import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/plist_reader.dart';

/// Les réglages iOS de la v1 : iPhone seul, portrait seul, pas de déclaration
/// d'export à refaire à chaque envoi, et un texte de micro qui dit vrai.
void main() {
  final plist =
      parsePlist(File('ios/Runner/Info.plist').readAsStringSync())!
          as Map<String, Object?>;
  final pbxproj = File(
    'ios/Runner.xcodeproj/project.pbxproj',
  ).readAsStringSync();

  test(
    'ITSAppUsesNonExemptEncryption vaut false (HTTPS et Keychain d\'Apple)',
    () {
      expect(plist['ITSAppUsesNonExemptEncryption'], isFalse);
    },
  );

  test('l\'iPhone reste en portrait, comme le code de main.dart', () {
    expect(plist['UISupportedInterfaceOrientations'], [
      'UIInterfaceOrientationPortrait',
    ]);
  });

  test('plus aucune orientation iPad : l\'app est réservée à l\'iPhone', () {
    expect(
      plist.keys,
      isNot(contains('UISupportedInterfaceOrientations~ipad')),
    );
  });

  test('main.dart n\'autorise que le portrait', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('DeviceOrientation.portraitUp'));
    expect(main, isNot(contains('landscape')));
  });

  group('TARGETED_DEVICE_FAMILY', () {
    final values = RegExp(
      r'TARGETED_DEVICE_FAMILY = ([^;]+);',
    ).allMatches(pbxproj).map((m) => m.group(1)!.replaceAll('"', '')).toList();

    test('est défini', () => expect(values, isNotEmpty));

    test('vaut 1 (iPhone) dans toutes les configurations', () {
      expect(values.toSet(), {'1'});
    });
  });

  group('texte du micro', () {
    // Le micro ne sert qu'à enregistrer les messages vocaux du chat : aucun
    // appel vidéo n'existe dans l'app.
    final callWords = RegExp(
      r'appel|vid[ée]o|\bcalls?\b|llamada|звон|וידאו|שיחות',
      caseSensitive: false,
    );
    final voiceWords = RegExp(
      r'vocau|voice|voz|голос|קולי',
      caseSensitive: false,
    );

    for (final language in ['fr', 'en', 'he', 'es', 'ru']) {
      test('$language : parle des messages vocaux, pas d\'appels vidéo', () {
        final strings = File(
          'ios/Runner/$language.lproj/InfoPlist.strings',
        ).readAsStringSync();
        final line = strings
            .split('\n')
            .singleWhere((l) => l.startsWith('"NSMicrophoneUsageDescription"'));
        expect(line, matches(voiceWords), reason: line);
        expect(line, isNot(matches(callWords)), reason: line);
      });
    }

    test('Info.plist (français) dit la même chose', () {
      final text = plist['NSMicrophoneUsageDescription']! as String;
      expect(text, matches(voiceWords));
      expect(text, isNot(matches(callWords)));
    });
  });
}
