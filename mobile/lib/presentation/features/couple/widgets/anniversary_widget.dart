import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/api_service.dart' hide ProfilePhoto;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/milestone_label.dart';

IconData _iconForName(String iconName) {
  switch (iconName) {
    case 'seedling':
      return LucideIcons.sprout;
    case 'heart':
      return LucideIcons.heart;
    case 'star':
      return LucideIcons.star;
    case 'fire':
      return LucideIcons.flame;
    case 'crown':
      return LucideIcons.crown;
    case 'diamond':
      return LucideIcons.gem;
    default:
      return LucideIcons.heart;
  }
}

/// Pastille cœur tekhelet posée entre les deux photos du couple.
class _HeartDot extends StatelessWidget {
  const _HeartDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: size,
      height: size,
      decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
      child: Icon(LucideIcons.heart, color: scheme.onPrimary, size: size / 2),
    );
  }
}

/// Widget for displaying couple anniversary information
class AnniversaryWidget extends StatelessWidget {
  const AnniversaryWidget({
    super.key,
    required this.anniversaryData,
    this.onShare,
  });

  final CoupleAnniversaryData anniversaryData;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final muted = TextStyle(fontSize: 15, color: scheme.onSurfaceVariant);
    final isAnniversary = anniversaryData.isAnniversaryToday;
    final current = anniversaryData.currentMilestone;
    final next = anniversaryData.nextMilestone;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (isAnniversary) ...[
                  TagPill(
                    l10n.coupleSpaceAnniversaryTag,
                    icon: LucideIcons.partyPopper,
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _photo(anniversaryData.myPhotoUrl, 0, 72),
                    const _HeartDot(size: 32),
                    _photo(anniversaryData.partnerPhotoUrl, 1, 72),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '${anniversaryData.daysTogether}',
                  style: TextStyle(
                    fontFamily: AppTypography.family,
                    color: scheme.onSurface,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.coupleSpaceAnniversaryDaysLabel(
                    anniversaryData.daysTogether,
                  ),
                  style: muted,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.coupleSpaceAnniversaryWith(anniversaryData.partnerName),
                  style: muted,
                ),
                if (current != null) ...[
                  const SizedBox(height: 16),
                  TagPill(current.name(l10n), icon: _iconForName(current.icon)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Row(
              children: [
                if (next != null) ...[
                  Icon(
                    _iconForName(next.icon),
                    color: scheme.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.coupleSpaceAnniversaryNext(
                        next.name(l10n),
                        next.daysUntil ?? 0,
                      ),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(LucideIcons.share2, size: 16),
                  label: Text(l10n.commonShare),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 44),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _photo(String? url, int seed, double size) {
  return SizedBox.square(
    dimension: size,
    child: ProfilePhoto(
      url: url,
      seed: seed,
      radius: size / 2,
      iconSize: size / 2.5,
    ),
  );
}

/// Anniversary celebration dialog
class AnniversaryCelebrationDialog extends StatefulWidget {
  const AnniversaryCelebrationDialog({
    super.key,
    required this.anniversaryData,
  });

  final CoupleAnniversaryData anniversaryData;

  static Future<void> show(
    BuildContext context,
    CoupleAnniversaryData anniversaryData,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AnniversaryCelebrationDialog(anniversaryData: anniversaryData),
    );
  }

  @override
  State<AnniversaryCelebrationDialog> createState() =>
      _AnniversaryCelebrationDialogState();
}

class _AnniversaryCelebrationDialogState
    extends State<AnniversaryCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final ApiService _apiService = ApiService();
  bool _isGeneratingCard = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _shareCard() async {
    final l10n = context.l10n;
    final milestone = widget.anniversaryData.currentMilestone;
    final text = l10n.coupleSpaceAnniversaryShare(
      widget.anniversaryData.daysTogether,
      milestone?.name(l10n) ?? '',
    );
    setState(() => _isGeneratingCard = true);

    final result = await _apiService.generateAnniversaryCard();

    if (mounted) {
      setState(() => _isGeneratingCard = false);

      if (result.success && result.data != null && result.data!.isNotEmpty) {
        await Share.share(text);
      } else {
        // Fallback to simple share
        await Share.share(text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final milestone = widget.anniversaryData.currentMilestone;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.partyPopper,
                  color: scheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.coupleSpaceAnniversaryHappy,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (milestone != null) ...[
                const SizedBox(height: 12),
                TagPill(milestone.name(l10n)),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _photo(widget.anniversaryData.myPhotoUrl, 0, 56),
                  const _HeartDot(size: 28),
                  _photo(widget.anniversaryData.partnerPhotoUrl, 1, 56),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.coupleSpaceAnniversaryDaysWith(
                  widget.anniversaryData.daysTogether,
                  widget.anniversaryData.partnerName,
                ),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isGeneratingCard ? null : _shareCard,
                      icon: _isGeneratingCard
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.share2, size: 18),
                      label: Text(_isGeneratingCard ? '' : l10n.commonShare),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.coupleSpaceAnniversaryThanks),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Milestones timeline widget
class MilestonesTimeline extends StatelessWidget {
  const MilestonesTimeline({
    super.key,
    required this.milestones,
    required this.daysTogether,
  });

  final List<CoupleMilestone> milestones;
  final int daysTogether;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(l10n.coupleSpaceMilestonesTitle),
            const SizedBox(height: 16),
            ...milestones.map((milestone) {
              final isReached = daysTogether >= milestone.days;
              final isCurrent =
                  isReached &&
                  (milestones.indexOf(milestone) == milestones.length - 1 ||
                      daysTogether <
                          milestones[milestones.indexOf(milestone) + 1].days);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(color: scheme.primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        _iconForName(milestone.icon),
                        color: isReached
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.name(l10n),
                            style: TextStyle(
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isReached
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                          if (!isReached && milestone.daysUntil != null)
                            Text(
                              l10n.coupleSpaceMilestoneIn(milestone.daysUntil!),
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isReached)
                      const Icon(
                        LucideIcons.check,
                        color: AppColors.success,
                        size: 20,
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
