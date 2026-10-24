import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/profile.dart';
import '../../../../core/motion/mazl_motion.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_sheet.dart';
import '../../../common/widgets/paired_avatars.dart';

/// What the person chose on the match sheet. `null` from [showMatchSheet]
/// means it was dismissed (drag down or tap outside).
enum MatchSheetChoice { message, keepDiscovering }

/// The « match » moment: a light sheet, not a full screen (the big
/// celebration is reserved for the couple's « Mazal tov »).
///
/// [myPhotoUrl] and [myName] default to the signed-in user.
Future<MatchSheetChoice?> showMatchSheet(
  BuildContext context, {
  required Profile matched,
  String? myPhotoUrl,
  String? myName,
}) {
  final me = AuthService().currentUser;
  return showMazlSheet<MatchSheetChoice>(
    context,
    builder: (_) => MatchSheetContent(
      matched: matched,
      myPhotoUrl: myPhotoUrl ?? me?.photoUrl,
      myName: myName ?? me?.displayName,
    ),
  );
}

/// Content of the sheet (the frame, handle and padding come from
/// [showMazlSheet]). Pops with a [MatchSheetChoice].
class MatchSheetContent extends StatefulWidget {
  const MatchSheetContent({super.key, required this.matched, this.myPhotoUrl, this.myName});

  static const avatarSize = 80.0;
  static const badgeSize = 32.0;

  /// Paper ring around each photo, so the two stay distinct where they touch.
  static const paperRing = 3.0;
  static const ringKey = Key('match-ring');
  static const myAvatarKey = Key('match-avatar-me');
  static const theirAvatarKey = Key('match-avatar-them');

  final Profile matched;
  final String? myPhotoUrl;
  final String? myName;

  @override
  State<MatchSheetContent> createState() => _MatchSheetContentState();
}

class _MatchSheetContentState extends State<MatchSheetContent> with TickerProviderStateMixin {
  late final AnimationController _meet = AnimationController(
    vsync: this,
    duration: MazlMotion.matchMeet,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: MazlMotion.matchPulse,
  );
  bool _started = false;
  bool _pulsing = false;
  Animation<double>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MazlMotion.reduced(context)) {
      _meet.value = 1;
      _touch(withRing: false);
      return;
    }
    // The photos wait for the sheet to be in place, so the slide is seen.
    final route = ModalRoute.of(context)?.animation;
    if (route == null || route.isCompleted) {
      _startMeet();
    } else {
      _route = route..addStatusListener(_onRouteStatus);
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _route?.removeStatusListener(_onRouteStatus);
    _route = null;
    _startMeet();
  }

  void _startMeet() {
    if (!mounted) return;
    _meet.forward().then((_) => _touch(withRing: true));
  }

  /// The photos touch: one haptic tick, and the ring pulses once.
  void _touch({required bool withRing}) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    if (!withRing) return;
    setState(() => _pulsing = true);
    _pulse.forward().then((_) {
      if (mounted) setState(() => _pulsing = false);
    });
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_onRouteStatus);
    _meet.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _choose(MatchSheetChoice choice) => Navigator.of(context).pop(choice);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final name = widget.matched.displayName?.trim();
    final l10n = context.l10n;
    final line = name == null || name.isEmpty
        ? l10n.matchingMatchLineAnonymous
        : l10n.matchingMatchLineNamed(name);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _buildPair(scheme)),
        const SizedBox(height: 24),
        Text(l10n.matchingMatchTitle, textAlign: TextAlign.center, style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          line,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => _choose(MatchSheetChoice.message),
          child: Text(l10n.matchingMatchSendMessage),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => _choose(MatchSheetChoice.keepDiscovering),
          child: Text(l10n.matchingMatchKeepDiscovering),
        ),
      ],
    );
  }

  Widget _buildPair(ColorScheme scheme) {
    final pair = PairedAvatars(
      progress: CurvedAnimation(parent: _meet, curve: MazlMotion.matchMeetCurve),
      startOffset: MazlMotion.matchApartOffset,
      placement: PairBadgePlacement.overlay,
      first: _MatchAvatar(
        key: MatchSheetContent.myAvatarKey,
        url: widget.myPhotoUrl,
        label: widget.myName,
      ),
      second: _MatchAvatar(
        key: MatchSheetContent.theirAvatarKey,
        url: widget.matched.photos.isEmpty ? null : widget.matched.photos.first,
        label: widget.matched.displayName,
      ),
      badge: Container(
        width: MatchSheetContent.badgeSize,
        height: MatchSheetContent.badgeSize,
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.surface, width: 3),
        ),
        child: Icon(LucideIcons.heart, color: scheme.onPrimary, size: 14),
      ),
    );
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [if (_pulsing) _buildRing(scheme), pair],
    );
  }

  /// One ring around the pair, growing and fading out. Not hit-testable.
  Widget _buildRing(ColorScheme scheme) {
    const size = MatchSheetContent.avatarSize;
    final t = CurvedAnimation(parent: _pulse, curve: MazlMotion.matchPulseCurve);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: t,
        builder: (context, _) => Opacity(
          key: MatchSheetContent.ringKey,
          opacity: 1 - t.value,
          child: Transform.scale(
            scale: 1 + (MazlMotion.matchPulseMaxScale - 1) * t.value,
            child: Container(
              width: size * 2,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size / 2),
                border: Border.all(color: scheme.primary, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round photo, or the initial on a neutral surface when there is none.
class _MatchAvatar extends StatelessWidget {
  const _MatchAvatar({super.key, this.url, this.label});

  final String? url;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = (label ?? '').trim();
    final fallback = ColoredBox(
      color: scheme.surfaceContainer,
      child: Center(
        child: Text(
          initial.isEmpty ? '?' : initial.characters.first.toUpperCase(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
        ),
      ),
    );
    return Container(
      width: MatchSheetContent.avatarSize,
      height: MatchSheetContent.avatarSize,
      padding: const EdgeInsets.all(MatchSheetContent.paperRing),
      decoration: BoxDecoration(color: scheme.surface, shape: BoxShape.circle),
      child: ClipOval(
        child: url == null || url!.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => ColoredBox(color: scheme.surfaceContainer),
                errorWidget: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}
