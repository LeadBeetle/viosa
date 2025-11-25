import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prompt_result.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../l10n/l10n.dart';
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
          context.l10n.promptResultsCount(widget.results.length),
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
                isExpanded: false,
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
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: Text(ctx.l10n.deletePromptResult),
              content: Text(
                ctx.l10n.deletePromptResultConfirmation(widget.result.promptName),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(ctx.l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text(ctx.l10n.delete),
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
        content: Text(context.l10n.promptResultDeleted(widget.result.promptName)),
        duration: const Duration(seconds: 5),
        action: widget.onRestore != null
            ? SnackBarAction(
                label: context.l10n.undo,
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
            title: context.l10n.promptLabel(widget.result.promptName),
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
                  label: context.l10n.modelUsedLabel(widget.result.modelUsed),
                  icon: Icons.memory,
                ),
                InfoChip(
                  label: context.l10n.wordsLabel(widget.result.wordCount),
                  icon: Icons.text_fields,
                ),
                InfoChip(
                  label: context.l10n.charactersLabel(widget.result.characterCount),
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
