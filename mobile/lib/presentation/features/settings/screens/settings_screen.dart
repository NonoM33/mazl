import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/providers/service_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/revenuecat_service.dart';
import '../../../../core/services/couple_service.dart';
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
    final result = await context.push<bool>(RoutePaths.premium);
    if (result == true && mounted) {
      setState(() {}); // Refresh UI
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

  Widget _buildCoupleModeCard(BuildContext context) {
    final coupleService = CoupleService();
    final isCoupleModeEnabled = coupleService.isCoupleModeEnabled;
    final coupleData = coupleService.coupleData;

    if (isCoupleModeEnabled && coupleData != null) {
      // Show couple mode active card
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.heartHandshake,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mode Couple Actif',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Avec ${coupleData.partnerName ?? 'ton/ta partenaire'}',
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
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${coupleData.daysTogether} jours',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go(RoutePaths.coupleDashboard),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    child: const Text('Dashboard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go(RoutePaths.jewishCalendar),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    child: const Text('Calendrier'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Show activate couple mode card
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.heartHandshake,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu as trouve l\'amour ?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Active le mode couple pour des features exclusives',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.go(RoutePaths.coupleSetup),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 36),
            ),
            child: const Text('Activer'),
          ),
        ],
      ),
    );
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
          icon: const Icon(LucideIcons.arrowLeft),
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
                          ? Icon(LucideIcons.user, size: 40, color: AppColors.primary)
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
                icon: LucideIcons.userCircle,
                title: 'Informations personnelles',
                onTap: () {},
              ),
              _SettingTile(
                icon: LucideIcons.mail,
                title: 'Email',
                subtitle: userEmail,
                onTap: () {},
              ),
              _SettingTile(
                icon: LucideIcons.phone,
                title: 'Telephone',
                subtitle: 'Non verifie',
                onTap: () {},
              ),

              // Discovery section
              _SectionHeader(title: 'Decouverte'),
              _SettingTile(
                icon: LucideIcons.mapPin,
                title: 'Localisation',
                subtitle: userLocation,
                onTap: () {},
              ),
              _SettingTile(
                icon: LucideIcons.radar,
                title: 'Distance maximale',
                subtitle: '$distanceMax km',
                onTap: () {},
              ),
              _SettingTile(
                icon: LucideIcons.users,
                title: 'Tranche d\'age',
                subtitle: '$ageMin - $ageMax ans',
                onTap: () {},
              ),

              // Jewish settings
              _SectionHeader(title: 'Parametres juifs'),
              _SettingTile(
                icon: LucideIcons.moonStar,
                iconColor: AppColors.accentGold,
                title: 'Mode Shabbat',
                subtitle: 'Active - Pause automatique',
                onTap: () => context.go(RoutePaths.shabbatMode),
              ),
              _SettingTile(
                icon: LucideIcons.calendarHeart,
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
                icon: LucideIcons.heartHandshake,
                title: 'Nouveaux matchs',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),
              _SettingTile(
                icon: LucideIcons.messageCircle,
                title: 'Messages',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),
              _SettingTile(
                icon: LucideIcons.star,
                title: 'Super Likes',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),

              // Couple Mode Section
              _SectionHeader(title: 'Mode Couple'),
              _buildCoupleModeCard(context),

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
                          const Icon(LucideIcons.crown, color: Colors.white),
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
                      const Icon(LucideIcons.crown, color: Colors.white),
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
                        onPressed: _handleShowPaywall,
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
                icon: LucideIcons.refreshCw,
                title: 'Restaurer les achats',
                onTap: _handleRestorePurchases,
              ),

              // About
              _SectionHeader(title: 'A propos'),
              _SettingTile(
                icon: LucideIcons.helpCircle,
                title: 'Aide & Support',
                onTap: () {},
              ),
              _SettingTile(
                icon: LucideIcons.fileText,
                title: 'Conditions d\'utilisation',
                onTap: () {},
              ),
              _SettingTile(
                icon: LucideIcons.shield,
                title: 'Politique de confidentialite',
                onTap: () {},
              ),
              _SettingTile(
                icon: LucideIcons.info,
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
      trailing: trailing ?? const Icon(LucideIcons.chevronRight),
      onTap: onTap,
    );
  }
}
