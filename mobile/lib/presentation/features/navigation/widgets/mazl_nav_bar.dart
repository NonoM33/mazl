import 'package:flutter/material.dart';

import '../../../../core/layout/safe_insets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';

class MazlNavItem {
  const MazlNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Barre d'onglets en capsule d'encre qui flotte au-dessus du bas de l'écran.
///
/// Elle laisse toujours [gap] points entre elle et la zone système : rien
/// n'est collé au bord. Avec `Scaffold(extendBody: true)`, le corps reçoit
/// sa hauteur dans `MediaQuery.padding.bottom`.
///
/// [collapsed] la replie en une pastille ronde, à gauche, qui ne montre que
/// l'icône de l'onglet courant ; la toucher appelle [onExpand]. La hauteur
/// réservée ne change pas (le contenu ne saute pas) et, repliée, la barre
/// laisse passer les touches à côté de la pastille.
class MazlNavBar extends StatelessWidget {
  const MazlNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.collapsed = false,
    this.onExpand,
  });

  static const barHeight = 64.0;
  static const gap = 12.0;
  static const sideMargin = 16.0;
  static const _duration = Duration(milliseconds: 260);

  final List<MazlNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool collapsed;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safe = MediaQuery.paddingOf(context);
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : _duration;
    // The horizontal insets are not symmetric on every display (system
    // controls can sit along one edge only): each side keeps its own.
    final direction = Directionality.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        sideMargin + safe.startFor(direction),
        0,
        sideMargin + safe.endFor(direction),
        safe.bottom + gap,
      ),
      child: SizedBox(
        height: barHeight,
        child: LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedContainer(
              key: const Key('mazl-nav-bar'),
              duration: duration,
              curve: Curves.easeOutCubic,
              width: collapsed ? barHeight : constraints.maxWidth,
              height: barHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.ink,
                borderRadius: BorderRadius.circular(barHeight / 2),
                border: isDark ? Border.all(color: AppColors.dividerDark) : null,
              ),
              child: Stack(
                children: [
                  _Layer(
                    visible: !collapsed,
                    duration: duration,
                    child: OverflowBox(
                      alignment: AlignmentDirectional.centerStart,
                      minWidth: constraints.maxWidth,
                      maxWidth: constraints.maxWidth,
                      child: _Tabs(items: items, currentIndex: currentIndex, onTap: onTap),
                    ),
                  ),
                  _Layer(
                    visible: collapsed,
                    duration: duration,
                    child: _CollapsedTab(item: items[currentIndex], onTap: onExpand),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The same destinations as [MazlNavBar], as a vertical ink capsule on the
/// leading side, for a regular-width window. Same buttons, same selected
/// state, same [MazlNavBar.gap] from the edges and from the system areas; the
/// leading inset (it can differ from the trailing one) is added to the gap.
class MazlNavRail extends StatelessWidget {
  const MazlNavRail({super.key, required this.items, required this.currentIndex, required this.onTap});

  final List<MazlNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Horizontal room the rail takes, given the safe-area insets.
  static double reservedWidth(EdgeInsets safe, TextDirection direction) =>
      safe.startFor(direction) + MazlNavBar.gap + MazlNavBar.barHeight + MazlNavBar.gap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safe = MediaQuery.paddingOf(context);
    final direction = Directionality.of(context);
    return SizedBox(
      width: reservedWidth(safe, direction),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          safe.startFor(direction) + MazlNavBar.gap,
          safe.top + MazlNavBar.gap,
          MazlNavBar.gap,
          safe.bottom + MazlNavBar.gap,
        ),
        child: Center(
          child: Container(
            key: const Key('mazl-nav-rail'),
            width: MazlNavBar.barHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.ink,
              borderRadius: BorderRadius.circular(MazlNavBar.barHeight / 2),
              border: isDark ? Border.all(color: AppColors.dividerDark) : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Each button is as wide as the capsule: the whole width is
              // tappable, not only the icon (Apple: 44 x 44 pt at least).
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++)
                  _NavButton(item: items[i], selected: i == currentIndex, onTap: () => onTap(i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The same destinations as [MazlNavBar], in the vertical bar of the
/// foldable iPhone (closed, or held sideways): the column along one side that
/// iOS gives to the status bar, the Dynamic Island and the app's bars.
///
/// As Apple's own tab bar does there, it is an icon-only ink capsule aligned
/// to the BOTTOM of the room it is given ([VerticalBarGeometry.controls]),
/// within reach of the thumb. When the room is short, the buttons get smaller
/// before the capsule scrolls; the labels stay for VoiceOver.
class MazlNavStrip extends StatelessWidget {
  const MazlNavStrip({super.key, required this.items, required this.currentIndex, required this.onTap});

  static const width = 56.0;
  static const itemExtent = 52.0;
  static const minItemExtent = 44.0;
  static const _padding = 4.0;

  final List<MazlNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxHeight - 2 * _padding;
        final extent = (room / items.length).clamp(minItemExtent, itemExtent).toDouble();
        final capsule = Container(
          key: const Key('mazl-nav-strip'),
          width: width,
          padding: const EdgeInsets.symmetric(vertical: _padding),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.ink,
            borderRadius: BorderRadius.circular(width / 2),
            border: isDark ? Border.all(color: AppColors.dividerDark) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Each button is as wide as the capsule: the whole width is
            // tappable, not only the icon (Apple: 44 x 44 pt at least).
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavButton(item: items[i], selected: i == currentIndex, onTap: () => onTap(i), extent: extent),
            ],
          ),
        );
        return Align(
          alignment: Alignment.bottomCenter,
          child: SingleChildScrollView(reverse: true, child: capsule),
        );
      },
    );
  }
}

/// One of the two faces of the bar: fades, and is neither tappable nor read
/// out loud while hidden. The leaving face is gone in the first third of the
/// resize and the arriving one only shows in the second half, so the pill's
/// icon never lands on top of the first tab's.
class _Layer extends StatelessWidget {
  const _Layer({required this.visible, required this.duration, required this.child});

  static const _leave = Interval(0, 0.35, curve: Curves.easeOut);
  static const _arrive = Interval(0.5, 1, curve: Curves.easeOut);

  final bool visible;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !visible,
    child: ExcludeSemantics(
      excluding: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        curve: visible ? _arrive : _leave,
        child: child,
      ),
    ),
  );
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.items, required this.currentIndex, required this.onTap});

  final List<MazlNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < items.length; i++)
        Expanded(
          child: _NavButton(item: items[i], selected: i == currentIndex, onTap: () => onTap(i)),
        ),
    ],
  );
}

class _CollapsedTab extends StatelessWidget {
  const _CollapsedTab({required this.item, required this.onTap});

  final MazlNavItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: context.l10n.navigationShowTabs,
    value: item.label,
    child: InkResponse(
      onTap: onTap,
      radius: 28,
      child: SizedBox.square(
        dimension: MazlNavBar.barHeight,
        child: Icon(item.icon, size: 22, color: Colors.white),
      ),
    ),
  );
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.extent = MazlNavBar.barHeight,
  });

  final MazlNavItem item;
  final bool selected;
  final VoidCallback onTap;

  /// Height of the button (its width comes from the bar).
  final double extent;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.iconOnInk;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          height: extent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 22, color: color),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
