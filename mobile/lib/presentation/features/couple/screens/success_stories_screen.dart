import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/api_service.dart' hide ProfilePhoto;
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/mazl_sheet.dart';

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
          likesCount: story.isLikedByMe
              ? story.likesCount - 1
              : story.likesCount + 1,
          isLikedByMe: !story.isLikedByMe,
          isApproved: story.isApproved,
        );
      });
    }

    await _apiService.likeSuccessStory(story.id);
  }

  void _shareStory(SuccessStory story) {
    Share.share(
      '${story.couple1Name} et ${story.couple2Name} se sont rencontrés sur MAZL. Leur histoire : ${story.story.substring(0, story.story.length.clamp(0, 100))}...',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histoires de couples'),
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.circleAlert,
            size: 32,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadStories, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_stories.isEmpty) {
      return _buildEmptyState();
    }

    final bottom = MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      onRefresh: _loadStories,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(24, 8, 24, bottom + 16),
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.heart, size: 32, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Pas encore d\'histoires de couples',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Les premières histoires d\'amour MAZL seront bientôt partagées.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
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
    final scheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMMM yyyy', 'fr_FR');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 48,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: _buildPhotoCircle(
                          context,
                          story.couple1PhotoUrl,
                          0,
                        ),
                      ),
                      Positioned(
                        left: 28,
                        child: _buildPhotoCircle(
                          context,
                          story.couple2PhotoUrl,
                          1,
                        ),
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${story.statusLabel} · depuis ${dateFormat.format(story.matchDate)}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
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
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        story.photoUrls[index],
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 150,
                          height: 200,
                          color: AppColors
                              .photoTints[index % AppColors.photoTints.length],
                          child: const Icon(
                            LucideIcons.image,
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              story.story,
              style: const TextStyle(fontSize: 14, height: 1.5),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _ActionPill(
                  icon: LucideIcons.heart,
                  label: '${story.likesCount}',
                  highlighted: story.isLikedByMe,
                  onTap: onLike,
                ),
                const SizedBox(width: 8),
                _ActionPill(
                  icon: LucideIcons.share2,
                  label: 'Partager',
                  onTap: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCircle(BuildContext context, String? photoUrl, int seed) {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: ProfilePhoto(url: photoUrl, seed: seed, radius: 22, iconSize: 20),
    );
  }
}

/// Bouton en pilule d'une carte d'histoire : fond blanc, contour filet ; le
/// « j'aime » actif passe à l'accent.
class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = highlighted ? scheme.primary : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: highlighted ? scheme.primary : scheme.outline,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for submitting a success story
class SubmitSuccessStoryDialog extends StatefulWidget {
  const SubmitSuccessStoryDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showMazlSheet<bool>(
      context,
      isScrollControlled: true,
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
  final List<String> _photoUrls = [];
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
          content: Text('Votre histoire doit faire au moins 100 caractères'),
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
            content: Text(
              'Merci. Votre histoire sera publiée après validation.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Erreur lors de l\'envoi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Partagez votre histoire', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Inspirez la communauté MAZL en partageant votre histoire.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          const SectionLabel('Votre statut'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildStatusChip('dating', 'En couple'),
              _buildStatusChip('engaged', 'Fiancés'),
              _buildStatusChip('married', 'Mariés'),
            ],
          ),
          const SizedBox(height: 20),

          const SectionLabel('Votre histoire (min. 100 caractères)'),
          const SizedBox(height: 8),
          TextField(
            controller: _storyController,
            maxLines: 5,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText:
                  'Comment vous êtes-vous rencontrés ? Qu\'est-ce qui vous a plu chez l\'autre ?…',
            ),
          ),
          const SizedBox(height: 20),

          const SectionLabel('Photos (optionnel)'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outline),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.camera,
                  color: scheme.onSurfaceVariant,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez des photos de couple',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.surface,
                      ),
                    )
                  : const Text('Soumettre notre histoire'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedStatus == value,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = value);
        }
      },
    );
  }
}
