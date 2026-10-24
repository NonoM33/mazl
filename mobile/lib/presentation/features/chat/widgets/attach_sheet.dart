import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_sheet.dart';

enum AttachChoice { gallery, camera }

/// The « + » sheet: gallery (several photos) or camera.
Future<AttachChoice?> pickAttachment(BuildContext context) {
  return showMazlSheet<AttachChoice>(
    context,
    padded: false,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(LucideIcons.image),
          title: Text(sheet.l10n.chatAttachPhotos),
          subtitle: Text(sheet.l10n.chatAttachPhotosLimit),
          onTap: () => Navigator.pop(sheet, AttachChoice.gallery),
        ),
        ListTile(
          leading: const Icon(LucideIcons.camera),
          title: Text(sheet.l10n.chatAttachCamera),
          onTap: () => Navigator.pop(sheet, AttachChoice.camera),
        ),
      ],
    ),
  );
}
