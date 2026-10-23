import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../logic/chat_dates.dart';
import 'voice_capture.dart';

/// The composer while a voice note is recorded (docs/design/CHAT.md §8): a
/// pulsing red dot, the timer, live level bars and « ‹ Glisser pour annuler ».
class RecordingStrip extends StatelessWidget {
  const RecordingStrip({super.key, required this.capture, required this.onCancel});

  final VoiceCapture capture;

  /// The trash button shown once the recording is locked.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cancelling = capture.willCancel;
    return Row(
      children: [
        if (capture.locked)
          IconButton(
            tooltip: 'Annuler l\'enregistrement',
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: const Icon(LucideIcons.trash2, size: 20, color: AppColors.error),
            onPressed: onCancel,
          )
        else
          const SizedBox(width: 14),
        const _PulsingDot(),
        const SizedBox(width: 10),
        Text(
          minutesSeconds(capture.elapsed),
          style: TextStyle(
            fontFamily: AppTypography.monoFamily,
            fontSize: 14,
            color: scheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 12),
        _LevelBars(levels: capture.levels, color: scheme.onSurfaceVariant),
        const Spacer(),
        if (!capture.locked)
          Flexible(
            child: Text(
              cancelling ? 'Relâchez pour annuler' : '‹ Glisser pour annuler',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: cancelling ? AppColors.error : scheme.onSurfaceVariant),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
        child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
      );
}

class _LevelBars extends StatelessWidget {
  const _LevelBars({required this.levels, required this.color});

  final List<int> levels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final padded = [
      for (var i = 0; i < VoiceCapture.visibleLevels - levels.length; i++) 0,
      ...levels,
    ];
    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final level in padded)
            Container(
              margin: const EdgeInsets.only(right: 2),
              width: 3,
              height: 4 + 20 * (level.clamp(0, 100) / 100),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1.5)),
            ),
        ],
      ),
    );
  }
}
