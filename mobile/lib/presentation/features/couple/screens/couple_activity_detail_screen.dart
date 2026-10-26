import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/models/couple_activity.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/couple_feed_labels.dart';
import '../widgets/activity_visual.dart';
import '../widgets/book_pages.dart';
import '../widgets/couple_message_view.dart';

class CoupleActivityDetailScreen extends StatefulWidget {
  const CoupleActivityDetailScreen({
    super.key,
    required this.activityId,
    this.apiService,
  });

  final String activityId;

  /// Injected by tests; the app uses the real service.
  final CoupleApiService? apiService;

  @override
  State<CoupleActivityDetailScreen> createState() =>
      _CoupleActivityDetailScreenState();
}

class _CoupleActivityDetailScreenState
    extends State<CoupleActivityDetailScreen> {
  late final CoupleApiService _apiService =
      widget.apiService ?? CoupleApiService();
  CoupleActivity? _activity;
  bool _isLoading = true;
  bool _isSaved = false;
  bool _isSaving = false;
  CoupleFailure? _failure;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    final id = int.tryParse(widget.activityId);
    if (id == null) {
      setState(() {
        _isLoading = false;
        _failure = const CoupleFailure(
          CoupleFailureKind.notFound,
          'invalidActivityId',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _failure = null;
    });

    // The activity route does not say whether it is saved: ask the saved list.
    final results = await Future.wait([
      _apiService.getActivity(id),
      _apiService.getSavedActivities(),
    ]);
    if (!mounted) return;

    final activity = results[0] as CoupleResult<CoupleActivity>;
    final saved = results[1] as CoupleResult<List<CoupleActivity>>;
    setState(() {
      _isLoading = false;
      switch ((activity, saved)) {
        case (CoupleFailed(:final failure), _):
        case (_, CoupleFailed(:final failure)):
          _failure = failure;
        case (CoupleOk(value: final a), CoupleOk(value: final list)):
          _activity = a;
          _isSaved = list.any((s) => s.id == a.id);
      }
    });
  }

  Future<void> _toggleSaved() async {
    final activity = _activity;
    if (activity == null || _isSaving) return;

    final wasSaved = _isSaved;
    setState(() {
      _isSaved = !wasSaved;
      _isSaving = true;
    });

    final result = wasSaved
        ? await _apiService.removeSavedActivity(activity.id)
        : await _apiService.saveActivity(activity.id);
    if (!mounted) return;
    setState(() => _isSaving = false);

    switch (result) {
      case CoupleFailed():
        setState(() => _isSaved = wasSaved);
        showCoupleError(
          context,
          wasSaved
              ? context.l10n.coupleFeedActivityRemoveError
              : context.l10n.coupleFeedActivitySaveError,
        );
      case CoupleOk():
        if (!wasSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.coupleFeedActivitySavedConfirm),
              action: SnackBarAction(
                label: context.l10n.commonSee,
                textColor: Theme.of(context).colorScheme.onInverseSurface,
                onPressed: () => context.push('/couple/activities/saved'),
              ),
            ),
          );
        }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyDiscountCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.coupleFeedCodeCopied(code))),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final failure = _failure;
    if (failure != null || _activity == null) {
      final notFound = failure?.kind == CoupleFailureKind.notFound;
      return Scaffold(
        appBar: AppBar(),
        body: notFound || failure == null
            ? CoupleMessageView(
                icon: LucideIcons.searchX,
                title: context.l10n.coupleFeedActivityNotFoundTitle,
                line: context.l10n.coupleFeedActivityNotFoundLine,
              )
            : coupleFailureView(context, failure, onRetry: _loadActivity),
      );
    }

    final activity = _activity!;

    return FoldCutBuilder(
      minPaneExtent: bookPaneExtent,
      builder: (context, cut) => cut?.axis == FoldSplitAxis.vertical
          ? Scaffold(body: _buildBook(activity, cut!))
          : _buildFlat(activity),
    );
  }

  Widget _buildFlat(CoupleActivity activity) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leadingWidth: 72,
            leading: Padding(
              padding: const EdgeInsetsDirectional.only(start: 24),
              child: Center(child: _backButton()),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ActivityVisual(activity: activity, iconSize: 48),
            ),
            actions: [..._visualActions(activity), const SizedBox(width: 24)],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeadline(activity),
                  const SizedBox(height: 24),
                  ..._buildDetails(activity),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBookingBar(activity),
    );
  }

  /// Held like a book: the visual, the title and the labels to look at on
  /// the first page; the description, the address and the booking on the
  /// other.
  Widget _buildBook(CoupleActivity activity, FoldCut cut) {
    final top = MediaQuery.paddingOf(context).top;
    return bookPages(
      cut,
      lead: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300 + top,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ActivityVisual(activity: activity, iconSize: 48),
                  PositionedDirectional(
                    top: top + 8,
                    start: 24,
                    child: _backButton(),
                  ),
                  PositionedDirectional(
                    top: top + 8,
                    end: 24,
                    child: Row(children: _visualActions(activity)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: _buildHeadline(activity),
            ),
          ],
        ),
      ),
      action: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, top + 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildDetails(activity),
              ),
            ),
          ),
          _buildBookingBar(activity),
        ],
      ),
    );
  }

  Widget _backButton() => RoundIconButton(
    icon: backArrowIcon(context),
    tooltip: context.l10n.commonBack,
    size: 40,
    iconSize: 18,
    onPressed: () => Navigator.of(context).maybePop(),
  );

  /// Share and save, over the visual.
  List<Widget> _visualActions(CoupleActivity activity) {
    final l10n = context.l10n;
    return [
      RoundIconButton(
        icon: LucideIcons.share2,
        tooltip: l10n.commonShare,
        size: 40,
        iconSize: 18,
        onPressed: () {
          final activity = _activity;
          if (activity == null) return;
          Share.share(
            l10n.coupleFeedActivityShareText(activity.title),
            subject: activity.title,
          );
        },
      ),
      const SizedBox(width: 8),
      RoundIconButton(
        icon: _isSaved ? LucideIcons.bookMarked : LucideIcons.bookmark,
        tooltip: _isSaved ? l10n.coupleFeedRemoveFromSaved : l10n.commonSave,
        size: 40,
        iconSize: 18,
        style: _isSaved ? RoundButtonStyle.ink : RoundButtonStyle.outline,
        onPressed: _toggleSaved,
      ),
    ];
  }

  /// Category, rating, title, place, duration and labels.
  Widget _buildHeadline(CoupleActivity activity) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final city = activity.city;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TagPill(
              activity.categoryName(l10n),
              icon: activityCategoryIcon(activity.category),
            ),
            const SizedBox(width: 12),
            if (activity.rating != null)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(LucideIcons.star, color: scheme.onSurface, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        activity.ratingWithReviewsLabel(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(activity.title, style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            if (city != null) _MetaItem(icon: LucideIcons.mapPin, label: city),
            if (activity.durationLabel(l10n) case final duration?)
              _MetaItem(icon: LucideIcons.clock, label: duration),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (activity.isPartner)
              AccentPill(
                activity.discountPercent != null
                    ? l10n.coupleFeedPartnerDiscount(activity.discountPercent!)
                    : l10n.coupleFeedPartnerMazl,
                icon: LucideIcons.badgePercent,
              ),
            if (activity.isKosher) TagPill(l10n.coupleFeedKosher),
            TagPill(activity.priceLabel(l10n), icon: LucideIcons.euro),
          ],
        ),
      ],
    );
  }

  /// Promo code, description, tags, address and contact.
  List<Widget> _buildDetails(CoupleActivity activity) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final city = activity.city;
    return [
      if (activity.isPartner && activity.discountCode != null) ...[
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 12, 16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(l10n.coupleFeedPromoCodeLabel),
                    const SizedBox(height: 6),
                    Text(
                      activity.discountCode!,
                      style: textTheme.titleLarge?.copyWith(letterSpacing: 2),
                    ),
                  ],
                ),
              ),
              RoundIconButton(
                icon: LucideIcons.copy,
                tooltip: l10n.coupleFeedCopyCode,
                size: 40,
                iconSize: 18,
                onPressed: () => _copyDiscountCode(activity.discountCode!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
      SectionLabel(l10n.coupleFeedDescription),
      const SizedBox(height: 8),
      Text(activity.description, style: textTheme.bodyLarge),
      const SizedBox(height: 24),
      if (activity.tags.isNotEmpty) ...[
        SectionLabel(l10n.coupleFeedTags),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final tag in activity.tags) TagPill('#$tag')],
        ),
        const SizedBox(height: 24),
      ],
      if (activity.address != null || activity.location != null) ...[
        SectionLabel(l10n.coupleFeedAddress),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activity.location != null)
                Text(activity.location!, style: textTheme.titleMedium),
              if (activity.address != null)
                Text(
                  activity.address!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              if (city != null)
                Text(
                  city,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
      if (activity.phone != null || activity.website != null) ...[
        SectionLabel(l10n.coupleFeedContact),
        const SizedBox(height: 12),
        Row(
          children: [
            if (activity.phone != null)
              Expanded(
                child: _ContactButton(
                  icon: LucideIcons.phone,
                  label: l10n.coupleFeedCall,
                  onPressed: () => _makeCall(activity.phone!),
                ),
              ),
            if (activity.phone != null && activity.website != null)
              const SizedBox(width: 12),
            if (activity.website != null)
              Expanded(
                child: _ContactButton(
                  icon: LucideIcons.globe,
                  label: l10n.coupleFeedWebsite,
                  onPressed: () => _openUrl(activity.website!),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    ];
  }

  Widget _buildBookingBar(CoupleActivity activity) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: SafeArea(
        child: FoldSafeActions(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.coupleFeedFromPrice, style: textTheme.bodySmall),
                    Text(
                      activity.priceLabel(l10n),
                      style: textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: activity.bookingUrl != null
                      ? () => _openUrl(activity.bookingUrl!)
                      : null,
                  icon: const Icon(LucideIcons.externalLink, size: 18),
                  label: Text(l10n.coupleFeedBook),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
        ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
