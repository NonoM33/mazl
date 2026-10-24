import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../l10n/l10n.dart';
import 'profile_identity.dart';
import 'profile_photo_gallery.dart';
import 'profile_sections.dart';
import 'profile_view_data.dart';

/// Contenu défilant d'un profil : rangée du haut, galerie, puis les blocs
/// séparés de 28 points. Les blocs propres à un cas (complétion, compatibilité,
/// mode couple, signalement) arrivent par [leading] et [trailing].
class ProfileViewContent extends StatelessWidget {
  const ProfileViewContent({
    super.key,
    required this.data,
    required this.topBar,
    required this.isOwnProfile,
    required this.bottomPadding,
    this.prompts = const [],
    this.leading = const [],
    this.trailing = const [],
    this.onVerificationTap,
    this.onAddPhotos,
  });

  static const blockGap = 28.0;

  final ProfileViewData data;
  final Widget topBar;
  final bool isOwnProfile;

  /// Espace sous le dernier bloc : barre d'onglets ou barre d'actions comprise.
  final double bottomPadding;
  final List<({String question, String answer})> prompts;
  final List<Widget> leading;
  final List<Widget> trailing;
  final VoidCallback? onVerificationTap;
  final VoidCallback? onAddPhotos;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final facts = data.facts(l10n);
    final bio = data.bio;
    final lookingFor = data.lookingFor;
    final blocks = <Widget>[
      ...leading,
      _identityBlock(l10n),
      if (bio != null && bio.isNotEmpty) ProfileTextSection(label: l10n.profileAbout, text: bio),
      if (facts.isNotEmpty) ProfileFactsSection(facts: facts),
      if (lookingFor != null && lookingFor.isNotEmpty)
        ProfileTextSection(label: l10n.profileLookingFor, text: lookingFor),
      if (prompts.isNotEmpty) ProfilePromptCards(prompts: prompts),
      ...trailing,
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          topBar,
          ProfilePhotoGallery(photos: data.galleryPhotos, seed: data.name.hashCode),
          if (isOwnProfile && data.hasNoUploadedPhoto) _addPhotosButton(l10n),
          const SizedBox(height: blockGap),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < blocks.length; i++) ...[
                  if (i > 0) const SizedBox(height: blockGap),
                  blocks[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _identityBlock(AppLocalizations l10n) {
    final showTag = isOwnProfile || data.isVerified;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileIdentity(name: data.name, age: data.age, metaLine: data.metaLine(l10n)),
        if (showTag) ...[
          const SizedBox(height: 12),
          ProfileVerificationTag(
            isVerified: data.isVerified,
            level: data.verificationLevel,
            onTap: isOwnProfile ? onVerificationTap : null,
          ),
        ],
      ],
    );
  }

  Widget _addPhotosButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          onPressed: onAddPhotos,
          icon: const Icon(LucideIcons.camera, size: 18),
          label: Text(l10n.profileAddPhotos),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
        ),
      ),
    );
  }
}
