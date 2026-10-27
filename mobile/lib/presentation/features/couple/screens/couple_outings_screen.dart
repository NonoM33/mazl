import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/layout/fold_spread.dart';
import '../../../../core/models/couple_daily.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/services/couple_daily_api.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/couple_failure_label.dart';
import '../widgets/couple_kit.dart';
import '../widgets/couple_message_view.dart';
import '../widgets/outing_featured_card.dart';
import '../widgets/outing_tile.dart';
import '../../../common/widgets/star_refresh/star_refresh.dart';

/// The « Sorties » tab: the outing put forward and the ideas picked for the
/// two of them, filtered by one pill at a time.
class CoupleOutingsScreen extends StatefulWidget {
  const CoupleOutingsScreen({super.key, this.api, this.contentApi});

  /// Injected by tests; the app uses the real clients.
  final CoupleDailyApi? api;
  final CoupleApiService? contentApi;

  @override
  State<CoupleOutingsScreen> createState() => _CoupleOutingsScreenState();
}

class _CoupleOutingsScreenState extends State<CoupleOutingsScreen> {
  late final CoupleDailyApi _api = widget.api ?? CoupleDailyApi.forApp();
  late final CoupleApiService _content =
      widget.contentApi ?? CoupleApiService();

  OutingFilter? _filter;
  OutingsPage? _page;
  bool _loading = true;
  CoupleFailure? _failure;

  /// Identifies the latest request: an older answer that comes back late is
  /// dropped, it would show another filter's outings under the right pill.
  int _token = 0;

  /// Activities whose bookmark is being sent: a second tap waits.
  final Set<int> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool quiet = false}) async {
    final token = ++_token;
    if (!quiet) {
      setState(() {
        _loading = true;
        _failure = null;
      });
    }
    final result = await _api.getOutings(_filter);
    if (!mounted || token != _token) return;
    switch (result) {
      case CoupleOk(:final value):
        setState(() {
          _page = value;
          _loading = false;
          _failure = null;
        });
      case CoupleFailed(:final failure):
        if (quiet && _page != null) {
          showCoupleError(context, failure.label(context.l10n));
        } else {
          setState(() {
            _loading = false;
            _failure = failure;
          });
        }
    }
  }

  void _pick(OutingFilter filter) {
    _filter = _filter == filter ? null : filter;
    _load();
  }

  void _showAll() {
    _filter = null;
    _load();
  }

  void _open(Outing outing) => context.push(
    outing.isEvent
        ? RoutePaths.coupleEventPath(outing.id)
        : RoutePaths.coupleActivityPath(outing.id),
  );

  void _setSaved(int id, bool saved) {
    final page = _page;
    if (page == null) return;
    Outing mark(Outing o) =>
        !o.isEvent && o.id == id ? o.copyWith(saved: saved) : o;
    final featured = page.featured;
    setState(() {
      _page = OutingsPage(
        featured: featured == null ? null : mark(featured),
        items: [for (final o in page.items) mark(o)],
      );
    });
  }

  Future<void> _toggleSave(Outing outing) async {
    if (outing.isEvent || !_saving.add(outing.id)) return;
    final target = !outing.saved;
    _setSaved(outing.id, target);
    final result = target
        ? await _content.saveActivity(outing.id)
        : await _content.removeSavedActivity(outing.id);
    _saving.remove(outing.id);
    if (!mounted || result is CoupleOk) return;
    _setSaved(outing.id, !target);
    showCoupleError(context, context.l10n.coupleOutingsSaveFailed);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context);
    return Scaffold(
      body: StarRefresh(
        onRefresh: () => _load(quiet: true),
        // A short page (an empty state) can still be pulled down to refresh.
        child: ScrollConfiguration(
          behavior: const _PullableBehavior(),
          child: FoldCutBuilder(
            minPaneExtent: 240,
            builder: (context, cut) {
              final laptop = cut?.axis == FoldSplitAxis.horizontal;
              final page = _page;
              final ready = !_loading && _failure == null && page != null;
              final showing =
                  ready && (page.featured != null || page.items.isNotEmpty);
              final featured = showing && page.featured != null
                  ? _featured(page.featured!)
                  : null;
              return FoldSpread(
                laptopVolets: true,
                wideFrom: 720,
                padding: EdgeInsets.fromLTRB(
                  24,
                  inset.top + 16,
                  24,
                  inset.bottom + 24,
                ),
                start: [
                  _header(page),
                  const SizedBox(height: 20),
                  _filters(),
                  const SizedBox(height: 20),
                  if (featured != null && !laptop) featured,
                ],
                end: [
                  if (!showing)
                    _status()
                  else ...[
                    if (featured != null && laptop) ...[
                      featured,
                      const SizedBox(height: 24),
                    ],
                    if (page.items.isNotEmpty) ..._picks(page.items),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(OutingsPage? page) {
    final l10n = context.l10n;
    final city = page?.featured?.city ?? page?.items.firstOrNull?.city;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CoupleHeader(
            eyebrow: city == null
                ? l10n.coupleOutingsEyebrow
                : l10n.coupleOutingsEyebrowCity(city),
            title: l10n.coupleOutingsTitle,
          ),
        ),
        const SizedBox(width: 12),
        RoundIconButton(
          icon: LucideIcons.bookmark,
          tooltip: l10n.coupleOutingsSavedTooltip,
          onPressed: () => context.push(RoutePaths.coupleSavedActivities),
        ),
      ],
    );
  }

  Widget _filters() {
    final l10n = context.l10n;
    final labels = <OutingFilter, String>{
      OutingFilter.tonight: l10n.coupleOutingsFilterTonight,
      OutingFilter.week: l10n.coupleOutingsFilterWeek,
      OutingFilter.kosher: l10n.coupleOutingsFilterKosher,
      OutingFilter.cheap: l10n.coupleOutingsFilterCheap,
      OutingFilter.mazl: l10n.coupleOutingsFilterMazl,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in labels.entries)
          CouplePill(
            label: entry.value,
            selected: _filter == entry.key,
            onTap: () => _pick(entry.key),
          ),
      ],
    );
  }

  Widget _featured(Outing outing) => OutingFeaturedCard(
    outing: outing,
    onOpen: () => _open(outing),
    onToggleSave: () => _toggleSave(outing),
  );

  List<Widget> _picks(List<Outing> items) {
    final l10n = context.l10n;
    return [
      SectionLabel(l10n.coupleOutingsPicksLabel),
      const SizedBox(height: 12),
      for (var i = 0; i < items.length; i += 2) ...[
        if (i > 0) const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _tile(items[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < items.length
                    ? _tile(items[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),
      Text(
        l10n.coupleOutingsNote,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }

  Widget _tile(Outing outing) => OutingTile(
    key: ValueKey('outing-${outing.kind.name}-${outing.id}'),
    outing: outing,
    onOpen: () => _open(outing),
    onToggleSave: () => _toggleSave(outing),
  );

  /// Loading, failure or nothing to show, in the place of the outings.
  Widget _status() {
    final l10n = context.l10n;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final failure = _failure;
    if (failure != null) {
      return _Message(
        icon: LucideIcons.alertCircle,
        title: l10n.coupleSpaceLoadFailedTitle,
        line: failure.label(l10n),
        actionLabel: l10n.commonRetry,
        onAction: _load,
      );
    }
    if (_filter != null) {
      return _Message(
        icon: LucideIcons.searchX,
        title: l10n.coupleOutingsEmptyFilterTitle,
        line: l10n.coupleOutingsEmptyFilterLine,
        actionLabel: l10n.coupleOutingsShowAll,
        onAction: _showAll,
      );
    }
    return _Message(
      icon: LucideIcons.sparkles,
      title: l10n.coupleOutingsEmptyTitle,
      line: l10n.coupleOutingsEmptyLine,
    );
  }
}

/// An icon, a title, one line and at most one action, in the flow of the page
/// (the page scrolls, so it cannot take the room the way a full-screen
/// message does).
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.line,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String line;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 32, color: muted),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            line,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// The platform's own scrolling, but always pullable.
class _PullableBehavior extends MaterialScrollBehavior {
  const _PullableBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      AlwaysScrollableScrollPhysics(parent: super.getScrollPhysics(context));
}
