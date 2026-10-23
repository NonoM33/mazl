import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_activity.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';
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

  static const coupleAccent = Color(0xFFFF6B9D);

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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: coupleAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_activities.length}',
                    style: const TextStyle(
                      color: coupleAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
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
        padding: const EdgeInsets.all(16),
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

  static const coupleAccent = Color(0xFFFF6B9D);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              width: 120,
              height: 140,
              child: activity.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: activity.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: coupleAccent.withValues(alpha: 0.3)),
                      errorWidget: (context, url, error) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    Text(
                      '${activity.categoryEmoji} ${activity.categoryLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: coupleAccent,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Location
                    if (activity.city != null)
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              activity.city!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),

                    // Price + Remove button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activity.formattedPrice,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 18),
                          color: Colors.grey[400],
                          onPressed: onRemove,
                          tooltip: 'Retirer',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: coupleAccent.withValues(alpha: 0.3),
      child: Center(
        child: Text(
          activity.categoryEmoji,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
