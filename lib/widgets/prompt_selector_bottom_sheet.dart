import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prompt.dart';
import '../providers/prompts_provider.dart';
import '../services/snackbar_service.dart';
import '../utils/constants.dart';
import '../l10n/l10n.dart';

/// Bottom sheet for selecting a prompt with tabs for custom and built-in prompts
class PromptSelectorBottomSheet extends StatefulWidget {
  const PromptSelectorBottomSheet({super.key});

  static Future<Map<String, String>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      builder: (context) => const PromptSelectorBottomSheet(),
    );
  }

  @override
  State<PromptSelectorBottomSheet> createState() => _PromptSelectorBottomSheetState();
}

class _PromptSelectorBottomSheetState extends State<PromptSelectorBottomSheet>
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrompts();
    });
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
          padding: const EdgeInsets.all(AppSpacing.l),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
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
              margin: const EdgeInsets.only(left: AppSpacing.s),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.medium),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.selectPrompt,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Expanded(
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
            // Actions
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(context.l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: FilledButton(
                        onPressed: _selectedPrompt == null ? null : _selectPrompt,
                        child: Text(context.l10n.apply),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
