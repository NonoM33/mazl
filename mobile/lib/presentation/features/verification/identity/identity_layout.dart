import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../common/widgets/mazl_components.dart';
import 'identity_messages.dart';
import 'identity_parts.dart';

/// Cadre commun de chaque étape : un bouton fermer, une étiquette d'étape,
/// un grand titre, un paragraphe, le contenu, puis les actions épinglées en
/// bas. [dark] : écran de caméra, fond encre.
class IdentityPage extends StatelessWidget {
  const IdentityPage({
    super.key,
    this.eyebrow,
    this.lead,
    this.title,
    this.titleSize = 30,
    this.subtitle,
    this.child,
    this.note,
    this.actions = const [],
    this.onClose,
    this.dark = false,
    this.centerBody = false,
  });

  final String? eyebrow;
  final Widget? lead;
  final String? title;
  final double titleSize;
  final String? subtitle;
  final Widget? child;

  /// Ligne discrète juste au-dessus des actions.
  final Widget? note;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final bool dark;

  /// Centre [child] dans la page (indicateur de chargement).
  final bool centerBody;

  @override
  Widget build(BuildContext context) {
    final theme = dark ? AppTheme.darkTheme : Theme.of(context);
    return Theme(
      data: theme,
      child: Builder(builder: _scaffold),
    );
  }

  Widget _scaffold(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: scheme.brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              IdentityHeader(eyebrow: eyebrow, onClose: onClose),
              Expanded(child: _scrollArea()),
              if (note != null || actions.isNotEmpty) _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scrollArea() {
    if (centerBody) {
      return CustomScrollView(
        slivers: [SliverFillRemaining(hasScrollBody: false, child: Center(child: child))],
      );
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lead != null) ...[lead!, const SizedBox(height: 22)],
                if (title != null) IdentityHeadline(title!, size: titleSize),
                if (subtitle != null) ...[const SizedBox(height: 12), IdentityParagraph(subtitle!, size: 15)],
                if (child != null) ...[const SizedBox(height: 28), child!],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _footer() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (note != null) ...[note!, const SizedBox(height: 16)],
        for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(height: 4), actions[i]],
      ],
    ),
  );
}

/// Bouton fermer à gauche, étiquette d'étape au centre (« ÉTAPE 1 / 3 »).
class IdentityHeader extends StatelessWidget {
  const IdentityHeader({super.key, this.eyebrow, this.onClose});

  final String? eyebrow;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: onClose == null ? null : RoundIconButton(icon: LucideIcons.x, tooltip: 'Fermer', onPressed: onClose),
          ),
          Expanded(child: Center(child: eyebrow == null ? null : SectionLabel(eyebrow!))),
          const SizedBox(width: 44),
        ],
      ),
    ),
  );
}

/// Lien vers la page web où un document est relu par une personne.
class ManualReviewButton extends StatelessWidget {
  const ManualReviewButton({super.key});

  @override
  Widget build(BuildContext context) => IdentityLinkButton(
    'Envoyer mon document pour relecture',
    onPressed: () => launchUrl(identityManualReviewUri, mode: LaunchMode.externalApplication),
  );
}

/// Écran à message unique, dans le vocabulaire des mockups : pastille, grand
/// titre, un paragraphe facultatif, des conseils facultatifs, des pilules.
class IdentityNotice extends StatelessWidget {
  const IdentityNotice({
    super.key,
    required this.icon,
    required this.title,
    this.eyebrow,
    this.body,
    this.tips = const [],
    this.actions = const [],
    this.onClose,
    this.dark = false,
  });

  final IconData icon;
  final String title;
  final String? eyebrow;
  final String? body;
  final List<String> tips;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final bool dark;

  @override
  Widget build(BuildContext context) => IdentityPage(
    dark: dark,
    eyebrow: eyebrow,
    onClose: onClose,
    lead: IconDisc(icon: icon),
    title: title,
    titleSize: 36,
    subtitle: body,
    actions: actions,
    child: tips.isEmpty ? null : NumberedSteps(steps: [for (final tip in tips) NumberedStep(tip)], emphasised: false),
  );
}
