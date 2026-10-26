import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/providers/service_providers.dart';
import '../../../../core/layout/fold_aware_split.dart';
import '../../../../core/router/route_names.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../../core/layout/bar_navigation.dart';
import '../l10n/auth_failure_text.dart';
import '../widgets/auth_button_spinner.dart';
import '../widgets/auth_error_banner.dart';

/// Sign-in with an identifier and a password, for the one account the App
/// Store review uses (docs/launch/REVIEW-LOGIN-CONTRAT.md). Reached by the
/// plain link under the Apple and Google buttons, visible to everyone.
///
/// The password stays in its field: it is sent to the server and never
/// printed, logged or kept.
class ReviewLoginScreen extends ConsumerStatefulWidget {
  const ReviewLoginScreen({super.key});

  @override
  ConsumerState<ReviewLoginScreen> createState() => _ReviewLoginScreenState();
}

class _ReviewLoginScreenState extends ConsumerState<ReviewLoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _showPassword = false;
  String Function(AppLocalizations l10n)? _error;

  bool get _canSubmit =>
      !_isLoading &&
      _username.text.trim().isNotEmpty &&
      _password.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _username.addListener(_changed);
    _password.addListener(_changed);
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.login);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(authServiceProvider)
          .signInWithReviewCredentials(_username.text.trim(), _password.text);
      if (!mounted) return;
      if (result.success) {
        // The router guard sends a member with an incomplete profile to the setup.
        context.go(RoutePaths.discover);
        return;
      }
      final failure = result.failure;
      setState(() {
        _error = (l10n) =>
            authFailureText(l10n, failure, unknown: l10n.authErrorGeneric);
      });
    } catch (_) {
      // Nothing of the exception is shown or logged: it may quote the request.
      if (mounted) {
        setState(() => _error = (l10n) => l10n.authErrorGeneric);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget backButton() => IconButton(
      tooltip: context.l10n.commonBack,
      icon: const DirectionalIcon(LucideIcons.arrowLeft),
      onPressed: _goBack,
    );
    // With a vertical bar (foldable iPhone) the button is at its top.
    final back = BarNavigation(
      buttons: [backButton()],
      inline: Align(
        alignment: AlignmentDirectional.centerStart,
        child: backButton(),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: FoldAwareSplit(
          // Half open, the title is read on one side of the fold...
          lead: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              back,
              const Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: _Header(),
                ),
              ),
            ],
          ),
          // ...and the fields on the other.
          action: Builder(
            builder: (context) {
              final split = FoldAwareSplit.axisOf(context) != null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!split) back,
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!split) ...const [
                            _Header(),
                            SizedBox(height: 32),
                          ],
                          if (_error != null)
                            AuthErrorBanner(message: _error!(context.l10n)),
                          _buildForm(context),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final l10n = context.l10n;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _username,
            enabled: !_isLoading,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            onSubmitted: (_) => _passwordFocus.requestFocus(),
            decoration: InputDecoration(
              labelText: l10n.authReviewUsernameLabel,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            focusNode: _passwordFocus,
            enabled: !_isLoading,
            obscureText: !_showPassword,
            autocorrect: false,
            enableSuggestions: false,
            enableIMEPersonalizedLearning: false,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.authReviewPasswordLabel,
              suffixIcon: IconButton(
                tooltip: _showPassword
                    ? l10n.authReviewHidePassword
                    : l10n.authReviewShowPassword,
                icon: Icon(
                  _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 20,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _canSubmit ? _submit : null,
            child: _isLoading
                ? const AuthButtonSpinner()
                : Text(l10n.authReviewSubmit),
          ),
        ],
      ),
    );
  }
}

/// Title and one sentence: on the page where reading starts when the device
/// is folded, above the fields otherwise.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MazlWordmark(size: 40),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            l10n.authReviewTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.authReviewIntro,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
