import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_space.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../common/widgets/mazl_components.dart';
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTitleBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Notre espace',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          RoundIconButton(
            icon: LucideIcons.settings,
            tooltip: 'Réglages',
            onPressed: () => context.push('/couple/space/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_failure != null) {
      return CoupleMessageView.failure(_failure!, onRetry: _loadData);
    }
    final bottom = MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 16),
        children: [
          _buildCoupleHeader(),
          const SizedBox(height: 16),
          _buildStatsSection(),
          const SizedBox(height: 32),
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildMemoriesSection(),
          const SizedBox(height: 32),
          _buildBucketListSection(),
          const SizedBox(height: 32),
          _buildDatesSection(),
          const SizedBox(height: 32),
          _buildAchievementsSection(),
        ],
      ),
    );
  }

  Widget _buildCoupleHeader() {
    final scheme = Theme.of(context).colorScheme;
    final couple = CoupleService().coupleData;
    final user = AuthService().currentUser;
    final userName = user?.displayName ?? 'Vous';
    final partnerName = couple?.partnerName ?? 'Votre Moitié';
    final daysTogether = couple?.daysTogether ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: 72,
                child: ProfilePhoto(url: user?.photoUrl, radius: 36),
              ),
              const SizedBox(width: 12),
              Container(
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
              const SizedBox(width: 12),
              SizedBox.square(
                dimension: 72,
                child: ProfilePhoto(
                  url: couple?.partnerPicture,
                  seed: 1,
                  radius: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$userName & $partnerName',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            daysTogether > 0
                ? 'Ensemble depuis $daysTogether jours'
                : 'Votre histoire commence',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _snapshot.stats;
    return Row(
      children: [
        _StatCard(
          key: const Key('couple-stat-0'),
          icon: LucideIcons.bookmark,
          value: '${stats.savedActivities}',
          label: 'Activités\nsauvegardées',
        ),
        const SizedBox(width: 12),
        _StatCard(
          key: const Key('couple-stat-1'),
          icon: LucideIcons.calendar,
          value: '${stats.eventsRegistered}',
          label: 'Événements\nà venir',
        ),
        const SizedBox(width: 12),
        _StatCard(
          key: const Key('couple-stat-2'),
          icon: LucideIcons.camera,
          value: '${stats.memoriesCount}',
          label: 'Souvenirs\ncréés',
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Actions rapides'),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickActionButton(
              icon: LucideIcons.camera,
              label: 'Ajouter\nun souvenir',
              onTap: _showAddMemorySheet,
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: LucideIcons.target,
              label: 'Ajouter à\nla bucket list',
              onTap: _showAddBucketItemSheet,
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: LucideIcons.calendarPlus,
              label: 'Ajouter\nune date',
              onTap: _showAddDateSheet,
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
        const SectionLabel('Nos souvenirs'),
        const SizedBox(height: 12),
        if (_memories.isEmpty)
          const _EmptyCard(
            icon: LucideIcons.camera,
            title: 'Aucun souvenir pour l\'instant',
            hint: 'Ajoutez vos premiers souvenirs ensemble.',
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _memories.take(10).length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _MemoryTile(memory: _memories[index], seed: index),
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
        SectionLabel(
          _bucketList.isEmpty
              ? 'Bucket list'
              : 'Bucket list · ${completed.length}/${_bucketList.length}',
        ),
        const SizedBox(height: 12),
        if (_bucketList.isEmpty)
          const _EmptyCard(
            icon: LucideIcons.target,
            title: 'Votre bucket list est vide',
            hint: 'Ajoutez des expériences à vivre ensemble.',
          )
        else
          for (final item in pending.take(3))
            _BucketListItem(
              title: item.title,
              category: item.category,
              isCompleted: false,
              onComplete: () => _completeBucketItem(item.id),
            ),
      ],
    );
  }

  Widget _buildDatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Dates importantes')),
            TextButton(
              onPressed: () => context.go('/couple/calendar'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_dates.isEmpty)
          const _EmptyCard(
            icon: LucideIcons.calendarHeart,
            title: 'Aucune date importante',
            hint: 'Ajoutez vos anniversaires, fêtes, etc.',
          )
        else
          for (final date in _dates.take(3))
            _DateItem(
              title: date.title,
              date: _formatDate(date.date),
              type: date.type,
            ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    final achievements = _snapshot.achievements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Nos badges'),
        const SizedBox(height: 12),
        if (achievements.isEmpty)
          const _EmptyCard(
            icon: LucideIcons.award,
            title: 'Aucun badge pour l\'instant',
            hint: 'Faites des activités ensemble pour débloquer des badges.',
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final a in achievements)
                _AchievementBadge(
                  icon: _getAchievementIcon(a.type),
                  name: a.name,
                ),
            ],
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
}

/// Une tuile de chiffre : brume, icône accent, chiffre en encre.
class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(icon, color: scheme.primary, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTypography.family,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                height: 1.1,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un raccourci d'ajout : contour filet, icône accent, libellé encre.
class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outline),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// État vide : une carte brume, une icône grise, deux lignes.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Un souvenir : sa photo, ou une teinte neutre avec une icône et son titre.
class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.memory, required this.seed});

  final CoupleMemory memory;
  final int seed;

  IconData get _icon {
    switch (memory.type) {
      case 'photo':
        return LucideIcons.camera;
      case 'note':
        return LucideIcons.fileText;
      case 'milestone':
        return LucideIcons.trophy;
      case 'date':
        return LucideIcons.calendarHeart;
      default:
        return LucideIcons.sparkles;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.photoTints[seed % AppColors.photoTints.length];
    final imageUrl = memory.imageUrl;
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: 140,
              height: 140,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_icon, size: 28, color: AppColors.textTertiaryLight),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    memory.title ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onComplete,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? AppColors.success : scheme.outline,
                    width: 1.5,
                  ),
                  color: isCompleted ? AppColors.success : Colors.transparent,
                ),
                child: isCompleted
                    ? const Icon(
                        LucideIcons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (category != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      category!,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

  IconData get _typeIcon {
    switch (type) {
      case 'anniversary':
        return LucideIcons.heart;
      case 'birthday':
        return LucideIcons.cake;
      case 'holiday':
        return LucideIcons.moonStar;
      default:
        return LucideIcons.calendar;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Icon(_typeIcon, size: 22, color: scheme.primary),
          const SizedBox(width: 16),
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
                    color: scheme.onSurfaceVariant,
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
  const _AchievementBadge({required this.icon, required this.name});

  final IconData icon;
  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: scheme.primary, size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
