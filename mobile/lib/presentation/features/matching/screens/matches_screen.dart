import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Matchs'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return _MatchCard(
            name: ['Sarah', 'Rachel', 'Leah', 'Miriam', 'Hannah'][index],
            matchedAt: 'Il y a ${index + 1} jour${index > 0 ? 's' : ''}',
            color: [
              AppColors.primary,
              AppColors.secondary,
              AppColors.accent,
              AppColors.accentGold,
              AppColors.success,
            ][index],
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.name,
    required this.matchedAt,
    required this.color,
  });

  final String name;
  final String matchedAt;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: color,
          child: Text(
            name[0],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          matchedAt,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // TODO: Navigate to chat
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(100, 40),
          ),
          child: const Text('Écrire'),
        ),
      ),
    );
  }
}
