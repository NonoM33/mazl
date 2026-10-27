import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../identity/identity_parts.dart';

/// Where one level stands.
enum LevelState { todo, inProgress, verified, refused, blocked }

/// One thing a level brings: an icon and a short line.
class LevelBenefit {
  const LevelBenefit(this.icon, this.text);

  final IconData icon;
  final String text;
}

/// A verification level as a card: its icon, its state, what it brings and,
/// when there is one, its action.
class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.state,
    required this.description,
    required this.benefits,
    this.verifiedOn,
    this.action,
    this.footnote,
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final LevelState state;
  final String description;
  final List<LevelBenefit> benefits;

  /// The long date of the verification, when it is known.
  final String? verifiedOn;
  final Widget? action;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final verified = state == LevelState.verified;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: verified ? scheme.primary : Colors.transparent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: verified ? scheme.primary : scheme.surface),
                  child: Icon(icon, size: 26, color: verified ? scheme.onPrimary : scheme.onSurface),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [SectionLabel(eyebrow), const SizedBox(height: 4), IdentityHeadline(title, size: 20)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LevelStatePill(state),
              if (verifiedOn != null) Text(verifiedOn!, style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 14),
          IdentityParagraph(description, size: 15),
          const SizedBox(height: 16),
          // The action comes before the list: the main button of the page
          // stays in view on a small window, the list is what scrolls.
          if (action != null) ...[action!, const SizedBox(height: 16)],
          if (footnote != null) ...[
            Text(footnote!, style: TextStyle(fontSize: 13, height: 1.4, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
          ],
          for (final benefit in benefits) _Benefit(benefit),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.benefit);

  final LevelBenefit benefit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(benefit.icon, size: 18, color: scheme.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(benefit.text, style: TextStyle(fontSize: 14, height: 1.4, color: scheme.onSurface)),
          ),
        ],
      ),
    );
  }
}

/// The state of a level in a coloured pill: a check when verified, the
/// colour of an error when refused, soft otherwise.
class LevelStatePill extends StatelessWidget {
  const LevelStatePill(this.state, {super.key});

  final LevelState state;

  /// The pill's background and the colour of its text. The refused one is a
  /// faint wash of the error colour over the page, kept light enough for the
  /// text to stay at AA.
  static (Color, Color) colors(ColorScheme scheme, LevelState state) => switch (state) {
    LevelState.verified || LevelState.inProgress => (scheme.primaryContainer, scheme.onPrimaryContainer),
    LevelState.refused => (Color.alphaBlend(scheme.error.withValues(alpha: 0.07), scheme.surface), scheme.error),
    LevelState.todo || LevelState.blocked => (scheme.surface, scheme.onSurface),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = colors(scheme, state);
    final (IconData icon, String label) = switch (state) {
      LevelState.verified => (LucideIcons.check, l10n.verificationVerifiedPill),
      LevelState.inProgress => (LucideIcons.loader, l10n.verificationPillBusy),
      LevelState.refused => (LucideIcons.circleAlert, l10n.verificationPillRefused),
      LevelState.blocked => (LucideIcons.timer, l10n.verificationPillBlocked),
      LevelState.todo => (LucideIcons.circleDashed, l10n.verificationPillTodo),
    };
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 14, color: foreground)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: foreground),
          ),
        ],
      ),
    );
  }
}
