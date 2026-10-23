import 'package:flutter/material.dart';

/// 32 bars of 3 px, 2 px apart, 4 to 24 px high; the played part in full
/// colour and the rest at 40 % (docs/design/CHAT.md §8).
class Waveform extends StatelessWidget {
  const Waveform({super.key, required this.values, required this.progress, required this.color});

  static const bars = 32;
  static const barWidth = 3.0;
  static const barGap = 2.0;
  static const minHeight = 4.0;
  static const maxHeight = 24.0;
  static const width = bars * barWidth + (bars - 1) * barGap;

  final List<int> values;

  /// 0 to 1.
  final double progress;
  final Color color;

  /// The recorded [waveformBars] values squeezed (or padded) to [bars].
  static List<double> resample(List<int> values) {
    if (values.isEmpty) return List.filled(bars, 0.1);
    return [
      for (var i = 0; i < bars; i++)
        () {
          final from = (i * values.length / bars).floor();
          final to = ((i + 1) * values.length / bars).ceil().clamp(from + 1, values.length);
          final slice = values.sublist(from, to);
          return slice.reduce((a, b) => a + b) / slice.length / 100;
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: maxHeight,
        child: CustomPaint(painter: _WaveformPainter(resample(values), progress, color)),
      );
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter(this.levels, this.progress, this.color);

  final List<double> levels;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final played = Paint()..color = color;
    final rest = Paint()..color = color.withValues(alpha: 0.4);
    for (var i = 0; i < Waveform.bars; i++) {
      final height = Waveform.minHeight + (Waveform.maxHeight - Waveform.minHeight) * levels[i].clamp(0.0, 1.0);
      final x = i * (Waveform.barWidth + Waveform.barGap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - height) / 2, Waveform.barWidth, height),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rect, (i + 0.5) / Waveform.bars <= progress ? played : rest);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.progress != progress || old.color != color || old.levels != levels;
}
