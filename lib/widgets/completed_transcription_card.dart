import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transcription_result.dart';
import '../providers/settings_provider.dart';
import 'collapsible_text_section.dart';
import 'info_chip.dart';
import '../utils/constants.dart';

/// Card widget for displaying completed transcription with apply prompt button
class CompletedTranscriptionCard extends StatelessWidget {
  final TranscriptionResult transcriptionResult;
  final bool isPromptActive;
  final VoidCallback onApplyPrompt;

  const CompletedTranscriptionCard({
    super.key,
    required this.transcriptionResult,
    required this.isPromptActive,
    required this.onApplyPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<SettingsProvider>(
          builder: (context, settings, _) => CollapsibleTextSection(
            title: 'Transkription',
            content: transcriptionResult.text,
            isExpanded: true,
            contentStyle: TextStyle(
              fontSize: settings.textSize,
              height: 1.5,
            ),
            metadata: Wrap(
              spacing: 8,
              children: [
                InfoChip(
                  label: 'Sprache: ${transcriptionResult.language}',
                  icon: Icons.language,
                ),
                InfoChip(
                  label: 'Modell: ${transcriptionResult.modelUsed}',
                  icon: Icons.memory,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        ElevatedButton.icon(
          onPressed: isPromptActive ? null : onApplyPrompt,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Prompt anwenden'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
      ],
    );
  }
}
