import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/profile_prompts_section.dart';
import '../widgets/relationship_intention_selector.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService();
  final _bioController = TextEditingController();

  UserProfile? _userProfile;
  List<ProfilePhoto> _photos = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _error;

  // Editable fields
  String? _displayName;
  String? _location;
  String? _bio;
  String? _denomination;
  String? _kashrut;
  String? _shabbatObservance;
  String? _relationshipIntention;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Load user profile
    final userResponse = await _apiService.getCurrentUser();

    if (userResponse.success && userResponse.data != null) {
      final user = userResponse.data!;
      final profile = user.profile;

      setState(() {
        _userProfile = user;
        _displayName = profile?.displayName ?? user.name;
        _location = profile?.location;
        _bio = profile?.bio;
        _denomination = profile?.denomination;
        _kashrut = profile?.kashrut;
        _shabbatObservance = profile?.shabbatObservance;
        _relationshipIntention = profile?.relationshipIntention;
        _bioController.text = _bio ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = userResponse.error ?? 'Erreur de chargement';
        _isLoading = false;
      });
    }

    // Load photos separately (don't block if it fails - endpoints may not be deployed yet)
    try {
      final photosResponse = await _apiService.getProfilePhotos();
      if (photosResponse.success && photosResponse.data != null) {
        setState(() {
          _photos = photosResponse.data!;
        });
      }
    } catch (e) {
      // Silently ignore - photos feature may not be available yet
      debugPrint('Photos API not available: $e');
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final response = await _apiService.updateProfile({
      'displayName': _displayName,
      'location': _location,
      'bio': _bioController.text,
      'denomination': _denomination,
      'kashrutLevel': _kashrut,
      'shabbatObservance': _shabbatObservance,
      'relationshipIntention': _relationshipIntention,
    });

    setState(() => _isSaving = false);

    if (response.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis a jour !'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Erreur de sauvegarde'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final response = await _apiService.uploadProfilePhoto(
        image.path,
        isPrimary: _photos.isEmpty,
      );

      setState(() => _isUploadingPhoto = false);

      if (response.success && response.data != null) {
        setState(() {
          _photos.add(response.data!);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo ajoutee !'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Erreur d\'upload'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload non disponible pour le moment'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _deletePhoto(ProfilePhoto photo) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.trash2,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Supprimer la photo ?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cette action est irreversible',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiService.deleteProfilePhoto(photo.id);

      if (response.success) {
        setState(() {
          _photos.removeWhere((p) => p.id == photo.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo supprimee')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Erreur de suppression'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service temporairement indisponible'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _setAsPrimary(ProfilePhoto photo) async {
    try {
      final response = await _apiService.setPhotoPrimary(photo.id);

      if (response.success && response.data != null) {
        setState(() {
          _photos = response.data!;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo principale mise a jour')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service temporairement indisponible'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showEditSheet(String title, String? currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Text field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Entrez votre ${title.toLowerCase()}',
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onSave(controller.text);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSelectionSheet(String title, String? currentValue, List<String> options, Function(String) onSave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Options
              ...options.map((option) {
                final isSelected = currentValue == option;
                return InkWell(
                  onTap: () {
                    onSave(option);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? AppColors.primary : null,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Photos section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isUploadingPhoto)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Maintiens appuye pour definir comme principale',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        _buildPhotosGrid(),

        const SizedBox(height: 24),

        // Bio
        const Text(
          'A propos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bioController,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Parle de toi...',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 24),

        // Profile Prompts
        const ProfilePromptsSection(),

        const SizedBox(height: 24),

        // Relationship Intention
        RelationshipIntentionSelector(
          selectedIntention: _relationshipIntention,
          onChanged: (value) => setState(() => _relationshipIntention = value),
        ),

        const SizedBox(height: 24),

        // Basic info
        const Text(
          'Informations de base',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _EditField(
          label: 'Prenom',
          value: _displayName ?? 'Non renseigne',
          onTap: () => _showEditSheet('Prenom', _displayName, (v) => setState(() => _displayName = v)),
        ),
        _EditField(
          label: 'Ville',
          value: _location ?? 'Non renseigne',
          onTap: () => _showEditSheet('Ville', _location, (v) => setState(() => _location = v)),
        ),

        const SizedBox(height: 24),

        // Jewish preferences
        const Text(
          'Ma pratique',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _EditField(
          label: 'Denomination',
          value: _denomination ?? 'Non renseigne',
          onTap: () => _showSelectionSheet(
            'Denomination',
            _denomination,
            ['Laique', 'Traditionaliste', 'Massorti', 'Modern Orthodox', 'Orthodox', 'Habad', 'Autre'],
            (v) => setState(() => _denomination = v),
          ),
        ),
        _EditField(
          label: 'Kashrout',
          value: _kashrut ?? 'Non renseigne',
          onTap: () => _showSelectionSheet(
            'Kashrout',
            _kashrut,
            ['Non', 'A la maison', 'Strict', 'Glatt'],
            (v) => setState(() => _kashrut = v),
          ),
        ),
        _EditField(
          label: 'Shabbat',
          value: _shabbatObservance ?? 'Non renseigne',
          onTap: () => _showSelectionSheet(
            'Shabbat',
            _shabbatObservance,
            ['Non observant', 'Partiellement', 'Observant', 'Tres observant'],
            (v) => setState(() => _shabbatObservance = v),
          ),
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPhotosGrid() {
    // Get user's SSO picture as fallback
    final ssoPicture = _userProfile?.picture;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(6, (index) {
        // First show uploaded photos, then SSO picture if no photos, then empty slots
        ProfilePhoto? photo;
        String? fallbackUrl;
        bool isFromPhotos = false;

        if (index < _photos.length) {
          photo = _photos[index];
          isFromPhotos = true;
        } else if (index == 0 && _photos.isEmpty && ssoPicture != null) {
          fallbackUrl = ssoPicture;
        }

        final hasPhoto = photo != null || fallbackUrl != null;
        final photoUrl = photo?.url ?? fallbackUrl;
        final isPrimary = photo?.isPrimary ?? (index == 0 && _photos.isEmpty);

        return _PhotoSlot(
          photoUrl: photoUrl,
          isPrimary: isPrimary,
          onTap: hasPhoto ? null : _pickAndUploadPhoto,
          onRemove: isFromPhotos ? () => _deletePhoto(photo!) : null,
          onLongPress: isFromPhotos && !photo!.isPrimary
              ? () => _setAsPrimary(photo!)
              : null,
        );
      }),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    this.photoUrl,
    this.isPrimary = false,
    this.onTap,
    this.onRemove,
    this.onLongPress,
  });

  final String? photoUrl;
  final bool isPrimary;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: hasPhoto
              ? AppColors.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? Border.all(color: AppColors.accentGold, width: 3)
              : null,
        ),
        child: hasPhoto
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(isPrimary ? 9 : 12),
                    child: CachedNetworkImage(
                      imageUrl: photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          LucideIcons.user,
                          color: Colors.white54,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  if (onRemove != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (isPrimary)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Principal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : const Center(
                child: Icon(
                  LucideIcons.imagePlus,
                  color: Colors.grey,
                  size: 32,
                ),
              ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: const Icon(LucideIcons.chevronRight),
      onTap: onTap,
    );
  }
}
