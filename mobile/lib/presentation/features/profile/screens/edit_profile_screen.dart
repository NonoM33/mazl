import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Save profile
              context.pop();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Photos section
          const Text(
            'Photos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _PhotoSlot(hasPhoto: true, isPrimary: true),
              _PhotoSlot(hasPhoto: true),
              _PhotoSlot(hasPhoto: true),
              _PhotoSlot(hasPhoto: false),
              _PhotoSlot(hasPhoto: false),
              _PhotoSlot(hasPhoto: false),
            ],
          ),

          const SizedBox(height: 24),

          // Bio
          const Text(
            'À propos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            maxLines: 4,
            maxLength: 500,
            initialValue: 'Amoureuse de la vie, des voyages et de la bonne cuisine.',
            decoration: const InputDecoration(
              hintText: 'Parle de toi...',
            ),
          ),

          const SizedBox(height: 24),

          // Basic info
          const Text(
            'Informations de base',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _EditField(label: 'Prénom', value: 'Sarah'),
          _EditField(label: 'Ville', value: 'Paris'),
          _EditField(label: 'Profession', value: 'Designer'),
          _EditField(label: 'Taille', value: '165 cm'),

          const SizedBox(height: 24),

          // Jewish preferences
          const Text(
            'Ma pratique',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _EditField(label: 'Dénomination', value: 'Modern Orthodox'),
          _EditField(label: 'Kashrout', value: 'Casher à la maison'),
          _EditField(label: 'Shabbat', value: 'Observant'),
          _EditField(label: 'Synagogue', value: 'Chaque semaine'),

          const SizedBox(height: 24),

          // Interests
          const Text(
            'Intérêts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EditableChip(label: 'Voyages', selected: true),
              _EditableChip(label: 'Cuisine', selected: true),
              _EditableChip(label: 'Musique', selected: true),
              _EditableChip(label: 'Sport', selected: false),
              _EditableChip(label: 'Lecture', selected: true),
              _EditableChip(label: 'Cinéma', selected: false),
              _EditableChip(label: 'Art', selected: false),
              _EditableChip(label: 'Yoga', selected: true),
            ],
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.hasPhoto,
    this.isPrimary = false,
  });

  final bool hasPhoto;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Pick photo
      },
      child: Container(
        decoration: BoxDecoration(
          color: hasPhoto
              ? AppColors.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? Border.all(color: AppColors.accentGold, width: 3)
              : null,
        ),
        child: hasPhoto
            ? Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // TODO: Remove photo
                        },
                      ),
                    ),
                  ),
                  if (isPrimary)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Principal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : const Center(
                child: Icon(
                  Icons.add_photo_alternate,
                  color: Colors.grey,
                  size: 32,
                ),
              ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Open editor
      },
    );
  }
}

class _EditableChip extends StatelessWidget {
  const _EditableChip({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        // TODO: Toggle selection
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }
}
