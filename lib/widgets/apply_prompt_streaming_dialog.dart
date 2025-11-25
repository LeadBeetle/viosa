import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/prompt.dart';
import '../models/prompt_result.dart';
import '../providers/prompts_provider.dart';
import '../providers/settings_provider.dart';
import '../services/llm_provider.dart';
import '../services/llm_provider_factory.dart';
import '../utils/constants.dart';
import '../l10n/l10n.dart';

/// Dialog for selecting and applying a prompt with streaming response
/// Follows Single Responsibility Principle: Handles streaming prompt application UI
class ApplyPromptStreamingDialog extends StatefulWidget {
  final String transcriptionText;

  const ApplyPromptStreamingDialog({
    super.key,
    required this.transcriptionText,
  });

  @override
  State<ApplyPromptStreamingDialog> createState() => _ApplyPromptStreamingDialogState();
}

class _ApplyPromptStreamingDialogState extends State<ApplyPromptStreamingDialog> {
  ILLMProvider _getLLMProvider() {
    final model = context.read<SettingsProvider>().selectedModel;
    return LLMProviderFactory.createForModel(model);
  }

  List<Prompt> _prompts = [];
  Prompt? _selectedPrompt;
  bool _isLoading = true;
  bool _isStreaming = false;
  String _streamedResponse = '';
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
      _isStreaming = true;
      _errorMessage = null;
      _streamedResponse = '';
    });

    try {
      // Apply template with auto-injection support
      final promptText = context.read<PromptsProvider>().applyPromptTemplate(
        _selectedPrompt!.template,
        widget.transcriptionText,
      );

      final stream = _getLLMProvider().applyPromptStreaming(
        apiKey: apiKey,
        promptName: _selectedPrompt!.name,
        promptTemplate: promptText,
        transcriptionText: widget.transcriptionText,
      );

      await for (final chunk in stream) {
        setState(() {
          _streamedResponse += chunk;
        });
      }

      // Create result and return it
      final model = context.read<SettingsProvider>().selectedModel;
      final result = PromptResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        promptName: _selectedPrompt!.name,
        promptTemplate: _selectedPrompt!.template,
        transcriptionText: widget.transcriptionText,
        llmResponse: _streamedResponse,
        modelUsed: model,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isStreaming = false;
      });
    }
  }

  void _cancelStreaming() {
    if (_streamedResponse.isNotEmpty) {
      // Create partial result
      final model = context.read<SettingsProvider>().selectedModel;
      final result = PromptResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        promptName: '${_selectedPrompt!.name} (${context.l10n.cancelled})',
        promptTemplate: _selectedPrompt!.template,
        transcriptionText: widget.transcriptionText,
        llmResponse: _streamedResponse,
        modelUsed: model,
        timestamp: DateTime.now(),
      );
      Navigator.pop(context, result);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isStreaming ? context.l10n.generatingResponse : context.l10n.applyPrompt),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
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
                  if (_errorMessage != null) ...{
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
                  },
                  if (!_isStreaming) ...{
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
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _prompts.length,
                          itemBuilder: (context, index) {
                            final prompt = _prompts[index];
                            final isSelected = _selectedPrompt?.id == prompt.id;

                            return Card(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primaryContainer
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
                  } else ...{
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: _streamedResponse.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : MarkdownBody(
                                  data: _streamedResponse,
                                  selectable: true,
                                  styleSheet: MarkdownStyleSheet(
                                    p: Theme.of(context).textTheme.bodyMedium,
                                    h1: Theme.of(context).textTheme.headlineSmall,
                                    h2: Theme.of(context).textTheme.titleLarge,
                                    h3: Theme.of(context).textTheme.titleMedium,
                                    code: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontFamily: 'monospace',
                                          backgroundColor:
                                              Theme.of(context).colorScheme.surfaceContainerHigh,
                                        ),
                                    listBullet: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  },
                ],
              ),
      ),
      actions: [
        if (!_isStreaming) ...{
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton.icon(
            onPressed: _selectedPrompt == null ? null : _applyPrompt,
            icon: const Icon(Icons.auto_awesome),
            label: Text(context.l10n.apply),
          ),
        } else ...{
          FilledButton.icon(
            onPressed: _cancelStreaming,
            icon: const Icon(Icons.stop),
            label: Text(context.l10n.cancel),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        },
      ],
    );
  }
}
