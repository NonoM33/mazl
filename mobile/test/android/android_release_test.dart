import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Build de release Android (test fermé Play), qui doit rester sain :
/// pas de sauvegarde automatique des données de l'app dans le cloud de Google,
/// et les règles R8 que `build.gradle.kts` annonce doivent exister.
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  final rulesFile = File('android/app/proguard-rules.pro');

  test(
    'allowBackup est désactivé (jetons et messages hors du cloud Google)',
    () {
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, isNot(contains('android:allowBackup="true"')));
    },
  );

  test('le fichier de règles référencé par Gradle existe', () {
    expect(gradle, contains('"proguard-rules.pro"'));
    expect(rulesFile.existsSync(), isTrue, reason: rulesFile.path);
  });

  group('règles R8', () {
    late String rules;
    setUpAll(() => rules = rulesFile.readAsStringSync());

    test(
      'couvrent Gson, que flutter_local_notifications lit par réflexion',
      () {
        expect(
          File('pubspec.yaml').readAsStringSync(),
          contains('flutter_local_notifications:'),
        );
        expect(rules, contains('com.google.gson.reflect.TypeToken'));
        expect(rules, contains('-keepattributes Signature'));
      },
    );

    test('couvrent la lecture NFC des passeports', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('dmrtd:'));
      expect(rules, contains('im.nfc.flutter_nfc_kit'));
    });

    test('ne désactivent pas la réduction du code', () {
      expect(rules, isNot(contains('-dontshrink')));
      expect(rules, isNot(contains('-dontobfuscate')));
      expect(rules, isNot(contains('-dontoptimize')));
    });
  });

  // Le même identifiant que l'app iOS ; figé dès le premier envoi sur Play.
  test('l\'identifiant d\'application est celui de l\'app iOS', () {
    expect(gradle, contains('applicationId = "com.mazl.app"'));
  });

  test('minSdk couvre flutter_nfc_kit (Android 8)', () {
    expect(gradle, contains('minSdk = 26'));
  });

  test('les écritures ML Kit non embarquées ne cassent pas R8', () {
    final rules = rulesFile.readAsStringSync();
    expect(rules, contains('-dontwarn com.google.mlkit.vision.text.chinese.**'));
  });
}
