import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prompt_result.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import 'collapsible_text_section.dart';
import 'info_chip.dart';

/// Displays a list of prompt results with swipe-to-delete functionality
class PromptResultsList extends StatelessWidget {
  final List<PromptResult> results;
  final Function(String) onDelete;

  const PromptResultsList({
    super.key,
    required this.results,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prompt-Ergebnisse',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) => Column(
            children: results
                .map(
                  (result) => _DismissiblePromptResult(
                    result: result,
                    fontSize: settings.textSize,
                    onDelete: onDelete,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
      ],
    );
  }
}

/// Individual prompt result card with swipe-to-delete
class _DismissiblePromptResult extends StatelessWidget {
  final PromptResult result;
  final double fontSize;
  final Function(String) onDelete;

  const _DismissiblePromptResult({
    required this.result,
    required this.fontSize,
    required this.onDelete,
  });

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Prompt-Ergebnis löschen?'),
              content: Text(
                'Möchten Sie das Ergebnis "${result.promptName}" wirklich löschen?',
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
    onDelete(result.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.promptName} gelöscht'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(result.id),
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
      child: CollapsibleTextSection(
        title: 'Prompt: ${result.promptName}',
        content: result.llmResponse,
        isExpanded: false,
        contentStyle: TextStyle(
          fontSize: fontSize,
          height: 1.5,
        ),
        metadata: Wrap(
          spacing: 8,
          children: [
            InfoChip(
              label: 'Modell: ${result.modelUsed}',
              icon: Icons.memory,
            ),
            InfoChip(
              label:
                  '${result.timestamp.day}.${result.timestamp.month}.${result.timestamp.year} ${result.timestamp.hour}:${result.timestamp.minute.toString().padLeft(2, '0')}',
              icon: Icons.access_time,
            ),
          ],
        ),
      ),
    );
  }
}
