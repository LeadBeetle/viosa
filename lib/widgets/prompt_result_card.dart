import 'package:flutter/material.dart';
import '../models/prompt_result.dart';
import '../utils/constants.dart';
import 'info_chip.dart';
import 'collapsible_text_section.dart';

/// Widget displaying prompt application results
/// Follows Single Responsibility Principle: Only displays prompt result data
class PromptResultCard extends StatefulWidget {
  final PromptResult result;
  final VoidCallback? onClose;

  const PromptResultCard({
    super.key,
    required this.result,
    this.onClose,
  });

  @override
  State<PromptResultCard> createState() => _PromptResultCardState();
}

class _PromptResultCardState extends State<PromptResultCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              Icons.auto_awesome,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              widget.result.promptName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  tooltip: _isExpanded ? 'Einklappen' : 'Ausklappen',
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                    tooltip: 'Entfernen',
                  ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CollapsibleTextSection(
                    title: 'AI-Antwort',
                    content: widget.result.llmResponse,
                    isExpanded: false,
                    contentStyle: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                    metadata: Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      children: [
                        InfoChip(
                          label: widget.result.modelUsed,
                          icon: Icons.memory,
                        ),
                        InfoChip(
                          label: '${widget.result.wordCount} Wörter',
                          icon: Icons.text_fields,
                        ),
                        InfoChip(
                          label: '${widget.result.characterCount} Zeichen',
                          icon: Icons.abc,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  ExpansionTile(
                    title: const Text('Original-Transkription'),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppConstants.defaultBorderRadius),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: SelectableText(
                          widget.result.transcriptionText,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
