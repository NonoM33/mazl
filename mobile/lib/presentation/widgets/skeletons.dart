import 'package:flutter/material.dart';

import '../common/widgets/fold_pages.dart';
import 'loading_thread.dart';

/// Colour of every skeleton block: flat and neutral, from the theme. Only the
/// thread of [LoadingThread] moves, and only over these blocks, so a skeleton
/// must paint nothing but blocks (no card, no border behind them).
Color _blockColor(BuildContext context) =>
    Theme.of(context).colorScheme.surfaceContainer;

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
        color: _blockColor(context),
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
      decoration: BoxDecoration(
        color: _blockColor(context),
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
    return FoldFirstPage(
      child: LoadingThread(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Photo area
              const Expanded(child: SkeletonBox(borderRadius: 24)),
              // Info area
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        SkeletonBox(width: 120, height: 24, borderRadius: 4),
                        Spacer(),
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
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SkeletonCircle(size: 56),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 100, height: 16, borderRadius: 4),
                SizedBox(height: 8),
                SkeletonBox(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonBox(width: 40, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Chat conversation item skeleton
class ConversationSkeleton extends StatelessWidget {
  const ConversationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingThread(child: _ConversationRow());
  }
}

/// Chat list skeleton: one thread for the whole list.
class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return LoadingThread(
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) => const _ConversationRow(),
      ),
    );
  }
}

class _MatchItem extends StatelessWidget {
  const _MatchItem();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 100,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: 12),
        child: Column(
          children: [
            SkeletonCircle(size: 80),
            SizedBox(height: 8),
            SkeletonBox(width: 60, height: 14, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// Match card skeleton
class MatchCardSkeleton extends StatelessWidget {
  const MatchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingThread(child: _MatchItem());
  }
}

/// Matches list skeleton (horizontal): one thread for the whole row.
class MatchesListSkeleton extends StatelessWidget {
  const MatchesListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: LoadingThread(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: itemCount,
          itemBuilder: (context, index) => const _MatchItem(),
        ),
      ),
    );
  }
}

class _EventItem extends StatelessWidget {
  const _EventItem();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SkeletonBox(width: double.infinity, height: 120, borderRadius: 12),
          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 200, height: 18, borderRadius: 4),
                SizedBox(height: 12),
                SkeletonBox(width: 150, height: 14, borderRadius: 4),
                SizedBox(height: 8),
                SkeletonBox(width: 120, height: 14, borderRadius: 4),
                SizedBox(height: 12),
                Row(
                  children: [
                    SkeletonBox(width: 80, height: 14, borderRadius: 4),
                    Spacer(),
                    SkeletonBox(width: 60, height: 24, borderRadius: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Event card skeleton
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingThread(child: _EventItem());
  }
}

/// Events list skeleton: one thread for the whole list, kept on the first
/// page of a half-open foldable iPhone.
class EventsListSkeleton extends StatelessWidget {
  const EventsListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return FoldFirstPage(
      child: LoadingThread(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: itemCount,
          itemBuilder: (context, index) => const _EventItem(),
        ),
      ),
    );
  }
}

/// Profile view skeleton
class ProfileViewSkeleton extends StatelessWidget {
  const ProfileViewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return FoldFirstPage(child: _page(context));
  }

  Widget _page(BuildContext context) {
    return LoadingThread(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Photo area
            SkeletonBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.5,
              borderRadius: 0,
            ),
            // Info area
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonBox(width: 150, height: 28, borderRadius: 4),
                      Spacer(),
                      SkeletonBox(width: 70, height: 28, borderRadius: 14),
                    ],
                  ),
                  SizedBox(height: 8),
                  SkeletonBox(width: 100, height: 16, borderRadius: 4),
                  SizedBox(height: 16),
                  SkeletonBox(width: 120, height: 20, borderRadius: 4),
                  SizedBox(height: 8),
                  SkeletonBox(
                    width: double.infinity,
                    height: 50,
                    borderRadius: 8,
                  ),
                  SizedBox(height: 16),
                  SkeletonBox(width: 100, height: 20, borderRadius: 4),
                  SizedBox(height: 8),
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
    return const LoadingThread(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SkeletonCircle(size: 48),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 16, borderRadius: 4),
                  SizedBox(height: 8),
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
