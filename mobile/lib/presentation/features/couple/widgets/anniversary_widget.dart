import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget for displaying couple anniversary information
class AnniversaryWidget extends StatelessWidget {
  const AnniversaryWidget({
    super.key,
    required this.anniversaryData,
    this.onShare,
  });

  final CoupleAnniversaryData anniversaryData;
  final VoidCallback? onShare;

  IconData _getIconForName(String iconName) {
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

  @override
  Widget build(BuildContext context) {
    final isAnniversary = anniversaryData.isAnniversaryToday;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAnniversary
              ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
              : [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isAnniversary ? const Color(0xFFFF6B6B) : AppColors.primary)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Anniversary indicator
                if (isAnniversary)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.partyPopper,
                            color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Joyeux Anniversaire MAZL !',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Couple photos
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPhotoCircle(anniversaryData.myPhotoUrl),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.heart,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    _buildPhotoCircle(anniversaryData.partnerPhotoUrl),
                  ],
                ),

                const SizedBox(height: 20),

                // Days counter
                Text(
                  '${anniversaryData.daysTogether}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'jours ensemble',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 16),

                // Partner name
                Text(
                  'avec ${anniversaryData.partnerName}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),

                // Current milestone badge
                if (anniversaryData.currentMilestone != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForName(
                              anniversaryData.currentMilestone!.icon),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          anniversaryData.currentMilestone!.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Next milestone and share button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                if (anniversaryData.nextMilestone != null) ...[
                  Icon(
                    _getIconForName(anniversaryData.nextMilestone!.icon),
                    color: Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Prochain: ${anniversaryData.nextMilestone!.label} dans ${anniversaryData.nextMilestone!.daysUntil ?? 0} jours',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                TextButton.icon(
                  onPressed: onShare,
                  icon: const Icon(LucideIcons.share2,
                      size: 16, color: Colors.white),
                  label: const Text(
                    'Partager',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCircle(String? photoUrl) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: Icon(LucideIcons.user, color: Colors.grey[400]),
                ),
              )
            : Container(
                color: Colors.grey[300],
                child: Icon(LucideIcons.user, color: Colors.grey[400]),
              ),
      ),
    );
  }
}

/// Anniversary celebration dialog
class AnniversaryCelebrationDialog extends StatefulWidget {
  const AnniversaryCelebrationDialog({
    super.key,
    required this.anniversaryData,
  });

  final CoupleAnniversaryData anniversaryData;

  static Future<void> show(
      BuildContext context, CoupleAnniversaryData anniversaryData) {
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
    setState(() => _isGeneratingCard = true);

    final result = await _apiService.generateAnniversaryCard();

    if (mounted) {
      setState(() => _isGeneratingCard = false);

      if (result.success && result.data != null && result.data!.isNotEmpty) {
        await Share.share(
          'Nous fetons ${widget.anniversaryData.daysTogether} jours ensemble sur MAZL ! ${widget.anniversaryData.currentMilestone?.label ?? ""} ❤️',
        );
      } else {
        // Fallback to simple share
        await Share.share(
          'Nous fetons ${widget.anniversaryData.daysTogether} jours ensemble sur MAZL ! ${widget.anniversaryData.currentMilestone?.label ?? ""} ❤️',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final milestone = widget.anniversaryData.currentMilestone;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.partyPopper,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Joyeux Anniversaire !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Milestone
              if (milestone != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    milestone.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Partner photos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSmallPhotoCircle(widget.anniversaryData.myPhotoUrl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      LucideIcons.heart,
                      color: Colors.white.withOpacity(0.9),
                      size: 24,
                    ),
                  ),
                  _buildSmallPhotoCircle(
                      widget.anniversaryData.partnerPhotoUrl),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                '${widget.anniversaryData.daysTogether} jours avec ${widget.anniversaryData.partnerName}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isGeneratingCard ? null : _shareCard,
                      icon: _isGeneratingCard
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(LucideIcons.share2,
                              color: Colors.white, size: 18),
                      label: Text(
                        _isGeneratingCard ? '' : 'Partager',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6B6B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Merci !',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildSmallPhotoCircle(String? photoUrl) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child:
                      Icon(LucideIcons.user, color: Colors.grey[400], size: 20),
                ),
              )
            : Container(
                color: Colors.grey[300],
                child:
                    Icon(LucideIcons.user, color: Colors.grey[400], size: 20),
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

  IconData _getIconForName(String iconName) {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.milestone, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Vos Milestones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...milestones.map((milestone) {
              final isReached = daysTogether >= milestone.days;
              final isCurrent = isReached &&
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
                        color: isReached
                            ? (milestone.isSpecial
                                ? AppColors.accentGold.withOpacity(0.2)
                                : AppColors.primary.withOpacity(0.15))
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        _getIconForName(milestone.icon),
                        color: isReached
                            ? (milestone.isSpecial
                                ? AppColors.accentGold
                                : AppColors.primary)
                            : Colors.grey[400],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.label,
                            style: TextStyle(
                              fontWeight:
                                  isCurrent ? FontWeight.bold : FontWeight.w500,
                              color:
                                  isReached ? Colors.black : Colors.grey[500],
                            ),
                          ),
                          if (!isReached && milestone.daysUntil != null)
                            Text(
                              'dans ${milestone.daysUntil} jours',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isReached)
                      Icon(
                        LucideIcons.check,
                        color: milestone.isSpecial
                            ? AppColors.accentGold
                            : AppColors.success,
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
