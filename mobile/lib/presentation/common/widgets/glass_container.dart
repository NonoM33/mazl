import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A glassmorphism container widget with blur effect
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderRadius = 24,
    this.border,
    this.padding,
    this.margin,
    this.gradient,
  });

  final Widget child;
  final double? width;
  final double? height;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient ??
                  LinearGradient(
                    colors: [
                      (isDark ? AppColors.glassDark : AppColors.glassLight)
                          .withOpacity(opacity),
                      (isDark ? AppColors.glassDark : AppColors.glassLight)
                          .withOpacity(opacity * 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(
                    color: isDark
                        ? AppColors.glassBorderDark
                        : AppColors.glassBorderLight,
                    width: 1.5,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A glassmorphism card with shadow
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.blur = 15,
    this.opacity = 0.15,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.elevation = 8,
  });

  final Widget child;
  final double? width;
  final double? height;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      child: GlassContainer(
        blur: blur,
        opacity: opacity,
        borderRadius: borderRadius,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// A gradient-bordered glassmorphism container
class GlassGradientContainer extends StatelessWidget {
  const GlassGradientContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderRadius = 24,
    this.borderWidth = 2,
    this.padding,
    this.margin,
  });

  final Widget child;
  final double? width;
  final double? height;
  final double blur;
  final double opacity;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: AppColors.primaryGradient,
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        child: GlassContainer(
          blur: blur,
          opacity: opacity,
          borderRadius: borderRadius - borderWidth,
          padding: padding,
          border: Border.all(color: Colors.transparent),
          child: child,
        ),
      ),
    );
  }
}
