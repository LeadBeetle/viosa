import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prompt_result.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import 'collapsible_text_section.dart';
import 'info_chip.dart';

/// Displays a list of prompt results with swipe-to-delete functionality
class PromptResultsList extends StatefulWidget {
  final List<PromptResult> results;
  final Function(String) onDelete;
  final Function(PromptResult)? onRestore;

  const PromptResultsList({
    super.key,
    required this.results,
    required this.onDelete,
    this.onRestore,
  });

  @override
  State<PromptResultsList> createState() => _PromptResultsListState();
}

class _PromptResultsListState extends State<PromptResultsList> {
  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prompt-Ergebnisse (${widget.results.length})',
          style: Theme.of(context).textTheme.titleLarge,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Column(
          children: widget.results.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final result = entry.value;
              final isNewest = index == 0;

              return _DismissiblePromptResult(
                key: ValueKey(result.id),
                result: result,
                onDelete: widget.onDelete,
                onRestore: widget.onRestore,
                isExpanded: true,
                showHighlight: isNewest,
              );
            },
          ).toList(),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
      ],
    );
  }
}

/// Individual prompt result card with swipe-to-delete
class _DismissiblePromptResult extends StatefulWidget {
  final PromptResult result;
  final Function(String) onDelete;
  final Function(PromptResult)? onRestore;
  final bool isExpanded;
  final bool showHighlight;

  const _DismissiblePromptResult({
    super.key,
    required this.result,
    required this.onDelete,
    this.onRestore,
    this.isExpanded = false,
    this.showHighlight = false,
  });

  @override
  State<_DismissiblePromptResult> createState() => _DismissiblePromptResultState();
}

class _DismissiblePromptResultState extends State<_DismissiblePromptResult> {
  bool _showHighlight = false;

  @override
  void initState() {
    super.initState();
    if (widget.showHighlight) {
      _showHighlight = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showHighlight = false;
          });
        }
      });
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Prompt-Ergebnis löschen?'),
              content: Text(
                'Möchten Sie das Ergebnis "${widget.result.promptName}" wirklich löschen?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Löschen'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _handleDismissed(BuildContext context) {
    widget.onDelete(widget.result.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.result.promptName} gelöscht'),
        duration: const Duration(seconds: 5),
        action: widget.onRestore != null
            ? SnackBarAction(
                label: 'Rückgängig',
                onPressed: () {
                  widget.onRestore!(widget.result);
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        border: _showHighlight
            ? Border.all(color: Colors.green, width: 3)
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Dismissible(
        key: Key(widget.result.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 32,
          ),
        ),
        confirmDismiss: (direction) => _confirmDelete(context),
        onDismissed: (direction) => _handleDismissed(context),
        child: Selector<SettingsProvider, double>(
          selector: (_, settings) => settings.textSize,
          builder: (context, fontSize, child) => CollapsibleTextSection(
            title: 'Prompt: ${widget.result.promptName}',
            content: widget.result.llmResponse,
            isExpanded: widget.isExpanded,
            contentStyle: TextStyle(
              fontSize: fontSize,
              height: 1.5,
            ),
            metadata: Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                InfoChip(
                  label: 'Modell: ${widget.result.modelUsed}',
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
        ),
      ),
    );
  }
}
