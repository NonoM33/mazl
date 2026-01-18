import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';

class CoupleSpaceScreen extends StatefulWidget {
  const CoupleSpaceScreen({super.key});

  @override
  State<CoupleSpaceScreen> createState() => _CoupleSpaceScreenState();
}

class _CoupleSpaceScreenState extends State<CoupleSpaceScreen> {
  final CoupleApiService _apiService = CoupleApiService();

  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _memories = [];
  List<Map<String, dynamic>> _bucketList = [];
  List<Map<String, dynamic>> _dates = [];
  bool _isLoading = true;

  static const coupleAccent = Color(0xFFFF6B9D);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _apiService.getStats(),
        _apiService.getMemories(),
        _apiService.getBucketList(),
        _apiService.getDates(),
      ]);

      setState(() {
        _stats = results[0] as Map<String, dynamic>?;
        _memories = results[1] as List<Map<String, dynamic>>;
        _bucketList = results[2] as List<Map<String, dynamic>>;
        _dates = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            coupleAccent,
            coupleAccent.withOpacity(0.7),
          ],
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
              _buildProfileAvatar(null), // TODO: Load user photo
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.heart,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              _buildProfileAvatar(null), // TODO: Load partner photo
            ],
          ),
          const SizedBox(height: 16),

          // Couple names
          const Text(
            'Vous & Votre Moitié',
            style: TextStyle(
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
              const Icon(
                LucideIcons.sparkles,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Ensemble depuis X jours', // TODO: Calculate from couple creation
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
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
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
              )
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
    final statsData = _stats?['stats'] as Map<String, dynamic>? ?? {};

    return Row(
      children: [
        _StatCard(
          icon: LucideIcons.heartHandshake,
          value: '${statsData['activitiesDone'] ?? 0}',
          label: 'Activités\nfaites',
          color: coupleAccent,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: LucideIcons.calendar,
          value: '${statsData['eventsAttended'] ?? 0}',
          label: 'Événements\nparticipés',
          color: AppColors.info,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: LucideIcons.camera,
          value: '${_memories.length}',
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
              color: coupleAccent.withOpacity(0.1),
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
                  'Ajoutez vos premiers souvenirs ensemble !',
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
                    color: coupleAccent.withOpacity(0.1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (memory['image_url'] != null)
                        CachedNetworkImage(
                          imageUrl: memory['image_url'],
                          fit: BoxFit.cover,
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getMemoryTypeEmoji(memory['type']),
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  memory['title'] ?? '',
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
    final pending = _bucketList.where((i) => i['completed_at'] == null).toList();
    final completed =
        _bucketList.where((i) => i['completed_at'] != null).toList();

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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.1),
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
              color: AppColors.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.target,
                    size: 40, color: AppColors.accentGold),
                const SizedBox(height: 12),
                const Text(
                  'Votre bucket list est vide',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ajoutez des expériences à vivre ensemble !',
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
                title: item['title'] ?? '',
                category: item['category'],
                isCompleted: false,
                onComplete: () => _completeBucketItem(item['id']),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.calendarHeart,
                    size: 40, color: AppColors.info),
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
                title: date['title'] ?? '',
                date: date['date'] ?? '',
                type: date['type'] ?? '',
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    final achievements =
        _stats?['achievements'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nos badges',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (achievements.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
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
                  'Faites des activités ensemble pour débloquer des badges !',
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
                icon: _getAchievementIcon(a['type']),
                name: a['title'] ?? '',
                color: _getAchievementColor(a['type']),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showAddMemorySheet() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddMemorySheet(),
    ).then((added) {
      if (added == true) _refreshMemories();
    });
  }

  void _showAddBucketItemSheet() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddBucketItemSheet(),
    ).then((added) {
      if (added == true) _refreshBucketList();
    });
  }

  void _showAddDateSheet() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddDateSheet(),
    ).then((added) {
      if (added == true) _refreshDates();
    });
  }

  Future<void> _refreshMemories() async {
    final memories = await _apiService.getMemories();
    setState(() => _memories = memories);
  }

  Future<void> _refreshBucketList() async {
    final bucketList = await _apiService.getBucketList();
    setState(() => _bucketList = bucketList);
  }

  Future<void> _refreshDates() async {
    final dates = await _apiService.getDates();
    setState(() => _dates = dates);
  }

  Future<void> _completeBucketItem(int itemId) async {
    final success = await _apiService.completeBucketListItem(itemId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Objectif accompli ! 🎉'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _refreshBucketList();
    }
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
          color: color.withOpacity(0.1),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
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
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (category != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    category!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: 20,
            color: Colors.grey[400],
          ),
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
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
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
            color: color.withOpacity(0.1),
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
class _AddMemorySheet extends StatefulWidget {
  const _AddMemorySheet();

  @override
  State<_AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<_AddMemorySheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'note';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter un souvenir',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.isEmpty) return;
                  final api = CoupleApiService();
                  final success = await api.addMemory(
                    type: _selectedType,
                    title: _titleController.text,
                    content: _contentController.text,
                  );
                  if (context.mounted) Navigator.pop(context, success);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Ajouter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBucketItemSheet extends StatefulWidget {
  const _AddBucketItemSheet();

  @override
  State<_AddBucketItemSheet> createState() => _AddBucketItemSheetState();
}

class _AddBucketItemSheetState extends State<_AddBucketItemSheet> {
  final _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter à la bucket list',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Que voulez-vous faire ensemble ?',
                border: OutlineInputBorder(),
                hintText: 'Ex: Voir les aurores boréales',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.isEmpty) return;
                  final api = CoupleApiService();
                  final success = await api.addBucketListItem(
                    title: _titleController.text,
                  );
                  if (context.mounted) Navigator.pop(context, success);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Ajouter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddDateSheet extends StatefulWidget {
  const _AddDateSheet();

  @override
  State<_AddDateSheet> createState() => _AddDateSheetState();
}

class _AddDateSheetState extends State<_AddDateSheet> {
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'anniversary';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter une date importante',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
                hintText: 'Ex: Notre anniversaire',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date'),
              subtitle:
                  Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              trailing: const Icon(LucideIcons.calendar),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.isEmpty) return;
                  final api = CoupleApiService();
                  final success = await api.addDate(
                    title: _titleController.text,
                    date: _selectedDate.toIso8601String().split('T')[0],
                    type: _selectedType,
                  );
                  if (context.mounted) Navigator.pop(context, success);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Ajouter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
