import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'streaming_text_display.dart';
import 'info_chip.dart';
import '../utils/constants.dart';

/// Card widget for displaying streaming prompt response
class StreamingPromptCard extends StatelessWidget {
  final String promptName;
  final Stream<String>? textStream;
  final VoidCallback onStreamComplete;
  final Function(String) onStreamError;
  final Function(String) onChunk;

  const StreamingPromptCard({
    super.key,
    required this.promptName,
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
            title: 'Prompt: $promptName',
            textStream: textStream,
            contentStyle: TextStyle(
              fontSize: settings.textSize,
              height: 1.5,
            ),
            metadata: Wrap(
              spacing: 8,
              children: [
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
