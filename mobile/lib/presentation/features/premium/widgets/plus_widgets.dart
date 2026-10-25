import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/daily_limit.dart';
import '../../../../core/services/premium_gate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/plus_text.dart';

/// Le nom du produit, tel qu'il est écrit dans les phrases traduites.
const String plusBrand = 'mazl+';

/// [phrase] (« Découvrir mazl+ ») avec la marque remplacée par [brand] : les
/// mots autour restent du texte simple. La place de la marque dans la phrase
/// change d'une langue à l'autre ; sans marque, la phrase est rendue telle
/// quelle.
List<InlineSpan> brandPhraseSpans(String phrase, List<InlineSpan> brand) {
  final at = phrase.indexOf(plusBrand);
  if (at < 0) return [TextSpan(text: phrase)];
  final after = phrase.substring(at + plusBrand.length);
  return [
    if (at > 0) TextSpan(text: phrase.substring(0, at)),
    ...brand,
    if (after.isNotEmpty) TextSpan(text: after),
  ];
}

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
    // Un logo : « mazl » puis « + » se lisent de gauche à droite dans toutes
    // les langues, même en hébreu où le « + » sauterait à gauche.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'mazl'),
            TextSpan(
              text: '+',
              style: TextStyle(color: plusColor ?? scheme.primary),
            ),
          ],
        ),
        semanticsLabel: plusBrand,
        style: TextStyle(
          fontFamily: AppTypography.family,
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: -size * 0.05,
          height: 0.95,
          color: color ?? scheme.onSurface,
        ),
      ),
    );
  }
}

/// Bouton plein encre qui écrit une phrase contenant « mazl+ » (la forme du
/// thème : pilule de 56).
class PlusCtaButton extends StatelessWidget {
  const PlusCtaButton({super.key, required this.label, required this.onPressed});

  /// La phrase entière, dans la langue du membre (« Découvrir mazl+ »).
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Semantics(
          label: label,
          excludeSemantics: true,
          child: Text.rich(
            TextSpan(
              children: brandPhraseSpans(
                label,
                plusWordSpans(plusColor: plusAccentOnInk(context)),
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Contenu commun des fenêtres du bas. Le fond, la poignée et le 24 px
/// viennent de `showMazlSheet`.
class PlusSheetFrame extends StatelessWidget {
  const PlusSheetFrame({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Le style du titre des fenêtres du bas (« Vos likes du jour sont partis. »).
TextStyle plusSheetTitleStyle(BuildContext context) =>
    Theme.of(context).textTheme.headlineLarge!.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.45,
      height: 1.08,
    );

/// Compte à rebours jusqu'à la remise à zéro du jour, chiffres à chasse fixe.
class DailyCountdown extends StatefulWidget {
  const DailyCountdown({super.key, this.resetsAt, this.now = DateTime.now});

  /// L'instant où le serveur remet les likes à zéro ; à défaut, minuit.
  final DateTime? resetsAt;

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
    final now = widget.now();
    final resetsAt = widget.resetsAt;
    return Text(
      formatCountdown(
        resetsAt == null ? timeUntilMidnight(now) : resetsAt.difference(now),
      ),
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
///
/// La limite et la remise à zéro viennent du serveur ; sans limite connue, la
/// pastille n'affiche aucun chiffre.
class DailyLimitSheet extends StatelessWidget {
  const DailyLimitSheet({
    super.key,
    required this.freeLikesPerDay,
    this.resetsAt,
    this.now = DateTime.now,
  });

  final int? freeLikesPerDay;
  final DateTime? resetsAt;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return PlusSheetFrame(
      children: [
        if (freeLikesPerDay != null) ...[
          SectionLabel(l10n.plusDailyLimitLabel(freeLikesPerDay!)),
          const SizedBox(height: 10),
        ],
        Text(l10n.plusDailyLimitTitle, style: plusSheetTitleStyle(context)),
        const SizedBox(height: 12),
        Text(
          l10n.plusDailyLimitBody,
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
                  l10n.plusDailyLimitNext,
                  style: TextStyle(
                    fontSize: 15,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DailyCountdown(resetsAt: resetsAt, now: now),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PlusCtaButton(
          label: l10n.plusDiscover,
          onPressed: () => Navigator.pop(context, true),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.plusDailyLimitWait),
          ),
        ),
      ],
    );
  }
}

/// Fenêtre expliquant une fonction réservée aux abonnés.
/// Se ferme avec `true` pour ouvrir l'offre.
class PremiumFeatureSheet extends StatelessWidget {
  const PremiumFeatureSheet({super.key, required this.feature});

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return PlusSheetFrame(
      children: [
        SectionLabel(l10n.plusReservedLabel),
        const SizedBox(height: 10),
        Text(feature.title(l10n), style: plusSheetTitleStyle(context)),
        const SizedBox(height: 12),
        Text(
          feature.description(l10n),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        PlusCtaButton(
          label: l10n.plusDiscover,
          onPressed: () => Navigator.pop(context, true),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.plusNotNow),
          ),
        ),
      ],
    );
  }
}
