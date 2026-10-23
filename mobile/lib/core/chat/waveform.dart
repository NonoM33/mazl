import 'voice.dart';

/// Reduces [levels] (0–100, any count) to exactly [waveformBars] bars, each
/// the peak of its slice so a short loud sound is not averaged away. Fewer
/// samples than bars are stretched (nearest sample), no samples give silence.
List<int> downsampleWaveform(List<int> levels) {
  if (levels.isEmpty) return List.filled(waveformBars, 0);
  final count = levels.length;
  return [
    for (var bar = 0; bar < waveformBars; bar++)
      () {
        final start = bar * count ~/ waveformBars;
        final end = ((bar + 1) * count ~/ waveformBars).clamp(start + 1, count);
        var peak = 0;
        for (var i = start; i < end; i++) {
          final level = levels[i].clamp(0, 100);
          if (level > peak) peak = level;
        }
        return peak;
      }(),
  ];
}

/// Maps a microphone level in dBFS (-160…0) to 0–100, linear from -60 dB.
int amplitudeToLevel(double decibels) {
  if (decibels.isNaN) return 0;
  const floor = -60.0;
  if (decibels <= floor) return 0;
  if (decibels >= 0) return 100;
  return ((decibels - floor) / -floor * 100).round();
}
