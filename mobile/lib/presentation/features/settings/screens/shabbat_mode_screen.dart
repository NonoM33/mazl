import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class ShabbatModeScreen extends StatefulWidget {
  const ShabbatModeScreen({super.key});

  @override
  State<ShabbatModeScreen> createState() => _ShabbatModeScreenState();
}

class _ShabbatModeScreenState extends State<ShabbatModeScreen> {
  bool _isEnabled = true;
  bool _includeHolidays = true;
  int _bufferMinutes = 18;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Shabbat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header illustration
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.shabbatBackground, Color(0xFF2D2D5A)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  '🕯️🕯️',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Shabbat Shalom',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Profite d\'une pause automatique',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Enable switch
          Card(
            child: SwitchListTile(
              title: const Text('Activer le mode Shabbat'),
              subtitle: const Text(
                'Pause automatique des notifications pendant Shabbat',
              ),
              value: _isEnabled,
              onChanged: (value) {
                setState(() => _isEnabled = value);
              },
              activeColor: AppColors.accentGold,
            ),
          ),

          if (_isEnabled) ...[
            const SizedBox(height: 16),

            // Next Shabbat info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prochain Shabbat',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.wb_sunny,
                      label: 'Allumage des bougies',
                      value: 'Vendredi 17:45',
                    ),
                    _InfoRow(
                      icon: Icons.nightlight_round,
                      label: 'Sortie de Shabbat',
                      value: 'Samedi 18:52',
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Basé sur Paris, France',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            // TODO: Change location
                          },
                          child: const Text('Modifier'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Options
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Inclure les fêtes'),
                    subtitle: const Text(
                      'Pause aussi pendant Yom Tov',
                    ),
                    value: _includeHolidays,
                    onChanged: (value) {
                      setState(() => _includeHolidays = value);
                    },
                    activeColor: AppColors.accentGold,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Buffer avant allumage'),
                    subtitle: Text('$_bufferMinutes minutes'),
                    trailing: SizedBox(
                      width: 150,
                      child: Slider(
                        value: _bufferMinutes.toDouble(),
                        min: 0,
                        max: 30,
                        divisions: 6,
                        label: '$_bufferMinutes min',
                        onChanged: (value) {
                          setState(() => _bufferMinutes = value.toInt());
                        },
                        activeColor: AppColors.accentGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: AppColors.info),
                      SizedBox(width: 8),
                      Text(
                        'Comment ça marche ?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Les notifications sont automatiquement mises en pause\n'
                    '• Les messages sont mis en file d\'attente\n'
                    '• Tu recevras tout après la fin de Shabbat\n'
                    '• Ton statut sera affiché comme "Mode Shabbat"',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentGold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
