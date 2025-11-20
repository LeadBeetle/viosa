import 'package:flutter/material.dart';
import '../models/model_config.dart';
import '../utils/audio_utils.dart';

/// Dialog to confirm starting a transcription
/// Shows file duration, split info, and selected model
class TranscriptionConfirmationDialog extends StatelessWidget {
  final Duration duration;
  final bool shouldSplit;
  final int splitCount;
  final ModelConfig selectedModel;

  const TranscriptionConfirmationDialog({
    super.key,
    required this.duration,
    required this.shouldSplit,
    required this.splitCount,
    required this.selectedModel,
  });

  /// Shows the dialog and returns true if user confirms
  static Future<bool> show(
    BuildContext context, {
    required Duration duration,
    required bool shouldSplit,
    required int splitCount,
    required ModelConfig selectedModel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TranscriptionConfirmationDialog(
        duration: duration,
        shouldSplit: shouldSplit,
        splitCount: splitCount,
        selectedModel: selectedModel,
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(shouldSplit ? 'Lange Audiodatei erkannt' : 'Transkription starten'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shouldSplit
                ? 'Diese Audiodatei ist ${AudioUtils.formatDurationShort(duration)} lang und '
                  'wird in $splitCount Segmente aufgeteilt (je ~10 Minuten).\n\n'
                  'Die Transkription läuft im Hintergrund und kann einige Minuten dauern.'
                : 'Diese Audiodatei ist ${AudioUtils.formatDurationShort(duration)} lang.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.smart_toy_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modell: ${selectedModel.name}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        selectedModel.tier,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Starten'),
        ),
      ],
    );
  }
}
