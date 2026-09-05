import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'streaming_text_display.dart';
import 'info_chip.dart';
import '../utils/constants.dart';
import '../repositories/model_repository.dart';
import '../l10n/l10n.dart';

/// Card widget for displaying streaming prompt response
class StreamingPromptCard extends StatelessWidget {
  final String promptName;
  final Stream<String>? textStream;
  final VoidCallback onStreamComplete;
  final Function(String) onStreamError;
  final Function(String) onChunk;
  final VoidCallback? onStop;

  const StreamingPromptCard({
    super.key,
    required this.promptName,
    required this.textStream,
    required this.onStreamComplete,
    required this.onStreamError,
    required this.onChunk,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onStop != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(context.l10n.stopGeneration),
            ),
          ),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) => StreamingTextDisplay(
            title: 'Prompt: $promptName',
            textStream: textStream,
            contentStyle: TextStyle(
              fontSize: settings.textSize,
              height: 1.5,
            ),
            metadata: Wrap(
              spacing: AppSpacing.s,
              children: [
                InfoChip(
                  label:
                      context.l10n.modelLabel(ModelRepository.defaultModel.name),
                  icon: Icons.memory,
                ),
              ],
            ),
            onStreamComplete: onStreamComplete,
            onStreamError: onStreamError,
            onChunk: onChunk,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
      ],
    );
  }
}
