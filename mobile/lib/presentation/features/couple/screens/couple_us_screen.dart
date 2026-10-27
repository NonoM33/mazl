import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/layout/fold_spread.dart';
import '../../../../core/layout/full_bleed.dart';
import '../../../../core/models/couple_daily.dart';
import '../../../../core/models/couple_space.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/services/couple_daily_api.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/mazl_sheet.dart';
import '../l10n/couple_failure_label.dart';
import '../widgets/couple_kit.dart';
import '../widgets/couple_message_view.dart';
import '../widgets/us_checkin_card.dart';
import '../widgets/us_load.dart';
import '../widgets/us_question_card.dart';
import '../widgets/us_section_error.dart';
import '../widgets/us_settings_section.dart';
import '../widgets/us_space_tiles.dart';
import 'couple_space_sheets.dart';
import '../../../common/widgets/star_refresh/star_refresh.dart';

/// « Nous deux », the fifth tab of the couple space: the couple, the
/// question of the day, the monthly check-in, the memories, the goals and the
/// dates, and the settings of the couple.
///
/// Every section loads on its own: a failing question never wipes the
/// memories, and a route the server does not have yet gives an empty card or
/// nothing, never an error.
class CoupleUsScreen extends StatefulWidget {
  const CoupleUsScreen({
    super.key,
    this.apiService,
    this.dailyApi,
    this.couple,
  });

  /// Injected by tests; the app uses the real services.
  final CoupleApiService? apiService;
  final CoupleDailyApi? dailyApi;
  final CoupleService? couple;

  @override
  State<CoupleUsScreen> createState() => _CoupleUsScreenState();
}

/// The four lists of the shared space, loaded together.
class _Space {
  const _Space({
    required this.snapshot,
    required this.memories,
    required this.bucketList,
    required this.dates,
  });

  final CoupleStatsSnapshot snapshot;
  final List<CoupleMemory> memories;
  final List<BucketListItem> bucketList;
  final List<CoupleDate> dates;
}

class _CoupleUsScreenState extends State<CoupleUsScreen> {
  late final CoupleApiService _apiService =
      widget.apiService ?? CoupleApiService();
  late final CoupleDailyApi _dailyApi =
      widget.dailyApi ?? CoupleDailyApi.forApp();
  late final CoupleService _couple = widget.couple ?? CoupleService();

  UsLoad<_Space> _space = const UsLoading();
  UsLoad<CoupleQuestion?> _question = const UsLoading();
  UsLoad<CoupleCheckin?> _checkin = const UsLoading();

  /// Whether the partner answered the question, as the day's summary says
  /// (the fact only, never the words). Unknown until read.
  bool? _partnerAnswered;

  /// The status the member just chose, shown until the server answers.
  RelationshipStatus? _pendingStatus;

  @override
  void initState() {
    super.initState();
    _loadSpace();
    _loadQuestion();
    _loadCheckin();
  }

  Future<void> _reloadAll() => Future.wait([
    _loadSpace(quiet: true),
    _loadQuestion(quiet: true),
    _loadCheckin(quiet: true),
  ]);

  /// Reads the four lists. [quiet] keeps the screen as it is while loading
  /// (after an add) and, on failure, keeps the old data and says so.
  Future<void> _loadSpace({bool quiet = false}) async {
    if (!quiet) setState(() => _space = const UsLoading());

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
      } else {
        setState(() => _space = UsFailed(failure));
      }
      return;
    }

    setState(
      () => _space = UsReady(
        _Space(
          snapshot: stats.valueOrNull!,
          memories: memories.valueOrNull!,
          bucketList: bucket.valueOrNull!,
          dates: dates.valueOrNull!,
        ),
      ),
    );
  }

  Future<void> _loadQuestion({bool quiet = false}) async {
    final coupleId = _couple.coupleData?.coupleId;
    if (coupleId == null) {
      setState(() => _question = const UsReady(null));
      return;
    }
    if (!quiet) setState(() => _question = const UsLoading());

    final result = await _dailyApi.getQuestion(coupleId);
    if (!mounted) return;
    switch (result) {
      case CoupleOk(:final value):
        final partnerAnswered = value != null && !value.answered
            ? await _readPartnerAnswered()
            : null;
        if (!mounted) return;
        setState(() {
          _question = UsReady(value);
          _partnerAnswered = partnerAnswered;
        });
      case CoupleFailed(:final failure):
        if (!quiet) setState(() => _question = UsFailed(failure));
    }
  }

  /// Only the fact that the partner answered (the day's summary), to tell the
  /// member it is their turn. A failure here only means "unknown".
  Future<bool?> _readPartnerAnswered() async {
    final today = await _dailyApi.getToday();
    return today.valueOrNull?.question?.partnerAnswered;
  }

  Future<void> _loadCheckin({bool quiet = false}) async {
    if (!quiet) setState(() => _checkin = const UsLoading());
    final result = await _dailyApi.getCheckin();
    if (!mounted) return;
    switch (result) {
      case CoupleOk(:final value):
        setState(() => _checkin = UsReady(value));
      case CoupleFailed(:final failure):
        if (!quiet) setState(() => _checkin = UsFailed(failure));
    }
  }

  /// Opens a page and, on the way back, re-reads what it may have changed.
  Future<void> _open(String path) async {
    await context.push(path);
    if (!mounted) return;
    await Future.wait([_loadQuestion(quiet: true), _loadCheckin(quiet: true)]);
  }

  Future<void> _setStatus(RelationshipStatus status) async {
    if (_pendingStatus != null) return;
    if (status == _couple.coupleData?.status) return;
    setState(() => _pendingStatus = status);
    final result = await _couple.updateStatus(status);
    if (!mounted) return;
    setState(() => _pendingStatus = null);
    if (!result.ok) {
      final l10n = context.l10n;
      showCoupleError(
        context,
        (result.failure ?? CoupleActionFailure.unknown).label(l10n),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: ListenableBuilder(
        listenable: _couple,
        builder: (context, _) => StarRefresh(
          onRefresh: _reloadAll,
          child: FoldCutBuilder(
            minPaneExtent: 240,
            builder: (context, cut) {
              // Held like a book: the couple, the question and the check-in
              // are what the pair looks at (left), the rest what it does.
              // Set down like a laptop only the couple and the question fit
              // above the fold; the check-in goes below with the rest.
              final laptop = cut?.axis == FoldSplitAxis.horizontal;
              return FoldSpread(
                laptopVolets: true,
                padding: EdgeInsets.fromLTRB(24, top + 16, 24, bottom + 24),
                start: [
                  _buildTitleBar(),
                  const SizedBox(height: 16),
                  _buildCoupleHeader(),
                  const SizedBox(height: 16),
                  ..._buildQuestion(),
                  if (!laptop) ..._buildCheckin(),
                ],
                end: [
                  if (laptop) ..._buildCheckin(),
                  ..._buildSpace(),
                  _buildSettings(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.coupleTabUs,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        RoundIconButton(
          icon: LucideIcons.settings,
          tooltip: context.l10n.coupleSpaceSettingsTooltip,
          onPressed: () => context.push(RoutePaths.coupleUsSettings),
        ),
      ],
    );
  }

  String get _partnerName =>
      _couple.coupleData?.partnerName ??
      context.l10n.coupleSpacePartnerFallback;

  Widget _buildCoupleHeader() {
    final scheme = Theme.of(context).colorScheme;
    final couple = _couple.coupleData;
    final user = AuthService().currentUser;
    final l10n = context.l10n;
    final userName = user?.displayName ?? l10n.coupleSpaceYou;
    final daysTogether = couple?.daysTogether ?? 0;

    return CoupleCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 52,
            child: ProfilePhoto(url: user?.photoUrl, radius: 26),
          ),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.heart,
              size: 12,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox.square(
            dimension: 52,
            child: ProfilePhoto(
              url: couple?.partnerPicture,
              seed: 1,
              radius: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$userName & $_partnerName',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  daysTogether > 0
                      ? l10n.coupleUsDay(daysTogether)
                      : l10n.coupleSpaceStoryBegins,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  List<Widget> _buildQuestion() {
    final l10n = context.l10n;
    switch (_question) {
      case UsLoading():
        return const [UsLoadingCard(), SizedBox(height: 16)];
      case UsFailed(:final failure):
        return [
          UsSectionError(
            title: l10n.coupleUsQuestionLabel,
            line: failure.label(l10n),
            onRetry: _loadQuestion,
          ),
          const SizedBox(height: 16),
        ];
      case UsReady(:final value):
        if (value == null) return const [];
        return [
          UsQuestionCard(
            question: value,
            partnerName: _partnerName,
            partnerAnswered: _partnerAnswered,
            onOpen: () => _open(RoutePaths.coupleQuestion),
          ),
          _buildHistoryLink(),
          const SizedBox(height: 16),
        ];
    }
  }

  Widget _buildHistoryLink() {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.push(RoutePaths.coupleQuestions),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTapTarget),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.coupleUsHistoryLink,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            DirectionalIcon(
              LucideIcons.chevronRight,
              size: 18,
              color: scheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCheckin() {
    final l10n = context.l10n;
    switch (_checkin) {
      case UsLoading():
        return const [UsLoadingCard(), SizedBox(height: 16)];
      case UsFailed(:final failure):
        return [
          UsSectionError(
            title: l10n.coupleUsCheckinLabel,
            line: failure.label(l10n),
            onRetry: _loadCheckin,
          ),
          const SizedBox(height: 16),
        ];
      case UsReady(:final value):
        if (value == null) return const [];
        return [
          UsCheckinCard(
            checkin: value,
            partnerName: _partnerName,
            onOpen: () => _open(RoutePaths.coupleCheckin),
          ),
          const SizedBox(height: 32),
        ];
    }
  }

  List<Widget> _buildSpace() {
    final l10n = context.l10n;
    switch (_space) {
      case UsLoading():
        return const [UsLoadingCard(), SizedBox(height: 32)];
      case UsFailed(:final failure):
        return [
          UsSectionError(
            title: l10n.coupleSpaceLoadFailedTitle,
            line: failure.label(l10n),
            onRetry: _loadSpace,
          ),
          const SizedBox(height: 32),
        ];
      case UsReady(:final value):
        return [
          _buildStatsSection(value.snapshot),
          const SizedBox(height: 32),
          _buildQuickActions(),
          const SizedBox(height: 32),
          ..._buildMemoriesSection(value.memories),
          const SizedBox(height: 32),
          _buildBucketListSection(value.bucketList),
          const SizedBox(height: 32),
          _buildDatesSection(value.dates),
          const SizedBox(height: 32),
        ];
    }
  }

  Widget _buildSettings() {
    final couple = _couple.coupleData;
    return UsSettingsSection(
      status: _pendingStatus ?? couple?.status ?? RelationshipStatus.single,
      premium: _couple.premium,
      partnerName: _partnerName,
      onStatus: _setStatus,
      onPremium: () => context.push(RoutePaths.couplePremium),
    );
  }

  Widget _buildStatsSection(CoupleStatsSnapshot snapshot) {
    final stats = snapshot.stats;
    final l10n = context.l10n;
    return Row(
      children: [
        UsStatCard(
          key: const Key('couple-stat-0'),
          icon: LucideIcons.bookmark,
          value: '${stats.savedActivities}',
          label: l10n.coupleSpaceStatSavedActivities,
        ),
        const SizedBox(width: 12),
        UsStatCard(
          key: const Key('couple-stat-1'),
          icon: LucideIcons.calendar,
          value: '${stats.eventsRegistered}',
          label: l10n.coupleSpaceStatUpcomingEvents,
        ),
        const SizedBox(width: 12),
        UsStatCard(
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
            UsQuickAction(
              icon: LucideIcons.camera,
              label: l10n.coupleSpaceQuickAddMemory,
              onTap: _showAddMemorySheet,
            ),
            const SizedBox(width: 12),
            UsQuickAction(
              icon: LucideIcons.target,
              label: l10n.coupleSpaceQuickAddBucket,
              onTap: _showAddBucketItemSheet,
            ),
            const SizedBox(width: 12),
            UsQuickAction(
              icon: LucideIcons.calendarPlus,
              label: l10n.coupleSpaceQuickAddDate,
              onTap: _showAddDateSheet,
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildMemoriesSection(List<CoupleMemory> memories) {
    final l10n = context.l10n;
    return [
      SectionLabel(l10n.coupleSpaceMemoriesTitle),
      const SizedBox(height: 12),
      if (memories.isEmpty)
        UsEmptyCard(
          icon: LucideIcons.camera,
          title: l10n.coupleSpaceMemoriesEmptyTitle,
          hint: l10n.coupleSpaceMemoriesEmptyHint,
        )
      else
        FullBleed(
          builder: (context, gutter) => SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: gutter,
              itemCount: memories.take(10).length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  UsMemoryTile(memory: memories[index], seed: index),
            ),
          ),
        ),
    ];
  }

  Widget _buildBucketListSection(List<BucketListItem> bucketList) {
    final pending = bucketList.where((i) => !i.isCompleted).toList();
    final completed = bucketList.where((i) => i.isCompleted).toList();
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          bucketList.isEmpty
              ? l10n.coupleSpaceBucketTitle
              : l10n.coupleSpaceBucketProgress(
                  completed.length,
                  bucketList.length,
                ),
        ),
        const SizedBox(height: 12),
        if (bucketList.isEmpty)
          UsEmptyCard(
            icon: LucideIcons.target,
            title: l10n.coupleSpaceBucketEmptyTitle,
            hint: l10n.coupleSpaceBucketEmptyHint,
          )
        else
          for (final item in pending.take(3))
            UsBucketItem(
              title: item.title,
              category: item.category,
              isCompleted: false,
              onComplete: () => _completeBucketItem(item.id),
            ),
      ],
    );
  }

  Widget _buildDatesSection(List<CoupleDate> dates) {
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
        if (dates.isEmpty)
          UsEmptyCard(
            icon: LucideIcons.calendarHeart,
            title: l10n.coupleSpaceDatesEmptyTitle,
            hint: l10n.coupleSpaceDatesEmptyHint,
          )
        else
          for (final date in dates.take(3))
            UsDateItem(
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
    if (added == true && mounted) await _loadSpace(quiet: true);
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
        await _loadSpace(quiet: true);
      case CoupleFailed():
        showCoupleError(context, l10n.coupleSpaceGoalFailed);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat.yMMMd(context.l10n.localeName).format(date);
  }
}
