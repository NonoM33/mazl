import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/mazl_sheet.dart';
import '../l10n/couple_feed_labels.dart';
import '../l10n/couple_feed_service_content.dart';
import 'success_stories_screen.dart';

class CoupleDashboardScreen extends StatefulWidget {
  const CoupleDashboardScreen({super.key});

  @override
  State<CoupleDashboardScreen> createState() => _CoupleDashboardScreenState();
}

class _CoupleDashboardScreenState extends State<CoupleDashboardScreen> {
  final CoupleService _coupleService = CoupleService();

  @override
  void initState() {
    super.initState();
    _coupleService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final coupleData = _coupleService.coupleData;
    final daysTogether = coupleData?.daysTogether ?? 0;
    final milestones = _coupleService.getMilestones();
    final activities = _coupleService.getCoupleActivities();
    final questions = _coupleService.getDailyQuestions();
    final bottom = MediaQuery.paddingOf(context).bottom;
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(24, 16, 24, bottom + 16),
          children: [
            _buildTopBar(),
            const SizedBox(height: 16),
            _buildCoupleHeader(coupleData, daysTogether),
            const SizedBox(height: 16),
            _buildDailyQuestionCard(questions.first),
            const SizedBox(height: 32),
            SectionLabel(l10n.coupleFeedDashboardActivities),
            const SizedBox(height: 12),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: activities.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _buildActivityCard(activities[index]),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: SectionLabel(l10n.coupleFeedDashboardMilestones)),
                TextButton(
                  onPressed: () {
                    // Show all milestones
                  },
                  child: Text(l10n.coupleFeedDashboardSeeAll),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...milestones.take(3).map(_buildMilestoneCard),
            const SizedBox(height: 32),
            SectionLabel(l10n.coupleFeedDashboardEvents),
            const SizedBox(height: 12),
            _buildCoupleEventsCard(),
            const SizedBox(height: 32),
            SectionLabel(l10n.coupleFeedDashboardJewishCalendar),
            const SizedBox(height: 12),
            _buildJewishCalendarCard(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: SectionLabel(l10n.coupleFeedStoriesTitle)),
                TextButton(
                  onPressed: () => context.push(RoutePaths.successStories),
                  child: Text(l10n.coupleFeedDashboardSeeAllStories),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildSuccessStoriesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        RoundIconButton(
          icon: backArrowIcon(context),
          tooltip: context.l10n.commonBack,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/profile');
            }
          },
        ),
        const Spacer(),
        RoundIconButton(
          icon: LucideIcons.settings,
          tooltip: context.l10n.coupleFeedDashboardSettingsTooltip,
          onPressed: () {
            // Navigate to couple settings
          },
        ),
      ],
    );
  }

  Widget _buildCoupleHeader(CoupleData? coupleData, int daysTogether) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return _SurfaceCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatar(l10n.coupleFeedDashboardMe, null, 0),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.heart,
                  size: 16,
                  color: scheme.onPrimary,
                ),
              ),
              _buildAvatar(
                coupleData?.partnerName ??
                    l10n.coupleFeedDashboardPartnerFallback,
                coupleData?.partnerPicture,
                1,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.coupleFeedDashboardDaysTogether(daysTogether),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, String? imageUrl, int seed) {
    return Column(
      children: [
        SizedBox.square(
          dimension: 72,
          child: ProfilePhoto(url: imageUrl, seed: seed, radius: 36),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDailyQuestionCard(DailyQuestion question) {
    final l10n = context.l10n;
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SectionLabel(l10n.coupleFeedDashboardDailyQuestion)),
              TagPill(questionCategory(l10n, question)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            questionText(l10n, question),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAnswerDialog(question),
              child: Text(l10n.coupleFeedDashboardAnswer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    IconData icon;
    switch (activity['icon']) {
      case 'utensils':
        icon = LucideIcons.utensilsCrossed;
        break;
      case 'book':
        icon = LucideIcons.bookOpen;
        break;
      case 'heart':
        icon = LucideIcons.heart;
        break;
      case 'dumbbell':
        icon = LucideIcons.dumbbell;
        break;
      case 'hand-heart':
        icon = LucideIcons.heartHandshake;
        break;
      case 'plane':
        icon = LucideIcons.plane;
        break;
      default:
        icon = LucideIcons.sparkles;
    }

    return Container(
      width: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: scheme.primary),
          const Spacer(),
          Text(
            ideaTitle(l10n, activity),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            ideaCategory(l10n, activity),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(CoupleMilestone milestone) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(
            milestone.isAchieved ? LucideIcons.trophy : LucideIcons.flag,
            size: 22,
            color: milestone.isAchieved
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestoneTitle(l10n, milestone),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  milestoneLine(l10n, milestone),
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (milestone.isAchieved)
            const Icon(LucideIcons.circleCheck, color: AppColors.success)
          else
            Icon(LucideIcons.circle, color: scheme.outline),
        ],
      ),
    );
  }

  Widget _buildCoupleEventsCard() {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return _SurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.calendarHeart, color: scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.coupleFeedDashboardEventSampleTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      l10n.coupleFeedDashboardEventSampleWhen,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TagPill(l10n.coupleFeedDashboardEventSampleTag),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Navigate to events
              },
              child: Text(l10n.coupleFeedDashboardAllEvents),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJewishCalendarCard() {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return _SurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.moonStar, color: scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.coupleFeedDashboardParasha,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      l10n.coupleFeedDashboardShabbatTimes,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.flame, color: scheme.primary),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShabbatSuggestion(
                l10n.coupleFeedDashboardShabbatDinner,
                LucideIcons.utensilsCrossed,
              ),
              _buildShabbatSuggestion(
                l10n.coupleFeedDashboardShabbatPrayer,
                LucideIcons.bookOpen,
              ),
              _buildShabbatSuggestion(
                l10n.coupleFeedDashboardShabbatRest,
                LucideIcons.bed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShabbatSuggestion(String label, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: scheme.primary),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _showAnswerDialog(DailyQuestion question) {
    final controller = TextEditingController();
    final l10n = context.l10n;

    showMazlSheet(
      context,
      isScrollControlled: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionText(l10n, question),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (question.options != null) ...[
            ...question.options!.indexed.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAnswerSentSnackbar();
                    },
                    child: Text(
                      questionOption(l10n, question, option.$1),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.coupleFeedDashboardAnswerHint,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAnswerSentSnackbar();
                },
                child: Text(l10n.coupleFeedDashboardSend),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAnswerSentSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.check, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(context.l10n.coupleFeedDashboardAnswerSent)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSuccessStoriesCard() {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return _SurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.heart, color: scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.coupleFeedStoryShareTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.coupleFeedDashboardShareStoryLine,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(RoutePaths.successStories),
                  child: Text(l10n.coupleFeedDashboardSeeStories),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await SubmitSuccessStoryDialog.show(context);
                    if (result == true) {
                      // Story submitted
                    }
                  },
                  child: Text(l10n.commonShare),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Une carte brume, rayon 24, sans ombre ni dégradé.
class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}
