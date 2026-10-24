import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/dev/dev_login.dart';
import '../../../../core/di/providers/service_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/auth_failure_text.dart';
import '../l10n/linked_text.dart';
import 'email_auth_screen.dart';

/// Les trois façons de se connecter, pour savoir quel bouton affiche
/// l'indicateur de chargement.
enum _SignInMethod { apple, google }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.showApple,
    this.onOpenTerms,
    this.onOpenPrivacy,
  });

  /// Connexion avec Apple : proposée sur iOS uniquement quand non précisé.
  final bool? showApple;

  /// Ouvre les Conditions / la Confidentialité. Aucune page n'existe encore
  /// dans l'application : tant que rien n'est branché, le lien ne fait rien.
  final VoidCallback? onOpenTerms;
  final VoidCallback? onOpenPrivacy;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  _SignInMethod? _activeMethod;
  String Function(AppLocalizations l10n)? _error;

  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => widget.onOpenTerms?.call();
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => widget.onOpenPrivacy?.call();

  bool get _showApple => widget.showApple ?? Platform.isIOS;

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _activeMethod = _SignInMethod.google;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();

      if (!mounted) return;

      if (result.success) {
        // The router guard sends a member with an incomplete profile to the setup.
        context.go(RoutePaths.discover);
      } else {
        final failure = result.failure;
        setState(() {
          _error = (l10n) => authFailureText(
            l10n,
            failure,
            unknown: l10n.authErrorGeneric,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = (l10n) => l10n.authErrorGeneric;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _activeMethod = null;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _activeMethod = _SignInMethod.apple;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithApple();

      if (!mounted) return;

      if (result.success) {
        // The router guard sends a member with an incomplete profile to the setup.
        context.go(RoutePaths.discover);
      } else {
        final failure = result.failure;
        setState(() {
          _error = (l10n) => authFailureText(
            l10n,
            failure,
            unknown: l10n.authErrorGeneric,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = (l10n) => l10n.authErrorGeneric;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _activeMethod = null;
        });
      }
    }
  }

  /// Développement local seulement : session fictive, aucun appel au serveur.
  Future<void> _handleDemoSignIn() async {
    if (!kDevLoginAvailable) return;
    final result = await ref.read(authServiceProvider).signInAsDemo();
    if (!mounted || !result.success) return;
    context.go(RoutePaths.discover);
  }

  void _navigateToEmailAuth({required bool isLogin}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailAuthScreen(isLogin: isLogin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Hero(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null)
                          _ErrorBanner(message: _error!(context.l10n)),
                        _buildActions(),
                        const SizedBox(height: 20),
                        _buildLegal(context),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showApple) ...[
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleAppleSignIn,
            icon: _activeMethod == _SignInMethod.apple
                ? const _ButtonSpinner()
                : const Icon(LucideIcons.apple, size: 20),
            label: Text(context.l10n.authLoginApple),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          onPressed: _isLoading ? null : _handleGoogleSignIn,
          child: _activeMethod == _SignInMethod.google
              ? const _ButtonSpinner()
              : Text(context.l10n.authLoginGoogle),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => _navigateToEmailAuth(isLogin: true),
          child: Text(context.l10n.authLoginEmail),
        ),
        if (kDevLoginAvailable)
          TextButton.icon(
            onPressed: _isLoading ? null : _handleDemoSignIn,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            icon: const Icon(LucideIcons.flaskConical, size: 16),
            label: Text(context.l10n.authLoginDev),
          ),
      ],
    );
  }

  Widget _buildLegal(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = TextStyle(
      fontFamily: AppTypography.family,
      fontSize: 12,
      height: 1.5,
      color: scheme.onSurfaceVariant,
    );
    final link = base.copyWith(
      color: scheme.onSurface,
      decoration: TextDecoration.underline,
      decorationColor: scheme.onSurface,
    );
    final l10n = context.l10n;
    final terms = l10n.authLegalTermsLink;
    final privacy = l10n.authLegalPrivacyLink;
    return Text.rich(
      TextSpan(
        style: base,
        children: spansWithLinks(l10n.authLegal(terms, privacy), [
          (label: terms, style: link, recognizer: _termsTap),
          (label: privacy, style: link, recognizer: _privacyTap),
        ]),
      ),
    );
  }
}

/// Signature de l'écran : étiquette, mot-symbole géant et promesse en une phrase.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(context.l10n.authLoginEyebrow),
        const SizedBox(height: 16),
        const MazlWordmark(size: 88),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            context.l10n.authLoginTagline,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.circleAlert, size: 18, color: scheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.error,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: IconTheme.of(context).color,
      ),
    );
  }
}
