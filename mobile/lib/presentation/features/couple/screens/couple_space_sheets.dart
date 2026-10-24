import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../l10n/couple_failure_label.dart';

// The three "add" forms of the couple space. They are opened with
// `showMazlSheet` by the screen and pop `true` once the server accepted the
// entry; on failure they stay open and say why.

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
  );
}

class _SheetSubmit extends StatelessWidget {
  const _SheetSubmit({
    required this.enabled,
    required this.busy,
    required this.error,
    required this.onPressed,
  });

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
          child: busy
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                )
              : Text(context.l10n.coupleSpaceSheetAdd),
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
        final l10n = context.l10n;
        setState(() {
          _busy = false;
          _error = l10n.coupleSpaceAddFailed(failure.label(l10n));
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetTitle(l10n.coupleSpaceAddMemoryTitle),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(labelText: l10n.coupleSpaceFieldTitle),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _contentController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.coupleSpaceFieldDescription,
          ),
        ),
        const SizedBox(height: 20),
        ListenableBuilder(
          listenable: _titleController,
          builder: (context, _) => _SheetSubmit(
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
        final l10n = context.l10n;
        setState(() {
          _busy = false;
          _error = l10n.coupleSpaceAddFailed(failure.label(l10n));
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetTitle(l10n.coupleSpaceAddBucketTitle),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: l10n.coupleSpaceBucketFieldLabel,
            hintText: l10n.coupleSpaceBucketFieldHint,
          ),
        ),
        const SizedBox(height: 20),
        ListenableBuilder(
          listenable: _titleController,
          builder: (context, _) => _SheetSubmit(
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
        final l10n = context.l10n;
        setState(() {
          _busy = false;
          _error = l10n.coupleSpaceAddFailed(failure.label(l10n));
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetTitle(l10n.coupleSpaceAddDateTitle),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: l10n.coupleSpaceFieldTitle,
            hintText: l10n.coupleSpaceDateFieldHint,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          tileColor: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Text(l10n.coupleSpaceFieldDate),
          subtitle: Text(DateFormat.yMd(l10n.localeName).format(_selectedDate)),
          trailing: Icon(
            LucideIcons.calendar,
            color: Theme.of(context).colorScheme.primary,
          ),
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
