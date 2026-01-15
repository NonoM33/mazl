import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

/// MAZL Logo widget with customizable size and color
class MazlLogo extends StatelessWidget {
  const MazlLogo({
    super.key,
    this.size = 100,
    this.color,
    this.useGradient = true,
  });

  final double size;
  final Color? color;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo.svg',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

/// MAZL Logo with white background container
class MazlLogoContainer extends StatelessWidget {
  const MazlLogoContainer({
    super.key,
    this.size = 100,
    this.backgroundColor = Colors.white,
    this.borderRadius = 25,
    this.padding = 16,
    this.elevation = 10,
  });

  final double size;
  final Color backgroundColor;
  final double borderRadius;
  final double padding;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + padding * 2,
      height: size + padding * 2,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      child: Center(
        child: MazlLogo(size: size),
      ),
    );
  }
}

/// Animated MAZL Logo for splash screen
class AnimatedMazlLogo extends StatefulWidget {
  const AnimatedMazlLogo({
    super.key,
    this.size = 120,
    this.duration = const Duration(milliseconds: 1500),
  });

  final double size;
  final Duration duration;

  @override
  State<AnimatedMazlLogo> createState() => _AnimatedMazlLogoState();
}

class _AnimatedMazlLogoState extends State<AnimatedMazlLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: MazlLogoContainer(
              size: widget.size,
              padding: 20,
              borderRadius: 30,
            ),
          ),
        );
      },
    );
  }
}
