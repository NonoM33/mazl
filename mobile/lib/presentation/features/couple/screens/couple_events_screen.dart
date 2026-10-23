import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_event.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/couple_message_view.dart';
import '../widgets/event_category.dart';

class CoupleEventsScreen extends StatefulWidget {
  const CoupleEventsScreen({super.key, this.apiService});

  /// Injected by tests; the app uses the real service.
  final CoupleApiService? apiService;

  @override
  State<CoupleEventsScreen> createState() => _CoupleEventsScreenState();
}

class _CoupleEventsScreenState extends State<CoupleEventsScreen>
    with SingleTickerProviderStateMixin {
  late final CoupleApiService _apiService =
      widget.apiService ?? CoupleApiService();
  late TabController _tabController;

  List<CoupleEvent> _allEvents = [];
  List<CoupleEvent> _registeredEvents = [];
  bool _isLoading = true;
  CoupleFailure? _failure;
  int _loadToken = 0;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final token = ++_loadToken;
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final results = await Future.wait([
      _apiService.getEvents(limit: 50, category: _selectedCategory),
      _apiService.getRegisteredEvents(),
    ]);
    if (!mounted || token != _loadToken) return;

    final all = results[0];
    final registered = results[1];
    setState(() {
      _isLoading = false;
      if (all is CoupleOk<List<CoupleEvent>> &&
          registered is CoupleOk<List<CoupleEvent>>) {
        _allEvents = all.value;
        _registeredEvents = registered.value;
      } else {
        _failure = all.failureOrNull ?? registered.failureOrNull;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: top + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Événements',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                  height: 1.05,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  const Tab(text: 'À venir'),
                  Tab(text: 'Inscrits (${_registeredEvents.length})'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryFilter(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventsList(_allEvents, showRegisterButton: true),
                  _buildEventsList(
                    _registeredEvents,
                    showRegisterButton: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: eventCategoryFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = eventCategoryFilters[index];
          return _FilterPill(
            key: Key('events-filter-${cat.key ?? 'all'}'),
            label: cat.label,
            selected: _selectedCategory == cat.key,
            onTap: () {
              setState(() => _selectedCategory = cat.key);
              _loadEvents();
            },
          );
        },
      ),
    );
  }

  Widget _buildEventsList(
    List<CoupleEvent> events, {
    required bool showRegisterButton,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final failure = _failure;
    if (failure != null) {
      return CoupleMessageView.failure(failure, onRetry: _loadEvents);
    }

    if (events.isEmpty) {
      return CoupleMessageView(
        icon: LucideIcons.calendar,
        title: showRegisterButton
            ? 'Aucun événement disponible'
            : 'Vous n\'êtes inscrit à aucun événement',
        actionLabel: showRegisterButton ? null : 'Découvrir les événements',
        onAction: showRegisterButton ? null : () => _tabController.animateTo(0),
      );
    }

    final bottom = MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottom + 24),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _EventCard(
            event: event,
            seed: index,
            showRegisterButton: showRegisterButton,
            onTap: () => context.push('/couple/events/${event.id}'),
            onRegister: () => _registerForEvent(event),
            onCancel: () => _cancelRegistration(event),
            isRegistered: _registeredEvents.any((e) => e.id == event.id),
          );
        },
      ),
    );
  }

  Future<void> _registerForEvent(CoupleEvent event) async {
    final result = await _apiService.registerForEvent(event.id);
    if (!mounted) return;
    switch (result) {
      case CoupleOk():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inscrits à "${event.title}"'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadEvents();
      case CoupleFailed(:final failure):
        showCoupleError(
          context,
          failure.kind == CoupleFailureKind.full
              ? failure.message
              : 'Inscription impossible. Réessayez.',
        );
    }
  }

  Future<void> _cancelRegistration(CoupleEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'inscription ?'),
        content: Text(
          'Voulez-vous vraiment annuler votre inscription à "${event.title}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _apiService.cancelEventRegistration(event.id);
      if (!mounted) return;
      switch (result) {
        case CoupleOk():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscription annulée'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadEvents();
        case CoupleFailed():
          showCoupleError(
            context,
            'Impossible d\'annuler l\'inscription. Réessayez.',
          );
      }
    }
  }
}

/// Puce de filtre : choisie, elle est pleine d'encre.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.onSurface : scheme.surfaceContainer,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? scheme.surface : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.seed,
    required this.showRegisterButton,
    required this.onTap,
    required this.onRegister,
    required this.onCancel,
    required this.isRegistered,
  });

  final CoupleEvent event;
  final int seed;
  final bool showRegisterButton;
  final VoidCallback onTap;
  final VoidCallback onRegister;
  final VoidCallback onCancel;
  final bool isRegistered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final when = [
      event.formattedDate,
      if (event.formattedTime.isNotEmpty) event.formattedTime,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(when),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 22),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    _buildMeta(scheme),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TagPill(
                          eventCategoryLabel(event.category),
                          icon: eventCategoryIcon(event.category),
                          onDark: true,
                        ),
                        TagPill(event.formattedPrice, onDark: true),
                      ],
                    ),
                    ..._buildAction(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (event.imageUrl != null)
            CachedNetworkImage(
              imageUrl: event.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) => _placeholder(),
              errorWidget: (_, _, _) => _placeholder(),
            )
          else
            _placeholder(),
          if (event.isFeatured || event.isKosher)
            Positioned(
              top: 12,
              left: 12,
              child: Wrap(
                spacing: 8,
                children: [
                  if (event.isFeatured)
                    const TagPill(
                      'À la une',
                      icon: LucideIcons.star,
                      onDark: true,
                    ),
                  if (event.isKosher) const TagPill('Casher', onDark: true),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() =>
      EventImagePlaceholder(category: event.category, seed: seed);

  Widget _buildMeta(ColorScheme scheme) {
    final muted = scheme.onSurfaceVariant;
    final style = TextStyle(color: muted, fontSize: 14);
    final full = event.isFull;
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        if (event.city != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.mapPin, size: 16, color: muted),
              const SizedBox(width: 6),
              Text(event.city!, style: style),
            ],
          ),
        if (event.maxCouples != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.users,
                size: 16,
                color: full ? AppColors.error : muted,
              ),
              const SizedBox(width: 6),
              Text(
                full ? 'Complet' : '${event.spotsLeft} places',
                style: style.copyWith(
                  color: full ? AppColors.error : muted,
                  fontWeight: full ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
      ],
    );
  }

  List<Widget> _buildAction() {
    final Widget button;
    if (showRegisterButton && !isRegistered && !event.isFull) {
      button = FilledButton(
        onPressed: onRegister,
        child: const Text('S\'inscrire'),
      );
    } else if (isRegistered) {
      button = OutlinedButton(
        onPressed: onCancel,
        child: const Text('Annuler'),
      );
    } else {
      return const [];
    }
    return [
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: button),
    ];
  }
}
