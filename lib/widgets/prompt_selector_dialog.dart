import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prompt.dart';
import '../providers/prompts_provider.dart';
import '../services/snackbar_service.dart';
import '../l10n/l10n.dart';

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
      final l10n = context.l10n;
      setState(() {
        _customPrompts = promptsProvider.customPrompts;
        _predefinedPrompts = promptsProvider.getPredefinedPrompts(l10n);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackBarService().showError(context, context.l10n.errorLoadingPrompts(e.toString()));
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
      leading: Icon(
        isSelected
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
      title: Text(context.l10n.selectPrompt),
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
                              ? context.l10n.customPromptsCount(_customPrompts.length)
                              : context.l10n.customPrompts,
                        ),
                      ),
                      Tab(
                        child: Text(context.l10n.standardPromptsCount(_predefinedPrompts.length)),
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
                          context.l10n.noCustomPromptsAvailable,
                        ),
                        _buildPromptList(
                          _predefinedPrompts,
                          context.l10n.noPredefinedPromptsAvailable,
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
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _selectedPrompt == null ? null : _selectPrompt,
          child: Text(context.l10n.apply),
        ),
      ],
    );
  }
}
