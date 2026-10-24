import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The « back » arrow of a round button, pointing the way the language reads:
/// left in left-to-right, right in right-to-left. `RoundIconButton` takes an
/// icon, not a widget, so it cannot hold a `DirectionalIcon`.
IconData backArrowIcon(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
    ? LucideIcons.arrowRight
    : LucideIcons.arrowLeft;
