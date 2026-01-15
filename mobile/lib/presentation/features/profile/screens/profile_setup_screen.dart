import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Étape ${_currentStep + 1}/$_totalSteps'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: AppColors.dividerLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _BasicInfoStep(),
                _PhotosStep(),
                _JewishInfoStep(),
                _PreferencesStep(),
              ],
            ),
          ),

          // Next button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _nextStep,
                child: Text(
                  _currentStep < _totalSteps - 1 ? 'Suivant' : 'Terminer',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete setup and go to discover
      context.go(RoutePaths.discover);
    }
  }

  void _previousStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

class _BasicInfoStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Parle-nous de toi',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ces informations seront visibles sur ton profil',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 32),

        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Prénom',
            hintText: 'Comment tu t\'appelles ?',
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Date de naissance',
            hintText: 'JJ/MM/AAAA',
            suffixIcon: Icon(Icons.calendar_today),
          ),
          readOnly: true,
          onTap: () {
            // TODO: Show date picker
          },
        ),
        const SizedBox(height: 16),

        const Text(
          'Je suis',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _GenderChip(label: 'Un homme', selected: false)),
            const SizedBox(width: 12),
            Expanded(child: _GenderChip(label: 'Une femme', selected: true)),
          ],
        ),
        const SizedBox(height: 16),

        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Ville',
            hintText: 'Où habites-tu ?',
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
      ],
    );
  }
}

class _PhotosStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Ajoute des photos',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ajoute au moins 2 photos pour continuer',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 32),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: List.generate(6, (index) {
            return GestureDetector(
              onTap: () {
                // TODO: Pick photo
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: index == 0
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      color: index == 0 ? AppColors.primary : Colors.grey,
                      size: 32,
                    ),
                    if (index == 0) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Principal',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.info),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Les profils avec des photos de bonne qualité reçoivent 3x plus de matchs !',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JewishInfoStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Ta pratique',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Aide-nous à trouver quelqu\'un qui te correspond',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 32),

        const Text('Dénomination', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SelectableChip(label: 'Orthodox', selected: false),
            _SelectableChip(label: 'Modern Orthodox', selected: true),
            _SelectableChip(label: 'Conservative', selected: false),
            _SelectableChip(label: 'Reform', selected: false),
            _SelectableChip(label: 'Traditional', selected: false),
            _SelectableChip(label: 'Secular', selected: false),
          ],
        ),

        const SizedBox(height: 24),

        const Text('Kashrout', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SelectableChip(label: 'Strict', selected: false),
            _SelectableChip(label: 'À la maison', selected: true),
            _SelectableChip(label: 'Parfois', selected: false),
            _SelectableChip(label: 'Non', selected: false),
          ],
        ),

        const SizedBox(height: 24),

        const Text('Shabbat', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SelectableChip(label: 'Strict', selected: false),
            _SelectableChip(label: 'Généralement', selected: true),
            _SelectableChip(label: 'Parfois', selected: false),
            _SelectableChip(label: 'Rarement', selected: false),
          ],
        ),

        const SizedBox(height: 24),

        const Text('Synagogue', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SelectableChip(label: 'Quotidien', selected: false),
            _SelectableChip(label: 'Chaque semaine', selected: true),
            _SelectableChip(label: 'Fêtes', selected: false),
            _SelectableChip(label: 'Rarement', selected: false),
          ],
        ),
      ],
    );
  }
}

class _PreferencesStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Ce que tu recherches',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Aide-nous à te montrer les bons profils',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 32),

        const Text('Je recherche', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _GenderChip(label: 'Un homme', selected: true)),
            const SizedBox(width: 12),
            Expanded(child: _GenderChip(label: 'Une femme', selected: false)),
          ],
        ),

        const SizedBox(height: 24),

        const Text('Tranche d\'âge', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        RangeSlider(
          values: const RangeValues(22, 35),
          min: 18,
          max: 60,
          divisions: 42,
          labels: const RangeLabels('22', '35'),
          onChanged: (values) {},
        ),

        const SizedBox(height: 24),

        const Text('Distance maximum', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Slider(
          value: 50,
          min: 5,
          max: 200,
          divisions: 39,
          label: '50 km',
          onChanged: (value) {},
        ),

        const SizedBox(height: 24),

        const Text('Objectif', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SelectableChip(label: 'Mariage', selected: true),
            _SelectableChip(label: 'Relation sérieuse', selected: false),
            _SelectableChip(label: 'Je ne sais pas', selected: false),
          ],
        ),

        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Notre AI Shadchan utilisera ces préférences pour te proposer des profils compatibles !',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primary : Colors.grey,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
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
      onSelected: (value) {},
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }
}
