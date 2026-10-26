import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// permission_handler on iOS compiles a permission only when its macro is set in
// the Podfile (GCC_PREPROCESSOR_DEFINITIONS, see the plugin's README); without it,
// `Permission.camera.request()` answers "permanently denied" even when the member
// allowed the camera in Settings. Seen on the iPhone Duo on 2026-10-26: the
// selfie check kept asking for the camera.

/// The plugin's macro for a `Permission.<name>` getter.
const _macros = {
  'camera': 'PERMISSION_CAMERA',
  'microphone': 'PERMISSION_MICROPHONE',
  'photos': 'PERMISSION_PHOTOS',
  'notification': 'PERMISSION_NOTIFICATIONS',
  'location': 'PERMISSION_LOCATION',
  'locationWhenInUse': 'PERMISSION_LOCATION_WHENINUSE',
  'contacts': 'PERMISSION_CONTACTS',
};

void main() {
  test('every permission the app requests is compiled in on iOS', () {
    final used = <String>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final match in RegExp(
        r'\bPermission\.(\w+)\.(request|status)',
      ).allMatches(file.readAsStringSync())) {
        used.add(match.group(1)!);
      }
    }
    expect(used, contains('camera'), reason: 'the selfie check asks for it');
    final podfile = File('ios/Podfile').readAsStringSync();
    for (final permission in used) {
      final macro = _macros[permission];
      expect(macro, isNotNull, reason: 'add the macro of Permission.$permission');
      expect(
        podfile,
        contains("'$macro=1'"),
        reason: 'Permission.$permission is requested but $macro is not set',
      );
    }
  });
}
