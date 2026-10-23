import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_space.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/mazl_sheet.dart';
import '../widgets/couple_message_view.dart';
import 'couple_space_sheets.dart';

class CoupleSpaceScreen extends StatefulWidget {
  const CoupleSpaceScreen({super.key, this.apiService});

  /// Injected by tests; the app uses the real service.
  final CoupleApiService? apiService;

  @override
  State<CoupleSpaceScreen> createState() => _CoupleSpaceScreenState();
}

class _CoupleSpaceScreenState extends State<CoupleSpaceScreen> {
  late final CoupleApiService _apiService =
      widget.apiService ?? CoupleApiService();

  CoupleStatsSnapshot _snapshot = const CoupleStatsSnapshot();
  List<CoupleMemory> _memories = [];
  List<BucketListItem> _bucketList = [];
  List<CoupleDate> _dates = [];
  bool _isLoading = true;
  CoupleFailure? _failure;

  static const coupleAccent = Color(0xFFFF6B9D);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Reads the four lists. [quiet] keeps the screen as it is while loading
  /// (after an add) and, on failure, keeps the old data and says so.
  Future<void> _loadData({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _isLoading = true;
        _failure = null;
      });
    }

    final results = await Future.wait([
      _apiService.getStats(),
      _apiService.getMemories(),
      _apiService.getBucketList(),
      _apiService.getDates(),
    ]);
    if (!mounted) return;

    final stats = results[0] as CoupleResult<CoupleStatsSnapshot>;
    final memories = results[1] as CoupleResult<List<CoupleMemory>>;
    final bucket = results[2] as CoupleResult<List<BucketListItem>>;
    final dates = results[3] as CoupleResult<List<CoupleDate>>;

    final failure =
        stats.failureOrNull ??
        memories.failureOrNull ??
        bucket.failureOrNull ??
        dates.failureOrNull;

    if (failure != null) {
      if (quiet) {
        showCoupleError(
          context,
          'Actualisation impossible. ${failure.message}',
        );
      }
      setState(() {
        _isLoading = false;
        if (!quiet) _failure = failure;
      });
      return;
    }

    setState(() {
      _snapshot = stats.valueOrNull!;
      _memories = memories.valueOrNull!;
      _bucketList = bucket.valueOrNull!;
      _dates = dates.valueOrNull!;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('Notre Espace'),
            SizedBox(width: 8),
            Text('💑', style: TextStyle(fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => context.push('/couple/space/settings'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _failure != null
          ? CoupleMessageView.failure(_failure!, onRetry: _loadData)
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Couple header
                    _buildCoupleHeader(),
                    const SizedBox(height: 24),

                    // Stats cards
                    _buildStatsSection(),
                    const SizedBox(height: 24),

                    // Quick actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // Memories section
                    _buildMemoriesSection(),
                    const SizedBox(height: 24),

                    // Bucket list section
                    _buildBucketListSection(),
                    const SizedBox(height: 24),

                    // Important dates section
                    _buildDatesSection(),
                    const SizedBox(height: 24),

                    // Achievements section
                    _buildAchievementsSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCoupleHeader() {
    final couple = CoupleService().coupleData;
    final user = AuthService().currentUser;
    final userName = user?.displayName ?? 'Vous';
    final partnerName = couple?.partnerName ?? 'Votre Moitié';
    final daysTogether = couple?.daysTogether ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [coupleAccent, coupleAccent.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Couple photos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProfileAvatar(user?.photoUrl),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.heart,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              _buildProfileAvatar(couple?.partnerPicture),
            ],
          ),
          const SizedBox(height: 16),

          // Couple names
          Text(
            '$userName & $partnerName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Together since
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.sparkles, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                daysTogether > 0
                    ? 'Ensemble depuis $daysTogether jours'
                    : 'Votre histoire commence',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String? imageUrl) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null
            ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
            : Container(
                color: Colors.white,
                child: const Icon(
                  LucideIcons.user,
                  size: 40,
                  color: coupleAccent,
                ),
              ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _snapshot.stats;

    return Row(
      children: [
        _StatCard(
          icon: LucideIcons.bookmark,
          value: '${stats.savedActivities}',
          label: 'Activités\nsauvegardées',
          color: coupleAccent,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: LucideIcons.calendar,
          value: '${stats.eventsRegistered}',
          label: 'Événements\nà venir',
          color: AppColors.info,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: LucideIcons.camera,
          value: '${stats.memoriesCount}',
          label: 'Souvenirs\ncréés',
          color: AppColors.accentGold,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickActionButton(
              icon: LucideIcons.camera,
              label: 'Ajouter\nun souvenir',
              color: coupleAccent,
              onTap: () => _showAddMemorySheet(),
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: LucideIcons.target,
              label: 'Ajouter à\nla bucket list',
              color: AppColors.accentGold,
              onTap: () => _showAddBucketItemSheet(),
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: LucideIcons.calendarPlus,
              label: 'Ajouter\nune date',
              color: AppColors.info,
              onTap: () => _showAddDateSheet(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nos souvenirs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: _showAddMemorySheet,
              icon: const Icon(LucideIcons.plus),
              color: coupleAccent,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_memories.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: coupleAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.camera, size: 40, color: coupleAccent),
                const SizedBox(height: 12),
                const Text(
                  'Aucun souvenir pour l\'instant',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ajoutez vos premiers souvenirs ensemble.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showAddMemorySheet,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Ajouter un souvenir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coupleAccent,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _memories.take(10).length,
              itemBuilder: (context, index) {
                final memory = _memories[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: coupleAccent.withValues(alpha: 0.1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (memory.imageUrl != null)
                        CachedNetworkImage(
                          imageUrl: memory.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getMemoryTypeEmoji(memory.type),
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  memory.title ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBucketListSection() {
    final pending = _bucketList.where((i) => !i.isCompleted).toList();
    final completed = _bucketList.where((i) => i.isCompleted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Bucket List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${completed.length}/${_bucketList.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentGold,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _showAddBucketItemSheet,
              icon: const Icon(LucideIcons.plus),
              color: AppColors.accentGold,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_bucketList.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.target,
                  size: 40,
                  color: AppColors.accentGold,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Votre bucket list est vide',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ajoutez des expériences à vivre ensemble.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showAddBucketItemSheet,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: pending.take(3).map((item) {
              return _BucketListItem(
                title: item.title,
                category: item.category,
                isCompleted: false,
                onComplete: () => _completeBucketItem(item.id),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dates importantes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.go('/couple/calendar'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_dates.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.calendarHeart,
                  size: 40,
                  color: AppColors.info,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aucune date importante',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ajoutez vos anniversaires, fêtes, etc.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showAddDateSheet,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _dates.take(3).map((date) {
              return _DateItem(
                title: date.title,
                date: _formatDate(date.date),
                type: date.type,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    final achievements = _snapshot.achievements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nos badges',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (achievements.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.award, size: 40, color: Colors.purple),
                const SizedBox(height: 12),
                const Text(
                  'Aucun badge pour l\'instant',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Faites des activités ensemble pour débloquer des badges.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((a) {
              return _AchievementBadge(
                icon: _getAchievementIcon(a.type),
                name: a.name,
                color: _getAchievementColor(a.type),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _showAddSheet(Widget Function(BuildContext) builder) async {
    final added = await showMazlSheet<bool>(
      context,
      isScrollControlled: true,
      builder: builder,
    );
    if (added == true && mounted) await _loadData(quiet: true);
  }

  void _showAddMemorySheet() =>
      _showAddSheet((_) => AddMemorySheet(apiService: _apiService));

  void _showAddBucketItemSheet() =>
      _showAddSheet((_) => AddBucketItemSheet(apiService: _apiService));

  void _showAddDateSheet() =>
      _showAddSheet((_) => AddDateSheet(apiService: _apiService));

  Future<void> _completeBucketItem(int itemId) async {
    final result = await _apiService.completeBucketListItem(itemId);
    if (!mounted) return;
    switch (result) {
      case CoupleOk():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Objectif accompli'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadData(quiet: true);
      case CoupleFailed():
        showCoupleError(
          context,
          'Impossible de valider cet objectif. Réessayez.',
        );
    }
  }

  static const _months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  String _getMemoryTypeEmoji(String? type) {
    switch (type) {
      case 'photo':
        return '📸';
      case 'note':
        return '📝';
      case 'milestone':
        return '🏆';
      case 'date':
        return '💑';
      default:
        return '✨';
    }
  }

  IconData _getAchievementIcon(String? type) {
    switch (type) {
      case 'first_activity':
        return LucideIcons.star;
      case 'ten_activities':
        return LucideIcons.trophy;
      case 'first_event':
        return LucideIcons.partyPopper;
      default:
        return LucideIcons.award;
    }
  }

  Color _getAchievementColor(String? type) {
    switch (type) {
      case 'first_activity':
        return coupleAccent;
      case 'ten_activities':
        return AppColors.accentGold;
      case 'first_event':
        return Colors.purple;
      default:
        return AppColors.info;
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BucketListItem extends StatelessWidget {
  const _BucketListItem({
    required this.title,
    required this.isCompleted,
    required this.onComplete,
    this.category,
  });

  final String title;
  final String? category;
  final bool isCompleted;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onComplete,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppColors.success : Colors.grey,
                  width: 2,
                ),
                color: isCompleted ? AppColors.success : Colors.transparent,
              ),
              child: isCompleted
                  ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (category != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    category!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

class _DateItem extends StatelessWidget {
  const _DateItem({
    required this.title,
    required this.date,
    required this.type,
  });

  final String title;
  final String date;
  final String type;

  String get _typeEmoji {
    switch (type) {
      case 'anniversary':
        return '💍';
      case 'birthday':
        return '🎂';
      case 'holiday':
        return '✡️';
      default:
        return '📅';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Text(_typeEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
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

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.icon,
    required this.name,
    required this.color,
  });

  final IconData icon;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// Bottom sheets for adding content
