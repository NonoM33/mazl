import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/daily_limit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../common/widgets/mazl_components.dart';

/// Les deux morceaux du nom du produit : « mazl » en gras, « + » en accent.
/// À glisser dans un `TextSpan.children` pour écrire « Découvrir mazl+ ».
List<InlineSpan> plusWordSpans({Color? plusColor}) => [
  const TextSpan(
    text: 'mazl',
    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.45),
  ),
  TextSpan(
    text: '+',
    style: TextStyle(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.45,
      color: plusColor,
    ),
  ),
];

/// Teinte du « + » posé sur une surface d'encre (bouton, carte).
Color plusAccentOnInk(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light
    ? AppColors.tekheletLight
    : AppColors.tekhelet;

/// « mazl+ » seul, à la taille voulue.
class PlusWord extends StatelessWidget {
  const PlusWord({super.key, required this.size, this.color, this.plusColor});

  final double size;
  final Color? color;
  final Color? plusColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'mazl'),
          TextSpan(
            text: '+',
            style: TextStyle(color: plusColor ?? scheme.primary),
          ),
        ],
      ),
      semanticsLabel: 'mazl+',
      style: TextStyle(
        fontFamily: AppTypography.family,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -size * 0.05,
        height: 0.95,
        color: color ?? scheme.onSurface,
      ),
    );
  }
}

/// Bouton plein encre « préfixe + mazl+ » (la forme du thème : pilule de 56).
class PlusCtaButton extends StatelessWidget {
  const PlusCtaButton({
    super.key,
    required this.prefix,
    required this.onPressed,
  });

  final String prefix;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Semantics(
          label: '${prefix}mazl+',
          excludeSemantics: true,
          child: Text.rich(
            TextSpan(
              text: prefix,
              children: plusWordSpans(plusColor: plusAccentOnInk(context)),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Cadre commun des fenêtres du bas : poignée, coins hauts arrondis, 24 px.
class PlusSheetFrame extends StatelessWidget {
  const PlusSheetFrame({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: scheme.outline,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

TextStyle _sheetTitle(BuildContext context) =>
    Theme.of(context).textTheme.headlineLarge!.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.45,
      height: 1.08,
    );

/// Compte à rebours jusqu'à minuit, chiffres à chasse fixe.
class DailyCountdown extends StatefulWidget {
  const DailyCountdown({super.key, this.now = DateTime.now});

  /// Horloge injectable pour les tests.
  final DateTime Function() now;

  @override
  State<DailyCountdown> createState() => _DailyCountdownState();
}

class _DailyCountdownState extends State<DailyCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatCountdown(timeUntilMidnight(widget.now())),
      style: TextStyle(
        fontFamily: AppTypography.monoFamily,
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Fenêtre affichée quand les likes gratuits du jour sont épuisés.
/// Se ferme avec `true` pour ouvrir l'offre, `false` ou null pour attendre.
class DailyLimitSheet extends StatelessWidget {
  const DailyLimitSheet({
    super.key,
    required this.freeLikesPerDay,
    this.now = DateTime.now,
  });

  final int freeLikesPerDay;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PlusSheetFrame(
      children: [
        const SizedBox(height: 28),
        SectionLabel('Limite du jour · $freeLikesPerDay / $freeLikesPerDay'),
        const SizedBox(height: 10),
        Text('Vos likes du jour sont partis.', style: _sheetTitle(context)),
        const SizedBox(height: 12),
        Text(
          'Ils reviennent à minuit. Ou continuez sans compter, et voyez qui vous a déjà aimé.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Prochains likes dans',
                  style: TextStyle(
                    fontSize: 15,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DailyCountdown(now: now),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PlusCtaButton(
          prefix: 'Découvrir ',
          onPressed: () => Navigator.pop(context, true),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Attendre minuit'),
          ),
        ),
      ],
    );
  }
}

/// Fenêtre expliquant une fonction réservée aux abonnés.
/// Se ferme avec `true` pour ouvrir l'offre.
class PremiumFeatureSheet extends StatelessWidget {
  const PremiumFeatureSheet({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PlusSheetFrame(
      children: [
        const SizedBox(height: 28),
        const SectionLabel('Réservé à mazl+'),
        const SizedBox(height: 10),
        Text(title, style: _sheetTitle(context)),
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        PlusCtaButton(
          prefix: 'Découvrir ',
          onPressed: () => Navigator.pop(context, true),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Pas maintenant'),
          ),
        ),
      ],
    );
  }
}
