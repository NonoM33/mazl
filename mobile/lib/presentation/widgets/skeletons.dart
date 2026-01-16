import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';

/// Base shimmer wrapper
class ShimmerWrapper extends StatelessWidget {
  const ShimmerWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: child,
    );
  }
}

/// Simple skeleton box
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton circle (for avatars)
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Profile card skeleton (for discover screen)
class ProfileCardSkeleton extends StatelessWidget {
  const ProfileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Photo area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
            ),
            // Info area
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SkeletonBox(width: 120, height: 24, borderRadius: 4),
                      const Spacer(),
                      SkeletonBox(width: 60, height: 24, borderRadius: 12),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: 80, height: 16, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat conversation item skeleton
class ConversationSkeleton extends StatelessWidget {
  const ConversationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SkeletonCircle(size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 100, height: 16, borderRadius: 4),
                  const SizedBox(height: 8),
                  SkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const SkeletonBox(width: 40, height: 12, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// Chat list skeleton
class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => const ConversationSkeleton(),
    );
  }
}

/// Match card skeleton
class MatchCardSkeleton extends StatelessWidget {
  const MatchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            const SkeletonBox(width: 60, height: 14, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// Matches list skeleton (horizontal)
class MatchesListSkeleton extends StatelessWidget {
  const MatchesListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) => const MatchCardSkeleton(),
      ),
    );
  }
}

/// Event card skeleton
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 120,
              color: Colors.grey[300],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 200, height: 18, borderRadius: 4),
                  const SizedBox(height: 12),
                  const SkeletonBox(width: 150, height: 14, borderRadius: 4),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: 120, height: 14, borderRadius: 4),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SkeletonBox(width: 80, height: 14, borderRadius: 4),
                      const Spacer(),
                      SkeletonBox(width: 60, height: 24, borderRadius: 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Events list skeleton
class EventsListSkeleton extends StatelessWidget {
  const EventsListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const EventCardSkeleton(),
    );
  }
}

/// Profile view skeleton
class ProfileViewSkeleton extends StatelessWidget {
  const ProfileViewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Photo area
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              color: Colors.grey[300],
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SkeletonBox(width: 150, height: 28, borderRadius: 4),
                      const Spacer(),
                      SkeletonBox(width: 70, height: 28, borderRadius: 14),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: 100, height: 16, borderRadius: 4),
                  const SizedBox(height: 16),
                  const SkeletonBox(width: 120, height: 20, borderRadius: 4),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: double.infinity, height: 50, borderRadius: 8),
                  const SizedBox(height: 16),
                  const SkeletonBox(width: 100, height: 20, borderRadius: 4),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SkeletonBox(width: 80, height: 32, borderRadius: 16),
                      SkeletonBox(width: 100, height: 32, borderRadius: 16),
                      SkeletonBox(width: 70, height: 32, borderRadius: 16),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple list item skeleton
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SkeletonCircle(size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 120, height: 16, borderRadius: 4),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 180, height: 14, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
