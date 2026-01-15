import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers/service_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/revenuecat_service.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  UserProfile? _userProfile;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final response = await _apiService.getCurrentUser();
    if (response.success && response.data != null && mounted) {
      setState(() {
        _userProfile = response.data;
      });
    }
  }

  Future<void> _handleShowPaywall() async {
    setState(() => _isLoading = true);
    try {
      await RevenueCatService().showPaywall();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleShowCustomerCenter() async {
    try {
      await RevenueCatService().showCustomerCenter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _handleRestorePurchases() async {
    setState(() => _isLoading = true);
    try {
      await RevenueCatService().restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achats restaures avec succes!')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se deconnecter'),
        content: const Text('Es-tu sur de vouloir te deconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (mounted) {
        context.go(RoutePaths.login);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irreversible. Toutes tes donnees seront supprimees.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = ref.read(authServiceProvider);
      await authService.deleteAccount();
      if (mounted) {
        context.go(RoutePaths.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final revenueCat = RevenueCatService();
    final isMazlPro = revenueCat.isMazlPro;
    final subscriptionStatus = revenueCat.subscriptionStatusText;
    final currentUser = ref.watch(currentUserProvider);

    // Use profile data from API if available
    final profile = _userProfile?.profile;
    final userEmail = _userProfile?.email ?? currentUser?.email ?? 'Non connecte';
    final userName = _userProfile?.name ?? currentUser?.displayName ?? 'Utilisateur';
    final userPicture = _userProfile?.picture ?? currentUser?.photoUrl;
    final userLocation = profile?.location ?? 'Non defini';
    final distanceMax = profile?.distanceMax?.toString() ?? '50';
    final ageMin = profile?.ageMin?.toString() ?? '18';
    final ageMax = profile?.ageMax?.toString() ?? '99';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parametres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              // User header with photo
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      backgroundImage: userPicture != null
                          ? CachedNetworkImageProvider(userPicture)
                          : null,
                      child: userPicture == null
                          ? Icon(Icons.person, size: 40, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Account section
              _SectionHeader(title: 'Compte'),
              _SettingTile(
                icon: Icons.person,
                title: 'Informations personnelles',
                onTap: () {},
              ),
              _SettingTile(
                icon: Icons.email,
                title: 'Email',
                subtitle: userEmail,
                onTap: () {},
              ),
              _SettingTile(
                icon: Icons.phone,
                title: 'Telephone',
                subtitle: 'Non verifie',
                onTap: () {},
              ),

              // Discovery section
              _SectionHeader(title: 'Decouverte'),
              _SettingTile(
                icon: Icons.location_on,
                title: 'Localisation',
                subtitle: userLocation,
                onTap: () {},
              ),
              _SettingTile(
                icon: Icons.explore,
                title: 'Distance maximale',
                subtitle: '$distanceMax km',
                onTap: () {},
              ),
              _SettingTile(
                icon: Icons.people,
                title: 'Tranche d\'age',
                subtitle: '$ageMin - $ageMax ans',
                onTap: () {},
              ),

              // Jewish settings
              _SectionHeader(title: 'Parametres juifs'),
              _SettingTile(
                icon: Icons.nights_stay,
                iconColor: AppColors.accentGold,
                title: 'Mode Shabbat',
                subtitle: 'Active - Pause automatique',
                onTap: () => context.go(RoutePaths.shabbatMode),
              ),
              _SettingTile(
                icon: Icons.event,
                title: 'Alertes fetes',
                subtitle: 'Notifications avant les fetes',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),

              // Notifications
              _SectionHeader(title: 'Notifications'),
              _SettingTile(
                icon: Icons.favorite,
                title: 'Nouveaux matchs',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),
              _SettingTile(
                icon: Icons.chat,
                title: 'Messages',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),
              _SettingTile(
                icon: Icons.star,
                title: 'Super Likes',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),

              // Premium / Subscription
              _SectionHeader(title: 'Abonnement'),
              if (isMazlPro) ...[
                // User is subscribed
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.premiumGradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mazl Pro',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  subscriptionStatus,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Actif',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _handleShowCustomerCenter,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          child: const Text('Gerer mon abonnement'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // User is not subscribed - show upgrade card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.premiumGradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Passe a Mazl Pro',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Likes illimites, voir qui t\'aime, boost',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleShowPaywall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.accentGold,
                          minimumSize: const Size(80, 36),
                        ),
                        child: const Text('Voir'),
                      ),
                    ],
                  ),
                ),
              ],
              _SettingTile(
                icon: Icons.refresh,
                title: 'Restaurer les achats',
                onTap: _handleRestorePurchases,
              ),

              // About
              _SectionHeader(title: 'A propos'),
              _SettingTile(
                icon: Icons.help,
                title: 'Aide & Support',
                onTap: () {},
              ),
              _SettingTile(
                icon: Icons.description,
                title: 'Conditions d\'utilisation',
                onTap: () {},
              ),
              _SettingTile(
                icon: Icons.privacy_tip,
                title: 'Politique de confidentialite',
                onTap: () {},
              ),
              _SettingTile(
                icon: Icons.info,
                title: 'Version',
                subtitle: '1.0.0',
                onTap: () {},
              ),

              // Logout
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: _handleLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Se deconnecter'),
                ),
              ),

              const SizedBox(height: 8),

              // Delete account
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: _handleDeleteAccount,
                  child: const Text(
                    'Supprimer mon compte',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
