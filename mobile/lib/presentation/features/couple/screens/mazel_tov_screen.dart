import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Beautiful celebration screen shown when couple mode is activated
class MazelTovScreen extends StatefulWidget {
  const MazelTovScreen({
    super.key,
    required this.partnerName,
    this.partnerPicture,
    this.myPicture,
  });

  final String partnerName;
  final String? partnerPicture;
  final String? myPicture;

  static Future<void> show(
    BuildContext context, {
    required String partnerName,
    String? partnerPicture,
    String? myPicture,
    required VoidCallback onContinue,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _MazelTovScreenWrapper(
              partnerName: partnerName,
              partnerPicture: partnerPicture,
              myPicture: myPicture,
              onContinue: onContinue,
            ),
          );
        },
      ),
    );
  }

  @override
  State<MazelTovScreen> createState() => _MazelTovScreenState();
}

class _MazelTovScreenWrapper extends StatelessWidget {
  const _MazelTovScreenWrapper({
    required this.partnerName,
    this.partnerPicture,
    this.myPicture,
    required this.onContinue,
  });

  final String partnerName;
  final String? partnerPicture;
  final String? myPicture;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _MazelTovContent(
      partnerName: partnerName,
      partnerPicture: partnerPicture,
      myPicture: myPicture,
      onContinue: () {
        Navigator.of(context).pop();
        onContinue();
      },
    );
  }
}

class _MazelTovContent extends StatefulWidget {
  const _MazelTovContent({
    required this.partnerName,
    this.partnerPicture,
    this.myPicture,
    required this.onContinue,
  });

  final String partnerName;
  final String? partnerPicture;
  final String? myPicture;
  final VoidCallback onContinue;

  @override
  State<_MazelTovContent> createState() => _MazelTovContentState();
}

class _MazelTovContentState extends State<_MazelTovContent>
    with TickerProviderStateMixin {
  final List<_ConfettiParticle> _particles = [];
  late AnimationController _confettiController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Generate confetti particles
    _generateConfetti();

    // Start confetti animation
    Future.delayed(const Duration(milliseconds: 300), () {
      _confettiController.forward();
    });
  }

  void _generateConfetti() {
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFF6B9D), // Pink
      const Color(0xFF4ECDC4), // Teal
      const Color(0xFFFFE66D), // Yellow
      const Color(0xFFFF8E6B), // Orange
      Colors.white,
    ];

    for (int i = 0; i < 100; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        delay: _random.nextDouble() * 0.5,
        speed: 0.5 + _random.nextDouble() * 0.5,
        size: 8 + _random.nextDouble() * 8,
        color: colors[_random.nextInt(colors.length)],
        rotation: _random.nextDouble() * 360,
        rotationSpeed: _random.nextDouble() * 720 - 360,
        swayAmount: _random.nextDouble() * 50,
        swaySpeed: 1 + _random.nextDouble() * 2,
      ));
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Confetti layer
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _confettiController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Mazel Tov text with animation
                _buildMazelTovTitle(),

                const SizedBox(height: 40),

                // Two hearts/photos coming together
                _buildCoupleVisual(),

                const SizedBox(height: 40),

                // Warm message
                _buildWarmMessage(),

                const Spacer(flex: 2),

                // Continue button
                _buildContinueButton(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMazelTovTitle() {
    return Column(
      children: [
        // Hebrew text
        const Text(
          'מזל טוב',
          style: TextStyle(
            fontSize: 28,
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.w300,
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: -0.3, end: 0),

        const SizedBox(height: 8),

        // Main title
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFD700),
              Color(0xFFFF6B9D),
              Color(0xFFFFD700),
            ],
          ).createShader(bounds),
          child: const Text(
            'MAZEL TOV !',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1))
            .then()
            .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
      ],
    );
  }

  Widget _buildCoupleVisual() {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing circle behind
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF6B9D).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 600.ms)
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),

          // Two profile pictures/avatars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // My picture
              _buildProfileCircle(
                picture: widget.myPicture,
                fallbackIcon: LucideIcons.user,
                delay: 800,
                slideFrom: -1,
              ),

              // Heart in the middle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFF8E6B)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B9D).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.heart,
                    color: Colors.white,
                    size: 28,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1200.ms)
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                      duration: 800.ms,
                    )
                    .then()
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 1000.ms,
                    ),
              ),

              // Partner picture
              _buildProfileCircle(
                picture: widget.partnerPicture,
                fallbackText: widget.partnerName,
                delay: 800,
                slideFrom: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCircle({
    String? picture,
    IconData? fallbackIcon,
    String? fallbackText,
    required int delay,
    required double slideFrom,
  }) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipOval(
        child: picture != null
            ? CachedNetworkImage(
                imageUrl: picture,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              )
            : Container(
                color: AppColors.primary.withOpacity(0.3),
                child: Center(
                  child: fallbackIcon != null
                      ? Icon(fallbackIcon, color: Colors.white, size: 36)
                      : Text(
                          fallbackText?.isNotEmpty == true
                              ? fallbackText![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: slideFrom * 0.5, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }

  Widget _buildWarmMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            'Felicitations ${widget.partnerName} et toi !',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          )
              .animate()
              .fadeIn(delay: 1400.ms, duration: 600.ms),

          const SizedBox(height: 16),

          Text(
            'Vous commencez une belle aventure ensemble.\nMAZL vous accompagne dans cette nouvelle etape.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              height: 1.5,
            ),
          )
              .animate()
              .fadeIn(delay: 1600.ms, duration: 600.ms),

          const SizedBox(height: 24),

          // Blessing
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.sparkles,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Que votre amour grandisse de jour en jour',
                  style: TextStyle(
                    color: const Color(0xFFFFD700).withOpacity(0.9),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 1800.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: widget.onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B9D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: const Color(0xFFFF6B9D).withOpacity(0.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Commencer notre aventure',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(LucideIcons.arrowRight, size: 20),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(delay: 2000.ms, duration: 600.ms)
          .slideY(begin: 0.5, end: 0),
    );
  }
}

class _MazelTovScreenState extends State<MazelTovScreen> {
  @override
  Widget build(BuildContext context) {
    return _MazelTovContent(
      partnerName: widget.partnerName,
      partnerPicture: widget.partnerPicture,
      myPicture: widget.myPicture,
      onContinue: () => context.go('/couple/dashboard'),
    );
  }
}

// Custom confetti particle
class _ConfettiParticle {
  final double x;
  final double delay;
  final double speed;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
  final double swayAmount;
  final double swaySpeed;

  _ConfettiParticle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.swayAmount,
    required this.swaySpeed,
  });
}

// Custom painter for confetti
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate effective progress for this particle (accounting for delay)
      final effectiveProgress = (progress - particle.delay).clamp(0.0, 1.0);
      if (effectiveProgress <= 0) continue;

      // Calculate position
      final x = particle.x * size.width +
          sin(effectiveProgress * particle.swaySpeed * pi * 2) * particle.swayAmount;
      final y = effectiveProgress * size.height * particle.speed;

      // Calculate rotation
      final rotation = particle.rotation + effectiveProgress * particle.rotationSpeed;

      // Calculate opacity (fade out at the end)
      final opacity = effectiveProgress < 0.8
          ? 1.0
          : 1.0 - ((effectiveProgress - 0.8) / 0.2);

      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation * pi / 180);

      // Draw rectangle confetti
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
