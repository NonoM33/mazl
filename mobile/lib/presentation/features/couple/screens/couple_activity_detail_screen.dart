import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/couple_activity.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/activity_visual.dart';
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
          'Cette activité n\'existe plus.',
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
              ? 'Impossible de retirer cette activité. Réessayez.'
              : 'Impossible de sauvegarder cette activité. Réessayez.',
        );
      case CoupleOk():
        if (!wasSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Activité sauvegardée'),
              action: SnackBarAction(
                label: 'Voir',
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Code $code copié')));
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
            ? const CoupleMessageView(
                icon: LucideIcons.searchX,
                title: 'Activité introuvable',
                line: 'Elle n\'est plus proposée.',
              )
            : CoupleMessageView.failure(failure, onRetry: _loadActivity),
      );
    }

    final activity = _activity!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final city = activity.city;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leadingWidth: 72,
            leading: Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Center(
                child: RoundIconButton(
                  icon: LucideIcons.arrowLeft,
                  tooltip: 'Retour',
                  size: 40,
                  iconSize: 18,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ActivityVisual(activity: activity, iconSize: 48),
            ),
            actions: [
              RoundIconButton(
                icon: LucideIcons.share2,
                tooltip: 'Partager',
                size: 40,
                iconSize: 18,
                onPressed: () {
                  final activity = _activity;
                  if (activity == null) return;
                  Share.share(
                    'Idée de date pour nous : "${activity.title}" (via MAZL)',
                    subject: activity.title,
                  );
                },
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: _isSaved ? LucideIcons.bookMarked : LucideIcons.bookmark,
                tooltip: _isSaved
                    ? 'Retirer des activités sauvegardées'
                    : 'Enregistrer',
                size: 40,
                iconSize: 18,
                style: _isSaved
                    ? RoundButtonStyle.ink
                    : RoundButtonStyle.outline,
                onPressed: _toggleSaved,
              ),
              const SizedBox(width: 24),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TagPill(
                        activity.categoryLabel,
                        icon: activityCategoryIcon(activity.category),
                      ),
                      const SizedBox(width: 12),
                      if (activity.rating != null)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                LucideIcons.star,
                                color: scheme.onSurface,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _ratingLabel(activity),
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
                      if (city != null)
                        _MetaItem(icon: LucideIcons.mapPin, label: city),
                      if (activity.durationMinutes != null)
                        _MetaItem(
                          icon: LucideIcons.clock,
                          label: activity.formattedDuration,
                        ),
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
                              ? '-${activity.discountPercent} % Partenaire'
                              : 'Partenaire MAZL',
                          icon: LucideIcons.badgePercent,
                        ),
                      if (activity.isKosher) const TagPill('Casher'),
                      TagPill(activity.formattedPrice, icon: LucideIcons.euro),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (activity.isPartner && activity.discountCode != null) ...[
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
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
                                const SectionLabel('Code promo MAZL'),
                                const SizedBox(height: 6),
                                Text(
                                  activity.discountCode!,
                                  style: textTheme.titleLarge?.copyWith(
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RoundIconButton(
                            icon: LucideIcons.copy,
                            tooltip: 'Copier le code',
                            size: 40,
                            iconSize: 18,
                            onPressed: () =>
                                _copyDiscountCode(activity.discountCode!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const SectionLabel('Description'),
                  const SizedBox(height: 8),
                  Text(activity.description, style: textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  if (activity.tags.isNotEmpty) ...[
                    const SectionLabel('Tags'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in activity.tags) TagPill('#$tag'),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (activity.address != null ||
                      activity.location != null) ...[
                    const SectionLabel('Adresse'),
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
                            Text(
                              activity.location!,
                              style: textTheme.titleMedium,
                            ),
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
                    const SectionLabel('Contact'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (activity.phone != null)
                          Expanded(
                            child: _ContactButton(
                              icon: LucideIcons.phone,
                              label: 'Appeler',
                              onPressed: () => _makeCall(activity.phone!),
                            ),
                          ),
                        if (activity.phone != null && activity.website != null)
                          const SizedBox(width: 12),
                        if (activity.website != null)
                          Expanded(
                            child: _ContactButton(
                              icon: LucideIcons.globe,
                              label: 'Site web',
                              onPressed: () => _openUrl(activity.website!),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('À partir de', style: textTheme.bodySmall),
                    Text(activity.formattedPrice, style: textTheme.titleLarge),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: activity.bookingUrl != null
                      ? () => _openUrl(activity.bookingUrl!)
                      : null,
                  icon: const Icon(LucideIcons.externalLink, size: 18),
                  label: const Text('Réserver'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _ratingLabel(CoupleActivity activity) {
  final rating = activity.rating!.toStringAsFixed(1);
  final count = activity.reviewCount;
  return count == null ? rating : '$rating ($count avis)';
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
