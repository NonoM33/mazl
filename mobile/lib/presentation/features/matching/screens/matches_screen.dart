import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getMatches();
      if (response.success && response.data != null) {
        setState(() {
          _matches = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Erreur inconnue';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatMatchedAt(String? matchedAt) {
    if (matchedAt == null) return '';
    try {
      final date = DateTime.parse(matchedAt);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return "Aujourd'hui";
      } else if (diff.inDays == 1) {
        return 'Hier';
      } else if (diff.inDays < 7) {
        return 'Il y a ${diff.inDays} jours';
      } else if (diff.inDays < 30) {
        final weeks = (diff.inDays / 7).floor();
        return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
      } else {
        final months = (diff.inDays / 30).floor();
        return 'Il y a $months mois';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Matchs'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les matchs',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadMatches,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Pas encore de match',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Continue à découvrir des profils !',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          final profile = match['profile'] as Map<String, dynamic>?;

          if (profile == null) return const SizedBox.shrink();

          final userId = profile['user_id'] as int?;
          return _MatchCard(
            name: profile['display_name'] as String? ?? 'Inconnu',
            age: profile['age']?.toString(),
            location: profile['location'] as String?,
            picture: profile['picture'] as String?,
            isVerified: profile['is_verified'] == true,
            matchedAt: _formatMatchedAt(match['matchedAt'] as String?),
            onViewProfile: userId != null
                ? () => context.push('/discover/profile/$userId')
                : null,
            onChat: () {
              // Navigate to chat with this user
              final conversationId = match['conversationId'];
              if (conversationId != null) {
                context.go('/chat/$conversationId');
              }
            },
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.name,
    this.age,
    this.location,
    this.picture,
    this.isVerified = false,
    required this.matchedAt,
    this.onViewProfile,
    required this.onChat,
  });

  final String name;
  final String? age;
  final String? location;
  final String? picture;
  final bool isVerified;
  final String matchedAt;
  final VoidCallback? onViewProfile;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onChat,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar - tap to view profile
              GestureDetector(
                onTap: onViewProfile,
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  backgroundImage: picture != null
                      ? CachedNetworkImageProvider(picture!)
                      : null,
                  child: picture == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            age != null ? '$name, $age' : name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    if (location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            location!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      matchedAt,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Chat button
              ElevatedButton(
                onPressed: onChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(90, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Écrire'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
