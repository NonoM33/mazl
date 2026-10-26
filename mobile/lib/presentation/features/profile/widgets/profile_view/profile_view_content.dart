import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/layout/fold_cut.dart';
import '../../../../../l10n/l10n.dart';
import 'profile_identity.dart';
import 'profile_photo_gallery.dart';
import 'profile_sections.dart';
import 'profile_view_data.dart';

/// Contenu défilant d'un profil : rangée du haut, galerie, puis les blocs
/// séparés de 28 points. Les blocs propres à un cas (complétion, compatibilité,
/// mode couple, signalement) arrivent par [leading] et [trailing].
///
/// Tenu comme un livre (iPhone Duo à moitié plié, le pli descend au milieu),
/// le profil se lit en deux pages : la galerie et l'identité sur la page où la
/// lecture commence, tout le reste sur l'autre, chacune défilant seule. Partout
/// ailleurs, une seule colonne, dans l'ordre d'origine. Chaque morceau garde
/// son état quand l'appareil se plie ou se déplie.
class ProfileViewContent extends StatefulWidget {
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
  State<ProfileViewContent> createState() => _ProfileViewContentState();
}

class _ProfileViewContentState extends State<ProfileViewContent> {
  static const _blockGap = ProfileViewContent.blockGap;

  final List<GlobalKey> _keys = [];

  Widget _keyed(int index, Widget child) {
    while (_keys.length <= index) {
      _keys.add(GlobalKey(debugLabel: 'profile-view-${_keys.length}'));
    }
    return KeyedSubtree(key: _keys[index], child: child);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = widget.data;
    final facts = data.facts(l10n);
    final bio = data.bio;
    final lookingFor = lookingForLabel(l10n, data.lookingFor);
    final identity = _identityBlock(l10n);
    // Each block keeps its number whichever page it is on.
    final leading = [
      for (var i = 0; i < widget.leading.length; i++)
        (10 + i, widget.leading[i]),
    ];
    final restBlocks = <Widget>[
      if (bio != null && bio.isNotEmpty)
        ProfileTextSection(label: l10n.profileAbout, text: bio),
      if (facts.isNotEmpty) ProfileFactsSection(facts: facts),
      if (lookingFor != null)
        ProfileTextSection(label: l10n.profileLookingFor, text: lookingFor),
      if (widget.prompts.isNotEmpty)
        ProfilePromptCards(prompts: widget.prompts),
      ...widget.trailing,
    ];
    final rest = [
      for (var i = 0; i < restBlocks.length; i++) (100 + i, restBlocks[i]),
    ];
    final header = [
      _keyed(0, widget.topBar),
      _keyed(
        1,
        ProfilePhotoGallery(
          photos: data.galleryPhotos,
          seed: data.name.hashCode,
        ),
      ),
      if (widget.isOwnProfile && data.hasNoUploadedPhoto)
        _keyed(2, _addPhotosButton(l10n)),
      const SizedBox(height: _blockGap),
    ];
    final padding = EdgeInsets.fromLTRB(16, 0, 16, widget.bottomPadding);
    return FoldCutBuilder(
      builder: (context, cut) {
        if (cut?.axis == FoldSplitAxis.vertical) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: cut!.leadExtent,
                child: SingleChildScrollView(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...header,
                      _inset(_blocks([(3, identity)])),
                    ],
                  ),
                ),
              ),
              SizedBox(width: cut.gap),
              Expanded(
                child: SingleChildScrollView(
                  padding: padding.copyWith(top: 16),
                  child: _inset(_blocks([...leading, ...rest])),
                ),
              ),
            ],
          );
        }
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...header,
              _inset(_blocks([...leading, (3, identity), ...rest])),
            ],
          ),
        );
      },
    );
  }

  /// The blocks of [blocks] one under the other, 28 points apart, each with a
  /// key that follows it from one layout to the other.
  List<Widget> _blocks(List<(int, Widget)> blocks) => [
    for (var i = 0; i < blocks.length; i++) ...[
      if (i > 0) const SizedBox(height: _blockGap),
      _keyed(blocks[i].$1, blocks[i].$2),
    ],
  ];

  Widget _inset(List<Widget> children) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget _identityBlock(AppLocalizations l10n) {
    final data = widget.data;
    final isOwnProfile = widget.isOwnProfile;
    final showTag = isOwnProfile || data.isVerified;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileIdentity(
          name: data.name,
          age: data.age,
          metaLine: data.metaLine(l10n),
        ),
        if (showTag) ...[
          const SizedBox(height: 12),
          ProfileVerificationTag(
            isVerified: data.isVerified,
            level: data.verificationLevel,
            onTap: isOwnProfile ? widget.onVerificationTap : null,
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
          onPressed: widget.onAddPhotos,
          icon: const Icon(LucideIcons.camera, size: 18),
          label: Text(l10n.profileAddPhotos),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
        ),
      ),
    );
  }
}

/// Who a member looks for, as a sentence: the server's codes `male` / `female`
/// read as words, a sentence the member wrote stays as written, and any other
/// code (`all`, `serious`…) is not shown.
String? lookingForLabel(AppLocalizations l10n, String? value) {
  final text = value?.trim() ?? '';
  return switch (text.toLowerCase()) {
    'male' => l10n.profileAMan,
    'female' => l10n.profileAWoman,
    _ when text.isEmpty || RegExp(r'^[a-z_]+$').hasMatch(text) => null,
    _ => text,
  };
}
