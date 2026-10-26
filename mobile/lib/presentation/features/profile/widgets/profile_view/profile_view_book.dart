import 'package:flutter/material.dart';

import '../../../../../core/layout/fold_cut.dart';
import '../../../../../l10n/l10n.dart';
import 'profile_identity.dart';
import 'profile_photo_gallery.dart';
import 'profile_sections.dart';
import 'profile_view_content.dart';
import 'profile_view_data.dart';

/// A profile of another member read like a book, for the foldable iPhone held
/// half open with the fold running down the screen: the page to look at on the
/// reading-start side (top row, photos, name and what they are), the page to
/// read on the other (about, essentials, what they look for, [trailing]).
/// Each page scrolls on its own; nothing sits in the curve.
///
/// The blocks are the ones [ProfileViewContent] stacks in a single column.
class ProfileViewBook extends StatelessWidget {
  const ProfileViewBook({
    super.key,
    required this.cut,
    required this.data,
    required this.topBar,
    required this.bottomPadding,
    this.trailing = const [],
  });

  final FoldCut cut;
  final ProfileViewData data;
  final Widget topBar;

  /// Room under the last block of the reading page, for the action bar.
  final double bottomPadding;
  final List<Widget> trailing;

  /// The most the photo may be tall, as in the single column.
  static const _photoHeight = 440.0;

  /// What the name, the age and the line under them need under the photo.
  static const _identityRoom = 190.0;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: cut.leadExtent, child: _lookPage(context)),
      SizedBox(width: cut.gap),
      Expanded(child: _readPage(context)),
    ],
  );

  Widget _lookPage(BuildContext context) {
    final l10n = context.l10n;
    final showTag = data.isVerified;
    return LayoutBuilder(
      builder: (context, box) {
        // The photo takes what the page has left, as much as the single
        // column gives it at most.
        final photo = (box.maxHeight - _identityRoom - 80).clamp(
          200.0,
          _photoHeight,
        );
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              topBar,
              ProfilePhotoGallery(
                photos: data.galleryPhotos,
                seed: data.name.hashCode,
                height: photo,
              ),
              const SizedBox(height: ProfileViewContent.blockGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
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
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _readPage(BuildContext context) {
    final l10n = context.l10n;
    final facts = data.facts(l10n);
    final bio = data.bio;
    final lookingFor = data.lookingFor;
    final blocks = <Widget>[
      if (bio != null && bio.isNotEmpty)
        ProfileTextSection(label: l10n.profileAbout, text: bio),
      if (facts.isNotEmpty) ProfileFactsSection(facts: facts),
      if (lookingFor != null && lookingFor.isNotEmpty)
        ProfileTextSection(label: l10n.profileLookingFor, text: lookingFor),
      ...trailing,
    ];
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        ProfileViewContent.blockGap,
        24,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) const SizedBox(height: ProfileViewContent.blockGap),
            blocks[i],
          ],
        ],
      ),
    );
  }
}
