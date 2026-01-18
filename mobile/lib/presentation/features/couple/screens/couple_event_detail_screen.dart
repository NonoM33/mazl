import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/couple_event.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';

class CoupleEventDetailScreen extends StatefulWidget {
  const CoupleEventDetailScreen({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  State<CoupleEventDetailScreen> createState() => _CoupleEventDetailScreenState();
}

class _CoupleEventDetailScreenState extends State<CoupleEventDetailScreen> {
  final CoupleApiService _apiService = CoupleApiService();

  CoupleEvent? _event;
  bool _isLoading = true;
  bool _hasError = false;

  static const coupleAccent = Color(0xFFFF6B9D);

  int get _eventId => int.tryParse(widget.eventId) ?? 0;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final event = await _apiService.getEvent(_eventId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (event != null) {
          _event = event;
        } else {
          _hasError = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError || _event == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertTriangle, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Evenement introuvable',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: coupleAccent,
            ),
            child: const Text('Retour'),
          ),
        ],
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
                    placeholder: (context, url) => Container(
                      color: coupleAccent.withOpacity(0.3),
                    ),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: coupleAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${event.categoryEmoji} ${event.category ?? "Evenement"}',
                        style: const TextStyle(
                          color: coupleAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (event.isKosher)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.1),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.star, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'A la une',
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
                _buildInfoRow(
                  LucideIcons.calendar,
                  event.formattedDate,
                ),
                if (event.eventTime != null)
                  _buildInfoRow(
                    LucideIcons.clock,
                    event.formattedTime,
                  ),

                // Location
                if (event.location != null || event.city != null)
                  _buildInfoRow(
                    LucideIcons.mapPin,
                    event.location ?? event.city ?? '',
                  ),

                // Address
                if (event.address != null)
                  _buildInfoRow(
                    LucideIcons.navigation,
                    event.address!,
                  ),

                const SizedBox(height: 20),

                // Price
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
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
                            color: event.isFull ? AppColors.error : Colors.grey[600],
                            fontWeight: event.isFull ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                    'Dress code: ${event.dressCode}',
                  ),
                ],

                // Organizer
                if (event.organizerName != null) ...[
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    LucideIcons.user,
                    'Organise par ${event.organizerName}',
                  ),
                ],

                const SizedBox(height: 100), // Space for bottom button
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
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: coupleAccent.withOpacity(0.3),
      child: Center(
        child: Text(
          _event?.categoryEmoji ?? '',
          style: const TextStyle(fontSize: 64),
        ),
      ),
    );
  }
}
