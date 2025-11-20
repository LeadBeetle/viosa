import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'streaming_text_display.dart';
import 'info_chip.dart';
import '../utils/constants.dart';

/// Card widget for displaying streaming transcription
class StreamingTranscriptionCard extends StatelessWidget {
  final Stream<String>? textStream;
  final VoidCallback onStreamComplete;
  final Function(String) onStreamError;
  final Function(String) onChunk;

  const StreamingTranscriptionCard({
    super.key,
    required this.textStream,
    required this.onStreamComplete,
    required this.onStreamError,
    required this.onChunk,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Consumer<SettingsProvider>(
          builder: (context, settings, _) => StreamingTextDisplay(
            title: 'Transkription',
            textStream: textStream,
            contentStyle: TextStyle(
              fontSize: settings.textSize,
              height: 1.5,
            ),
            metadata: Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                InfoChip(
                  label: 'Sprache: ${settings.language}',
                  icon: Icons.language,
                ),
                InfoChip(
                  label: 'Modell: ${settings.selectedModel}',
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
