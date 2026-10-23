import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Beautiful celebration screen shown when couple mode is activated
class MazelTovScreen extends StatefulWidget {
  const MazelTovScreen({
    super.key,
    required this.partnerName,
    this.partnerPicture,
    this.myPicture,
  });

  final String partnerName;
  final String? partnerPicture;
  final String? myPicture;

  static Future<void> show(
    BuildContext context, {
    required String partnerName,
    String? partnerPicture,
    String? myPicture,
    required VoidCallback onContinue,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: AppColors.ink,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _MazelTovScreenWrapper(
              partnerName: partnerName,
              partnerPicture: partnerPicture,
              myPicture: myPicture,
              onContinue: onContinue,
            ),
          );
        },
      ),
    );
  }

  @override
  State<MazelTovScreen> createState() => _MazelTovScreenState();
}

class _MazelTovScreenWrapper extends StatelessWidget {
  const _MazelTovScreenWrapper({
    required this.partnerName,
    this.partnerPicture,
    this.myPicture,
    required this.onContinue,
  });

  final String partnerName;
  final String? partnerPicture;
  final String? myPicture;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _MazelTovContent(
      partnerName: partnerName,
      partnerPicture: partnerPicture,
      myPicture: myPicture,
      onContinue: () {
        Navigator.of(context).pop();
        onContinue();
      },
    );
  }
}

class _MazelTovContent extends StatefulWidget {
  const _MazelTovContent({
    required this.partnerName,
    this.partnerPicture,
    this.myPicture,
    required this.onContinue,
  });

  final String partnerName;
  final String? partnerPicture;
  final String? myPicture;
  final VoidCallback onContinue;

  @override
  State<_MazelTovContent> createState() => _MazelTovContentState();
}

class _MazelTovContentState extends State<_MazelTovContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
          child: FadeTransition(
            opacity: fade,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        _buildTitle(context),
                        const SizedBox(height: 40),
                        _buildCoupleVisual(),
                        const SizedBox(height: 40),
                        _buildMessage(context),
                        const Spacer(flex: 3),
                        _buildContinueButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          'מזל טוב',
          textDirection: TextDirection.rtl,
          style: textTheme.titleMedium?.copyWith(color: AppColors.tekheletLight),
        ),
        const SizedBox(height: 8),
        Text(
          'Mazal tov',
          textAlign: TextAlign.center,
          style: textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildCoupleVisual() {
    // The two avatars start slightly apart and settle next to the heart.
    final approach = CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: approach,
      builder: (context, _) {
        final gap = 24 * (1 - approach.value);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(-gap, 0),
              child: _buildProfileCircle(
                picture: widget.myPicture,
                fallbackIcon: LucideIcons.user,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.tekhelet,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.heart, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Transform.translate(
              offset: Offset(gap, 0),
              child: _buildProfileCircle(
                picture: widget.partnerPicture,
                fallbackText: widget.partnerName,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileCircle({
    String? picture,
    IconData? fallbackIcon,
    String? fallbackText,
  }) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(3),
      child: ClipOval(
        child: picture != null
            ? CachedNetworkImage(
                imageUrl: picture,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: AppColors.cardDark),
              )
            : ColoredBox(
                color: AppColors.cardDark,
                child: Center(
                  child: fallbackIcon != null
                      ? Icon(fallbackIcon, color: AppColors.textSecondaryDark, size: 36)
                      : Text(
                          fallbackText?.isNotEmpty == true
                              ? fallbackText!.characters.first.toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          'Félicitations à vous et à ${widget.partnerName}',
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'MAZL vous accompagne dans cette nouvelle étape.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondaryDark,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: widget.onContinue,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Commencer notre aventure',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Icon(LucideIcons.arrowRight, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MazelTovScreenState extends State<MazelTovScreen> {
  @override
  Widget build(BuildContext context) {
    return _MazelTovContent(
      partnerName: widget.partnerName,
      partnerPicture: widget.partnerPicture,
      myPicture: widget.myPicture,
      onContinue: () => context.go('/couple/activities'),
    );
  }
}
