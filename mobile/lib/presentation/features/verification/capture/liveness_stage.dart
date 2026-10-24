import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';

/// The selfie screen: the live camera in a circle ringed by the hold
/// progress, one big instruction, one bar per pose. Always dark.
class LivenessStage extends StatelessWidget {
  const LivenessStage({
    super.key,
    required this.camera,
    required this.instruction,
    required this.hint,
    required this.holdProgress,
    required this.total,
    required this.done,
    required this.onCancel,
  });

  /// Preview widget, clipped to the circle by this stage.
  final Widget camera;
  final String instruction;

  /// What to fix, or null when the pose is being held.
  final String? hint;

  /// 0..1, how long the right pose has been held.
  final double holdProgress;
  final int total;
  final int done;
  final VoidCallback onCancel;

  static const _maxDiameter = 300.0;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Builder(builder: _scaffold),
    );
  }

  Widget _scaffold(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      RoundIconButton(icon: LucideIcons.x, tooltip: context.l10n.commonCancel, onPressed: onCancel),
                      Expanded(
                        child: Center(
                          child: SectionLabel(context.l10n.verificationLivenessPoseCounter(math.min(done + 1, total), total)),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
              ),
              Expanded(child: _content(scheme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(ColorScheme scheme) {
    return LayoutBuilder(
      builder: (context, box) {
        final diameter = math.max(120.0, math.min(_maxDiameter, math.min(box.maxWidth - 48, box.maxHeight * 0.52)));
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              SizedBox.square(
                dimension: diameter,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: ClipOval(
                        child: ColoredBox(color: scheme.surfaceContainer, child: camera),
                      ),
                    ),
                    CustomPaint(
                      painter: _HoldRingPainter(progress: holdProgress, track: scheme.outline, arc: scheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Semantics(
                liveRegion: true,
                header: true,
                child: Text(
                  instruction,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.family,
                    fontSize: 28,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.035 * 28,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _PoseBars(total: total, done: done),
              const SizedBox(height: 14),
              SizedBox(
                height: 22,
                child: hint == null
                    ? null
                    : Text(hint!, style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant)),
              ),
              const Spacer(),
              Text(
                context.l10n.verificationLivenessPrivacy,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.45, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HoldRingPainter extends CustomPainter {
  const _HoldRingPainter({required this.progress, required this.track, required this.arc});

  final double progress;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(rect, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress.clamp(0.0, 1.0), false, paint..color = arc);
    }
  }

  @override
  bool shouldRepaint(_HoldRingPainter old) => old.progress != progress || old.track != track || old.arc != arc;
}

/// One bar per pose: taken, in progress, still to come.
class _PoseBars extends StatelessWidget {
  const _PoseBars({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l10n.verificationLivenessPosesTaken(done, total),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Container(
              // not a drag handle: one progress segment per pose
              width: 28,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i < done ? scheme.onSurface : (i == done ? scheme.primary : scheme.outline),
              ),
            ),
        ],
      ),
    );
  }
}
