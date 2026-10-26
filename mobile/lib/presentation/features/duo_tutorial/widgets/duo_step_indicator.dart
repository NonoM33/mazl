import 'package:flutter/material.dart';

import '../../../../core/motion/mazl_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';

/// Six traits : ceux déjà faits en tekhelet, l'étape en cours allongée, les
/// autres en filet. VoiceOver lit « Étape 2 sur 6 ».
class DuoStepIndicator extends StatelessWidget {
  const DuoStepIndicator({super.key, required this.count, required this.index});

  final int count;
  final int index;

  static const _slide = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final duration = MazlMotion.reduced(context) ? Duration.zero : _slide;
    return Semantics(
      label: context.l10n.duoTutorialProgress(index + 1, count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  width: i == index ? 26 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i <= index ? AppColors.tekhelet : AppColors.hairline,
                    borderRadius: BorderRadius.circular(3.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
