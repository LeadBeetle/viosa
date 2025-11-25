import 'package:flutter/material.dart';
import '../models/model_config.dart';
import '../utils/audio_utils.dart';
import '../l10n/l10n.dart';

/// Dialog to confirm starting a transcription
/// Shows file duration, split info, and selected model
class TranscriptionConfirmationDialog extends StatelessWidget {
  final Duration duration;
  final bool shouldSplit;
  final int splitCount;
  final ModelConfig selectedModel;
  final bool hasExistingData;

  const TranscriptionConfirmationDialog({
    super.key,
    required this.duration,
    required this.shouldSplit,
    required this.splitCount,
    required this.selectedModel,
    this.hasExistingData = false,
  });

  /// Shows the dialog and returns true if user confirms
  static Future<bool> show(
    BuildContext context, {
    required Duration duration,
    required bool shouldSplit,
    required int splitCount,
    required ModelConfig selectedModel,
    bool hasExistingData = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TranscriptionConfirmationDialog(
        duration: duration,
        shouldSplit: shouldSplit,
        splitCount: splitCount,
        selectedModel: selectedModel,
        hasExistingData: hasExistingData,
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(shouldSplit ? context.l10n.longAudioDetected : context.l10n.startTranscription),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning if existing data
          if (hasExistingData) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.warningExistingData,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            shouldSplit
                ? context.l10n.longAudioDescription(AudioUtils.formatDurationShort(duration), splitCount)
                : context.l10n.shortAudioDescription(AudioUtils.formatDurationShort(duration)),
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
                        context.l10n.modelLabel(selectedModel.name),
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
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.l10n.start),
        ),
      ],
    );
  }
}
