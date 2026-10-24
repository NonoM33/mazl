import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_activity.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/activity_visual.dart';
import '../widgets/couple_message_view.dart';

class SavedActivitiesScreen extends StatefulWidget {
  const SavedActivitiesScreen({super.key, this.apiService});

  /// Injected by tests; the app uses the real service.
  final CoupleApiService? apiService;

  @override
  State<SavedActivitiesScreen> createState() => _SavedActivitiesScreenState();
}

class _SavedActivitiesScreenState extends State<SavedActivitiesScreen> {
  late final CoupleApiService _apiService =
      widget.apiService ?? CoupleApiService();
  List<CoupleActivity> _activities = [];
  bool _isLoading = true;
  CoupleFailure? _failure;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final result = await _apiService.getSavedActivities();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      switch (result) {
        case CoupleOk(:final value):
          _activities = value;
        case CoupleFailed(:final failure):
          _failure = failure;
      }
    });
  }

  Future<void> _removeActivity(CoupleActivity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer de la liste ?'),
        content: Text(
          'Voulez-vous retirer "${activity.title}" de vos activités sauvegardées ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Optimistic: the row leaves now, and comes back if the server refuses.
    final position = _activities.indexWhere((a) => a.id == activity.id);
    if (position < 0) return;
    setState(() => _activities = [..._activities]..removeAt(position));

    final result = await _apiService.removeSavedActivity(activity.id);
    if (!mounted) return;

    switch (result) {
      case CoupleOk():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activité retirée'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case CoupleFailed():
        setState(() {
          final restored = [..._activities];
          restored.insert(position.clamp(0, restored.length), activity);
          _activities = restored;
        });
        showCoupleError(
          context,
          'Impossible de retirer « ${activity.title} ». Réessayez.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activités sauvegardées'),
        actions: [
          if (_activities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Center(child: TagPill('${_activities.length}')),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final failure = _failure;
    if (failure != null) {
      return CoupleMessageView.failure(failure, onRetry: _loadActivities);
    }

    if (_activities.isEmpty) {
      return CoupleMessageView(
        icon: LucideIcons.bookmark,
        title: 'Aucune activité sauvegardée',
        line: 'Glissez une carte vers le haut pour la garder.',
        actionLabel: 'Découvrir des activités',
        onAction: () => context.pop(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          final activity = _activities[index];
          return _SavedActivityCard(
            activity: activity,
            onTap: () => context.push('/couple/activities/${activity.id}'),
            onRemove: () => _removeActivity(activity),
          );
        },
      ),
    );
  }
}

class _SavedActivityCard extends StatelessWidget {
  const _SavedActivityCard({
    required this.activity,
    required this.onTap,
    required this.onRemove,
  });

  final CoupleActivity activity;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final city = activity.city;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 120,
                  child: ActivityVisual(activity: activity, iconSize: 28),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SectionLabel(activity.categoryLabel),
                        const SizedBox(height: 6),
                        Text(
                          activity.title,
                          style: textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (city != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 14,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  city,
                                  style: textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              activity.formattedPrice,
                              style: textTheme.titleSmall,
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 18),
                              color: scheme.onSurfaceVariant,
                              onPressed: onRemove,
                              tooltip: 'Retirer',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ],
                        ),
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
}
