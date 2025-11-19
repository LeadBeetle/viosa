import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Modal bottom sheet for naming a recording before saving
/// Provides a smart default name based on current date/time
class RecordingNameDialog extends StatefulWidget {
  /// Optional initial name to pre-fill
  final String? initialName;

  const RecordingNameDialog({super.key, this.initialName});

  /// Shows the dialog and returns the chosen name, or null if cancelled
  static Future<String?> show(BuildContext context, {String? initialName}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordingNameDialog(initialName: initialName),
    );
  }

  @override
  State<RecordingNameDialog> createState() => _RecordingNameDialogState();
}

class _RecordingNameDialogState extends State<RecordingNameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Use provided name or generate default
    String defaultName;
    if (widget.initialName != null) {
      // Remove file extension if present for editing
      defaultName = widget.initialName!;
      if (defaultName.endsWith('.m4a')) {
        defaultName = defaultName.substring(0, defaultName.length - 4);
      } else if (defaultName.endsWith('.mp3') || defaultName.endsWith('.wav')) {
        defaultName = defaultName.substring(0, defaultName.length - 4);
      }
    } else {
      // Generate smart default name with date/time
      final now = DateTime.now();
      final formattedDate = '${now.day.toString().padLeft(2, '0')}.'
          '${now.month.toString().padLeft(2, '0')}.'
          '${now.year} '
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}';
      defaultName = 'Aufnahme $formattedDate';
    }

    _nameController.text = defaultName;

    // Select all text when dialog opens for easy replacement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _nameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _nameController.text.length,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _sanitizeFileName(_nameController.text.trim()));
    }
  }

  /// Removes or replaces characters that are invalid in file names
  String _sanitizeFileName(String name) {
    // Replace invalid characters with underscore
    // Invalid chars: \ / : * ? " < > |
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.defaultBorderRadius),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Row(
                  children: [
                    Icon(
                      widget.initialName != null ? Icons.edit : Icons.mic,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.initialName != null
                            ? 'Aufnahme umbenennen'
                            : 'Aufnahme benennen',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Text field
                TextFormField(
                  controller: _nameController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Name der Aufnahme',
                    hintText: 'z.B. Meeting-Notizen',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte geben Sie einen Namen ein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Bottom actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Abbrechen'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text('Speichern'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
