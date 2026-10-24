import 'package:flutter/material.dart';

import '../../../../../core/motion/mazl_motion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/l10n.dart';
import '../../../../common/widgets/mazl_components.dart';

/// Galerie de photos : balayage, zones tactiles gauche/droite et compteur
/// « 1/4 ». Sans photo, un aplat neutre avec une silhouette.
class ProfilePhotoGallery extends StatefulWidget {
  const ProfilePhotoGallery({
    super.key,
    required this.photos,
    this.seed = 0,
    this.height = 440,
  });

  final List<String> photos;
  final int seed;
  final double height;

  @override
  State<ProfilePhotoGallery> createState() => _ProfilePhotoGalleryState();
}

class _ProfilePhotoGalleryState extends State<ProfilePhotoGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _hasSeveral => widget.photos.length > 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final target = _index + delta;
    if (target < 0 || target >= widget.photos.length) return;
    if (MazlMotion.reduced(context)) {
      _controller.jumpToPage(target);
      return;
    }
    _controller.animateToPage(
      target,
      duration: MazlMotion.galleryPageTurn,
      curve: MazlMotion.galleryPageCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.photos.isEmpty)
              ProfilePhoto(seed: widget.seed, radius: 0, iconSize: 56)
            else
              PageView.builder(
                controller: _controller,
                itemCount: widget.photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => ProfilePhoto(
                  url: widget.photos[i],
                  seed: widget.seed,
                  radius: 0,
                  iconSize: 56,
                ),
              ),
            if (_hasSeveral) ...[
              // Le début de la ligne : à gauche en français, à droite en hébreu,
              // où la page précédente est de ce côté.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _TapZone(
                  label: context.l10n.profilePhotoPrevious,
                  onTap: () => _go(-1),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _TapZone(
                  label: context.l10n.profilePhotoNext,
                  onTap: () => _go(1),
                ),
              ),
              PositionedDirectional(
                end: 16,
                bottom: 16,
                child: _Counter(current: _index + 1, total: widget.photos.length),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TapZone extends StatelessWidget {
  const _TapZone({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.3,
          height: double.infinity,
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.profilePhotoCounter(current, total),
      excludeSemantics: true,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('$current/$total', style: AppTypography.eyebrow(Colors.white)),
      ),
    );
  }
}
