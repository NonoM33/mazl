import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/profile.dart';

void main() {
  test('only the ML Kit adapter imports google_mlkit_face_detection', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('google_mlkit_face_detection'))
        .map((f) => f.path)
        .toList();
    expect(offenders, ['lib/core/vision/mlkit_face_pose_detector.dart']);
  });

  group('Profile verification flags', () {
    final base = {'id': 1, 'user_id': 2};

    test('default to false when the server does not send them', () {
      final profile = Profile.fromJson(base);
      expect(profile.photoVerified, isFalse);
      expect(profile.identityVerified, isFalse);
      expect(profile.isVerified, isFalse);
    });

    test('are read from photo_verified and identity_verified', () {
      final profile = Profile.fromJson({
        ...base,
        'is_verified': true,
        'photo_verified': true,
        'identity_verified': false,
      });
      expect(profile.isVerified, isTrue);
      expect(profile.photoVerified, isTrue);
      expect(profile.identityVerified, isFalse);
    });
  });
}
