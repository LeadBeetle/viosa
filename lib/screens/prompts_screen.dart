import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prompt.dart';
import '../providers/prompts_provider.dart';
import '../utils/constants.dart';
import '../widgets/prompt_edit_dialog.dart';
import '../services/snackbar_service.dart';

/// Screen for managing prompt templates
/// Follows Single Responsibility Principle: Manages prompt list UI
class PromptsScreen extends StatefulWidget {
  const PromptsScreen({super.key});

  @override
  State<PromptsScreen> createState() => _PromptsScreenState();
}

class _PromptsScreenState extends State<PromptsScreen> {
  Future<void> _createNewPrompt() async {
    final result = await showModalBottomSheet<Prompt>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const PromptEditDialog(),
    );

    if (result != null) {
      await _savePrompt(result);
    }
  }

  Future<void> _editPrompt(Prompt prompt) async {
    final result = await showModalBottomSheet<Prompt>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PromptEditDialog(prompt: prompt),
    );

    if (result != null) {
      await _savePrompt(result);
    }
  }

  Future<void> _savePrompt(Prompt prompt) async {
    try {
      final promptsProvider = context.read<PromptsProvider>();
      await promptsProvider.addPrompt(prompt);
      if (mounted) {
        _showSuccessSnackBar('Prompt erfolgreich gespeichert');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Speichern des Prompts: $e');
      }
    }
  }

  Future<void> _deletePrompt(Prompt prompt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prompt löschen'),
        content: Text('Möchten Sie "${prompt.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final promptsProvider = context.read<PromptsProvider>();
        await promptsProvider.deletePrompt(prompt.id);
        if (mounted) {
          _showSuccessSnackBar('Prompt gelöscht');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Fehler beim Löschen des Prompts: $e');
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    SnackBarService.showError(context, message);
  }

  void _showSuccessSnackBar(String message) {
    SnackBarService.showSuccess(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PromptsProvider>(
      builder: (context, promptsProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Prompts'),
          ),
          body: promptsProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Eigene Prompts',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton.icon(
                          onPressed: _createNewPrompt,
                          icon: const Icon(Icons.add),
                          label: const Text('Neu'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (promptsProvider.customPrompts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.text_snippet_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Noch keine eigenen Prompts',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Erstellen Sie eigene Prompts für Ihre Transkriptionen',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...promptsProvider.customPrompts.map((prompt) => _buildPromptCard(prompt)),
                    if (promptsProvider.customPrompts.isNotEmpty) const SizedBox(height: 24),
                    if (promptsProvider.predefinedPrompts.isNotEmpty) ...[
                      Text(
                        'Vordefinierte Prompts',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ...promptsProvider.predefinedPrompts.map((prompt) => _buildPromptCard(prompt)),
                    ],
              ],
            ),
        );
      },
    );
  }

  Widget _buildPromptCard(Prompt prompt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          prompt.isPredefined ? Icons.star : Icons.text_snippet,
          color: prompt.isPredefined
              ? Colors.amber
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(prompt.name),
        subtitle: Text(
          prompt.template,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: prompt.isPredefined
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editPrompt(prompt);
                  } else if (value == 'delete') {
                    _deletePrompt(prompt);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Bearbeiten'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('Löschen'),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
