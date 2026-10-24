import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import '../../../common/widgets/glass_container.dart';

class AISuggestionsScreen extends StatefulWidget {
  const AISuggestionsScreen({super.key});

  @override
  State<AISuggestionsScreen> createState() => _AISuggestionsScreenState();
}

class _AISuggestionsScreenState extends State<AISuggestionsScreen> {
  final List<_Suggestion> _suggestions = [
    const _Suggestion(
      name: 'Rachel',
      age: 26,
      city: 'Paris',
      compatibilityScore: 95,
      reasons: [
        _Reason.samePractice,
        _Reason.interests,
        _Reason.goals,
      ],
      color: AppColors.secondary,
    ),
    const _Suggestion(
      name: 'Leah',
      age: 24,
      city: 'Lyon',
      compatibilityScore: 88,
      reasons: [
        _Reason.family,
        _Reason.music,
        _Reason.location,
      ],
      color: AppColors.accent,
    ),
    const _Suggestion(
      name: 'Miriam',
      age: 27,
      city: 'Paris',
      compatibilityScore: 82,
      reasons: [
        _Reason.religion,
        _Reason.profession,
        _Reason.couple,
      ],
      color: AppColors.primary,
    ),
  ];

  void _handlePass(_Suggestion suggestion) {
    setState(() => _suggestions.remove(suggestion));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.shadchanPassed(suggestion.name))),
    );
  }

  void _handleLike(_Suggestion suggestion) {
    setState(() => _suggestions.remove(suggestion));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.shadchanLiked(suggestion.name)),
        backgroundColor: AppColors.likeGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.shadchanTitle),
        leading: IconButton(
          icon: const DirectionalIcon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          GlassGradientContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  '🤖',
                  style: TextStyle(fontSize: 48),
                ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.shadchanHeaderTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.shadchanHeaderBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Today's suggestions
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.shadchanTodayTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.sparkles, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.shadchanNewCount(_suggestions.length),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Suggestion cards
          if (_suggestions.isEmpty)
            _EmptySuggestions(onDiscover: () => context.go(RoutePaths.discover))
          else
            ..._suggestions.map(
              (suggestion) => _SuggestionCard(
                suggestion: suggestion,
                onPass: () => _handlePass(suggestion),
                onLike: () => _handleLike(suggestion),
              ),
            ),

          const SizedBox(height: 24),

          // How it works
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.lightbulb, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.shadchanHowTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _HowItWorksStep(
                    number: '1',
                    text: context.l10n.shadchanHowStepAnalyze,
                  ),
                  _HowItWorksStep(
                    number: '2',
                    text: context.l10n.shadchanHowStepCompare,
                  ),
                  _HowItWorksStep(
                    number: '3',
                    text: context.l10n.shadchanHowStepDaily,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Suggestion {
  const _Suggestion({
    required this.name,
    required this.age,
    required this.city,
    required this.compatibilityScore,
    required this.reasons,
    required this.color,
  });

  final String name;
  final int age;
  final String city;
  final int compatibilityScore;
  final List<_Reason> reasons;
  final Color color;
}

/// Why a profile is suggested. The words come from the member's language.
enum _Reason {
  samePractice,
  interests,
  goals,
  family,
  music,
  location,
  religion,
  profession,
  couple;

  String text(AppLocalizations l10n) => switch (this) {
    samePractice => l10n.shadchanReasonSamePractice,
    interests => l10n.shadchanReasonInterests,
    goals => l10n.shadchanReasonGoals,
    family => l10n.shadchanReasonFamily,
    music => l10n.shadchanReasonMusic,
    location => l10n.shadchanReasonLocation,
    religion => l10n.shadchanReasonReligion,
    profession => l10n.shadchanReasonProfession,
    couple => l10n.shadchanReasonCouple,
  };
}

class _EmptySuggestions extends StatelessWidget {
  const _EmptySuggestions({required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(LucideIcons.sparkles, size: 40, color: AppColors.accent),
            const SizedBox(height: 12),
            Text(
              context.l10n.shadchanEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.shadchanEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onDiscover,
              icon: const Icon(LucideIcons.compass),
              label: Text(context.l10n.shadchanEmptyAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.onPass,
    required this.onLike,
  });

  final _Suggestion suggestion;
  final VoidCallback onPass;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: suggestion.color,
                  child: Text(
                    suggestion.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${suggestion.name}, ${suggestion.age}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            suggestion.city,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _CompatibilityBadge(score: suggestion.compatibilityScore),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.sparkles, size: 16, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.shadchanWhy,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...suggestion.reasons.map((reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.check, size: 14, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                reason.text(context.l10n),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPass,
                    child: Text(context.l10n.matchingCardPass),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onLike,
                    child: Text(context.l10n.matchingCardLike),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompatibilityBadge extends StatelessWidget {
  const _CompatibilityBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 90
        ? AppColors.success
        : score >= 80
            ? AppColors.primary
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$score%',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            context.l10n.shadchanMatchBadge,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
