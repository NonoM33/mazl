import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget to manage profile prompts (Hinge-style Q&A)
class ProfilePromptsSection extends StatefulWidget {
  const ProfilePromptsSection({
    super.key,
    this.onPromptsChanged,
  });

  final VoidCallback? onPromptsChanged;

  @override
  State<ProfilePromptsSection> createState() => _ProfilePromptsSectionState();
}

class _ProfilePromptsSectionState extends State<ProfilePromptsSection> {
  final ApiService _apiService = ApiService();

  List<PromptTemplate> _availablePrompts = [];
  List<ProfilePrompt> _myPrompts = [];
  bool _isLoading = true;
  String? _error;

  static const int maxPrompts = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Load available prompts and user's prompts in parallel
    final results = await Future.wait([
      _apiService.getAvailablePrompts(),
      _apiService.getMyPrompts(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (results[0].success && results[0].data != null) {
          _availablePrompts = results[0].data as List<PromptTemplate>;
        }
        if (results[1].success && results[1].data != null) {
          _myPrompts = results[1].data as List<ProfilePrompt>;
        }
        if (!results[0].success && !results[1].success) {
          _error = results[0].error ?? results[1].error;
        }
      });
    }
  }

  Future<void> _addPrompt() async {
    if (_myPrompts.length >= maxPrompts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum $maxPrompts prompts atteint'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Filter out already used prompts
    final usedTemplateIds = _myPrompts.map((p) => p.promptId).toSet();
    final availableToAdd = _availablePrompts
        .where((t) => !usedTemplateIds.contains(t.id))
        .toList();

    if (availableToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tous les prompts sont deja utilises'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show prompt selection dialog
    final selectedTemplate = await showModalBottomSheet<PromptTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PromptSelectionSheet(prompts: availableToAdd),
    );

    if (selectedTemplate == null) return;

    // Show answer input dialog
    final answer = await _showAnswerDialog(selectedTemplate.text);

    if (answer == null || answer.isEmpty) return;

    // Save the prompt
    final result = await _apiService.addPrompt(
      promptId: selectedTemplate.id,
      answer: answer,
      position: _myPrompts.length + 1,
    );

    if (mounted) {
      if (result.success && result.data != null) {
        setState(() {
          _myPrompts.add(result.data!);
        });
        widget.onPromptsChanged?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Erreur lors de l\'ajout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editPrompt(ProfilePrompt prompt) async {
    final answer = await _showAnswerDialog(prompt.promptText, currentAnswer: prompt.answer);

    if (answer == null || answer.isEmpty || answer == prompt.answer) return;

    final result = await _apiService.updatePrompt(prompt.id, answer);

    if (mounted) {
      if (result.success && result.data != null) {
        setState(() {
          final index = _myPrompts.indexWhere((p) => p.id == prompt.id);
          if (index != -1) {
            _myPrompts[index] = result.data!;
          }
        });
        widget.onPromptsChanged?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Erreur lors de la mise a jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePrompt(ProfilePrompt prompt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce prompt ?'),
        content: const Text('Cette action est irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _apiService.deletePrompt(prompt.id);

    if (mounted) {
      if (result.success) {
        setState(() {
          _myPrompts.removeWhere((p) => p.id == prompt.id);
        });
        widget.onPromptsChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prompt supprime')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showAnswerDialog(String question, {String? currentAnswer}) async {
    final controller = TextEditingController(text: currentAnswer);

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Question
                  Text(
                    question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Answer field
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 4,
                    maxLength: 150,
                    decoration: InputDecoration(
                      hintText: 'Ta reponse...',
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isNotEmpty) {
                          Navigator.pop(context, text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mes Prompts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_myPrompts.length}/$maxPrompts',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Reponds a des questions pour montrer ta personnalite',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          Center(
            child: Column(
              children: [
                Text(_error!, style: TextStyle(color: Colors.grey[600])),
                TextButton(onPressed: _loadData, child: const Text('Reessayer')),
              ],
            ),
          )
        else ...[
          // Existing prompts
          ...List.generate(_myPrompts.length, (index) {
            final prompt = _myPrompts[index];
            return _PromptCard(
              prompt: prompt,
              onEdit: () => _editPrompt(prompt),
              onDelete: () => _deletePrompt(prompt),
            );
          }),

          // Add prompt button
          if (_myPrompts.length < maxPrompts)
            _AddPromptButton(onTap: _addPrompt),
        ],
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.prompt,
    required this.onEdit,
    required this.onDelete,
  });

  final ProfilePrompt prompt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    prompt.promptText,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(LucideIcons.moreVertical, size: 18, color: AppColors.primary),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(LucideIcons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Answer
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              prompt.answer,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPromptButton extends StatelessWidget {
  const _AddPromptButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary,
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plus, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Ajouter un prompt',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptSelectionSheet extends StatelessWidget {
  const _PromptSelectionSheet({required this.prompts});

  final List<PromptTemplate> prompts;

  @override
  Widget build(BuildContext context) {
    // Group prompts by category
    final Map<String, List<PromptTemplate>> grouped = {};
    for (final prompt in prompts) {
      final category = prompt.category ?? 'Autre';
      grouped.putIfAbsent(category, () => []).add(prompt);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Choisis un prompt',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final entry in grouped.entries) ...[
                  // Category header
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // Prompts in category
                  ...entry.value.map((prompt) => _PromptOption(
                        prompt: prompt,
                        onTap: () => Navigator.pop(context, prompt),
                      )),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptOption extends StatelessWidget {
  const _PromptOption({
    required this.prompt,
    required this.onTap,
  });

  final PromptTemplate prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                prompt.text,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            Icon(LucideIcons.chevronRight, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
