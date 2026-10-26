import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/dev/dev_login.dart';
import '../../../../core/di/providers/service_providers.dart';
import '../../../../core/layout/fold_aware_split.dart';
import '../../../../core/links/public_links.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/session_end.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/l10n/open_public_link.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/auth_failure_text.dart';
import '../l10n/linked_text.dart';
import '../widgets/auth_button_spinner.dart';
import '../widgets/auth_error_banner.dart';

/// Les deux façons de se connecter, pour savoir quel bouton affiche
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

  /// Ouvre les Conditions / la Confidentialité. Sans valeur, les liens
  /// ouvrent les pages publiques de mazl.app hors de l'application.
  final VoidCallback? onOpenTerms;
  final VoidCallback? onOpenPrivacy;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  _SignInMethod? _activeMethod;
  String Function(AppLocalizations l10n)? _error;

  /// Set when the app ended the last session by itself: the screen says why.
  late final SessionEndReason? _endedBecause;

  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => (widget.onOpenTerms ?? _openTerms)();
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => (widget.onOpenPrivacy ?? _openPrivacy)();

  void _openTerms() => openPublicLink(context, ref, PublicLinks.terms);
  void _openPrivacy() => openPublicLink(context, ref, PublicLinks.privacy);

  @override
  void initState() {
    super.initState();
    _endedBecause = ref.read(sessionEndReasonReaderProvider)();
  }

  String? _sessionNotice(AppLocalizations l10n) => switch (_endedBecause) {
    SessionEndReason.expired => l10n.errorSessionExpired,
    SessionEndReason.accountDisabled => l10n.authErrorAccountDisabled(
      PublicLinks.help.path,
    ),
    null => null,
  };

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
          _error = (l10n) =>
              authFailureText(l10n, failure, unknown: l10n.authErrorGeneric);
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
          _error = (l10n) =>
              authFailureText(l10n, failure, unknown: l10n.authErrorGeneric);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FoldAwareSplit(
          // Half open, the brand is read on one side of the fold...
          lead: const SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: _Hero(),
          ),
          // ...and what is touched on the other.
          action: Builder(
            builder: (context) => FoldAwareSplit.axisOf(context) == null
                ? _buildFlatPage()
                : _buildTouchPane(),
          ),
        ),
      ),
    );
  }

  /// The whole screen when nothing folds it: brand on top, buttons below.
  Widget _buildFlatPage() => LayoutBuilder(
    builder: (context, constraints) => _isShortLandscape(constraints)
        // Low and wide (the foldable iPhone standing like a tent): the brand
        // on one side, the buttons on the other, all of them in view.
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 24, 12, 24),
                  child: _Hero(),
                ),
              ),
              Expanded(child: _buildTouchPane()),
            ],
          )
        : SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [const _Hero(), _buildBottom(context)],
                ),
              ),
            ),
          ),
  );

  static bool _isShortLandscape(BoxConstraints constraints) =>
      constraints.maxWidth > constraints.maxHeight &&
      constraints.maxHeight < 560;

  /// Buttons and legal links, alone: the half of the screen the member touches.
  Widget _buildTouchPane() => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_buildBottom(context)],
          ),
        ),
      ),
    ),
  );

  Widget _buildBottom(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_error != null)
        AuthErrorBanner(message: _error!(context.l10n))
      else if (_sessionNotice(context.l10n) case final notice?)
        AuthErrorBanner(message: notice),
      _buildActions(),
      const SizedBox(height: 20),
      _buildLegal(context),
    ],
  );

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showApple) ...[
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleAppleSignIn,
            icon: _activeMethod == _SignInMethod.apple
                ? const AuthButtonSpinner()
                : const Icon(LucideIcons.apple, size: 20),
            label: Text(context.l10n.authLoginApple),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          onPressed: _isLoading ? null : _handleGoogleSignIn,
          child: _activeMethod == _SignInMethod.google
              ? const AuthButtonSpinner()
              : Text(context.l10n.authLoginGoogle),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => context.push(RoutePaths.reviewLogin),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          child: Text(context.l10n.authLoginReviewLink),
        ),
        if (kDevLoginAvailable) ...[
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _isLoading ? null : _handleDemoSignIn,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            icon: const Icon(LucideIcons.flaskConical, size: 16),
            label: Text(context.l10n.authLoginDev),
          ),
        ],
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
