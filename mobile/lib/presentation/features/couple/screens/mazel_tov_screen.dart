import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import '../../../common/widgets/paired_avatars.dart';
import '../widgets/book_pages.dart';
import '../../../../core/images/mazl_network_image.dart';

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
            child: FoldCutBuilder(
              minPaneExtent: bookPaneExtent,
              builder: (context, cut) => cut?.axis == FoldSplitAxis.vertical
                  ? _buildBook(cut!)
                  : _buildFlat(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlat() {
    return CustomScrollView(
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
    );
  }

  /// Held like a book: the celebration to look at on the first page (the
  /// blessing, the couple), the words and the way forward on the other.
  Widget _buildBook(FoldCut cut) {
    Widget page(List<Widget> children) => Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
    return bookPages(
      cut,
      lead: page([
        _buildTitle(context),
        const SizedBox(height: 40),
        _buildCoupleVisual(),
      ]),
      action: page([
        _buildMessage(context),
        const SizedBox(height: 40),
        _buildContinueButton(),
      ]),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    return Column(
      children: [
        // The Hebrew blessing sits above the title in every language; in
        // Hebrew the title is that blessing, so it is not written twice.
        if (l10n.localeName != 'he') ...[
          Text(
            'מזל טוב',
            textDirection: TextDirection.rtl,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.tekheletLight,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          l10n.coupleSpaceMazelTovTitle,
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
    final approach = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutCubic,
    );
    return PairedAvatars(
      progress: approach,
      startOffset: 24,
      first: _buildProfileCircle(
        picture: widget.myPicture,
        fallbackIcon: LucideIcons.user,
      ),
      second: _buildProfileCircle(
        picture: widget.partnerPicture,
        fallbackText: widget.partnerName,
      ),
      badge: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.tekhelet,
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.heart, color: Colors.white, size: 22),
      ),
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
            ? MazlNetworkImage(
                url: picture,
                placeholder: (_) =>
                    const ColoredBox(color: AppColors.cardDark),
              )
            : ColoredBox(
                color: AppColors.cardDark,
                child: Center(
                  child: fallbackIcon != null
                      ? Icon(
                          fallbackIcon,
                          color: AppColors.textSecondaryDark,
                          size: 36,
                        )
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
    final l10n = context.l10n;
    return Column(
      children: [
        Text(
          l10n.coupleSpaceMazelTovCongrats(widget.partnerName),
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
          l10n.coupleSpaceMazelTovWelcome,
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
    return FoldSafeActions(
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: widget.onContinue,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.ink,
            minimumSize: const Size.fromHeight(56),
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  context.l10n.coupleSpaceMazelTovStart,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const DirectionalIcon(LucideIcons.arrowRight, size: 20),
            ],
          ),
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
      onContinue: () => context.go(RoutePaths.coupleToday),
    );
  }
}
