import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_typography.dart';

/// Grand titre serré des écrans de vérification : 30 à 48 px, interlettrage
/// de -0,04 em.
class IdentityHeadline extends StatelessWidget {
  const IdentityHeadline(this.text, {super.key, this.size = 30, this.textAlign});

  final String text;
  final double size;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: AppTypography.family,
        fontSize: size,
        fontWeight: size >= 36 ? FontWeight.w700 : FontWeight.w600,
        letterSpacing: -size * 0.04,
        height: size >= 36 ? 1.04 : 1.1,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

/// Le paragraphe unique sous un titre.
class IdentityParagraph extends StatelessWidget {
  const IdentityParagraph(this.text, {super.key, this.size = 16});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontFamily: AppTypography.family,
      fontSize: size,
      height: 1.5,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// Pastille ronde à icône, au-dessus d'un titre. [filled] : tekhelet plein
/// (réussite, bienvenue) ; sinon aplat neutre (alerte, information).
class IconDisc extends StatelessWidget {
  const IconDisc({super.key, required this.icon, this.size = 56, this.filled = false});

  final IconData icon;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: filled ? scheme.primary : scheme.surfaceContainer),
        child: Icon(icon, size: size * 0.46, color: filled ? Colors.white : scheme.onSurface),
      ),
    );
  }
}

class NumberedStep {
  const NumberedStep(this.title, {this.detail});

  final String title;
  final String? detail;
}

/// Liste numérotée « 01 / 02 / 03 » séparée par des filets.
class NumberedSteps extends StatelessWidget {
  const NumberedSteps({super.key, required this.steps, this.emphasised = true});

  final List<NumberedStep> steps;

  /// Titres en semi-gras (étapes d'un parcours) ou en texte courant (conseils).
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Container(
            padding: EdgeInsets.symmetric(vertical: emphasised ? 16 : 14),
            decoration: BoxDecoration(
              border: i == steps.length - 1 ? null : Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  (i + 1).toString().padLeft(2, '0'),
                  style: TextStyle(fontFamily: AppTypography.monoFamily, fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Expanded(child: _stepText(scheme, steps[i])),
              ],
            ),
          ),
      ],
    );
  }

  Widget _stepText(ColorScheme scheme, NumberedStep step) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        step.title,
        style: TextStyle(
          fontFamily: AppTypography.family,
          fontSize: 16,
          height: 1.4,
          fontWeight: emphasised ? FontWeight.w600 : FontWeight.w400,
          color: scheme.onSurface,
        ),
      ),
      if (step.detail != null) ...[
        const SizedBox(height: 3),
        Text(step.detail!, style: TextStyle(fontSize: 14, height: 1.4, color: scheme.onSurfaceVariant)),
      ],
    ],
  );
}

/// Ligne discrète avec un cadenas : la promesse de confidentialité.
class PrivacyLine extends StatelessWidget {
  const PrivacyLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: ExcludeSemantics(child: Icon(LucideIcons.lock, size: 16, color: muted)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, height: 1.45, color: muted)),
        ),
      ],
    );
  }
}

/// Bouton principal : pilule encre (claire sur fond sombre).
class IdentityPrimaryButton extends StatelessWidget {
  const IdentityPrimaryButton(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ElevatedButton(onPressed: onPressed, child: Text(label));
}

/// Action secondaire : pilule à filet.
class IdentityOutlineButton extends StatelessWidget {
  const IdentityOutlineButton(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(onPressed: onPressed, child: Text(label));
}

/// Action tertiaire : texte seul, 48 px de haut.
class IdentityLinkButton extends StatelessWidget {
  const IdentityLinkButton(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(minimumSize: const Size(44, 48)),
    child: Text(label, textAlign: TextAlign.center),
  );
}
