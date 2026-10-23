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
class MazlNavBar extends StatelessWidget {
  const MazlNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  static const barHeight = 64.0;
  static const gap = 12.0;
  static const sideMargin = 16.0;

  final List<MazlNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(sideMargin, 0, sideMargin, safeBottom + gap),
      child: Container(
        key: const Key('mazl-nav-bar'),
        height: barHeight,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.ink,
          borderRadius: BorderRadius.circular(barHeight / 2),
          border: isDark ? Border.all(color: AppColors.dividerDark) : null,
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
