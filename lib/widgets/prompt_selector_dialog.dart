import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prompt.dart';
import '../providers/prompts_provider.dart';
import '../services/snackbar_service.dart';

/// Dialog for selecting a prompt with tabs for custom and built-in prompts
class PromptSelectorDialog extends StatefulWidget {
  const PromptSelectorDialog({super.key});

  @override
  State<PromptSelectorDialog> createState() => _PromptSelectorDialogState();
}

class _PromptSelectorDialogState extends State<PromptSelectorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Prompt> _customPrompts = [];
  List<Prompt> _predefinedPrompts = [];
  Prompt? _selectedPrompt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPrompts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPrompts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final promptsProvider = context.read<PromptsProvider>();
      setState(() {
        _customPrompts = promptsProvider.customPrompts;
        _predefinedPrompts = promptsProvider.predefinedPrompts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackBarService().showError(context, 'Fehler beim Laden der Prompts: $e');
      }
    }
  }

  void _selectPrompt() {
    if (_selectedPrompt != null) {
      Navigator.of(context).pop({
        'promptId': _selectedPrompt!.id,
        'promptName': _selectedPrompt!.name,
        'promptTemplate': _selectedPrompt!.template,
      });
    }
  }

  Widget _buildPromptList(List<Prompt> prompts, String emptyMessage) {
    if (prompts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            emptyMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: prompts.length,
      itemBuilder: (context, index) {
        final prompt = prompts[index];
        final isSelected = _selectedPrompt?.id == prompt.id;
        return _buildPromptTile(prompt, isSelected);
      },
    );
  }

  Widget _buildPromptTile(Prompt prompt, bool isSelected) {
    return ListTile(
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
        prompt.template.length > 100
            ? '${prompt.template.substring(0, 100)}...'
            : prompt.template,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Radio<String>(
        value: prompt.id,
        groupValue: _selectedPrompt?.id,
        onChanged: (String? value) {
          setState(() {
            _selectedPrompt = prompt;
          });
        },
      ),
      selected: isSelected,
      onTap: () {
        setState(() {
          _selectedPrompt = prompt;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Prompt auswählen'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabAlignment: TabAlignment.fill,
                    tabs: [
                      Tab(
                        child: Text(
                          _customPrompts.isNotEmpty
                              ? 'Eigene (${_customPrompts.length})'
                              : 'Eigene',
                        ),
                      ),
                      Tab(
                        child: Text('Standard (${_predefinedPrompts.length})'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPromptList(
                          _customPrompts,
                          'Keine eigenen Prompts vorhanden.\n\nErstellen Sie Ihre eigenen Prompts unter "Prompts" in der Navigation.',
                        ),
                        _buildPromptList(
                          _predefinedPrompts,
                          'Keine vordefinierten Prompts verfügbar.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _selectedPrompt == null ? null : _selectPrompt,
          child: const Text('Anwenden'),
        ),
      ],
    );
  }
}
