import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_event.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/couple_message_view.dart';

class CoupleEventDetailScreen extends StatefulWidget {
  const CoupleEventDetailScreen({
    super.key,
    required this.eventId,
    this.apiService,
  });

  final String eventId;

  /// Injected by tests; the app uses the real service.
  final CoupleApiService? apiService;

  @override
  State<CoupleEventDetailScreen> createState() =>
      _CoupleEventDetailScreenState();
}

class _CoupleEventDetailScreenState extends State<CoupleEventDetailScreen> {
  late final CoupleApiService _apiService =
      widget.apiService ?? CoupleApiService();

  CoupleEvent? _event;
  bool _isRegistered = false;
  bool _isLoading = true;
  bool _isUpdatingRegistration = false;
  CoupleFailure? _failure;

  static const coupleAccent = Color(0xFFFF6B9D);

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    final id = int.tryParse(widget.eventId);
    if (id == null) {
      setState(() {
        _isLoading = false;
        _failure = const CoupleFailure(
          CoupleFailureKind.notFound,
          'Cet événement n\'existe plus.',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final results = await Future.wait([
      _apiService.getEvent(id),
      _apiService.getRegisteredEvents(),
    ]);
    if (!mounted) return;

    final event = results[0] as CoupleResult<CoupleEvent>;
    final registered = results[1] as CoupleResult<List<CoupleEvent>>;
    setState(() {
      _isLoading = false;
      switch ((event, registered)) {
        case (CoupleFailed(:final failure), _):
        case (_, CoupleFailed(:final failure)):
          _failure = failure;
        case (CoupleOk(value: final e), CoupleOk(value: final list)):
          _event = e;
          _isRegistered = list.any((r) => r.id == e.id);
      }
    });
  }

  Future<void> _toggleRegistration() async {
    final event = _event;
    if (event == null || _isUpdatingRegistration) return;

    final wasRegistered = _isRegistered;
    setState(() => _isUpdatingRegistration = true);

    final result = wasRegistered
        ? await _apiService.cancelEventRegistration(event.id)
        : await _apiService.registerForEvent(event.id);
    if (!mounted) return;

    switch (result) {
      case CoupleFailed(:final failure):
        setState(() => _isUpdatingRegistration = false);
        showCoupleError(
          context,
          failure.kind == CoupleFailureKind.full
              ? failure.message
              : wasRegistered
              ? 'Impossible d\'annuler l\'inscription. Réessayez.'
              : 'Inscription impossible. Réessayez.',
        );
      case CoupleOk():
        setState(() {
          _isUpdatingRegistration = false;
          _isRegistered = !wasRegistered;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasRegistered
                  ? 'Inscription annulée'
                  : 'Inscrits à « ${event.title} »',
            ),
            backgroundColor: wasRegistered ? null : AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _refreshEvent(event.id);
    }
  }

  /// Seats left changed: re-read the event; a failure keeps what is shown.
  Future<void> _refreshEvent(int id) async {
    final result = await _apiService.getEvent(id);
    if (!mounted) return;
    if (result case CoupleOk(:final value)) setState(() => _event = value);
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
    final event = _event;
    if (failure != null || event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: failure == null || failure.kind == CoupleFailureKind.notFound
            ? const CoupleMessageView(
                icon: LucideIcons.calendarX,
                title: 'Événement introuvable',
                line: 'Il n\'est plus proposé.',
              )
            : CoupleMessageView.failure(failure, onRetry: _loadEvent),
      );
    }

    return Scaffold(
      body: _buildContent(),
      bottomNavigationBar: _buildRegistrationBar(event),
    );
  }

  Widget _buildRegistrationBar(CoupleEvent event) {
    final label = _isRegistered
        ? 'Annuler mon inscription'
        : event.isFull
        ? 'Complet'
        : 'S\'inscrire';
    final canTap = !_isUpdatingRegistration && (_isRegistered || !event.isFull);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          width: double.infinity,
          child: _isRegistered
              ? OutlinedButton(
                  onPressed: canTap ? _toggleRegistration : null,
                  child: Text(label),
                )
              : ElevatedButton(
                  onPressed: canTap ? _toggleRegistration : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coupleAccent,
                  ),
                  child: Text(label),
                ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final event = _event!;

    return CustomScrollView(
      slivers: [
        // App bar with image
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: event.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: event.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: coupleAccent.withValues(alpha: 0.3)),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: coupleAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${event.categoryEmoji} ${event.category ?? "Événement"}',
                        style: const TextStyle(
                          color: coupleAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (event.isKosher)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Casher',
                          style: TextStyle(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (event.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.star,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'À la une',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Date & Time
                _buildInfoRow(LucideIcons.calendar, event.formattedDate),
                if (event.eventTime != null)
                  _buildInfoRow(LucideIcons.clock, event.formattedTime),

                // Location
                if (event.location != null || event.city != null)
                  _buildInfoRow(
                    LucideIcons.mapPin,
                    event.location ?? event.city ?? '',
                  ),

                // Address
                if (event.address != null)
                  _buildInfoRow(LucideIcons.navigation, event.address!),

                const SizedBox(height: 20),

                // Price
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.ticket, color: AppColors.success),
                      const SizedBox(width: 12),
                      Text(
                        event.formattedPrice,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const Spacer(),
                      if (event.maxCouples != null)
                        Text(
                          event.isFull
                              ? 'Complet'
                              : '${event.spotsLeft} places restantes',
                          style: TextStyle(
                            color: event.isFull
                                ? AppColors.error
                                : Colors.grey[600],
                            fontWeight: event.isFull
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),

                // What's included
                if (event.whatIncluded != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Ce qui est inclus',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.whatIncluded!,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],

                // Dress code
                if (event.dressCode != null) ...[
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    LucideIcons.shirt,
                    'Dress code : ${event.dressCode}',
                  ),
                ],

                // Organizer
                if (event.organizerName != null) ...[
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    LucideIcons.user,
                    'Organisé par ${event.organizerName}',
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: coupleAccent.withValues(alpha: 0.3),
      child: Center(
        child: Text(
          _event?.categoryEmoji ?? '',
          style: const TextStyle(fontSize: 64),
        ),
      ),
    );
  }
}
