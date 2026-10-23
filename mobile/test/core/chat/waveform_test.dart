import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/chat/voice.dart';
import 'package:mazl/core/chat/waveform.dart';

void main() {
  test('48 bars, as the contract says', () {
    expect(waveformBars, 48);
    expect(downsampleWaveform(List.filled(500, 30)), hasLength(48));
  });

  test('nothing recorded gives 48 silent bars', () {
    expect(downsampleWaveform(const []), List.filled(48, 0));
  });

  test('exactly 48 levels come back unchanged', () {
    final levels = [for (var i = 0; i < 48; i++) i * 2];
    expect(downsampleWaveform(levels), levels);
  });

  test('each bar keeps the peak of its slice', () {
    final levels = [for (var i = 0; i < 96; i++) i.isEven ? 10 : 60];
    expect(downsampleWaveform(levels), List.filled(48, 60));
  });

  test('a single spike at the very end is not lost', () {
    final levels = List.filled(1000, 5)..[999] = 100;
    final bars = downsampleWaveform(levels);
    expect(bars.last, 100);
    expect(bars.sublist(0, 47), everyElement(5));
  });

  test('a spike in the middle lands in the middle bar', () {
    final levels = List.filled(480, 0)..[240] = 90;
    final bars = downsampleWaveform(levels);
    expect(bars.indexOf(90), 24);
    expect(bars.where((b) => b != 0), hasLength(1));
  });

  test('fewer levels than bars are stretched, keeping order', () {
    final bars = downsampleWaveform([10, 50, 90]);
    expect(bars, hasLength(48));
    expect(bars.first, 10);
    expect(bars.last, 90);
    for (var i = 1; i < bars.length; i++) {
      expect(bars[i], greaterThanOrEqualTo(bars[i - 1]));
    }
    expect(bars.toSet(), {10, 50, 90});
  });

  test('values are clamped to 0..100', () {
    final bars = downsampleWaveform([-20, 250, 40]);
    expect(bars.every((b) => b >= 0 && b <= 100), isTrue);
    expect(bars.contains(100), isTrue);
    expect(bars.contains(0), isTrue);
  });

  group('amplitudeToLevel', () {
    test('silence (-60 dB or less) is 0', () {
      expect(amplitudeToLevel(-160), 0);
      expect(amplitudeToLevel(-60), 0);
    });
    test('full scale (0 dB) is 100', () => expect(amplitudeToLevel(0), 100));
    test('above full scale is clamped', () => expect(amplitudeToLevel(6), 100));
    test('middle of the range is in the middle', () => expect(amplitudeToLevel(-30), 50));
    test('never outside 0..100 for any input', () {
      for (var db = -200.0; db <= 20; db += 7.5) {
        expect(amplitudeToLevel(db), inInclusiveRange(0, 100));
      }
    });
    test('NaN and infinity do not break the UI', () {
      expect(amplitudeToLevel(double.nan), 0);
      expect(amplitudeToLevel(double.negativeInfinity), 0);
      expect(amplitudeToLevel(double.infinity), 100);
    });
  });
}
