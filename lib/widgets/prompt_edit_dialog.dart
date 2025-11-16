import 'package:flutter/material.dart';
import '../models/prompt.dart';
import '../utils/constants.dart';
import 'placeholder_text_editing_controller.dart';

/// Modal bottom sheet for creating or editing a prompt
/// Follows Single Responsibility Principle: Only handles prompt editing UI
/// Uses modal bottom sheet for better mobile UX and keyboard handling
class PromptEditDialog extends StatefulWidget {
  final Prompt? prompt;

  const PromptEditDialog({super.key, this.prompt});

  @override
  State<PromptEditDialog> createState() => _PromptEditDialogState();
}

class _PromptEditDialogState extends State<PromptEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final PlaceholderTextEditingController _templateController;
  bool _advancedMode = false;

  @override
  void initState() {
    super.initState();

    // Initialize template controller with placeholder highlighting
    _templateController = PlaceholderTextEditingController(
      text: widget.prompt?.template ?? '',
      placeholder: '{transcription}',
    );

    if (widget.prompt != null) {
      _nameController.text = widget.prompt!.name;
      // Enable advanced mode if prompt already contains placeholder
      _advancedMode = widget.prompt!.template.contains('{transcription}');
    }
    // Listen to template changes to update visual feedback
    _templateController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _templateController.dispose();
    super.dispose();
  }

  void _insertPlaceholder() {
    final currentText = _templateController.text;
    final cursorPosition = _templateController.selection.baseOffset;

    // Insert placeholder at cursor position
    final newText = '${currentText.substring(0, cursorPosition)}'
        '{transcription}'
        '${currentText.substring(_templateController.selection.extentOffset)}';

    _templateController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: cursorPosition + '{transcription}'.length,
      ),
    );
  }

  String _getFinalTemplate() {
    final template = _templateController.text.trim();

    // If advanced mode and already contains placeholder, use as-is
    if (_advancedMode && template.contains('{transcription}')) {
      return template;
    }

    // If not in advanced mode or no placeholder, auto-inject at end
    if (!template.contains('{transcription}')) {
      return '$template\n\n{transcription}';
    }

    return template;
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final prompt = Prompt(
        id: widget.prompt?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        template: _getFinalTemplate(),
        isPredefined: false,
      );
      Navigator.pop(context, prompt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.prompt != null;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.defaultPadding,
                    0,
                    AppConstants.defaultPadding,
                    AppConstants.defaultPadding,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? 'Prompt bearbeiten' : 'Neuer Prompt',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Abbrechen',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Prompt-Name',
                            hintText: 'z.B. Zusammenfassen',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Bitte geben Sie einen Namen ein';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Advanced mode toggle
                        CheckboxListTile(
                          value: _advancedMode,
                          onChanged: (value) {
                            setState(() {
                              _advancedMode = value ?? false;
                            });
                          },
                          title: const Text('Erweiterte Optionen'),
                          subtitle: Text(
                            _advancedMode
                                ? 'Manuelle Platzierung der Transkription'
                                : 'Transkription wird automatisch am Ende eingefügt',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        const SizedBox(height: 8),
                        // Insert placeholder button (only in advanced mode)
                        if (_advancedMode)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: _insertPlaceholder,
                                icon: const Icon(Icons.add_circle_outline, size: 18),
                                label: const Text('Transkription einfügen'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          ),
                        TextFormField(
                          controller: _templateController,
                          decoration: InputDecoration(
                            labelText: 'Prompt-Vorlage',
                            hintText: _advancedMode
                                ? 'Verwenden Sie den Button oben, um {transcription} einzufügen'
                                : 'Beschreiben Sie, was mit der Transkription geschehen soll',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 10,
                          minLines: 6,
                          textInputAction: TextInputAction.newline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Bitte geben Sie eine Vorlage ein';
                            }
                            // No validation for placeholder in simple mode
                            return null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: Row(
                            children: [
                              // Status indicator
                              if (_advancedMode && _templateController.text.contains('{transcription}'))
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Chip(
                                    avatar: Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    label: const Text('{transcription} gefunden'),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  _advancedMode
                                      ? 'Verwenden Sie {transcription}, wo der Text eingefügt werden soll'
                                      : 'Die Transkription wird automatisch an Ihren Prompt angehängt',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Beispiel',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _advancedMode
                                    ? 'Fasse den folgenden Text zusammen:\n\n{transcription}\n\nAchte dabei auf die Hauptpunkte.'
                                    : 'Fasse den Text zusammen und liste die wichtigsten Punkte auf.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Add extra space at bottom for comfortable scrolling
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // Bottom actions
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: SafeArea(
                    child: Row(
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
                          child: FilledButton(
                            onPressed: _save,
                            child: Text(isEditing ? 'Speichern' : 'Erstellen'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
