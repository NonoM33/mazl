import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return _ConversationTile(
            name: ['Sarah', 'Rachel', 'Leah', 'Miriam', 'Hannah'][index],
            lastMessage: [
              'Hey! Comment vas-tu ?',
              'On se voit ce weekend ?',
              'J\'ai adoré notre conversation !',
              'Shabbat shalom !',
              'Merci pour hier soir'
            ][index],
            time: ['12:30', '11:20', 'Hier', 'Lun', 'Dim'][index],
            unreadCount: index == 0 ? 2 : (index == 1 ? 1 : 0),
            color: [
              AppColors.primary,
              AppColors.secondary,
              AppColors.accent,
              AppColors.accentGold,
              AppColors.success,
            ][index],
            conversationId: 'conv_$index',
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.color,
    required this.conversationId,
  });

  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final Color color;
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Text(
              name[0],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Text(
            name,
            style: TextStyle(
              fontWeight:
                  unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: unreadCount > 0
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unreadCount > 0
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight:
                    unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        context.go('/chat/$conversationId');
      },
    );
  }
}
