import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/mazl_sheet.dart';
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
            const SectionLabel('Activités en couple'),
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
                const Expanded(child: SectionLabel('Nos étapes')),
                TextButton(
                  onPressed: () {
                    // Show all milestones
                  },
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...milestones.take(3).map(_buildMilestoneCard),
            const SizedBox(height: 32),
            const SectionLabel('Événements en couple'),
            const SizedBox(height: 12),
            _buildCoupleEventsCard(),
            const SizedBox(height: 32),
            const SectionLabel('Calendrier juif'),
            const SizedBox(height: 12),
            _buildJewishCalendarCard(),
            const SizedBox(height: 32),
            Row(
              children: [
                const Expanded(child: SectionLabel('Histoires de couples')),
                TextButton(
                  onPressed: () => context.push(RoutePaths.successStories),
                  child: const Text('Voir toutes'),
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
          icon: LucideIcons.arrowLeft,
          tooltip: 'Retour',
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
          tooltip: 'Réglages',
          onPressed: () {
            // Navigate to couple settings
          },
        ),
      ],
    );
  }

  Widget _buildCoupleHeader(CoupleData? coupleData, int daysTogether) {
    final scheme = Theme.of(context).colorScheme;
    return _SurfaceCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatar('Moi', null, 0),
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
                coupleData?.partnerName ?? 'Partenaire',
                coupleData?.partnerPicture,
                1,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$daysTogether jours ensemble',
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
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionLabel('Question du jour')),
              TagPill(question.category),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.question,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAnswerDialog(question),
              child: const Text('Répondre'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final scheme = Theme.of(context).colorScheme;
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
            activity['title'],
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            activity['category'],
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(CoupleMilestone milestone) {
    final scheme = Theme.of(context).colorScheme;
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
                  milestone.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  milestone.description,
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
                    const Text(
                      'Cours de cuisine casher',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Dimanche 20 janvier - 15h00',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const TagPill('Couples'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Navigate to events
              },
              child: const Text('Voir tous les événements'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJewishCalendarCard() {
    final scheme = Theme.of(context).colorScheme;
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
                    const Text(
                      'Shabbat Beshalach',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Entrée : 17h23 - Sortie : 18h34',
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
              _buildShabbatSuggestion('Dîner', LucideIcons.utensilsCrossed),
              _buildShabbatSuggestion('Prière', LucideIcons.bookOpen),
              _buildShabbatSuggestion('Repos', LucideIcons.bed),
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

    showMazlSheet(
      context,
      isScrollControlled: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (question.options != null) ...[
            ...question.options!.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAnswerSentSnackbar();
                    },
                    child: Text(option, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ] else ...[
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Votre réponse…'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAnswerSentSnackbar();
                },
                child: const Text('Envoyer'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAnswerSentSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.check, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Réponse envoyée. Votre partenaire sera notifié(e).'),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSuccessStoriesCard() {
    final scheme = Theme.of(context).colorScheme;
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
                    const Text(
                      'Partagez votre histoire',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Inspirez la communauté MAZL avec votre histoire',
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
                  child: const Text('Voir les histoires'),
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
                  child: const Text('Partager'),
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
