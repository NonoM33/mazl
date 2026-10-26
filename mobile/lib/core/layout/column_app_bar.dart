import 'package:flutter/material.dart';

import 'bar_navigation.dart';
import 'vertical_bar.dart';

/// An [AppBar] whose navigation moves to the vertical bar when there is one.
///
/// The foldable iPhone closed, sideways or held like a book keeps a column
/// on one side: iOS puts the screen's back or close button there, at the top,
/// then its icon actions, within reach of the thumb that holds the device
/// (regles/iphone-duo.md §2.6). The bar keeps its title and any action that
/// is not an icon (a text button would not fit the column). Without a column
/// this is [appBar], unchanged.
///
/// The column is drawn above the navigator: a [leading] or an action must
/// carry its own `onPressed` (never rely on a default that looks up the
/// navigator from where it is drawn).
class ColumnAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ColumnAppBar({super.key, required this.appBar});

  final AppBar appBar;

  @override
  Size get preferredSize => appBar.preferredSize;

  static bool fitsColumn(Widget action) =>
      action is IconButton || action is PopupMenuButton;

  Widget? _leading(BuildContext context) {
    if (appBar.leading != null) return appBar.leading;
    if (!appBar.automaticallyImplyLeading) return null;
    final route = ModalRoute.of(context);
    if (route == null || !route.impliesAppBarDismissal) return null;
    // The column is drawn above the navigator: the button pops this page
    // through its own context, not the column's.
    void pop() => Navigator.maybePop(context);
    final closes = route is PageRoute && route.fullscreenDialog;
    return closes ? CloseButton(onPressed: pop) : BackButton(onPressed: pop);
  }

  @override
  Widget build(BuildContext context) {
    if (VerticalBarScope.geometryOf(context) == null) return appBar;
    final leading = _leading(context);
    final actions = appBar.actions ?? const <Widget>[];
    final moved = [?leading, ...actions.where(fitsColumn)];
    final kept = actions.where((action) => !fitsColumn(action)).toList();
    return Stack(
      fit: StackFit.passthrough,
      children: [
        AppBar(
          automaticallyImplyLeading: false,
          title: appBar.title,
          actions: kept.isEmpty ? null : kept,
          flexibleSpace: appBar.flexibleSpace,
          bottom: appBar.bottom,
          elevation: appBar.elevation,
          scrolledUnderElevation: appBar.scrolledUnderElevation,
          shadowColor: appBar.shadowColor,
          surfaceTintColor: appBar.surfaceTintColor,
          shape: appBar.shape,
          backgroundColor: appBar.backgroundColor,
          foregroundColor: appBar.foregroundColor,
          iconTheme: appBar.iconTheme,
          actionsIconTheme: appBar.actionsIconTheme,
          primary: appBar.primary,
          centerTitle: appBar.centerTitle,
          titleSpacing: appBar.titleSpacing,
          toolbarHeight: appBar.toolbarHeight,
          titleTextStyle: appBar.titleTextStyle,
          systemOverlayStyle: appBar.systemOverlayStyle,
          forceMaterialTransparency: appBar.forceMaterialTransparency,
        ),
        if (moved.isNotEmpty)
          BarNavigation(buttons: moved, inline: const SizedBox.shrink()),
      ],
    );
  }
}
