import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers/link_providers.dart';
import '../../../l10n/l10n.dart';

/// Opens [uri] outside the app. When the phone cannot (no mail account, no
/// browser), says where the link pointed so the member can still reach it.
Future<void> openPublicLink(
  BuildContext context,
  WidgetRef ref,
  Uri uri,
) async {
  final open = ref.read(externalLinkOpenerProvider);
  var opened = false;
  try {
    opened = await open(uri);
  } on PlatformException {
    opened = false;
  }
  if (opened || !context.mounted) return;
  final target = uri.scheme == 'mailto' ? uri.path : uri.toString();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.linkOpenError(target))),
  );
}
