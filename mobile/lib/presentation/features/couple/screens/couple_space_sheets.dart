import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';

// The three "add" forms of the couple space. They are opened with
// `showMazlSheet` by the screen and pop `true` once the server accepted the
// entry; on failure they stay open and say why.

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );
}

class _SheetSubmit extends StatelessWidget {
  const _SheetSubmit({
    required this.color,
    required this.enabled,
    required this.busy,
    required this.error,
    required this.onPressed,
  });

  final Color color;
  final bool enabled;
  final bool busy;
  final String? error;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ElevatedButton(
          onPressed: enabled && !busy ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ajouter'),
        ),
      ],
    );
  }
}

class AddMemorySheet extends StatefulWidget {
  const AddMemorySheet({super.key, required this.apiService});
  final CoupleApiService apiService;

  @override
  State<AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<AddMemorySheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final content = _contentController.text.trim();
    final result = await widget.apiService.addMemory(
      type: 'note',
      title: _titleController.text.trim(),
      content: content.isEmpty ? null : content,
    );
    if (!mounted) return;
    switch (result) {
      case CoupleOk():
        Navigator.pop(context, true);
      case CoupleFailed(:final failure):
        setState(() {
          _busy = false;
          _error = 'Ajout impossible. ${failure.message}';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SheetTitle('Ajouter un souvenir'),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Titre',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _contentController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        ListenableBuilder(
          listenable: _titleController,
          builder: (context, _) => _SheetSubmit(
            color: const Color(0xFFFF6B9D),
            enabled: _titleController.text.trim().isNotEmpty,
            busy: _busy,
            error: _error,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

class AddBucketItemSheet extends StatefulWidget {
  const AddBucketItemSheet({super.key, required this.apiService});
  final CoupleApiService apiService;

  @override
  State<AddBucketItemSheet> createState() => _AddBucketItemSheetState();
}

class _AddBucketItemSheetState extends State<AddBucketItemSheet> {
  final _titleController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.apiService.addBucketListItem(
      title: _titleController.text.trim(),
    );
    if (!mounted) return;
    switch (result) {
      case CoupleOk():
        Navigator.pop(context, true);
      case CoupleFailed(:final failure):
        setState(() {
          _busy = false;
          _error = 'Ajout impossible. ${failure.message}';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SheetTitle('Ajouter à la bucket list'),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Que voulez-vous faire ensemble ?',
            border: OutlineInputBorder(),
            hintText: 'Ex: Voir les aurores boréales',
          ),
        ),
        const SizedBox(height: 20),
        ListenableBuilder(
          listenable: _titleController,
          builder: (context, _) => _SheetSubmit(
            color: AppColors.accentGold,
            enabled: _titleController.text.trim().isNotEmpty,
            busy: _busy,
            error: _error,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

class AddDateSheet extends StatefulWidget {
  const AddDateSheet({super.key, required this.apiService});
  final CoupleApiService apiService;

  @override
  State<AddDateSheet> createState() => _AddDateSheetState();
}

class _AddDateSheetState extends State<AddDateSheet> {
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.apiService.addDate(
      title: _titleController.text.trim(),
      date: _selectedDate.toIso8601String().split('T')[0],
      type: 'anniversary',
    );
    if (!mounted) return;
    switch (result) {
      case CoupleOk():
        Navigator.pop(context, true);
      case CoupleFailed(:final failure):
        setState(() {
          _busy = false;
          _error = 'Ajout impossible. ${failure.message}';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SheetTitle('Ajouter une date importante'),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Titre',
            border: OutlineInputBorder(),
            hintText: 'Ex: Notre anniversaire',
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Date'),
          subtitle: Text(
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          ),
          trailing: const Icon(LucideIcons.calendar),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) setState(() => _selectedDate = date);
          },
        ),
        const SizedBox(height: 20),
        ListenableBuilder(
          listenable: _titleController,
          builder: (context, _) => _SheetSubmit(
            color: AppColors.info,
            enabled: _titleController.text.trim().isNotEmpty,
            busy: _busy,
            error: _error,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
