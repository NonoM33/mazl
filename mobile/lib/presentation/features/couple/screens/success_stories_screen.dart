import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Screen displaying success stories from MAZL couples
class SuccessStoriesScreen extends StatefulWidget {
  const SuccessStoriesScreen({super.key});

  @override
  State<SuccessStoriesScreen> createState() => _SuccessStoriesScreenState();
}

class _SuccessStoriesScreenState extends State<SuccessStoriesScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<SuccessStory> _stories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreStories();
    }
  }

  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _apiService.getSuccessStories(page: 1);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _stories = result.data!;
          _currentPage = 1;
          _hasMore = result.data!.length >= 10;
        } else {
          _error = result.error;
        }
      });
    }
  }

  Future<void> _loadMoreStories() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    final result = await _apiService.getSuccessStories(page: _currentPage + 1);

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success && result.data != null) {
          _stories.addAll(result.data!);
          _currentPage++;
          _hasMore = result.data!.length >= 10;
        }
      });
    }
  }

  Future<void> _likeStory(SuccessStory story) async {
    // Optimistic update
    final index = _stories.indexOf(story);
    if (index != -1) {
      setState(() {
        _stories[index] = SuccessStory(
          id: story.id,
          couple1Name: story.couple1Name,
          couple2Name: story.couple2Name,
          couple1PhotoUrl: story.couple1PhotoUrl,
          couple2PhotoUrl: story.couple2PhotoUrl,
          story: story.story,
          photoUrls: story.photoUrls,
          status: story.status,
          statusDate: story.statusDate,
          matchDate: story.matchDate,
          submittedAt: story.submittedAt,
          likesCount: story.isLikedByMe ? story.likesCount - 1 : story.likesCount + 1,
          isLikedByMe: !story.isLikedByMe,
          isApproved: story.isApproved,
        );
      });
    }

    await _apiService.likeSuccessStory(story.id);
  }

  void _shareStory(SuccessStory story) {
    Share.share(
      '${story.couple1Name} et ${story.couple2Name} se sont rencontres sur MAZL ! ${story.statusEmoji} Leur histoire: ${story.story.substring(0, story.story.length.clamp(0, 100))}...',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Success Stories'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStories,
            child: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_stories.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadStories,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _stories.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _stories.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _SuccessStoryCard(
            story: _stories[index],
            onLike: () => _likeStory(_stories[index]),
            onShare: () => _shareStory(_stories[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.heart,
              size: 48,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pas encore de success stories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Les premieres histoires d\'amour MAZL seront bientot partagees !',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessStoryCard extends StatelessWidget {
  const _SuccessStoryCard({
    required this.story,
    required this.onLike,
    required this.onShare,
  });

  final SuccessStory story;
  final VoidCallback onLike;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM yyyy', 'fr_FR');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with photos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Couple photos
                SizedBox(
                  width: 70,
                  height: 50,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: _buildPhotoCircle(story.couple1PhotoUrl),
                      ),
                      Positioned(
                        left: 25,
                        child: _buildPhotoCircle(story.couple2PhotoUrl),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${story.couple1Name} & ${story.couple2Name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(story.status),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${story.statusEmoji} ${story.statusLabel}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Depuis ${dateFormat.format(story.matchDate)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Photos carousel (if any)
          if (story.photoUrls.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: story.photoUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        story.photoUrls[index],
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 150,
                          height: 200,
                          color: Colors.grey[200],
                          child: Icon(
                            LucideIcons.image,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Story text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              story.story,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Like button
                InkWell(
                  onTap: onLike,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: story.isLikedByMe
                          ? AppColors.secondary.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          story.isLikedByMe
                              ? LucideIcons.heart
                              : LucideIcons.heart,
                          size: 18,
                          color: story.isLikedByMe
                              ? AppColors.secondary
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${story.likesCount}',
                          style: TextStyle(
                            color: story.isLikedByMe
                                ? AppColors.secondary
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Share button
                InkWell(
                  onTap: onShare,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.share2,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Partager',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCircle(String? photoUrl) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: Icon(LucideIcons.user, color: Colors.grey[400], size: 20),
                ),
              )
            : Container(
                color: Colors.grey[300],
                child: Icon(LucideIcons.user, color: Colors.grey[400], size: 20),
              ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'engaged':
        return const Color(0xFF9B59B6);
      case 'married':
        return AppColors.accentGold;
      default:
        return AppColors.secondary;
    }
  }
}

/// Dialog for submitting a success story
class SubmitSuccessStoryDialog extends StatefulWidget {
  const SubmitSuccessStoryDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const SubmitSuccessStoryDialog(),
    );
  }

  @override
  State<SubmitSuccessStoryDialog> createState() =>
      _SubmitSuccessStoryDialogState();
}

class _SubmitSuccessStoryDialogState extends State<SubmitSuccessStoryDialog> {
  final _storyController = TextEditingController();
  final _apiService = ApiService();
  String _selectedStatus = 'dating';
  DateTime? _statusDate;
  List<String> _photoUrls = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_storyController.text.length < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre histoire doit faire au moins 100 caracteres'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _apiService.submitSuccessStory(
      story: _storyController.text,
      photoUrls: _photoUrls,
      status: _selectedStatus,
      statusDate: _statusDate,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result.success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Merci ! Votre histoire sera publiee apres validation.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Erreur lors de l\'envoi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Row(
              children: [
                Icon(LucideIcons.heart, color: AppColors.secondary),
                SizedBox(width: 8),
                Text(
                  'Partagez votre histoire',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Inspirez la communaute MAZL en partageant votre success story !',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Status selection
            const Text(
              'Votre statut',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildStatusChip('dating', 'En couple', '❤️'),
                _buildStatusChip('engaged', 'Fiances', '💍'),
                _buildStatusChip('married', 'Maries', '👰'),
              ],
            ),
            const SizedBox(height: 20),

            // Story text
            const Text(
              'Votre histoire (min. 100 caracteres)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _storyController,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText:
                    'Comment vous etes-vous rencontres ? Qu\'est-ce qui vous a plu chez l\'autre ?...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Photo upload (placeholder)
            const Text(
              'Photos (optionnel)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(LucideIcons.camera, color: Colors.grey[400], size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez des photos de couple',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Soumettre notre histoire',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String value, String label, String emoji) {
    final isSelected = _selectedStatus == value;

    return ChoiceChip(
      label: Text('$emoji $label'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = value);
        }
      },
      selectedColor: AppColors.secondary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.secondary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
