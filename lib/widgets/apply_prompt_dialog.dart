import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prompt.dart';
import '../providers/prompts_provider.dart';
import '../providers/settings_provider.dart';
import '../services/llm_provider.dart';
import '../services/llm_provider_factory.dart';
import '../l10n/l10n.dart';

/// Dialog for selecting and applying a prompt to transcription text
/// Follows Single Responsibility Principle: Handles prompt application UI
class ApplyPromptDialog extends StatefulWidget {
  final String transcriptionText;

  const ApplyPromptDialog({
    super.key,
    required this.transcriptionText,
  });

  @override
  State<ApplyPromptDialog> createState() => _ApplyPromptDialogState();
}

class _ApplyPromptDialogState extends State<ApplyPromptDialog> {
  ILLMProvider _getLLMProvider() {
    final model = context.read<SettingsProvider>().completionModelId;
    return LLMProviderFactory.createForModel(model);
  }

  List<Prompt> _prompts = [];
  Prompt? _selectedPrompt;
  bool _isLoading = true;
  bool _isApplying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPrompts();
  }

  Future<void> _loadPrompts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final promptsProvider = context.read<PromptsProvider>();
      final l10n = context.l10n;
      final prompts = promptsProvider.getAllPrompts(l10n);
      setState(() {
        _prompts = prompts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = context.l10n.errorLoadingPrompts(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _applyPrompt() async {
    if (_selectedPrompt == null) {
      return;
    }

    final settingsProvider = context.read<SettingsProvider>();
    final apiKey = settingsProvider.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _errorMessage = context.l10n.configureApiKey;
      });
      return;
    }

    setState(() {
      _isApplying = true;
      _errorMessage = null;
    });

    try {
      // Apply template with auto-injection support
      final promptText = context.read<PromptsProvider>().applyPromptTemplate(
        _selectedPrompt!.template,
        widget.transcriptionText,
      );

      final result = await _getLLMProvider().applyPrompt(
        apiKey: apiKey,
        promptName: _selectedPrompt!.name,
        promptTemplate: promptText,
        transcriptionText: widget.transcriptionText,
      );

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isApplying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.applyPrompt),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(context.l10n.selectPromptForTranscription),
                  const SizedBox(height: 16),
                  if (_prompts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        context.l10n.noPromptsAvailable,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _prompts.length,
                        itemBuilder: (context, index) {
                          final prompt = _prompts[index];
                          final isSelected = _selectedPrompt?.id == prompt.id;

                          return Card(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : null,
                            child: ListTile(
                              leading: Icon(
                                prompt.isPredefined ? Icons.star : Icons.text_snippet,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimaryContainer
                                    : prompt.isPredefined
                                        ? Colors.amber
                                        : null,
                              ),
                              title: Text(prompt.name),
                              subtitle: Text(
                                prompt.template,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              selected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedPrompt = prompt;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isApplying ? null : () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: (_isApplying || _selectedPrompt == null) ? null : _applyPrompt,
          icon: _isApplying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(_isApplying ? context.l10n.applying : context.l10n.apply),
        ),
      ],
    );
  }
}
