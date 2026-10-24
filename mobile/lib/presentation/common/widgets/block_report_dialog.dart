import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../l10n/report_category_text.dart';
import 'mazl_sheet.dart';

/// Dialog for blocking or reporting a user
class BlockReportDialog extends StatefulWidget {
  const BlockReportDialog({
    super.key,
    required this.userId,
    required this.userName,
    this.onBlocked,
    this.onReported,
  });

  final int userId;
  final String userName;
  final VoidCallback? onBlocked;
  final VoidCallback? onReported;

  static Future<void> show(
    BuildContext context, {
    required int userId,
    required String userName,
    VoidCallback? onBlocked,
    VoidCallback? onReported,
  }) {
    return showMazlSheet(
      context,
      isScrollControlled: true,
      padded: false,
      builder: (context) => BlockReportDialog(
        userId: userId,
        userName: userName,
        onBlocked: onBlocked,
        onReported: onReported,
      ),
    );
  }

  @override
  State<BlockReportDialog> createState() => _BlockReportDialogState();
}

class _BlockReportDialogState extends State<BlockReportDialog> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          widget.userName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Block option
        _buildOption(
          icon: LucideIcons.ban,
          iconColor: Colors.orange,
          title: context.l10n.safetyBlock,
          subtitle: context.l10n.safetyBlockSubtitle,
          onTap: () => _showBlockConfirmation(context),
        ),

        const Divider(height: 1),

        // Report option
        _buildOption(
          icon: LucideIcons.flag,
          iconColor: Colors.red,
          title: context.l10n.commonReport,
          subtitle: context.l10n.safetyReportSubtitle,
          onTap: () => _showReportDialog(context),
        ),

        const SizedBox(height: 8),

        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.l10n.commonCancel,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showBlockConfirmation(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => _BlockConfirmationDialog(
        userId: widget.userId,
        userName: widget.userName,
        onBlocked: widget.onBlocked,
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    Navigator.pop(context);
    showMazlSheet(
      context,
      isScrollControlled: true,
      padded: false,
      builder: (context) => _ReportDialog(
        userId: widget.userId,
        userName: widget.userName,
        onReported: widget.onReported,
      ),
    );
  }
}

/// Confirmation dialog for blocking
class _BlockConfirmationDialog extends StatefulWidget {
  const _BlockConfirmationDialog({
    required this.userId,
    required this.userName,
    this.onBlocked,
  });

  final int userId;
  final String userName;
  final VoidCallback? onBlocked;

  @override
  State<_BlockConfirmationDialog> createState() => _BlockConfirmationDialogState();
}

class _BlockConfirmationDialogState extends State<_BlockConfirmationDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _blockUser() async {
    setState(() => _isLoading = true);

    final result = await _apiService.blockUser(widget.userId);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        Navigator.pop(context);
        widget.onBlocked?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.safetyBlocked(widget.userName)),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.safetyBlockFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(context.l10n.safetyBlockConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.safetyBlockConfirmIntro(widget.userName),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          _buildBulletPoint(context.l10n.safetyBlockEffectHidden),
          _buildBulletPoint(context.l10n.safetyBlockEffectNotSeen),
          _buildBulletPoint(context.l10n.safetyBlockEffectChats),
          _buildBulletPoint(context.l10n.safetyBlockEffectNotNotified),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _blockUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(context.l10n.safetyBlock),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Report dialog with categories
class _ReportDialog extends StatefulWidget {
  const _ReportDialog({
    required this.userId,
    required this.userName,
    this.onReported,
  });

  final int userId;
  final String userName;
  final VoidCallback? onReported;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final ApiService _apiService = ApiService();
  String? _selectedCategory;
  final TextEditingController _commentController = TextEditingController();
  bool _alsoBlock = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedCategory == null) return;

    setState(() => _isLoading = true);

    final result = await _apiService.reportUser(
      userId: widget.userId,
      category: _selectedCategory!,
      comment: _commentController.text.isNotEmpty ? _commentController.text : null,
      blockUser: _alsoBlock,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        Navigator.pop(context);
        widget.onReported?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.safetyReportThanks),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.safetyReportFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  context.l10n.safetyReportTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.safetyReportWhy(widget.userName),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                // Categories
                ...ReportCategory.categories.map((category) {
                  final isSelected = _selectedCategory == category.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = category.id),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? AppColors.primary : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.label(context.l10n),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    category.description(context.l10n),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Comment field
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: context.l10n.safetyReportDetailsHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Also block checkbox
                CheckboxListTile(
                  value: _alsoBlock,
                  onChanged: (value) => setState(() => _alsoBlock = value ?? false),
                  title: Text(context.l10n.safetyReportAlsoBlock),
                  subtitle: Text(
                    context.l10n.safetyReportAlsoBlockHint,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedCategory != null && !_isLoading
                        ? _submitReport
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            context.l10n.safetyReportSend,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.commonCancel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
