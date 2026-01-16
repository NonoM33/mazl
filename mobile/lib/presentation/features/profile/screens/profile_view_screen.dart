import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/providers/service_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileViewScreen extends ConsumerStatefulWidget {
  const ProfileViewScreen({
    super.key,
    this.userId,
    this.isOwnProfile = false,
  });

  final String? userId;
  final bool isOwnProfile;

  @override
  ConsumerState<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends ConsumerState<ProfileViewScreen> {
  UserProfile? _userProfile;
  Profile? _otherProfile;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();
  final PageController _photoController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (widget.isOwnProfile || widget.userId == null) {
      final response = await _apiService.getCurrentUser();
      if (response.success && response.data != null && mounted) {
        setState(() {
          _userProfile = response.data;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } else {
      final userId = int.tryParse(widget.userId!);
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await _apiService.getProfileById(userId);
      if (response.success && response.data != null && mounted) {
        setState(() {
          _otherProfile = response.data;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = widget.isOwnProfile || _otherProfile == null;

    // Extract profile data
    String userName;
    int? userAge;
    String userLocation;
    String? userBio;
    bool isVerified;
    String? verificationLevel;
    String? denomination;
    String? kashrut;
    String? shabbatObservance;
    String? lookingFor;
    String? gender;
    List<String> photos;
    String? fallbackPicture;
    double? distance;

    if (_otherProfile != null) {
      userName = _otherProfile!.displayName ?? 'Utilisateur';
      userAge = _otherProfile!.age;
      userLocation = _otherProfile!.location ?? 'France';
      userBio = _otherProfile!.bio;
      isVerified = _otherProfile!.isVerified;
      verificationLevel = _otherProfile!.verificationLevel;
      denomination = _otherProfile!.denomination;
      kashrut = _otherProfile!.kashrut;
      shabbatObservance = _otherProfile!.shabbatObservance;
      lookingFor = _otherProfile!.lookingFor;
      gender = _otherProfile!.gender;
      photos = _otherProfile!.photos;
      distance = _otherProfile!.distance;
      fallbackPicture = null;
    } else {
      final profile = _userProfile?.profile;
      userName = profile?.displayName ?? _userProfile?.name ?? currentUser?.displayName ?? 'Utilisateur';
      userAge = profile?.age;
      userLocation = profile?.location ?? 'France';
      userBio = profile?.bio;
      isVerified = profile?.isVerified ?? false;
      verificationLevel = profile?.verificationLevel;
      denomination = profile?.denomination;
      kashrut = profile?.kashrut;
      shabbatObservance = profile?.shabbatObservance;
      lookingFor = profile?.lookingFor;
      gender = profile?.gender;
      photos = profile?.photos ?? [];
      fallbackPicture = _userProfile?.picture ?? currentUser?.photoUrl;
      distance = null;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Main scrollable content
                CustomScrollView(
                  slivers: [
                    // Photo gallery header
                    SliverToBoxAdapter(
                      child: _buildPhotoGallery(
                        photos: photos,
                        fallbackPicture: fallbackPicture,
                        userName: userName,
                        isOwnProfile: isOwnProfile,
                      ),
                    ),

                    // Profile content
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        transform: Matrix4.translationValues(0, -24, 0),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name, age, verification
                              _buildNameSection(
                                userName: userName,
                                userAge: userAge,
                                isVerified: isVerified,
                                verificationLevel: verificationLevel,
                              ),

                              const SizedBox(height: 8),

                              // Location and distance
                              _buildLocationSection(
                                location: userLocation,
                                distance: distance,
                              ),

                              const SizedBox(height: 24),

                              // Bio / About section
                              if (userBio != null && userBio.isNotEmpty)
                                _buildSection(
                                  title: 'A propos de moi',
                                  icon: LucideIcons.user,
                                  child: Text(
                                    userBio,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                      height: 1.5,
                                    ),
                                  ),
                                ),

                              // Basic info cards
                              _buildSection(
                                title: 'Informations',
                                icon: LucideIcons.info,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (userAge != null)
                                      _buildInfoChip(
                                        icon: LucideIcons.cake,
                                        label: '$userAge ans',
                                      ),
                                    if (gender != null)
                                      _buildInfoChip(
                                        icon: gender == 'male' ? LucideIcons.user : LucideIcons.user,
                                        label: gender == 'male' ? 'Homme' : 'Femme',
                                      ),
                                    _buildInfoChip(
                                      icon: LucideIcons.mapPin,
                                      label: userLocation,
                                    ),
                                  ],
                                ),
                              ),

                              // Jewish practice section
                              if (denomination != null || kashrut != null || shabbatObservance != null)
                                _buildSection(
                                  title: 'Ma pratique',
                                  icon: LucideIcons.sparkles,
                                  child: Column(
                                    children: [
                                      if (denomination != null)
                                        _buildDetailRow(
                                          icon: LucideIcons.star,
                                          label: 'Courant',
                                          value: denomination,
                                        ),
                                      if (kashrut != null)
                                        _buildDetailRow(
                                          icon: LucideIcons.utensilsCrossed,
                                          label: 'Cacherout',
                                          value: kashrut,
                                        ),
                                      if (shabbatObservance != null)
                                        _buildDetailRow(
                                          icon: LucideIcons.moonStar,
                                          label: 'Shabbat',
                                          value: shabbatObservance,
                                        ),
                                    ],
                                  ),
                                ),

                              // Looking for section
                              if (lookingFor != null && lookingFor.isNotEmpty)
                                _buildSection(
                                  title: 'Ce que je recherche',
                                  icon: LucideIcons.heart,
                                  child: Text(
                                    lookingFor,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                      height: 1.5,
                                    ),
                                  ),
                                ),

                              // Own profile actions
                              if (isOwnProfile) ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),

                                _buildProfileAction(
                                  icon: LucideIcons.pencil,
                                  title: 'Modifier mon profil',
                                  subtitle: 'Photos, bio, informations',
                                  onTap: () => context.go(RoutePaths.editProfile),
                                ),
                                _buildProfileAction(
                                  icon: LucideIcons.sparkles,
                                  title: 'AI Shadchan',
                                  subtitle: 'Suggestions personnalisees',
                                  color: AppColors.accent,
                                  onTap: () => context.go(RoutePaths.aiShadchan),
                                ),
                                _buildProfileAction(
                                  icon: LucideIcons.shieldCheck,
                                  title: 'Verification',
                                  subtitle: isVerified ? 'Profil verifie' : 'Verifier mon profil',
                                  color: AppColors.success,
                                  onTap: () => context.go(RoutePaths.verification),
                                ),
                                _buildProfileAction(
                                  icon: LucideIcons.settings,
                                  title: 'Parametres',
                                  subtitle: 'Compte, notifications, confidentialite',
                                  onTap: () => context.go(RoutePaths.settings),
                                ),
                              ],

                              // Report/Block for other profiles
                              if (!isOwnProfile) ...[
                                const SizedBox(height: 32),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () => _showReportDialog(context),
                                    icon: Icon(LucideIcons.flag, size: 16, color: Colors.grey[500]),
                                    label: Text(
                                      'Signaler ce profil',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: _buildCircleButton(
                    icon: LucideIcons.arrowLeft,
                    onTap: () => context.pop(),
                  ),
                ),

                // More options button (for other profiles)
                if (!isOwnProfile)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 8,
                    child: _buildCircleButton(
                      icon: LucideIcons.moreVertical,
                      onTap: () => _showOptionsMenu(context),
                    ),
                  ),

                // Action buttons for other profiles
                if (!isOwnProfile)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildActionButtons(context),
                  ),
              ],
            ),
    );
  }

  Widget _buildPhotoGallery({
    required List<String> photos,
    required String? fallbackPicture,
    required String userName,
    required bool isOwnProfile,
  }) {
    final displayPhotos = photos.isNotEmpty ? photos : (fallbackPicture != null ? [fallbackPicture] : <String>[]);
    final hasMultiplePhotos = displayPhotos.length > 1;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photos PageView
          if (displayPhotos.isNotEmpty)
            PageView.builder(
              controller: _photoController,
              itemCount: displayPhotos.length,
              onPageChanged: (index) {
                setState(() => _currentPhotoIndex = index);
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: displayPhotos[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildPhotoPlaceholder(userName),
                );
              },
            )
          else
            _buildPhotoPlaceholder(userName),

          // Photo indicators at top
          if (hasMultiplePhotos)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: Row(
                children: List.generate(
                  displayPhotos.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index == _currentPhotoIndex
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Tap zones for photo navigation
          if (hasMultiplePhotos) ...[
            // Left tap zone
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.3,
              child: GestureDetector(
                onTap: () {
                  if (_currentPhotoIndex > 0) {
                    _photoController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Right tap zone
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.3,
              child: GestureDetector(
                onTap: () {
                  if (_currentPhotoIndex < displayPhotos.length - 1) {
                    _photoController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
          ],

          // Gradient at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String userName) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pas de photo',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSection({
    required String userName,
    required int? userAge,
    required bool isVerified,
    required String? verificationLevel,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            userAge != null ? '$userName, $userAge' : userName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.badgeCheck, size: 16, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  verificationLevel == 'verified_plus' ? 'Verifie+' : 'Verifie',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLocationSection({
    required String location,
    required double? distance,
  }) {
    return Row(
      children: [
        Icon(LucideIcons.mapPin, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          location,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
        if (distance != null) ...[
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${distance!.round()} km',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      trailing: Icon(LucideIcons.chevronRight, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          _buildActionButton(
            icon: LucideIcons.x,
            color: AppColors.passRed,
            size: 56,
            onTap: () {
              _sendSwipe('pass');
              context.pop('pass');
            },
          ),

          // Super Like button
          _buildActionButton(
            icon: LucideIcons.star,
            color: AppColors.superLikeBlue,
            size: 48,
            onTap: () {
              _sendSwipe('super_like');
              context.pop('super_like');
            },
          ),

          // Like button
          _buildActionButton(
            icon: LucideIcons.heart,
            color: AppColors.likeGreen,
            size: 56,
            onTap: () {
              _sendSwipe('like');
              context.pop('like');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }

  Future<void> _sendSwipe(String action) async {
    if (_otherProfile == null) return;

    final response = await _apiService.sendSwipe(
      targetUserId: _otherProfile!.userId,
      action: action,
    );

    if (response.success && response.data?['match'] == true && mounted) {
      _showMatchDialog();
    }
  }

  void _showMatchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('It\'s a Match! 🎉'),
        content: Text('Tu as matche avec ${_otherProfile?.displayName ?? 'cette personne'}!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to chat
            },
            child: const Text('Envoyer un message'),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.share2),
              title: const Text('Partager ce profil'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.flag, color: Colors.orange[700]),
              title: Text('Signaler', style: TextStyle(color: Colors.orange[700])),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.userX, color: Colors.red),
              title: const Text('Bloquer', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showBlockDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler ce profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pourquoi souhaitez-vous signaler ce profil ?'),
            const SizedBox(height: 16),
            ...[
              'Photos inappropriees',
              'Comportement inapproprie',
              'Faux profil',
              'Spam ou arnaque',
              'Autre',
            ].map((reason) => ListTile(
              title: Text(reason),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signalement envoye. Merci de nous aider a garder MAZL sur.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquer ce profil'),
        content: Text(
          'Etes-vous sur de vouloir bloquer ${_otherProfile?.displayName ?? 'ce profil'} ? '
          'Vous ne pourrez plus voir son profil et cette personne ne pourra plus vous contacter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil bloque.'),
                ),
              );
            },
            child: const Text('Bloquer'),
          ),
        ],
      ),
    );
  }
}
