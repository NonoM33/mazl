import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : _duration;
    return Padding(
      padding: EdgeInsets.fromLTRB(sideMargin, 0, sideMargin, safeBottom + gap),
      child: SizedBox(
        height: barHeight,
        child: LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.centerLeft,
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
                      alignment: Alignment.centerLeft,
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
    label: 'Afficher les onglets',
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
  const _NavButton({required this.item, required this.selected, required this.onTap});

  final MazlNavItem item;
  final bool selected;
  final VoidCallback onTap;

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
          height: MazlNavBar.barHeight,
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
