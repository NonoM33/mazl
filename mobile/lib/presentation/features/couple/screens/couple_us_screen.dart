import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_spread.dart';
import '../../../../core/models/couple_space.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_sheet.dart';
import '../l10n/couple_failure_label.dart';
import '../widgets/couple_message_view.dart';
import 'couple_space_sheets.dart';
import '../../../common/widgets/fold_pages.dart';

class CoupleUsScreen extends StatefulWidget {
  const CoupleUsScreen({super.key, this.apiService});

  /// Injected by tests; the app uses the real service.
  final CoupleApiService? apiService;

  @override
  State<CoupleUsScreen> createState() => _CoupleUsScreenState();
}

class _CoupleUsScreenState extends State<CoupleUsScreen> {
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
        final l10n = context.l10n;
        showCoupleError(
          context,
          l10n.coupleSpaceRefreshFailed(failure.label(l10n)),
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
              context.l10n.coupleSpaceTitle,
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          RoundIconButton(
            icon: LucideIcons.settings,
            tooltip: context.l10n.coupleSpaceSettingsTooltip,
            onPressed: () => context.push(RoutePaths.coupleUsSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const FoldSpinner();
    if (_failure != null) {
      return CoupleMessageView.failure(_failure!, onRetry: _loadData);
    }
    final bottom = MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      onRefresh: _loadData,
      // Held like a book: the couple, its numbers and its memories to look at
      // on the first page; the actions, the goals and the dates on the other.
      child: FoldSpread(
        padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 16),
        start: [
          _buildCoupleHeader(),
          const SizedBox(height: 16),
          _buildStatsSection(),
          const SizedBox(height: 32),
          _buildMemoriesSection(),
          const SizedBox(height: 32),
        ],
        end: [
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildBucketListSection(),
          const SizedBox(height: 32),
          _buildDatesSection(),
        ],
      ),
    );
  }

  Widget _buildCoupleHeader() {
    final scheme = Theme.of(context).colorScheme;
    final couple = CoupleService().coupleData;
    final user = AuthService().currentUser;
    final l10n = context.l10n;
    final userName = user?.displayName ?? l10n.coupleSpaceYou;
    final partnerName = couple?.partnerName ?? l10n.coupleSpacePartnerFallback;
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
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.heart,
                  size: 16,
                  color: scheme.onPrimaryContainer,
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
                ? l10n.coupleSpaceTogetherSince(daysTogether)
                : l10n.coupleSpaceStoryBegins,
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
    final l10n = context.l10n;
    return Row(
      children: [
        _StatCard(
          key: const Key('couple-stat-0'),
          icon: LucideIcons.bookmark,
          value: '${stats.savedActivities}',
          label: l10n.coupleSpaceStatSavedActivities,
        ),
        const SizedBox(width: 12),
        _StatCard(
          key: const Key('couple-stat-1'),
          icon: LucideIcons.calendar,
          value: '${stats.eventsRegistered}',
          label: l10n.coupleSpaceStatUpcomingEvents,
        ),
        const SizedBox(width: 12),
        _StatCard(
          key: const Key('couple-stat-2'),
          icon: LucideIcons.camera,
          value: '${stats.memoriesCount}',
          label: l10n.coupleSpaceStatMemories,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(l10n.coupleSpaceQuickActions),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickActionButton(
              icon: LucideIcons.camera,
              label: l10n.coupleSpaceQuickAddMemory,
              onTap: _showAddMemorySheet,
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: LucideIcons.target,
              label: l10n.coupleSpaceQuickAddBucket,
              onTap: _showAddBucketItemSheet,
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: LucideIcons.calendarPlus,
              label: l10n.coupleSpaceQuickAddDate,
              onTap: _showAddDateSheet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemoriesSection() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(l10n.coupleSpaceMemoriesTitle),
        const SizedBox(height: 12),
        if (_memories.isEmpty)
          _EmptyCard(
            icon: LucideIcons.camera,
            title: l10n.coupleSpaceMemoriesEmptyTitle,
            hint: l10n.coupleSpaceMemoriesEmptyHint,
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
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          _bucketList.isEmpty
              ? l10n.coupleSpaceBucketTitle
              : l10n.coupleSpaceBucketProgress(
                  completed.length,
                  _bucketList.length,
                ),
        ),
        const SizedBox(height: 12),
        if (_bucketList.isEmpty)
          _EmptyCard(
            icon: LucideIcons.target,
            title: l10n.coupleSpaceBucketEmptyTitle,
            hint: l10n.coupleSpaceBucketEmptyHint,
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
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SectionLabel(l10n.coupleSpaceDatesTitle)),
            TextButton(
              onPressed: () => context.go(RoutePaths.coupleAgenda),
              child: Text(l10n.coupleSpaceSeeAll),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_dates.isEmpty)
          _EmptyCard(
            icon: LucideIcons.calendarHeart,
            title: l10n.coupleSpaceDatesEmptyTitle,
            hint: l10n.coupleSpaceDatesEmptyHint,
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
    final l10n = context.l10n;
    switch (result) {
      case CoupleOk():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.coupleSpaceGoalDone),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadData(quiet: true);
      case CoupleFailed():
        showCoupleError(context, l10n.coupleSpaceGoalFailed);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat.yMMMd(context.l10n.localeName).format(date);
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
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 16, 4),
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
