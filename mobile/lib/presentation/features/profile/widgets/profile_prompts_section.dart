import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/l10n/api_error_text.dart';
import '../../../common/widgets/directional_icon.dart';
import '../../../common/widgets/mazl_sheet.dart';
import '../l10n/prompt_labels.dart';

/// Widget to manage profile prompts (Hinge-style Q&A)
class ProfilePromptsSection extends StatefulWidget {
  const ProfilePromptsSection({super.key, this.onPromptsChanged});

  final VoidCallback? onPromptsChanged;

  @override
  State<ProfilePromptsSection> createState() => _ProfilePromptsSectionState();
}

class _ProfilePromptsSectionState extends State<ProfilePromptsSection> {
  final ApiService _apiService = ApiService();

  List<PromptTemplate> _availablePrompts = [];
  List<ProfilePrompt> _myPrompts = [];
  bool _isLoading = true;
  bool _hasLoadError = false;
  ApiErrorKind? _errorKind;

  static const int maxPrompts = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
      _errorKind = null;
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
          _hasLoadError = true;
          _errorKind = results[0].errorKind ?? results[1].errorKind;
        }
      });
    }
  }

  Future<void> _addPrompt() async {
    final l10n = context.l10n;
    if (_myPrompts.length >= maxPrompts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profilePromptsMaxReached(maxPrompts)),
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
        SnackBar(
          content: Text(l10n.profilePromptsAllUsed),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show prompt selection dialog
    final selectedTemplate = await showMazlSheet<PromptTemplate>(
      context,
      isScrollControlled: true,
      padded: false,
      builder: (context) => _PromptSelectionSheet(prompts: availableToAdd),
    );

    if (selectedTemplate == null || !mounted) return;

    // Show answer input dialog
    final answer = await _showAnswerDialog(
      promptQuestionText(l10n, selectedTemplate.id, selectedTemplate.text),
    );

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
            content: Text(apiErrorText(context.l10n, result.errorKind)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editPrompt(ProfilePrompt prompt) async {
    final answer = await _showAnswerDialog(
      promptQuestionText(context.l10n, prompt.promptId, prompt.promptText),
      currentAnswer: prompt.answer,
    );

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
            content: Text(apiErrorText(context.l10n, result.errorKind)),
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
        title: Text(context.l10n.profilePromptDeleteTitle),
        content: Text(context.l10n.profileIrreversibleSentence),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.commonDelete),
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
          SnackBar(content: Text(context.l10n.profilePromptDeleted)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorText(context.l10n, result.errorKind)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showAnswerDialog(
    String question, {
    String? currentAnswer,
  }) async {
    final controller = TextEditingController(text: currentAnswer);

    return showMazlSheet<String>(
      context,
      isScrollControlled: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            question,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Answer field
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            maxLength: 150,
            decoration: InputDecoration(
              hintText: context.l10n.profilePromptYourAnswer,
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
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
              child: Text(context.l10n.commonSave),
            ),
          ),
        ],
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
            Text(
              context.l10n.profilePromptsMine,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_myPrompts.length}/$maxPrompts',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.profilePromptsSubtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        else if (_hasLoadError)
          Center(
            child: Column(
              children: [
                Text(
                  apiErrorText(context.l10n, _errorKind),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: _loadData,
                  child: Text(context.l10n.commonRetry),
                ),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    promptQuestionText(
                      context.l10n,
                      prompt.promptId,
                      prompt.promptText,
                    ),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  // Above the floating tab bar, like every overlay (sheet_rules_test).
                  useRootNavigator: true,
                  icon: Icon(
                    LucideIcons.moreVertical,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(LucideIcons.edit, size: 18),
                          const SizedBox(width: 8),
                          Text(context.l10n.profileEdit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.commonDelete,
                            style: const TextStyle(color: Colors.red),
                          ),
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
              style: const TextStyle(fontSize: 15, height: 1.4),
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
              context.l10n.profilePromptAdd,
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
      final category = prompt.category ?? '';
      grouped.putIfAbsent(category, () => []).add(prompt);
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              context.l10n.profilePromptChoose,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      promptCategoryText(
                        context.l10n,
                        entry.key.isEmpty ? null : entry.key,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // Prompts in category
                  ...entry.value.map(
                    (prompt) => _PromptOption(
                      prompt: prompt,
                      onTap: () => Navigator.pop(context, prompt),
                    ),
                  ),
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
  const _PromptOption({required this.prompt, required this.onTap});

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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                promptQuestionText(context.l10n, prompt.id, prompt.text),
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            DirectionalIcon(
              LucideIcons.chevronRight,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
