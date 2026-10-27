import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// The public site of MAZL: the link that goes with everything the app shares.
const String kMazlSiteUrl = 'https://mazl.app';

/// What the system share sheet is asked to do: [text], an optional [subject]
/// and the [origin] the sheet points at (a popover on a large screen).
typedef ShareSender =
    Future<void> Function({
      required String text,
      String? subject,
      required Rect origin,
    });

Future<void> _systemShare({
  required String text,
  String? subject,
  required Rect origin,
}) async {
  await Share.share(text, subject: subject, sharePositionOrigin: origin);
}

/// Opens the system share sheet from a button.
///
/// share_plus on iOS refuses to present the sheet without a non-empty
/// `sharePositionOrigin` inside the view on a large screen (the open iPhone
/// Duo, an iPad), where the sheet is a popover: it throws, and a button that
/// only calls `Share.share(text)` then does nothing, silently. The origin is
/// the button's own box, taken from [buttonContext] (the context of the
/// button, not of the page: the buttons of the vertical bar are drawn above
/// the navigator), or the middle of the screen when it cannot be measured.
abstract final class ShareSheet {
  @visibleForTesting
  static ShareSender sender = _systemShare;

  /// Shares [text] followed by the site link. Returns whether the sheet was
  /// opened (false after an error, which is logged).
  static Future<bool> share(
    BuildContext buttonContext, {
    required String text,
    String? subject,
  }) async {
    final origin = originOf(buttonContext);
    try {
      await sender(
        text: '$text\n$kMazlSiteUrl',
        subject: subject,
        origin: origin,
      );
      return true;
    } on Object catch (error, stack) {
      developer.log(
        error.toString(),
        name: 'share',
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// The box of [context] in the window, never empty.
  static Rect originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize && box.attached) {
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (!rect.isEmpty) return rect;
    }
    final size = MediaQuery.maybeSizeOf(context) ?? const Size(2, 2);
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: 1,
      height: 1,
    );
  }
}
