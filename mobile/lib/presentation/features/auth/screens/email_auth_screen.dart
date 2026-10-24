import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/providers/service_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import '../../../common/widgets/glass_container.dart';
import '../l10n/auth_failure_text.dart';

/// Email authentication screen for login and registration
class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({
    super.key,
    this.isLogin = true,
  });

  final bool isLogin;

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  late bool _isLogin;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String Function(AppLocalizations l10n)? _error;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n.authValidationEmailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return context.l10n.authValidationEmailInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n.authValidationPasswordRequired;
    }
    if (value.length < 8) {
      return context.l10n.authValidationPasswordMin;
    }
    if (!_isLogin) {
      if (!RegExp(r'[A-Z]').hasMatch(value)) {
        return context.l10n.authValidationPasswordUpper;
      }
      if (!RegExp(r'[0-9]').hasMatch(value)) {
        return context.l10n.authValidationPasswordDigit;
      }
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return context.l10n.authValidationPasswordMismatch;
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n.authValidationNameRequired;
    }
    if (value.length < 2) {
      return context.l10n.authValidationNameMin;
    }
    return null;
  }

  double _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.1;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.15;
    return strength.clamp(0, 1);
  }

  Color _getPasswordStrengthColor(double strength) {
    if (strength < 0.3) return Colors.red;
    if (strength < 0.6) return Colors.orange;
    if (strength < 0.8) return Colors.yellow;
    return Colors.green;
  }

  String _getPasswordStrengthText(double strength) {
    final l10n = context.l10n;
    if (strength < 0.3) return l10n.authStrengthWeak;
    if (strength < 0.6) return l10n.authStrengthFair;
    if (strength < 0.8) return l10n.authStrengthGood;
    return l10n.authStrengthExcellent;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLogin && !_acceptedTerms) {
      setState(() {
        _error = (l10n) => l10n.authErrorTermsRequired;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      if (_isLogin) {
        final result = await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;

        if (result.success) {
          context.go(RoutePaths.discover);
        } else {
          final failure = result.failure;
          setState(() {
            _error = (l10n) => authFailureText(
              l10n,
              failure,
              unknown: l10n.authErrorLoginFailed,
            );
          });
        }
      } else {
        final result = await authService.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

        if (!mounted) return;

        if (result.success) {
          // Show email verification dialog
          _showEmailVerificationDialog();
        } else {
          final failure = result.failure;
          setState(() {
            _error = (l10n) => authFailureText(
              l10n,
              failure,
              unknown: l10n.authErrorRegisterFailed,
            );
          });
        }
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
        });
      }
    }
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.mail, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Text(context.l10n.authVerifyTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.authVerifySent,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _emailController.text,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.authVerifyInstruction,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Switch to login mode
              setState(() {
                _isLogin = true;
                _passwordController.clear();
              });
            },
            child: Text(context.l10n.authVerifyOk),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final forgotEmailController = TextEditingController(text: _emailController.text);
    bool isLoading = false;
    String? message;
    bool isSuccess = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(LucideIcons.keyRound, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(context.l10n.authForgotTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSuccess) ...[
                Text(
                  context.l10n.authForgotInstruction,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: forgotEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: context.l10n.authFieldEmail,
                    prefixIcon: const Icon(LucideIcons.mail),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              if (message != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? AppColors.success.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSuccess ? LucideIcons.check : LucideIcons.alertCircle,
                        color: isSuccess ? AppColors.success : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message!,
                          style: TextStyle(
                            color: isSuccess ? AppColors.success : Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isSuccess ? context.l10n.commonClose : context.l10n.commonCancel,
              ),
            ),
            if (!isSuccess)
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (forgotEmailController.text.isEmpty) {
                          setDialogState(() {
                            message = context.l10n.authValidationEmailRequired;
                            isSuccess = false;
                          });
                          return;
                        }

                        setDialogState(() => isLoading = true);

                        final authService = ref.read(authServiceProvider);
                        final result = await authService.sendPasswordResetEmail(
                          forgotEmailController.text.trim(),
                        );

                        setDialogState(() {
                          isLoading = false;
                          if (result.success) {
                            isSuccess = true;
                            message = context.l10n.authForgotSent;
                          } else {
                            message = authFailureText(
                              context.l10n,
                              result.failure,
                              unknown: context.l10n.authErrorGeneric,
                            );
                          }
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(context.l10n.authForgotSend),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passwordStrength = _getPasswordStrength(_passwordController.text);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    tooltip: context.l10n.commonBack,
                    onPressed: () => Navigator.pop(context),
                    icon: const DirectionalIcon(
                      LucideIcons.arrowLeft,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  _isLogin
                      ? context.l10n.authEmailTitleLogin
                      : context.l10n.authEmailTitleRegister,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn().slideY(begin: 0.3, end: 0),

                const SizedBox(height: 8),

                Text(
                  _isLogin
                      ? context.l10n.authEmailSubtitleLogin
                      : context.l10n.authEmailSubtitleRegister,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ).animate(delay: 100.ms).fadeIn(),

                const SizedBox(height: 32),

                // Error message
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!(context.l10n),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().shake(),

                // Form
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  opacity: 0.15,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Name field (registration only)
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              label: context.l10n.authFieldName,
                              icon: LucideIcons.user,
                            ),
                            validator: _validateName,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            label: context.l10n.authFieldEmail,
                            icon: LucideIcons.mail,
                          ),
                          validator: _validateEmail,
                        ),

                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (_) => setState(() {}),
                          decoration: _inputDecoration(
                            label: context.l10n.authFieldPassword,
                            icon: LucideIcons.lock,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: _validatePassword,
                        ),

                        // Password strength indicator (registration only)
                        if (!_isLogin && _passwordController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: passwordStrength,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation(
                                      _getPasswordStrengthColor(passwordStrength),
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _getPasswordStrengthText(passwordStrength),
                                style: TextStyle(
                                  color: _getPasswordStrengthColor(passwordStrength),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Confirm password field (registration only)
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              label: context.l10n.authFieldPasswordConfirm,
                              icon: LucideIcons.lock,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? LucideIcons.eye
                                      : LucideIcons.eyeOff,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: _validateConfirmPassword,
                          ),
                          const SizedBox(height: 16),

                          // Terms checkbox
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _acceptedTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptedTerms = value ?? false;
                                    });
                                  },
                                  fillColor: WidgetStateProperty.resolveWith(
                                    (states) => states.contains(WidgetState.selected)
                                        ? AppColors.secondary
                                        : Colors.transparent,
                                  ),
                                  side: const BorderSide(color: Colors.white70),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.l10n.authTermsCheckbox,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Forgot password (login only)
                        if (_isLogin) ...[
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: Text(
                                context.l10n.authForgotLink,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                                    ),
                                  )
                                : Text(
                                    _isLogin
                                        ? context.l10n.authSubmitLogin
                                        : context.l10n.authSubmitRegister,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Toggle login/register. A Wrap, not a Row: the two
                        // pieces share a line when they fit and stack when
                        // they do not (360 px wide, the line was cut off).
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? context.l10n.authToggleNoAccount
                                  : context.l10n.authToggleHaveAccount,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _error = null;
                                  _formKey.currentState?.reset();
                                });
                              },
                              child: Text(
                                _isLogin
                                    ? context.l10n.authToggleCreate
                                    : context.l10n.authToggleSignIn,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.7)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      errorStyle: const TextStyle(color: Colors.orangeAccent),
    );
  }
}
