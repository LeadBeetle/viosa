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

class _PromptsScreenState extends State<PromptsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
            bottom: TabBar(
              controller: _tabController,
              tabAlignment: TabAlignment.fill,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        promptsProvider.customPrompts.isNotEmpty
                            ? 'Eigene (${promptsProvider.customPrompts.length})'
                            : 'Eigene',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, size: 16),
                      const SizedBox(width: 4),
                      Text('Standard (${promptsProvider.predefinedPrompts.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: promptsProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Custom Prompts Tab
                    _buildCustomPromptsTab(promptsProvider),
                    // Predefined Prompts Tab
                    _buildPredefinedPromptsTab(promptsProvider),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _createNewPrompt,
            tooltip: 'Neuer Prompt',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildCustomPromptsTab(PromptsProvider promptsProvider) {
    if (promptsProvider.customPrompts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _createNewPrompt,
                icon: const Icon(Icons.add),
                label: const Text('Prompt erstellen'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: promptsProvider.customPrompts.length,
      itemBuilder: (context, index) {
        final prompt = promptsProvider.customPrompts[index];
        return _buildPromptCard(prompt);
      },
    );
  }

  Widget _buildPredefinedPromptsTab(PromptsProvider promptsProvider) {
    if (promptsProvider.predefinedPrompts.isEmpty) {
      return const Center(
        child: Text('Keine vordefinierten Prompts verfügbar'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: promptsProvider.predefinedPrompts.length,
      itemBuilder: (context, index) {
        final prompt = promptsProvider.predefinedPrompts[index];
        return _buildPromptCard(prompt);
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                prompt.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (prompt.usageCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${prompt.usageCount}x',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
          ],
        ),
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
