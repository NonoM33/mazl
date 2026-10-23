import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/verification/chip/chip_reader.dart';

enum StepState { done, active, waiting }

/// The four phases of a chip read, one row each: done, running, waiting.
class NfcStepChecklist extends StatelessWidget {
  const NfcStepChecklist({super.key, required this.current});

  final ChipReadStep current;

  static const labels = {
    ChipReadStep.waitingForDocument: 'Détection du document',
    ChipReadStep.authenticating: 'Connexion sécurisée',
    ChipReadStep.readingPhoto: 'Lecture de la photo',
    ChipReadStep.readingSignature: 'Lecture de la signature',
  };

  static String stateWord(StepState state) => switch (state) {
    StepState.done => 'terminé',
    StepState.active => 'en cours',
    StepState.waiting => 'en attente',
  };

  @override
  Widget build(BuildContext context) => Column(
    children: [for (final step in ChipReadStep.values) _StepRow(label: labels[step]!, state: _stateOf(step))],
  );

  StepState _stateOf(ChipReadStep step) {
    if (step.index < current.index) return StepState.done;
    return step == current ? StepState.active : StepState.waiting;
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state});

  final String label;
  final StepState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final waiting = state == StepState.waiting;
    return Semantics(
      label: '$label, ${NfcStepChecklist.stateWord(state)}',
      excludeSemantics: true,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            _Marker(state: state),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: state == StepState.active ? FontWeight.w600 : FontWeight.w400,
                  color: waiting ? scheme.onSurfaceVariant : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.state});

  final StepState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (state == StepState.done) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.onSurface),
        child: Icon(LucideIcons.check, size: 12, color: scheme.surface),
      );
    }
    return CustomPaint(
      size: const Size.square(22),
      painter: _RingPainter(
        ring: scheme.outline,
        arc: state == StepState.active ? scheme.primary : null,
        width: state == StepState.active ? 2 : 1.5,
      ),
    );
  }
}

/// Hairline ring; the active one carries a quarter of accent on top.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.ring, required this.arc, required this.width});

  final Color ring;
  final Color? arc;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = ring;
    canvas.drawOval(rect, paint);
    final accent = arc;
    if (accent != null) {
      canvas.drawArc(rect, -3.14159 * 3 / 4, 3.14159 / 2, false, paint..color = accent);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.ring != ring || old.arc != arc || old.width != width;
}
