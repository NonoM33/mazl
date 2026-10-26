import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/vision/rotation_search.dart';

void main() {
  test('tries the sensor orientation first, then every other quarter turn', () {
    expect(RotationSearch(90).candidates(), [90, 180, 270, 0]);
    expect(RotationSearch(270).candidates(), [270, 0, 90, 180]);
  });

  test('keeps the turn that found a face', () {
    final search = RotationSearch(90)..record(180);
    expect(search.candidates(), [180]);
  });

  test('searches again after frames in a row without a face', () {
    final search = RotationSearch(90, missesBeforeSearch: 3)..record(180);
    search
      ..record(null)
      ..record(null);
    expect(search.candidates(), [180]);
    search.record(null);
    expect(search.candidates(), [90, 180, 270, 0]);
  });

  test('a face found again resets the count of misses', () {
    final search = RotationSearch(90, missesBeforeSearch: 2)
      ..record(0)
      ..record(null)
      ..record(0)
      ..record(null);
    expect(search.candidates(), [0]);
  });

  test('a frame already standing in portrait is tried upright first', () {
    expect(firstRotation(720, 1280, 90), 0);
    expect(RotationSearch(firstRotation(720, 1280, 90)).candidates().first, 0);
  });

  test('a landscape frame starts from the sensor orientation', () {
    expect(firstRotation(1280, 720, 90), 90);
    expect(firstRotation(1920, 1080, 270), 270);
  });
}
