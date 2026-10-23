import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
          title: const Text('Photos'),
          subtitle: const Text('Jusqu\'à 10 à la fois'),
          onTap: () => Navigator.pop(sheet, AttachChoice.gallery),
        ),
        ListTile(
          leading: const Icon(LucideIcons.camera),
          title: const Text('Appareil photo'),
          onTap: () => Navigator.pop(sheet, AttachChoice.camera),
        ),
      ],
    ),
  );
}
